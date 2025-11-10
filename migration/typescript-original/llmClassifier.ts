import { z } from 'zod';
import { createHash } from 'crypto';
import { MessageAttributeValue, SendMessageCommand } from '@aws-sdk/client-sqs';
import { backOff } from 'exponential-backoff';
import openai from './openaiClient';
import sqs from '../db/sqsClient';
import { captureAsync } from './xray';
import { ulid } from 'ulid';
import OpenAI from 'openai';

// New V1 classification schema (message_type + group/task keys)
export type MessageType = 'GROUP' | 'STRAY' | 'INFO_REQUEST' | 'IGNORE';

export interface ClassificationV1 {
  schema_version: 1;
  message_type: MessageType;
  task_key: string | null;
  group_key:
    | 'SALE_LISTING'
    | 'LEASE_LISTING'
    | 'SALE_LEASE_LISTING'
    | 'SOLD_SALE_LEASE_LISTING'
    | 'RELIST_LISTING'
    | 'RELIST_LISTING_DEAL_SALE_OR_LEASE'
    | 'BUY_OR_LEASED'
    | 'MARKETING_AGENDA_TEMPLATE'
    | null;
  listing: { type: 'LEASE' | 'SALE' | null; address: string | null };
  assignee_hint: string | null;
  due_date: string | null; // ISO yyyy-mm-dd or yyyy-mm-ddThh:mm
  task_title: string | null; // Short summary for STRAY tasks (5-10 words, max 80 chars)
  confidence: number; // 0..1
  explanations: string[] | null;
}

// Base schema without refinement validation (for OpenAI Agents SDK compatibility)
const ClassificationV1BaseSchema = z.object({
  schema_version: z.literal(1),
  message_type: z.enum(['GROUP', 'STRAY', 'INFO_REQUEST', 'IGNORE']),
  task_key: z.union([
    z.enum([
      'SALE_ACTIVE_TASKS',
      'SALE_SOLD_TASKS',
      'SALE_CLOSING_TASKS',
      'LEASE_ACTIVE_TASKS',
      'LEASE_LEASED_TASKS',
      'LEASE_CLOSING_TASKS',
      'LEASE_ACTIVE_TASKS_ARLYN',
      'RELIST_LISTING_DEAL_SALE',
      'RELIST_LISTING_DEAL_LEASE',
      'BUYER_DEAL',
      'BUYER_DEAL_CLOSING_TASKS',
      'LEASE_TENANT_DEAL',
      'LEASE_TENANT_DEAL_CLOSING_TASKS',
      'PRECON_DEAL',
      'MUTUAL_RELEASE_STEPS',
      'OPS_MISC_TASK',
    ]),
    z.null(),
  ]),
  group_key: z.union([
    z.enum([
      'SALE_LISTING',
      'LEASE_LISTING',
      'SALE_LEASE_LISTING',
      'SOLD_SALE_LEASE_LISTING',
      'RELIST_LISTING',
      'RELIST_LISTING_DEAL_SALE_OR_LEASE',
      'BUY_OR_LEASED',
      'MARKETING_AGENDA_TEMPLATE',
    ]),
    z.null(),
  ]),
  listing: z.object({
    type: z.union([z.enum(['LEASE', 'SALE']), z.null()]),
    address: z.union([z.string(), z.null()]),
  }),
  assignee_hint: z.union([z.string(), z.null()]),
  due_date: z.union([z.string(), z.null()]),
  task_title: z.union([z.string().max(80), z.null()]),
  confidence: z.number().min(0).max(1),
  explanations: z.union([z.array(z.string()).min(1), z.null()]),
});

// Export base schema for OpenAI Agents SDK (requires plain ZodObject)
export { ClassificationV1BaseSchema };

// Full schema with refinement validation (for parsing/validation)
export const ClassificationV1Schema = ClassificationV1BaseSchema
  .refine((v) => {
    const groupPresent = v.group_key !== null;
    const taskPresent = v.task_key !== null;
    if (v.message_type === 'INFO_REQUEST' || v.message_type === 'IGNORE') {
      return !groupPresent && !taskPresent;
    }
    return groupPresent !== taskPresent;
  }, { message: 'Exactly one of group_key or task_key must be non-null unless message_type is INFO_REQUEST or IGNORE.' });

export type ClassificationV1Parsed = z.infer<typeof ClassificationV1Schema>;

function sha1Hex(input: string): string {
  return createHash('sha1').update(input).digest('hex');
}

function redactPII(text: string): string {
  if (!text) return '';
  return text
    .replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, (m) => (m.includes('*') ? m : '[REDACTED_EMAIL]'))
    .replace(/\b\+?\d[\d\s().-]{7,}\b/g, '[REDACTED_PHONE]');
}

export function extractFromSlackEvent(body: unknown):
  | { text: string; slack_user_id: string; channel_id: string; ts: string; links?: string[]; attachments?: unknown[] }
  | null {
  const payload = body as Record<string, any> | undefined;
  const type = payload?.type;

  if (type === 'event_callback' && payload?.event) {
    const event = payload.event as Record<string, any>;
    const text = String(event.text || '');
    const slackUser = String(event.user || event.user_id || '');
    const channel = String(event.channel || event.channel_id || '');
    const ts = String(event.event_ts || event.ts || payload.event_ts || '');
    if (!channel || !ts || !slackUser) return null;
    const links = Array.isArray(event.links) ? event.links : extractLinks(text);
    const attachments = Array.isArray(event.attachments) ? event.attachments : payload.attachments;
    return { text, slack_user_id: slackUser, channel_id: channel, ts, links, attachments };
  }

  if (type === 'shortcut' || type === 'message_action') {
    const text = String(
      payload?.message?.text ||
      payload?.text ||
      payload?.callback_id ||
      ''
    );
    const slackUser = String(payload?.user?.id || payload?.user_id || '');
    const channel = String(
      payload?.channel?.id ||
      payload?.channel?.name ||
      payload?.channel_id ||
      `shortcut:${slackUser}`
    );
    const ts = String(payload?.action_ts || payload?.message?.ts || payload?.ts || Date.now());
    if (!slackUser || !ts) return null;
    const links = extractLinks(text);
    const attachments = Array.isArray(payload?.attachments) ? payload?.attachments : undefined;
    return { text, slack_user_id: slackUser, channel_id: channel, ts, links, attachments };
  }

  return null;
}

function extractLinks(text: string): string[] | undefined {
  const raw = text.match(/https?:\/\/\S+/gi) ?? [];
  const cleaned = raw
    .map((u) => u.replace(/[&gt;>)\],.]+$/, '')) // remove common trailing punct or HTML-escaped '>'
    .map((u) => u.replace(/^&lt;|&gt;$/g, ''))    // strip HTML-escaped angle brackets if present
    .map((u) => u.replace(/^<|>$/g, ''))         // strip literal angle brackets
    .map((u) => u.split('|')[0]);                // keep URL before Slack's "|label" form
  return cleaned.length ? cleaned : undefined;
}

export function buildPrompt(input: { text: string; slack_user_id: string; channel_id: string; ts: string; links?: string[]; attachments?: unknown[] }) {
  const sanitizedText = redactPII(input.text);
  const tsNumber = Number(input.ts);
  const refISO = Number.isFinite(tsNumber) ? new Date(tsNumber * 1000).toISOString() : new Date().toISOString();
  const linksSection = Array.isArray(input.links) && input.links.length
    ? ['', 'Links (verbatim):', ...input.links].join('\n')
    : '';
  const system = [
    'System (ultra-brief, non-negotiable)',
    'You transform real-estate operations Slack messages into JSON only that conforms to the developer instructions and schema.',
    'Never fabricate fields. If irrelevant to ops, return IGNORE. If operational but incomplete, return INFO_REQUEST with brief explanations.',
    'Do not output prose or code fences—JSON only.',
  ].join('\n');

  const developer = [
    'Developer (full behavior spec)',
    'Objective',
    'Classify a Slack message and extract fields into a strict JSON object that matches the schema. Return only valid JSON.',
    '',
    'Message types',
    '• GROUP — The message declares or updates a listing container (i.e., “this is a listing entity”).',
    'Allowed group_key values:',
    '• SALE_LISTING',
    '• LEASE_LISTING',
    '• SALE_LEASE_LISTING',
    '• SOLD_SALE_LEASE_LISTING',
    '• RELIST_LISTING',
    '• RELIST_LISTING_DEAL_SALE_OR_LEASE',
    '• BUY_OR_LEASED',
    '• MARKETING_AGENDA_TEMPLATE',
    '• STRAY — A single actionable task that does not declare/update a listing group. Pick exactly one task_key: prefer the catalog below; otherwise use OPS_MISC_TASK for any clear request.',
    '• INFO_REQUEST — Operational/real-estate content but missing specifics to proceed. Explain what’s missing in explanations.',
    '• IGNORE — Chit-chat, reactions, or content unrelated to operations.',
    '',
    'Decision rules & tie-breaks',
    '• Choose exactly one message_type.',
    '• Prefer GROUP if a message both declares/updates a listing and requests tasks.',
    '• GROUP ⇒ set group_key (one of the allowed values) and task_key:null.',
    '• STRAY ⇒ set exactly one task_key (from taxonomy) and group_key:null.',
    '• If multiple task candidates appear, choose the most specific (e.g., *_CLOSING_* over *_ACTIVE_*). If ambiguity remains, use INFO_REQUEST and explain briefly.',
    '',
    'Listing types (for listing.type)',
    '• Only set "SALE" or "LEASE" if explicit OR unambiguously implied by the hints below. Otherwise null.',
    '  Hints for SALE (non-exhaustive): sold, conditional, firm, purchase agreement/APS, buyer deal, closing date (sale), MLS #, open house, staging, deposit (sale), conditions removal.',
    '  Hints for LEASE (non-exhaustive): lease/leased, tenant/landlord, showings schedule, OTL/offer to lease, LOI, rent/TMI/NNN, possession date (lease), renewal, term/rate per month.',
    '',
    'Assignees & addresses',
    '• assignee_hint → Person explicitly named or @-mentioned. If only pronouns (“he/she/they”) or only a team (“Marketing”), set null.',
    '• listing.address → Extract only if explicitly present in text OR clearly present within provided links/attachment titles.',
    '',
    'Dates & timezone policy',
    '• Timezone: America/Toronto. Current reference time: ' + refISO,
    '• CRITICAL: Use message_timestamp_iso as YOUR reference for "today" when parsing relative dates.',
    '',
    '• Output format rules:',
    '  - Date-only (no time mentioned): Use yyyy-MM-dd format',
    '  - Date AND time mentioned: Use yyyy-MM-ddTHH:mm format (24-hour)',
    '  - NEVER add a default time if time was not mentioned in the message',
    '',
    '• Date parsing examples (assume message_timestamp_iso = 2025-11-02T15:30:00.000Z):',
    '  - "tomorrow" → 1 day after message timestamp → "2025-11-03"',
    '  - "in 2 days" / "in two days" → 2 days after message timestamp → "2025-11-04"',
    '  - "by Friday" / "this Friday" → next Friday occurrence after message timestamp → "2025-11-08"',
    '  - "next week" → 7 days after message timestamp → "2025-11-09"',
    '  - "Oct 15" → abbreviated month, infer year → "2025-10-15"',
    '  - "November 10" → full month name, infer year → "2025-11-10"',
    '  - "December 1" → full month name, infer year → "2025-12-01"',
    '  - "due November 7" → extract date from phrase → "2025-11-07"',
    '  - "tomorrow at 3pm" → includes time → "2025-11-03T15:00"',
    '  - "Friday at 5pm" → includes time → "2025-11-08T17:00"',
    '',
    '• If ambiguous or contradictory, set null and add brief explanation.',
    '',
    'Best-effort vs nulls',
    '• Prefer best-effort fills with a short explanation when reasonable (e.g., listing.type from strong hints, relative dates).',
    '• Never fabricate addresses or names.',
    '',
    'Task taxonomy (valid task_key values for STRAY)',
    'Sale Listings',
    '• SALE_ACTIVE_TASKS, SALE_SOLD_TASKS, SALE_CLOSING_TASKS',
    '',
    'Lease Listings',
    '• LEASE_ACTIVE_TASKS, LEASE_LEASED_TASKS, LEASE_CLOSING_TASKS, LEASE_ACTIVE_TASKS_ARLYN (special case)',
    '',
    'Re-List Listings',
    '• RELIST_LISTING_DEAL_SALE, RELIST_LISTING_DEAL_LEASE',
    '',
    'Buyer Deals',
    '• BUYER_DEAL, BUYER_DEAL_CLOSING_TASKS',
    '',
    'Lease Tenant Deals',
    '• LEASE_TENANT_DEAL, LEASE_TENANT_DEAL_CLOSING_TASKS',
    '',
    'Pre-Con Deals',
    '• PRECON_DEAL',
    '',
    'Mutual Release',
    '• MUTUAL_RELEASE_STEPS',
    '',
    'General Ops',
    '• OPS_MISC_TASK (any actionable request without a specific template)',
    '',
    'Task Titles (for STRAY only)',
    '• For STRAY messages, generate a concise task_title (5-10 words max, 80 chars max) summarizing the actionable request',
    '• Remove filler words ("please", "can you", "could you")',
    '• Capitalize first word',
    '• Examples:',
    '  - "can you bring a small stack of your business cards to the office tomorrow?" → "Bring business cards to office"',
    '  - "Please update the brochure copy and send draft by Friday" → "Update brochure copy and send draft"',
    '  - "need help setting up the new listing photos" → "Set up new listing photos"',
    '• Set task_title:null for GROUP, INFO_REQUEST, IGNORE',
    '',
    'Extraction rules',
    '• listing.address → Street/building/unit only if explicit in text or provided links; otherwise null.',
    '• assignee_hint → name/@mention only; pronouns/teams => null.',
    '• due_date → resolve per rules above; if not resolvable, null with a brief explanation.',
    '• task_title → concise summary (5-10 words) for STRAY only; null for GROUP/INFO_REQUEST/IGNORE.',
    '• confidence ∈ [0,1] reflects certainty of classification and extracted fields.',
    '• explanations → brief bullets for assumptions, heuristics, or missing info; null if not needed.',
  ].join('\n');

  const fewShot = [
    {
      role: 'user' as const,
      content: 'Input: “Create a new lease listing for 22 King St W unit 1402.”',
    },
    {
      role: 'assistant' as const,
      content: JSON.stringify({
        schema_version: 1,
        message_type: 'GROUP',
        task_key: null,
        group_key: 'LEASE_LISTING',
        listing: { type: 'LEASE', address: '22 King St W unit 1402' },
        assignee_hint: null,
        due_date: null,
        task_title: null,
        confidence: 0.94,
        explanations: ['Due date not present'],
      } satisfies ClassificationV1),
    },
    {
      role: 'user' as const,
      content: 'Input: “For 18 Oak Ave, start closing checklist; target Oct 3 17:00.”',
    },
    {
      role: 'assistant' as const,
      content: JSON.stringify({
        schema_version: 1,
        message_type: 'STRAY',
        task_key: 'SALE_CLOSING_TASKS',
        group_key: null,
        listing: { type: 'SALE', address: '18 Oak Ave' },
        assignee_hint: null,
        due_date: '2025-10-03T17:00',
        task_title: 'Start closing checklist for 18 Oak Ave',
        confidence: 0.91,
        explanations: null,
      } satisfies ClassificationV1),
    },
    {
      role: 'user' as const,
      content: 'Input: “Please start active tasks for the new listing.”',
    },
    {
      role: 'assistant' as const,
      content: JSON.stringify({
        schema_version: 1,
        message_type: 'INFO_REQUEST',
        task_key: null,
        group_key: null,
        listing: { type: null, address: null },
        assignee_hint: null,
        due_date: null,
        task_title: null,
        confidence: 0.72,
        explanations: ['Missing listing type (SALE/LEASE)', 'Missing address', 'Due date not present'],
      } satisfies ClassificationV1),
    },
    {
      role: 'user' as const,
      content: 'Input: “Great job team! 🎉”',
    },
    {
      role: 'assistant' as const,
      content: JSON.stringify({
        schema_version: 1,
        message_type: 'IGNORE',
        task_key: null,
        group_key: null,
        listing: { type: null, address: null },
        assignee_hint: null,
        due_date: null,
        task_title: null,
        confidence: 0.99,
        explanations: ['Irrelevant to operations'],
      } satisfies ClassificationV1),
    },
    {
      role: 'user' as const,
      content: 'Input: “Please update the brochure copy and send draft by Friday.”',
    },
    {
      role: 'assistant' as const,
      content: JSON.stringify({
        schema_version: 1,
        message_type: 'STRAY',
        task_key: 'OPS_MISC_TASK',
        group_key: null,
        listing: { type: null, address: null },
        assignee_hint: null,
        due_date: null,
        task_title: 'Update brochure copy and send draft',
        confidence: 0.74,
        explanations: ['Generic operations request without a specific template'],
      } satisfies ClassificationV1),
    },
  ];

  const user = [
    'Return ONLY JSON per the schema.',
    '',
    `Context: timezone=America/Toronto; message_timestamp_iso=${refISO}`,
    '',
    'Message:',
    sanitizedText,
    linksSection
  ].join('\n');

  return { system, developer, user, fewShot };
}

export let callLLM = async (
  systemPrompt: string,
  userPrompt: string,
  fewShot?: Array<{ role: 'user' | 'assistant'; content: string }>,
  developerPrompt?: string,
  jsonSchema?: Record<string, unknown>
): Promise<string> => {
  const provider = (process.env.LLM_PROVIDER || '').toLowerCase();
  if (provider !== 'openai') {
    throw new Error(`LLM provider not configured${provider ? `: ${provider}` : ''}`);
  }
  const examplesSection = (fewShot && fewShot.length)
    ? ['', 'Examples:', ...fewShot.map((m) => `${m.role === 'user' ? 'User' : 'Assistant'}: ${m.content}`)].join('\n')
    : '';
  const instructions = [systemPrompt, developerPrompt || '', examplesSection]
    .filter(Boolean)
    .join('\n\n');

  const model = (process.env.OPENAI_MODEL || '').trim();
  if (!model) throw new Error('OPENAI_MODEL missing');
  const isGpt5 = model.toLowerCase().startsWith('gpt-5');
  const maxOutputTokens = Number(
    process.env.LLM_MAX_OUTPUT_TOKENS || (isGpt5 ? '2400' : '512'),
  );

  const basePayload: Record<string, any> = {
    model,
    instructions,
    input: userPrompt,
    max_output_tokens: maxOutputTokens,
  };

  if (isGpt5) {
    const effort = (process.env.LLM_REASONING_EFFORT || 'minimal').toLowerCase();
    basePayload.reasoning = { effort };
  }

  if (jsonSchema) {
    basePayload.text = {
      format: {
        type: 'json_schema',
        name: 'RealEstateOpsClassification',
        strict: true,
        schema: jsonSchema,
      },
    };
  }

  const useStreamEnv = (process.env.LLM_STREAM || 'true').toLowerCase() === 'true';
  const canStream = useStreamEnv && !isGpt5; // GPT-5 streaming requires verified org; avoid hard-failing

  const extractText = (resp: any): string | null => {
    if (!resp) return null;
    const outText = typeof resp.output_text === 'string' ? resp.output_text.trim() : '';
    if (outText) return outText;
    const output = resp.output;
    if (Array.isArray(output)) {
      for (const item of output) {
        if (item?.type === 'output_text' && typeof item?.text === 'string' && item.text.trim()) {
          return item.text.trim();
        }
        if (item?.type === 'message' && Array.isArray(item?.content)) {
          for (const c of item.content) {
            if (c?.type === 'output_text' && typeof c?.text === 'string' && c.text.trim()) {
              return c.text.trim();
            }
          }
        }
      }
    }
    return null;
  };

  try {
    if (canStream) {
       
      console.log('[llm-classify] responses.create (streaming)', { model });
      const stream = await openai.responses.create({
        ...basePayload,
        stream: true,
      } as any);

      let out = '';
      for await (const event of stream as any) {
        if (event?.type === 'response.output_text.delta') {
          out += event.delta || '';
        }
        if (event?.type === 'response.completed') break;
      }
      if (out.trim()) return out.trim();
      // fall through to non-streaming if streaming yielded nothing
    }

     
    console.log('[llm-classify] responses.create (non-streaming)', { model });
    const resp = await openai.responses.create(basePayload as any);

    try {
      const reqId = (resp as any)._request_id;
      const usage = (resp as any).usage || {};
       
      console.log('[llm-classify] request metrics', {
        request_id: reqId,
        input_tokens: usage.input_tokens,
        output_tokens: usage.output_tokens,
        total_tokens: usage.total_tokens,
      });
    } catch {}

    const text = extractText(resp);
    if (text && text !== '{}') return text;

    const output = (resp as any)?.output;
    if (Array.isArray(output)) {
      for (const item of output) {
        if (item?.type === 'function_call' && typeof item?.arguments === 'string' && item.arguments.trim()) {
          return item.arguments.trim();
        }
      }
    }
  } catch (err) {
     
    console.error('[llm-classify] responses error', err instanceof Error ? err.message : err);
    throw err;
  }

  return '{}';
};

export function __setCallLLM(fn: typeof callLLM) {
  callLLM = fn;
}

function parseLLMJson(raw: string): any {
  try {
    return JSON.parse(raw);
  } catch {
    const start = raw.indexOf('{');
    const end = raw.lastIndexOf('}');
    if (start >= 0 && end > start) {
      const sliced = raw.slice(start, end + 1);
      return JSON.parse(sliced);
    }
    throw new Error('Failed to parse LLM JSON output');
  }
}

const INTAKE_QUEUE_URL = process.env.INTAKE_QUEUE_URL || 'http://localhost:4566/000000000000/intake-queue';

// JSON Schema to enforce the new output structure (mirrors the spec provided)
export const CLASSIFICATION_JSON_SCHEMA: Record<string, unknown> = {
  $schema: 'https://json-schema.org/draft/2020-12/schema',
  title: 'RealEstateOpsClassification',
  type: 'object',
  additionalProperties: false,
  required: [
    'schema_version',
    'message_type',
    'task_key',
    'group_key',
    'listing',
    'assignee_hint',
    'due_date',
    'task_title',
    'confidence',
    'explanations',
  ],
  properties: {
    schema_version: { type: 'integer', const: 1 },
    message_type: { type: 'string', enum: ['GROUP', 'STRAY', 'INFO_REQUEST', 'IGNORE'] },
    task_key: {
      anyOf: [
        { type: 'string', enum: [
          'SALE_ACTIVE_TASKS',
          'SALE_SOLD_TASKS',
          'SALE_CLOSING_TASKS',
          'LEASE_ACTIVE_TASKS',
          'LEASE_LEASED_TASKS',
          'LEASE_CLOSING_TASKS',
          'LEASE_ACTIVE_TASKS_ARLYN',
          'RELIST_LISTING_DEAL_SALE',
          'RELIST_LISTING_DEAL_LEASE',
          'BUYER_DEAL',
          'BUYER_DEAL_CLOSING_TASKS',
          'LEASE_TENANT_DEAL',
          'LEASE_TENANT_DEAL_CLOSING_TASKS',
          'PRECON_DEAL',
          'MUTUAL_RELEASE_STEPS',
          'OPS_MISC_TASK',
        ]},
        { type: 'null' }
      ],
    },
    group_key: {
      anyOf: [
        { type: 'string', enum: [
          'SALE_LISTING',
          'LEASE_LISTING',
          'SALE_LEASE_LISTING',
          'SOLD_SALE_LEASE_LISTING',
          'RELIST_LISTING',
          'RELIST_LISTING_DEAL_SALE_OR_LEASE',
          'BUY_OR_LEASED',
          'MARKETING_AGENDA_TEMPLATE',
        ]},
        { type: 'null' }
      ],
    },
    listing: {
      type: 'object',
      additionalProperties: false,
      required: ['type', 'address'],
      properties: {
        type: { anyOf: [
          { type: 'string', enum: ['LEASE', 'SALE'] },
          { type: 'null' }
        ]},
        address: { anyOf: [
          { type: 'string' },
          { type: 'null' }
        ]},
      },
    },
    assignee_hint: { anyOf: [
      { type: 'string' },
      { type: 'null' }
    ]},
    due_date: {
      anyOf: [
        { type: 'string', pattern: '^\\d{4}-\\d{2}-\\d{2}(T\\d{2}:\\d{2}(:\\d{2})?)?$' },
        { type: 'null' }
      ],
    },
    task_title: {
      anyOf: [
        { type: 'string', maxLength: 80 },
        { type: 'null' }
      ],
    },
    confidence: { type: 'number', minimum: 0, maximum: 1 },
    explanations: { anyOf: [
      { type: 'array', items: { type: 'string' }, minItems: 1 },
      { type: 'null' }
    ]},
  },
};

/**
 * Pre-filter messages to skip obvious casual chat/noise before LLM classification.
 * Reduces unnecessary API calls by ~70-80% based on CloudWatch data showing 90% IGNORE rate.
 */
function shouldSkipPreFilter(text: string): boolean {
  if (!text || typeof text !== 'string') return false;

  const normalized = text.trim().toLowerCase();

  // Skip very short messages (< 10 chars, likely acknowledgments)
  if (normalized.length < 10) return true;

  // Skip emoji-only or mostly emoji messages (common casual reactions)
  const emojiPattern = /[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]/gu;
  const textWithoutEmoji = text.replace(emojiPattern, '').trim();
  if (textWithoutEmoji.length < 5) return true;

  // Skip common greetings/acknowledgments
  const casualPatterns = [
    /^(hi|hey|hello|thanks|thank you|thx|ty|ok|okay|sure|sounds good|perfect|great|awesome|nice|cool|lol|haha|yes|no|yep|nope|👍|👌)[\s!.]*$/i,
    /^(good morning|good afternoon|good evening|gm|gn)[\s!.]*$/i,
    /^(congrats|congratulations|well done|good job)[\s!.]*$/i,
  ];

  for (const pattern of casualPatterns) {
    if (pattern.test(normalized)) return true;
  }

  // Skip pure emoji/reaction messages
  if (/^[\s\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}!.?]+$/u.test(text)) {
    return true;
  }

  return false;
}

export async function classifyAndEnqueueFromSlackEvent(body: unknown): Promise<{ ok?: boolean; skipped?: boolean }> {
  const toggle = (process.env.USE_LLM_CLASSIFIER || '').toLowerCase();
  if (toggle !== 'true') return { skipped: true };

  const extracted = extractFromSlackEvent(body);
  if (!extracted) return { skipped: true };

  const { text, slack_user_id, channel_id, ts, links, attachments } = extracted;

  // Pre-filter: skip obvious casual chat before calling LLM
  if (shouldSkipPreFilter(text)) {
    return { skipped: true };
  }

  const idempotencyKey = sha1Hex(`${channel_id}:${ts}`);
  const { system, developer, user, fewShot } = buildPrompt({ text, slack_user_id, channel_id, ts, links, attachments });

  const timeoutMs = Number(process.env.LLM_TIMEOUT_MS || '20000');
  const confidenceMin = Number(process.env.LLM_CONFIDENCE_MIN || '0.6');

  // Exponential backoff configuration
  // Max 3 attempts with exponential delay: 100ms, 200ms, 400ms (with jitter)
  const maxRetries = Number(process.env.LLM_BACKOFF_ATTEMPTS || '3');
  const startingDelay = Number(process.env.LLM_BACKOFF_DELAY_MS || '100');

  const rawJson = await captureAsync('llm-classify', async () => {
    // Retry with exponential backoff for transient errors
    const out = await backOff(
      async () => {
        const withTimeout = <T>(promise: Promise<T>): Promise<T> =>
          new Promise<T>((resolve, reject) => {
            const timer = setTimeout(() => reject(new Error('LLM timeout')), timeoutMs);
            promise
              .then((value) => {
                clearTimeout(timer);
                resolve(value);
              })
              .catch((err) => {
                clearTimeout(timer);
                reject(err);
              });
          });

        return await withTimeout(callLLM(system, user, fewShot, developer, CLASSIFICATION_JSON_SCHEMA));
      },
      {
        numOfAttempts: maxRetries,
        startingDelay,
        timeMultiple: 2,
        jitter: 'full',
        retry: (error: any, attemptNumber: number) => {
          // Only retry on transient errors
          if (error instanceof OpenAI.APIConnectionTimeoutError) {
             
            console.log(`[llm-classify] Timeout on attempt ${attemptNumber}, retrying with backoff...`);
            return true;
          }
          if (error instanceof OpenAI.RateLimitError) {
             
            console.log(`[llm-classify] Rate limit on attempt ${attemptNumber}, retrying with backoff...`);
            return true;
          }
          if (error instanceof OpenAI.APIConnectionError) {
             
            console.log(`[llm-classify] Connection error on attempt ${attemptNumber}, retrying with backoff...`);
            return true;
          }
          if (error instanceof OpenAI.InternalServerError) {
             
            console.log(`[llm-classify] Server error on attempt ${attemptNumber}, retrying with backoff...`);
            return true;
          }
          // Don't retry on other errors (auth, validation, etc.)
          return false;
        },
      }
    );

    // lightweight debug log (redacts text earlier; prints length + sha1 idempotency key only)
    try {
      // avoid logging full content; just the size and a small prefix
      const snippet = typeof out === 'string' ? out.slice(0, 200) : String(out).slice(0, 200);
       
      console.log('[llm-classify] raw output snippet:', snippet);
    } catch {}
    return out;
  });

  let parsed: ClassificationV1Parsed;
  try {
    const candidate = (typeof rawJson === 'string' ? parseLLMJson(rawJson) : rawJson) as any;

    // Debug logging: track date parsing behavior
    try {
      const tsNumber = Number(ts);
      const refISO = Number.isFinite(tsNumber) ? new Date(tsNumber * 1000).toISOString() : new Date().toISOString();
      const textSnippet = text.slice(0, 100);
       
      console.log('[llm-classify] Date Debug:', {
        text_snippet: textSnippet,
        message_timestamp_iso: refISO,
        llm_due_date: candidate?.due_date ?? null,
        llm_confidence: candidate?.confidence ?? 'not set',
      });
    } catch (debugErr) {
      // Ignore debug logging errors
    }

    const withDefaults: ClassificationV1 = {
      schema_version: 1 as const,
      message_type: (candidate?.message_type as MessageType) || 'INFO_REQUEST',
      task_key: (candidate?.task_key as string | null) ?? null,
      group_key: (candidate?.group_key as any) ?? null,
      listing: {
        type: (candidate?.listing?.type as any) ?? null,
        address: (candidate?.listing?.address as any) ?? null,
      },
      assignee_hint: (candidate?.assignee_hint as any) ?? null,
      due_date: (candidate?.due_date as any) ?? null,
      task_title: (candidate?.task_title as string | null) ?? null,
      confidence: typeof candidate?.confidence === 'number' ? candidate.confidence : 0.8,
      explanations: Array.isArray(candidate?.explanations) ? candidate.explanations : null,
    };
    parsed = ClassificationV1Schema.parse(withDefaults);
  } catch (e) {
     
    console.error('[llm-classify] parse error:', e instanceof Error ? e.message : e);
    return { skipped: true };
  }

  if (parsed.message_type === 'IGNORE' || (parsed.confidence ?? 0) < confidenceMin) {
    return { skipped: true };
  }

  await captureAsync('enqueue-intake', async () => {
    const attributes: Record<string, MessageAttributeValue> = {
      message_type: { DataType: 'String', StringValue: parsed.message_type },
    };

    const traceId = ulid();
    attributes['x-trace-id'] = { DataType: 'String', StringValue: traceId };

    await sqs.send(
      new SendMessageCommand({
        QueueUrl: INTAKE_QUEUE_URL,
        MessageBody: JSON.stringify({
          schema: 'classification_v1',
          idempotency_key: idempotencyKey,
          source: { slack_user_id, channel_id, ts, text },
          payload: parsed,
          links,
          attachments,
        }),
        MessageAttributes: attributes,
      })
    );
     
    console.log('[llm-classify] enqueued intake', { message_type: parsed.message_type, channel_id });
  });

  return { ok: true };
}
