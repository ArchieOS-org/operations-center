# Python Migration API Endpoints

Complete API documentation for the SMS classification system.

## Base URL

**Production (Vercel):**
```
https://your-project.vercel.app
```

**Local Development:**
```
http://localhost:8000
```

---

## Webhook Endpoints (Called by Twilio)

### POST /api/sms/webhook

Receives incoming SMS messages from Twilio.

**Headers:**
- `X-Twilio-Signature` (required) - Twilio request signature

**Body (application/x-www-form-urlencoded):**
```
From=+14155551234
Body=We got an offer on 123 Main St by Friday
MessageSid=SM1234567890abcdef
To=+14155556789
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Message classified and saved",
  "classification": {
    "message_type": "STRAY",
    "confidence": 0.9
  }
}
```

**Errors:**
- `400` - Missing parameters
- `401` - Invalid Twilio signature
- `500` - Internal server error

---

## Dashboard API Endpoints (For Swift App)

### GET /api/conversations

Get all SMS conversations sorted by most recent activity.

**Query Parameters:**
- `limit` (optional, default: 50, max: 100) - Number of conversations
- `offset` (optional, default: 0) - Pagination offset

**Example:**
```bash
curl "https://your-project.vercel.app/api/conversations?limit=20&offset=0"
```

**Response (200 OK):**
```json
{
  "conversations": [
    {
      "conversation_id": "550e8400-e29b-41d4-a716-446655440000",
      "phone_number": "+14155551234",
      "agent_type": "classifier",
      "last_message_at": "2025-11-10T13:45:00Z",
      "user_name": "John Doe",
      "last_message": "We got an offer on 123 Main St",
      "message_count": 15
    }
  ],
  "total": 42,
  "limit": 20,
  "offset": 0
}
```

**Errors:**
- `400` - Invalid parameters
- `500` - Internal server error

---

### GET /api/messages

Get all messages for a specific conversation.

**Query Parameters:**
- `phone_number` (required) - User's phone number (E.164 format)
- `limit` (optional, default: 100, max: 200) - Number of messages

**Example:**
```bash
curl "https://your-project.vercel.app/api/messages?phone_number=%2B14155551234&limit=50"
```

**Response (200 OK):**
```json
{
  "messages": [
    {
      "id": "660e8400-e29b-41d4-a716-446655440001",
      "conversation_id": "550e8400-e29b-41d4-a716-446655440000",
      "role": "user",
      "content": "We got an offer on 123 Main St by Friday",
      "twilio_sid": "SM1234567890abcdef",
      "classification": {
        "schema_version": 1,
        "message_type": "STRAY",
        "task_key": "SALE_CLOSING_TASKS",
        "group_key": null,
        "listing": {
          "type": "SALE",
          "address": "123 Main St"
        },
        "assignee_hint": null,
        "due_date": "2025-11-15T17:00:00",
        "task_title": "Schedule closing",
        "confidence": 0.9,
        "explanations": ["Inferred SALE from 'offer' context"]
      },
      "created_at": "2025-11-10T13:45:00Z"
    }
  ],
  "total": 15,
  "phone_number": "+14155551234",
  "conversation_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Errors:**
- `400` - Missing phone_number parameter
- `404` - No conversation found for phone number
- `500` - Internal server error

---

## Classification Schema

All user messages receive a classification with the following structure:

```typescript
{
  schema_version: 1,
  message_type: "GROUP" | "STRAY" | "INFO_REQUEST" | "IGNORE",
  task_key: string | null,        // For STRAY messages
  group_key: string | null,       // For GROUP messages
  listing: {
    type: "SALE" | "LEASE" | null,
    address: string | null
  },
  assignee_hint: string | null,
  due_date: string | null,        // ISO 8601 format
  task_title: string | null,      // Max 80 chars
  confidence: number,             // 0..1
  explanations: string[] | null
}
```

### Message Types

**GROUP** - Message declares or updates a listing entity
- `group_key` must be set
- `task_key` must be null

**STRAY** - Single actionable task not related to a listing group
- `task_key` must be set
- `group_key` must be null

**INFO_REQUEST** - Operational content but missing details
- Both `task_key` and `group_key` are null
- `explanations` describes what's missing

**IGNORE** - Chit-chat or non-operational content
- Both `task_key` and `group_key` are null

### Valid Group Keys

- `SALE_LISTING`
- `LEASE_LISTING`
- `SALE_LEASE_LISTING`
- `SOLD_SALE_LEASE_LISTING`
- `RELIST_LISTING`
- `RELIST_LISTING_DEAL_SALE_OR_LEASE`
- `BUY_OR_LEASED`
- `MARKETING_AGENDA_TEMPLATE`

### Valid Task Keys

**Sale:**
- `SALE_ACTIVE_TASKS`
- `SALE_SOLD_TASKS`
- `SALE_CLOSING_TASKS`

**Lease:**
- `LEASE_ACTIVE_TASKS`
- `LEASE_LEASED_TASKS`
- `LEASE_CLOSING_TASKS`
- `LEASE_ACTIVE_TASKS_ARLYN`

**Re-List:**
- `RELIST_LISTING_DEAL_SALE`
- `RELIST_LISTING_DEAL_LEASE`

**Buyer:**
- `BUYER_DEAL`
- `BUYER_DEAL_CLOSING_TASKS`

**Tenant:**
- `LEASE_TENANT_DEAL`
- `LEASE_TENANT_DEAL_CLOSING_TASKS`

**Other:**
- `PRECON_DEAL`
- `MUTUAL_RELEASE_STEPS`
- `OPS_MISC_TASK` (catch-all)

---

## Swift Integration Examples

### Fetch Conversations

```swift
import Foundation

struct Conversation: Codable, Identifiable {
    let conversation_id: UUID
    let phone_number: String
    let last_message_at: Date
    let last_message: String?
    let message_count: Int

    var id: UUID { conversation_id }
}

func fetchConversations() async throws -> [Conversation] {
    let url = URL(string: "https://your-project.vercel.app/api/conversations?limit=50")!
    let (data, _) = try await URLSession.shared.data(from: url)

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    let response = try decoder.decode([String: Any].self, from: data)
    let conversations = response["conversations"] as! [[String: Any]]

    return try JSONDecoder().decode([Conversation].self, from: JSONSerialization.data(withJSONObject: conversations))
}
```

### Fetch Messages

```swift
struct Message: Codable, Identifiable {
    let id: UUID
    let conversation_id: UUID
    let role: String
    let content: String
    let classification: Classification?
    let created_at: Date
}

struct Classification: Codable {
    let message_type: String
    let confidence: Double
    // ... other fields
}

func fetchMessages(phoneNumber: String) async throws -> [Message] {
    let encoded = phoneNumber.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    let url = URL(string: "https://your-project.vercel.app/api/messages?phone_number=\(encoded)")!

    let (data, _) = try await URLSession.shared.data(from: url)

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    let response = try decoder.decode([String: Any].self, from: data)
    let messages = response["messages"] as! [[String: Any]]

    return try JSONDecoder().decode([Message].self, from: JSONSerialization.data(withJSONObject: messages))
}
```

---

## CORS Headers

All API endpoints include CORS headers for Swift app access:

```
Access-Control-Allow-Origin: *
```

For production, you may want to restrict this to your Swift app's domain.

---

## Rate Limiting

**Vercel Free Tier:**
- 100 GB-hrs/month
- Unlimited invocations

**Recommended:**
- Add rate limiting for production
- Use Vercel Pro for higher limits ($20/month)

---

## Error Handling

All errors follow this format:

```json
{
  "success": false,
  "error": "Error message describing the problem"
}
```

**Common HTTP Status Codes:**
- `200` - Success
- `400` - Bad request (invalid parameters)
- `401` - Unauthorized (invalid signature)
- `404` - Not found (conversation doesn't exist)
- `500` - Internal server error

---

## Testing Endpoints Locally

### Webhook (Port 8000)
```bash
python api/sms/webhook.py

curl -X POST http://localhost:8000 \
  -d 'From=+14155551234' \
  -d 'Body=Test message' \
  -d 'MessageSid=SM123'
```

### Conversations (Port 8001)
```bash
python api/conversations.py

curl http://localhost:8001?limit=10
```

### Messages (Port 8002)
```bash
python api/messages.py

curl 'http://localhost:8002?phone_number=%2B14155551234'
```

---

## Deployment

See `SETUP.md` for complete deployment instructions to Vercel.

**Quick deploy:**
```bash
vercel deploy --prod
```

**Set webhook URL in Twilio:**
```
https://your-project.vercel.app/api/sms/webhook
```

---

## OpenAPI Specification

Full OpenAPI 3.1 spec available in `openapi.yaml`.

View interactive docs:
- [Swagger Editor](https://editor.swagger.io/) - Paste openapi.yaml
- [Postman](https://www.postman.com/) - Import openapi.yaml
