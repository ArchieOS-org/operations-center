# Operations Center - Test Seed Data

## Overview
Comprehensive seed data for development and testing of the Operations Center application. This creates a realistic working environment with staff, realtors, listings, tasks, acknowledgments, and Slack message history.

## Execution

To populate the database with seed data:

```bash
# Option 1: Via Supabase MCP (recommended if available)
# Use the Supabase MCP execute_sql tool to run:
# - 001_seed_test_data.sql
# - 002_seed_tasks_and_messages.sql

# Option 2: Via psql
cd supabase/seed
psql $DATABASE_URL < 001_seed_test_data.sql
psql $DATABASE_URL < 002_seed_tasks_and_messages.sql

# Option 3: Combined file
psql $DATABASE_URL < complete_seed.sql
```

## Data Created

### Staff (8 team members)
- **2 Admins**: Sarah Chen, Michael Rodriguez
- **3 Operations**: Alex Johnson, Priya Patel, David Kim
- **2 Marketing**: Emma Wilson (photography specialist), Jorge Sanchez (content specialist)
- **1 Support**: Lisa Thompson

**Test Credentials**:
- sarah.admin@opscenter.test (Admin)
- alex.ops@opscenter.test (Operations)
- emma.marketing@opscenter.test (Marketing - Photography)

### Realtors (12 external agents)
- **10 Active realtors** across various specializations:
  - Luxury: James Patterson, Jennifer Lee
  - Residential: Maria Garcia
  - Commercial: Robert Chen
  - Estates: William Brown
  - Condos: Sophia Martinez
  - Tech clients: Daniel Nguyen
  - Family homes: Olivia Johnson
  - Investment: Thomas Anderson
  - First-time buyers: Isabella Wang
- **1 Inactive**: Mark Sullivan (retired)
- **1 Pending**: Amy Foster (background check)

### Listings (25 properties)
- **7 New** (unclaimed, will appear in everyone's Inbox):
  - 2847 Pacific Avenue (luxury Victorian)
  - 456 Lombard Street (rental, tourist area)
  - 789 Valencia Street (Mission condo)
  - 321 Page Street (Haight vintage)
  - 2223 Taraval Street (investment property)
  - 2425 Balboa Street (commercial space)
  - 3031 Fillmore Street (rental, long lead time)

- **13 In Progress** (claimed by staff, active work):
  - Various stages: 15% to 90% complete
  - 2 OVERDUE listings (Noe Street, Sacramento Street)
  - Mix of residential, commercial, rental

- **5 Completed** (finished, delivered):
  - Recent completions within last 2-15 days
  - All with 100% progress

**Property Types Distribution**:
- SALE: 19 listings
- RENTAL: 4 listings
- COMMERCIAL: 2 listings

### Activities (50 listing-linked tasks)
Tasks attached to specific listings, showing full workflow:

**Status Distribution**:
- OPEN: 21 tasks (ready to claim)
- CLAIMED: 10 tasks (assigned but not started)
- IN_PROGRESS: 8 tasks (active work)
- DONE: 11 tasks (completed, historical reference)

**Category Distribution**:
- MARKETING: 35 tasks (photography, content, campaigns)
- ADMIN: 15 tasks (CRM, MLS uploads, QA, zoning)

**Visibility Distribution**:
- BOTH: 18 tasks (visible to all teams)
- MARKETING: 23 tasks (marketing team only)
- AGENT: 9 tasks (operations/admin only)

**Notable Tasks**:
- Overdue photography edits (URGENT flags)
- Virtual tour creation
- Drone photography (weather-dependent)
- Staging coordination
- MLS uploads
- Social media campaigns

### Agent Tasks (25 standalone realtor tasks)
Tasks for realtors NOT tied to specific listings:

**Status Distribution**:
- OPEN: 13 tasks
- CLAIMED: 7 tasks
- IN_PROGRESS: 4 tasks
- DONE: 3 tasks (historical)
- CANCELLED: 1 task (example of cancellation)

**Category Distribution**:
- ADMIN: 12 tasks (CRM updates, license renewals, market reports)
- MARKETING: 13 tasks (brochures, websites, content calendars, newsletters)

**Examples**:
- CRM updates (Q4 contacts)
- Broker license renewal (continuing education)
- Website updates
- Client appreciation events
- Market analysis reports
- Photography standards documentation
- Referral program launches
- Investment analysis templates

### Listing Acknowledgments (40 records)
Tracks which staff have "claimed" which listings:

**Distribution by Staff**:
- Sarah (admin): 4 acknowledgments (oversight role)
- Michael (admin): 3 acknowledgments (oversight role)
- Alex (operations): 5 acknowledgments (assigned listings)
- Priya (operations): 4 acknowledgments (assigned listings)
- David (operations): 4 acknowledgments (assigned listings)
- Emma (marketing): 8 acknowledgments (photography focus)
- Jorge (marketing): 6 acknowledgments (content focus)
- Lisa (support): 3 acknowledgments (support role)

**Acknowledgment Sources**:
- mobile: 27 (mobile app)
- web: 10 (web interface)
- notification: 3 (push notification)

**Inbox Strategy**:
Listings 01, 02, 03, 04, 19, 20, 23 have NO acknowledgments - they will appear in every staff member's Inbox as "unclaimed new work".

### Slack Messages (15 messages)
Message history showing classification and entity creation:

**Message Types**:
- new_listing: 3 messages (created listings 01, 02, 20)
- task_request: 4 messages (created agent tasks)
- listing_task: 2 messages (created activities)
- status_update: 2 messages (progress updates)
- question: 1 message (support inquiry)
- escalation: 2 messages (urgent/overdue notices)
- unclassified: 1 message (failed classification)

**Processing Status**:
- processed: 13 messages
- pending: 1 message (recent, unprocessed)
- skipped: 1 message (low confidence)

**Classification Confidence**:
- Range: 0.15 to 0.96
- Average: ~0.88 (high confidence)

## Data Relationships

```
Staff (8)
├─> Activities (50) [assigned_staff_id]
├─> Agent Tasks (25) [assigned_staff_id]
└─> Listing Acknowledgments (40) [staff_id]
     └─> Listings (25)

Realtors (12)
├─> Listings (25) [realtor_id]
├─> Activities (50) [realtor_id]
└─> Agent Tasks (25) [realtor_id, CASCADE DELETE]

Slack Messages (15)
├─> Created Listings (3)
├─> Created Activities (2)
└─> Created Agent Tasks (4)
```

## Testing Scenarios

This seed data enables testing of:

### 1. Inbox Functionality
- 7 new listings appear in ALL staff Inboxes
- Acknowledging a listing removes it from that staff member's Inbox
- Other staff still see it until they acknowledge

### 2. Task Assignment
- Open tasks can be claimed
- Claimed tasks show assignee
- In-progress tasks show work underway
- Completed tasks provide history

### 3. Team Filtering
- Marketing team sees MARKETING visibility tasks
- Operations sees AGENT visibility tasks
- Both see BOTH visibility tasks
- Category filtering (ADMIN vs MARKETING)

### 4. Overdue Detection
- 2 listings with overdue dates (Noe Street, Sacramento Street)
- Urgent/escalation flags in tasks
- Priority levels (0-100)

### 5. Status Progression
- OPEN → CLAIMED → IN_PROGRESS → DONE
- Timestamps track progression (claimed_at, completed_at)
- Failed/Cancelled states

### 6. Slack Integration
- Messages create listings
- Messages create tasks
- Classification confidence tracking
- Processing status tracking
- Thread references (slack_ts, slack_thread_ts)

### 7. Data Variety
- Different property types (SALE, RENTAL, COMMERCIAL)
- Different team roles (admin, operations, marketing, support)
- Different task categories (ADMIN, MARKETING, PHOTO, STAGING)
- Different realtorstatuses (active, inactive, pending)

## Data Volume Summary

| Entity | Count | Notes |
|--------|-------|-------|
| Staff | 8 | 2 admin, 3 ops, 2 marketing, 1 support |
| Realtors | 12 | 10 active, 1 inactive, 1 pending |
| Listings | 25 | 7 new, 13 in progress, 5 completed |
| Activities | 50 | Listing-linked tasks |
| Agent Tasks | 25 | Standalone realtor tasks |
| Listing Acks | 40 | Staff × Listing claims |
| Slack Messages | 15 | Message history with classification |
| **TOTAL** | **175 records** | Across 7 tables |

## Realistic Features

### Time Distribution
- Created dates: Last 1-120 days
- Due dates: Past (overdue), present (urgent), future (planned)
- Progress timestamps: claimed_at, completed_at, updated_at
- Relative time calculations using `NOW() - INTERVAL`

### Geographic Diversity
- San Francisco neighborhoods: Pacific Heights, Marina, Mission, SOMA, Castro, Haight, Richmond, Sunset
- Property types reflect neighborhood characteristics
- Realtor territories: SF, Peninsula, East Bay, South Bay

### Metadata Richness
- JSON fields (inputs, outputs, metadata)
- Task dependencies ("depends_on": "staging")
- Photographer names, budgets, shot types
- Escalation levels, notification history

### Edge Cases
- Soft deletes (deleted_at, deleted_by)
- Optional fields (null handling)
- Array fields (territories)
- JSONB queries (classification, metadata)
- Status transitions (OPEN → CLAIMED → IN_PROGRESS → DONE)

## Cleanup

To reset and re-seed:

```sql
BEGIN;

-- Clear existing data (cascades will handle related records)
DELETE FROM slack_messages;
DELETE FROM listing_acknowledgments;
DELETE FROM activities;
DELETE FROM agent_tasks;
DELETE FROM listings;
DELETE FROM realtors;
DELETE FROM staff;

COMMIT;

-- Re-run seed scripts
\i 001_seed_test_data.sql
\i 002_seed_tasks_and_messages.sql
```

## Notes

- All email addresses use `.test` TLD (won't send real emails)
- All phone numbers use 555 prefix (fictional)
- All Slack IDs are fictional (U01*, U02*)
- ULID format IDs (01JCQM...) for unique identification
- Deterministic: Re-running creates consistent data (for deterministic `NOW()`, replace with fixed dates)

---

**Generated**: January 2025
**Schema Version**: Based on migrations 001-020
**Total Records**: 175 across 7 tables
**Purpose**: Development, testing, and UI validation
