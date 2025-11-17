"""
Message Classifier using LangChain (Optimal Implementation)

This is the OPTIMAL Python implementation using LangChain's structured output features:
- Uses create_agent() with response_format for native structured output
- Automatic validation with Pydantic models
- Built-in error handling and retries
- Easy to swap LLM providers (OpenAI, Anthropic, etc.)
- Better observability with LangSmith integration
"""

import os
from typing import Optional
from langchain_openai import ChatOpenAI
from schemas.classification import ClassificationV1


# Classification instructions (same as TypeScript version)
CLASSIFICATION_INSTRUCTIONS = """
System (ultra-brief, non-negotiable)
You transform real-estate operations Slack messages into JSON only that conforms to the developer instructions and schema.
Never fabricate fields. If irrelevant to ops, return IGNORE. If operational but incomplete, return INFO_REQUEST with brief explanations.
Do not output prose or code fences—JSON only.

Developer (full behavior spec)
Objective
Classify a Slack message and extract fields into a strict JSON object that matches the schema. Return only valid JSON.

Message types
• GROUP — The message declares or updates a listing container (i.e., "this is a listing entity").
Allowed group_key values:
• SALE_LISTING
• LEASE_LISTING
• SALE_LEASE_LISTING
• SOLD_SALE_LEASE_LISTING
• RELIST_LISTING
• RELIST_LISTING_DEAL_SALE_OR_LEASE
• BUY_OR_LEASED
• MARKETING_AGENDA_TEMPLATE
• STRAY - A single actionable task that does not declare/update a listing group. Pick exactly one task_key: prefer the catalog below; otherwise use OPS_MISC_TASK for any clear request.
• INFO_REQUEST - Operational/real-estate content but missing specifics to proceed. Explain what is missing in explanations.
• IGNORE - Chit-chat, reactions, or content unrelated to operations.

Decision rules & tie-breaks
• Choose exactly one message_type.
• Prefer GROUP if a message both declares/updates a listing and requests tasks.
• GROUP ⇒ set group_key (one of the allowed values) and task_key:null.
• STRAY ⇒ set exactly one task_key (from taxonomy) and group_key:null.
• If multiple task candidates appear, choose the most specific (e.g., *_CLOSING_* over *_ACTIVE_*). If ambiguity remains, use INFO_REQUEST and explain briefly.

Listing types (for listing.type)
• Only set "SALE" or "LEASE" if explicit OR unambiguously implied by the hints below. Otherwise null.
  Hints for SALE (non-exhaustive): sold, conditional, firm, purchase agreement/APS, buyer deal, closing date (sale), MLS #, open house, staging, deposit (sale), conditions removal.
  Hints for LEASE (non-exhaustive): lease/leased, tenant/landlord, showings schedule, OTL/offer to lease, LOI, rent/TMI/NNN, possession date (lease), renewal, term/rate per month.

Assignees & addresses
• assignee_hint → Person explicitly named or @-mentioned. If only pronouns ("he/she/they") or only a team ("Marketing"), set null.
• listing.address → Extract only if explicitly present in text OR clearly present within provided links/attachment titles.

Dates & timezone policy
• Timezone: America/Toronto. Use the provided message timestamp (ISO) as the reference for resolving relative dates.
• due_date → Use ISO formats: Date: YYYY-MM-DD; DateTime: YYYY-MM-DDThh:mm (24h).
• Relative phrases:
  - "by Friday"/"this Friday": choose the next occurrence of that weekday on/after the message timestamp; if no time provided, default to 17:00 local.
  - Day-only like "Oct 3": use the next such date on/after the message timestamp; if year omitted, use the message year; default time 17:00 if time missing.
  - If still ambiguous or contradictory, set null and add a brief explanation.

Best-effort vs nulls
• Prefer best-effort fills with a short explanation when reasonable (e.g., listing.type from strong hints, relative dates).
• Never fabricate addresses or names.

Task taxonomy (valid task_key values for STRAY)
Sale Listings
• SALE_ACTIVE_TASKS, SALE_SOLD_TASKS, SALE_CLOSING_TASKS

Lease Listings
• LEASE_ACTIVE_TASKS, LEASE_LEASED_TASKS, LEASE_CLOSING_TASKS, LEASE_ACTIVE_TASKS_ARLYN (special case)

Re-List Listings
• RELIST_LISTING_DEAL_SALE, RELIST_LISTING_DEAL_LEASE

Buyer Deals
• BUYER_DEAL, BUYER_DEAL_CLOSING_TASKS

Lease Tenant Deals
• LEASE_TENANT_DEAL, LEASE_TENANT_DEAL_CLOSING_TASKS

Pre-Con Deals
• PRECON_DEAL

Mutual Release
• MUTUAL_RELEASE_STEPS

General Ops
• OPS_MISC_TASK (any actionable request without a specific template)

Extraction rules
• listing.address → Street/building/unit only if explicit in text or provided links; otherwise null.
• assignee_hint → name/@mention only; pronouns/teams => null.
• due_date → resolve per rules above; if not resolvable, null with a brief explanation.
• confidence ∈ [0,1] reflects certainty of classification and extracted fields.
• explanations → brief bullets for assumptions, heuristics, or missing info; null if not needed.
"""


class MessageClassifier:
    """
    LangChain-based message classifier with structured output

    Benefits over direct OpenAI API:
    - Automatic Pydantic validation (no manual parsing)
    - Built-in error handling and retries
    - Easy to swap LLM providers
    - LangSmith tracing for debugging
    - Middleware support for future enhancements
    """

    @property
    def name(self) -> str:
        return "classifier"

    @property
    def description(self) -> str:
        return "Classifies messages and extracts structured data"

    def __init__(self, model_name: str | None = None, temperature: float = 0):
        """
        Initialize the classifier

        Args:
            model_name: OpenAI model name (default: from env or gpt-4o-mini)
            temperature: Sampling temperature (0 for deterministic)
        """
        self.model_name = model_name or os.getenv("OPENAI_MODEL", "gpt-4o-mini")

        # Initialize OpenAI chat model with structured output
        # LangChain automatically reads OPENAI_API_KEY from environment
        self.llm = ChatOpenAI(
            model=self.model_name,
            temperature=temperature,
            timeout=20.0,  # 20 second timeout (matches original)
            max_retries=0,  # No automatic retries
        ).with_structured_output(ClassificationV1)

    async def process(self, input_data: dict) -> dict:
        """
        Process input through classifier agent (BaseAgent interface)

        Args:
            input_data: Dict with 'message' and optional 'metadata'

        Returns:
            Classification result as dict
        """
        message = input_data.get("message", "")
        metadata = input_data.get("metadata", {})
        message_timestamp = metadata.get("ts")

        classification = self.classify(message, message_timestamp)

        # Return as dict for workflow compatibility
        return classification.model_dump()

    def classify(
        self, message: str, message_timestamp: Optional[str] = None
    ) -> ClassificationV1:
        """
        Classify a message and return structured output

        Args:
            message: The message text to classify
            message_timestamp: ISO timestamp of the message (for date resolution)

        Returns:
            ClassificationV1: Validated classification result

        Raises:
            ValueError: If classification fails validation
        """
        # Add timestamp context if provided
        user_message = message
        if message_timestamp:
            user_message = (
                f"Message timestamp: {message_timestamp}\n\nMessage: {message}"
            )

        # Invoke LLM with structured output
        # with_structured_output() guarantees ClassificationV1 return type
        messages = [
            {"role": "system", "content": CLASSIFICATION_INSTRUCTIONS},
            {"role": "user", "content": user_message},
        ]

        classification: ClassificationV1 = self.llm.invoke(messages)

        # Additional custom validation
        classification.validate_keys()

        return classification


# Singleton instance for reuse (optimal for serverless)
_classifier_instance = None


def get_classifier() -> MessageClassifier:
    """Get or create singleton classifier instance"""
    global _classifier_instance
    if _classifier_instance is None:
        _classifier_instance = MessageClassifier()
    return _classifier_instance


def classify_message(
    message: str, message_timestamp: str | None = None
) -> ClassificationV1:
    """
    Convenience function to classify a message

    Args:
        message: The message text to classify
        message_timestamp: ISO timestamp of the message

    Returns:
        ClassificationV1: Validated classification result
    """
    classifier = get_classifier()
    return classifier.classify(message, message_timestamp)


# Example usage and testing
if __name__ == "__main__":
    from datetime import datetime

    def test_classifier():
        """Test the classifier with example messages"""
        test_messages = [
            "We got an offer on 123 Main St! Need to schedule closing by Friday.",
            "Can someone update the MLS listing for the property at 456 Oak Ave?",
            "Great job team! 🎉",
            "Need help with a lease renewal for a tenant",
        ]

        timestamp = datetime.utcnow().isoformat()

        for msg in test_messages:
            print(f"\n{'=' * 80}")
            print(f"Message: {msg}")
            print(f"{'=' * 80}")

            try:
                result = classify_message(msg, timestamp)
                print("\nClassification:")
                print(result.model_dump_json(indent=2))
            except Exception as e:
                print(f"\nError: {e}")

    test_classifier()
