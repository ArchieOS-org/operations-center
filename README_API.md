# API Endpoint Documentation

**Project**: La-Paz Operations Center
**Framework**: FastAPI + Supabase
**Deployment**: Vercel Serverless Functions
**Last Updated**: 2025-11-11

---

## API Structure

All endpoints follow the pattern: `/v1/operations/<resource>`

### Base URL (Production)
```
https://your-app.vercel.app/api/v1/operations/
```

### Base URL (Local Development)
```
http://localhost:3000/api/v1/operations/
```

---

## Authentication

All endpoints require authentication via Bearer token.

**Header:**
```
Authorization: Bearer <your-jwt-token>
```

**Permissions:**
- **Admins**: Full access to all endpoints
- **Staff**: Read/update access based on role
- **Realtors**: Limited to own data

---

## 1. Staff Management

### `GET /v1/operations/staff`
List all staff members with optional filtering.

**Query Parameters:**
- `role` (optional): Filter by role (admin, operations, marketing, support)
- `status` (optional): Filter by status (active, inactive, suspended)
- `page` (optional, default: 1): Page number
- `page_size` (optional, default: 50, max: 100): Items per page

**Response:**
```json
{
  "data": [
    {
      "staff_id": "01HWQK3Y9X8ZHQT2N7G4FVWXYZ",
      "email": "jane.doe@example.com",
      "name": "Jane Doe",
      "role": "operations",
      "slack_user_id": "U01234ABCD",
      "phone": "+1-555-0100",
      "status": "active",
      "metadata": {},
      "created_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-01-15T10:30:00Z",
      "deleted_at": null
    }
  ],
  "total": 15,
  "page": 1,
  "page_size": 50
}
```

---

### `GET /v1/operations/staff/{staff_id}`
Get single staff member by ID.

**Path Parameters:**
- `staff_id`: Staff member's unique ID

**Response:**
```json
{
  "staff_id": "01HWQK3Y9X8ZHQT2N7G4FVWXYZ",
  "email": "jane.doe@example.com",
  "name": "Jane Doe",
  "role": "operations",
  "slack_user_id": "U01234ABCD",
  "phone": "+1-555-0100",
  "status": "active",
  "metadata": {},
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z",
  "deleted_at": null
}
```

**Error Responses:**
- `404 Not Found`: Staff member not found

---

### `POST /v1/operations/staff`
Create a new staff member.

**Request Body:**
```json
{
  "email": "john.smith@example.com",
  "name": "John Smith",
  "role": "marketing",
  "slack_user_id": "U56789EFGH",
  "phone": "+1-555-0200",
  "status": "active",
  "metadata": {}
}
```

**Response:** `201 Created`
```json
{
  "staff_id": "01HWQK4Z1A2BCDE5G6HIJKLMNO",
  "email": "john.smith@example.com",
  "name": "John Smith",
  "role": "marketing",
  ...
}
```

**Error Responses:**
- `409 Conflict`: Email already exists
- `422 Unprocessable Entity`: Validation error

---

### `PUT /v1/operations/staff/{staff_id}`
Update staff member.

**Request Body** (all fields optional):
```json
{
  "name": "John Smith Jr.",
  "phone": "+1-555-0999",
  "status": "inactive"
}
```

**Response:** `200 OK`

---

### `DELETE /v1/operations/staff/{staff_id}`
Soft delete staff member (sets `deleted_at` timestamp).

**Response:** `204 No Content`

---

## 2. Realtor Management

### `GET /v1/operations/realtors`
List all realtors with optional filtering.

**Query Parameters:**
- `status` (optional): Filter by status
- `brokerage` (optional): Filter by brokerage name (partial match)
- `page` (optional, default: 1)
- `page_size` (optional, default: 50, max: 100)

**Response:**
```json
{
  "data": [
    {
      "realtor_id": "01HWQK5Z8Y9ABCD3F4G5HVWXYZ",
      "email": "john.agent@realty.com",
      "name": "John Agent",
      "phone": "+1-555-0200",
      "license_number": "CA-DRE-01234567",
      "brokerage": "Premier Realty Group",
      "slack_user_id": "U56789EFGH",
      "territories": ["San Francisco", "Oakland"],
      "status": "active",
      "metadata": {},
      "created_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-01-15T10:30:00Z",
      "deleted_at": null
    }
  ],
  "total": 42,
  "page": 1,
  "page_size": 50
}
```

---

### `GET /v1/operations/realtors/{realtor_id}`
Get single realtor by ID.

### `POST /v1/operations/realtors`
Create new realtor.

**Request Body:**
```json
{
  "email": "sarah.broker@realty.com",
  "name": "Sarah Broker",
  "phone": "+1-555-0300",
  "license_number": "CA-DRE-98765432",
  "brokerage": "Elite Properties",
  "slack_user_id": "U98765WXYZ",
  "territories": ["Berkeley", "Richmond"],
  "status": "pending",
  "metadata": {}
}
```

### `PUT /v1/operations/realtors/{realtor_id}`
Update realtor.

### `DELETE /v1/operations/realtors/{realtor_id}`
Soft delete realtor.

---

## 3. Listing Tasks (Property-Specific)

### `GET /v1/operations/listings/{listing_id}/tasks`
Get all tasks for a specific listing.

**Query Parameters:**
- `status` (optional): Filter by status (OPEN, CLAIMED, DONE, etc.)
- `assigned_staff_id` (optional): Filter by assigned staff
- `task_category` (optional): Filter by category (ADMIN, MARKETING, PHOTO, etc.)
- `page` (optional, default: 1)
- `page_size` (optional, default: 50)

**Response:**
```json
{
  "data": [
    {
      "task_id": "01HWQK7A1B2CDEF4H5JKLMNOP",
      "listing_id": "01HWQK6Z9X8ABCD3F4G5HVWXY",
      "realtor_id": "01HWQK5Z8Y9ABCD3F4G5HVWXYZ",
      "name": "Schedule professional photography",
      "description": "Coordinate with photographer",
      "task_category": "PHOTO",
      "status": "OPEN",
      "priority": 5,
      "visibility_group": "BOTH",
      "assigned_staff_id": null,
      "due_date": "2024-02-01T14:00:00Z",
      "inputs": {},
      "outputs": {},
      "claimed_at": null,
      "completed_at": null,
      "created_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-01-15T10:30:00Z",
      "deleted_at": null,
      "deleted_by": null
    }
  ],
  "total": 8,
  "page": 1,
  "page_size": 50
}
```

---

### `POST /v1/operations/listings/{listing_id}/tasks`
Create a new task for a listing.

**Request Body:**
```json
{
  "name": "Edit listing photos",
  "description": "Color correction and touch-ups",
  "task_category": "PHOTO",
  "status": "OPEN",
  "priority": 7,
  "visibility_group": "MARKETING",
  "due_date": "2024-02-05T17:00:00Z",
  "inputs": {
    "photo_count": 25
  }
}
```

**Response:** `201 Created`

---

### `GET /v1/operations/listing-tasks/{task_id}`
Get single listing task by ID.

### `PUT /v1/operations/listing-tasks/{task_id}`
Update listing task.

### `POST /v1/operations/listing-tasks/{task_id}/claim`
Claim a task (assign to current user).

**Request Body:**
```json
{
  "assigned_staff_id": "01HWQK3Y9X8ZHQT2N7G4FVWXYZ"
}
```

**Response:** `200 OK` - Updates `assigned_staff_id` and `claimed_at`

---

### `POST /v1/operations/listing-tasks/{task_id}/complete`
Mark task as complete.

**Request Body:**
```json
{
  "outputs": {
    "photos_edited": 25,
    "time_spent_minutes": 120
  }
}
```

**Response:** `200 OK` - Sets `status` to `DONE` and `completed_at`

---

### `DELETE /v1/operations/listing-tasks/{task_id}`
Soft delete listing task.

---

## 4. Stray Tasks (Realtor-Specific)

### `GET /v1/operations/realtors/{realtor_id}/stray-tasks`
Get all stray tasks for a realtor.

**Query Parameters:**
- `status` (optional)
- `assigned_staff_id` (optional)
- `page`, `page_size`

**Response:**
```json
{
  "data": [
    {
      "task_id": "01HWQK8B2C3DEFG5I6JKLMNOPQ",
      "realtor_id": "01HWQK5Z8Y9ABCD3F4G5HVWXYZ",
      "task_key": "general_support",
      "name": "Update CRM records",
      "description": "Update contact information",
      "status": "OPEN",
      "priority": 3,
      "assigned_staff_id": null,
      "due_date": "2024-02-05T17:00:00Z",
      "inputs": {},
      "outputs": {},
      "claimed_at": null,
      "completed_at": null,
      "created_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-01-15T10:30:00Z",
      "deleted_at": null,
      "deleted_by": null
    }
  ],
  "total": 3,
  "page": 1,
  "page_size": 50
}
```

---

### `POST /v1/operations/realtors/{realtor_id}/stray-tasks`
Create stray task for realtor.

### `GET /v1/operations/stray-tasks/{task_id}`
Get single stray task.

### `PUT /v1/operations/stray-tasks/{task_id}`
Update stray task.

### `POST /v1/operations/stray-tasks/{task_id}/claim`
Claim stray task.

### `POST /v1/operations/stray-tasks/{task_id}/complete`
Complete stray task.

### `DELETE /v1/operations/stray-tasks/{task_id}`
Soft delete stray task.

---

## 5. Slack Messages

### `GET /v1/operations/slack-messages`
List Slack messages with processing status.

**Query Parameters:**
- `slack_user_id` (optional): Filter by Slack user
- `slack_channel_id` (optional): Filter by channel
- `message_type` (optional): Filter by classified type
- `processing_status` (optional): pending, processed, failed, skipped
- `created_listing_id` (optional): Messages that created this listing
- `page`, `page_size`

**Response:**
```json
{
  "data": [
    {
      "message_id": "01HWQK9C3D4EFGH6J7KLMNOPQR",
      "slack_user_id": "U56789EFGH",
      "slack_channel_id": "C0123456789",
      "slack_ts": "1705317000.123456",
      "slack_thread_ts": null,
      "message_text": "New listing at 123 Main St",
      "classification": {
        "type": "new_listing",
        "confidence": 0.95
      },
      "message_type": "new_listing",
      "task_key": null,
      "confidence": "0.9500",
      "created_listing_id": "01HWQK6Z9X8ABCD3F4G5HVWXY",
      "created_task_id": null,
      "created_task_type": null,
      "processing_status": "processed",
      "error_message": null,
      "metadata": {},
      "received_at": "2024-01-15T10:30:00Z",
      "processed_at": "2024-01-15T10:30:01Z"
    }
  ],
  "total": 1247,
  "page": 1,
  "page_size": 50
}
```

---

### `GET /v1/operations/slack-messages/{message_id}`
Get single Slack message.

### `POST /v1/operations/slack-messages/{message_id}/reprocess`
Reprocess failed Slack message classification.

**Response:** `200 OK` - Triggers re-classification

---

## 6. Listings (Updated)

### `GET /v1/operations/listings/{listing_id}`
Get listing with realtor details.

**Response now includes:**
```json
{
  "listing_id": "01HWQK6Z9X8ABCD3F4G5HVWXY",
  "address_string": "123 Main St, San Francisco, CA 94102",
  "status": "in_progress",
  "realtor_id": "01HWQK5Z8Y9ABCD3F4G5HVWXYZ",
  "realtor": {
    "realtor_id": "01HWQK5Z8Y9ABCD3F4G5HVWXYZ",
    "name": "John Agent",
    "email": "john.agent@realty.com",
    "phone": "+1-555-0200",
    "brokerage": "Premier Realty Group"
  },
  ...
}
```

---

## Error Responses

All endpoints follow consistent error response format:

### `400 Bad Request`
```json
{
  "detail": "Invalid request parameters"
}
```

### `401 Unauthorized`
```json
{
  "detail": "Not authenticated"
}
```

### `403 Forbidden`
```json
{
  "detail": "Insufficient permissions"
}
```

### `404 Not Found`
```json
{
  "detail": "Resource not found"
}
```

### `409 Conflict`
```json
{
  "detail": "Resource already exists"
}
```

### `422 Unprocessable Entity`
```json
{
  "detail": [
    {
      "loc": ["body", "email"],
      "msg": "value is not a valid email address",
      "type": "value_error.email"
    }
  ]
}
```

### `500 Internal Server Error`
```json
{
  "detail": "Database error: <error message>"
}
```

---

## Pagination

All list endpoints support pagination:

**Request:**
```
GET /v1/operations/staff?page=2&page_size=25
```

**Response includes:**
- `data`: Array of items
- `total`: Total count across all pages
- `page`: Current page number
- `page_size`: Items per page

---

## Implementation Template

### Router File Template (`backend/routers/staff.py`)

```python
from fastapi import APIRouter, HTTPException, Depends, Query
from backend.models.staff import StaffCreate, StaffUpdate, StaffMember, StaffListResponse
from backend.database.staff import (
    create_staff, get_staff_by_id, list_staff, update_staff, soft_delete_staff
)
from backend.services.authz import require_admin, get_current_user
from ulid import ULID

router = APIRouter(prefix="/staff", tags=["staff"])

@router.get("/", response_model=StaffListResponse)
async def list_staff_members(
    role: str | None = None,
    status: str | None = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    current_user=Depends(get_current_user)
):
    """List all staff members with optional filtering."""
    staff_list, total = await list_staff(role=role, status=status, page=page, page_size=page_size)
    return StaffListResponse(data=staff_list, total=total, page=page, page_size=page_size)

@router.get("/{staff_id}", response_model=StaffMember)
async def get_staff_member(staff_id: str, current_user=Depends(get_current_user)):
    """Get single staff member by ID."""
    staff = await get_staff_by_id(staff_id)
    if not staff:
        raise HTTPException(status_code=404, detail="Staff member not found")
    return staff

@router.post("/", response_model=StaffMember, status_code=201)
async def create_staff_member(
    staff_data: StaffCreate,
    current_user=Depends(require_admin)
):
    """Create new staff member (admin only)."""
    staff_id = str(ULID())
    return await create_staff(staff_data, staff_id)

@router.put("/{staff_id}", response_model=StaffMember)
async def update_staff_member(
    staff_id: str,
    updates: StaffUpdate,
    current_user=Depends(require_admin)
):
    """Update staff member (admin only)."""
    staff = await update_staff(staff_id, updates)
    if not staff:
        raise HTTPException(status_code=404, detail="Staff member not found")
    return staff

@router.delete("/{staff_id}", status_code=204)
async def delete_staff_member(
    staff_id: str,
    current_user=Depends(require_admin)
):
    """Soft delete staff member (admin only)."""
    success = await soft_delete_staff(staff_id)
    if not success:
        raise HTTPException(status_code=404, detail="Staff member not found")
```

### Vercel Entry Point Template (`api/v1/staff.py`)

```python
from fastapi import FastAPI
from mangum import Mangum
from backend.routers.staff import router as staff_router

app = FastAPI()
app.include_router(staff_router, prefix="/v1/operations")

handler = Mangum(app)
```

---

## Testing

### Example cURL Requests

**List staff:**
```bash
curl -H "Authorization: Bearer $TOKEN" \
  https://your-app.vercel.app/api/v1/operations/staff?role=operations
```

**Create staff:**
```bash
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","name":"Test User","role":"admin"}' \
  https://your-app.vercel.app/api/v1/operations/staff
```

**Update staff:**
```bash
curl -X PUT \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status":"inactive"}' \
  https://your-app.vercel.app/api/v1/operations/staff/01HWQK3Y9X8ZHQT2N7G4FVWXYZ
```

---

## Next Steps

1. ⏳ Implement all router files in `backend/routers/`
2. ⏳ Create Vercel entry points in `api/v1/`
3. ⏳ Set up authentication middleware
4. ⏳ Add request validation
5. ⏳ Write API tests
6. ⏳ Deploy to Vercel
7. ⏳ Update Slack webhook to use new endpoints

**See `README_DATABASE.md` for database schema details**
**See `README_MIGRATION.md` for migration instructions**
