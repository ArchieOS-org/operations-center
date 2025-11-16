# Task Management System Specification

**Last Updated:** 2025-01-15
**Status:** Final Design Document

---

## Overview

This document defines the complete behavior of the Task Management system within Operations Center. The system revolves around three core entities: **Listings**, **Activities**, and **Tasks**, organized around a **Claimed vs Unclaimed** state model.

---

## Core Entities

### Listings

**Properties:**
- Address
- Agent
- Type (determines which Activities are auto-created)
- Due Date
- Date Created
- Date Done (hidden)
- Date Deleted (hidden)
- Client Manager (CM)
- Notes (unlimited, author-tagged)
- Status
- Slack messages that spawned it

**Behavior:**
- Spawned by AI from Slack messages
- Has predefined Activities based on type (set by backend at creation)
- Can have Tasks assigned to it
- Requires acknowledgment from all staff before appearing in their views
- When ALL Activities are complete → Moves to Logbook
- Activities can be added/removed manually after creation

---

### Activities

**Properties:**
- Title
- Notes
- Status
- Agent
- Address
- Date Created
- Due Date
- Date Claimed
- Date Completed
- User Claimed At
- User Type (Marketing or Admin - **pre-set by backend, cannot toggle**)

**Behavior:**
- ALWAYS belong to a Listing
- Spawned by backend template based on listing type
- Can be added/removed manually after creation
- Pre-set as Marketing or Admin (cannot be toggled)
- When completed: move to bottom of Activity list, show as crossed out
- Stay in Listing even after completion (unlike Tasks which go to Logbook)

---

### Tasks

**Properties:**
- Title
- Notes
- Status
- Agent
- Address
- Date Created
- Due Date
- Date Claimed
- Date Completed
- User Claimed At
- User Type (Marketing or Admin - **can toggle**)

**Behavior:**
- Standalone work requests from agents (via Slack AI)
- Can be created manually by admins
- Can be assigned to a Listing (becomes associated but remains a Task)
- Tagged as Marketing or Admin (can be toggled by user)
- When completed: → Logbook
- Must be claimed from Inbox before appearing in task views

---

## State Model: Claimed vs Unclaimed

### Unclaimed Work (Inbox)

**Tasks:**
- Waiting to be claimed by at least one person
- Visible in Inbox to everyone
- Once claimed → Moves to My Tasks/All Tasks/Team Views

**Listings:**
- Waiting to be acknowledged by everyone
- Visible in Inbox to all staff
- Per-user state: Listing only moves out of YOUR Inbox after YOU acknowledge
- Once acknowledged → Appears in your All Listings/Agent Screen/My Listings (if you claim Activities)

### Claimed Work (System)

**Activities:**
- Claimed by users
- Visible on Listing Screen
- Appear in My Listings if user has claimed at least one Activity for that Listing

**Tasks:**
- Claimed by users
- Visible in My Tasks, All Tasks, Team Views
- Can be assigned to multiple users (stacked initials)

---

## Screen Definitions

### 📥 Inbox

**Purpose:** Triage unclaimed work

**Contains:**
- Unclaimed Listings (requiring acknowledgment)
- Unclaimed Tasks (requiring claim)

**Listing Cards:**
- **Collapsed view shows:**
  - Address
  - Agent
  - Date Created
  - Due Date
  - Type
- **Expanded view shows (ONLY expandable in Inbox):**
  - All collapsed fields
  - Notes
  - Slack messages that spawned it
  - Status
  - List of Activities
  - Client Manager (CM)
- **Action Bar (when expanded):**
  - Acknowledge
  - Delete
- **Acknowledgment behavior:**
  - All staff must acknowledge
  - Per-user state: Listing moves out of YOUR Inbox after YOU acknowledge
  - Once acknowledged → Appears in your All Listings/Agent Screen

**Task Cards:**
- **Collapsed view shows:**
  - Title
  - Agent
  - Due Date
  - Assignment status
- **Expanded view shows:**
  - All Task properties (see Card Definitions)
- **Action Bar (when expanded):**
  - Claim
  - User Type toggle (Marketing/Admin)
- **Claim behavior:**
  - At least one person must claim
  - Once claimed → Moves out of Inbox into My Tasks/All Tasks

**UI Elements:**
- Add Button (bottom right): Creates new Task modal

---

### ✅ My Tasks

**Purpose:** See all Tasks I've claimed

**Shows:**
- Standalone Tasks claimed by user (no Activities)
- Tasks I've claimed that are also assigned to Listings

**Task Cards:**
- Expandable inline
- Shows assignment (default: creator's name)
- Can reassign or mark unassigned

**Add Button:**
- Creates new Task inline at bottom
- No action bar shown during creation

**Bottom Action Bar (when card expanded):**
- Claim (press/hold for assignment)
- User Type toggle (Marketing/Admin)

**Toggle:** None (only shows MY tasks)

---

### 🏘️ My Listings

**Purpose:** See all Listings where I've claimed Activities

**Shows:**
- Listings where user has claimed at least one Activity

**Listing Cards:**
- Collapsed only
- Click → Navigate to Listing Screen
- No inline expansion

**Toggle:** Marketing/Admin/All (bottom left)

**Bottom Action Bar (when card expanded):**
- Delete

---

### 👥 Marketing Team View

**Purpose:** See what all marketing staff are working on

**Shows:**
- All claimed marketing work (Activities + Tasks) across entire team

**Task/Activity Cards:**
- Expandable inline
- Shows who claimed each item

**Add Button:**
- Creates new Task

**Bottom Action Bar (when card expanded):**
- Claim (press/hold for assignment)
- User Type toggle (for Tasks only)

**Toggle:** None (pre-filtered to Marketing)

---

### 👥 Admin Team View

**Purpose:** See what all admin staff are working on

**Shows:**
- All claimed admin work (Activities + Tasks) across entire team

**Task/Activity Cards:**
- Expandable inline
- Shows who claimed each item

**Add Button:**
- Creates new Task

**Bottom Action Bar (when card expanded):**
- Claim (press/hold for assignment)
- User Type toggle (for Tasks only)

**Toggle:** None (pre-filtered to Admin)

---

### 👥 Agents

**Purpose:** Browse work by agent

**Shows:**
- List of all agents

**Interaction:**
- Click Agent → Navigate to Agent Screen

---

### 👤 Agent Screen

**Purpose:** See all work for a specific agent

**Shows:**
- All Listings for this agent
- All Tasks associated with this agent
- Both claimed and unclaimed

**Bottom Action Bar (when card expanded):**
- Context-dependent based on card type

---

### 📋 All Tasks

**Purpose:** See all claimed Tasks system-wide

**Shows:**
- All claimed Tasks (standalone + assigned to listings)

**Task Cards:**
- Expandable inline

**Toggle:** Marketing/Admin/All (bottom left)

**Add Button:**
- Creates new Task

**Bottom Action Bar (when card expanded):**
- Claim (press/hold for assignment)
- User Type toggle (Marketing/Admin)

---

### 🏢 All Listings

**Purpose:** Browse all listings to claim Activities

**Shows:**
- All Listings across system (acknowledged and unacknowledged)

**Listing Cards:**
- Collapsed only
- Click → Navigate to Listing Screen

**Toggle:** Marketing/Admin/All (bottom left)

**Bottom Action Bar (when card expanded):**
- Delete

---

### 📖 Logbook

**Purpose:** Archive of completed work

**Shows:**
- Completed Listings (when ALL Activities are done)
- Completed Tasks

**Functionality:**
- *[TO DEFINE: Search? Filter? Or just chronological archive?]*

---

### 📄 Listing Screen (Detail View)

**Purpose:** See and claim Activities within a Listing

**Accessed by:**
- Clicking any Listing card (except in Inbox where it expands inline)

**Components:**

**Header:**
- Address
- Trigger messages menu (top right)

**Notes Section:**
- Click to add note
- Type, press Enter to save
- Shows author name per note
- Unlimited notes

**Activities Section:**
- **Marketing Activities** (separate section)
- **Admin Activities** (separate section)
- Shows claimed/unclaimed status per Activity
- Can add/remove Activities manually
- Completed Activities move to bottom, show crossed out

**Tasks Section:**
- Tasks that have been assigned to this Listing
- *[TO CLARIFY: Separate section or mixed with Activities?]*

**Add Button:**
- Adds Activity to this Listing

**Bottom Action Bar (when Activity expanded):**
- Claim (press/hold for assignment)
- User Type is pre-set (cannot toggle for Activities)

---

## Card Definitions

### Listing Card

**Collapsed (all views):**
- Address
- Agent
- Date Created
- Due Date
- Type

**Expanded (Inbox only):**
- All collapsed fields
- Notes
- Slack messages that spawned it
- Status
- List of Activities
- CM (Client Manager)

**Hidden fields (database only):**
- Date Done
- Date Deleted

**Action Bar Button Set:**
- **In Inbox:** Acknowledge, Delete
- **Outside Inbox:** Delete

---

### Task Card

**Collapsed:**
- Title
- Agent
- Due Date
- Assignment status

**Expanded:**
- Title
- Notes
- Status
- Agent
- Address
- Date Created
- Due Date
- Date Claimed
- Date Completed
- User Claimed At
- User Type (Marketing/Admin - **can toggle for Tasks only**)

**Action Bar Button Set:**
- **Claim:**
  - **Press:** Claim for yourself (shows "Claimed" or user initials)
  - **Hold:** List of users appears → Drag to assign (haptic feedback, can select multiple)
  - If multiple assigned: Shows stacked initials with current user's initial first
  - Hold again to change who is assigned
- **User Type:**
  - Default says "Assign"
  - Marketing/Admin toggle (Tasks only)

---

### Activity Card

**Same as Task Card except:**
- User Type is pre-set by backend (Marketing or Admin - **cannot toggle**)
- Always belongs to a Listing
- When completed: stays in Listing (moves to bottom, crossed out)
- Does not go to Logbook when complete (stays in Listing forever)

---

## Global UI Elements

### Add Button (Bottom Right)

**Default behavior:**
- Opens new Task modal (overlays top of screen)

**On task list screens:**
- Opens new Task inline at bottom of list

**On Listing Screen:**
- Adds Activity to current Listing

**During creation:**
- No action bar shown

---

### Context Menu (Floating Action Bar)

**Appearance:**
- Floats at bottom middle of screen
- Only appears when a card is expanded

**Triggers:**
- When Task/Activity/Listing is expanded

**Contents:**
- Contextual buttons based on card type (not screen)

**Paired with:**
- Card type (Task, Activity, Listing), NOT screen

---

### Marketing/Admin/All Toggle

**Location:** Bottom left

**Present on:**
- My Listings
- All Tasks
- All Listings

**Not present on:**
- Inbox
- My Tasks
- Marketing Team View (already filtered)
- Admin Team View (already filtered)
- Agents

---

## Data Flow Summary

### Listing Lifecycle
```text
Slack Message → AI Creates Listing → Inbox (All Users)
  ↓
User Acknowledges → Appears in User's All Listings/Agent Screen
  ↓
User Claims Activities → Appears in User's My Listings
  ↓
All Activities Completed → Moves to Logbook
```

### Task Lifecycle
```text
Slack Message OR Manual Creation → Inbox (Unclaimed)
  ↓
User Claims Task → My Tasks, All Tasks, Team Views
  ↓
Task Completed → Logbook
```

### Activity Lifecycle
```text
Listing Created → Activities Auto-Generated (Based on Type)
  ↓
User Claims Activity → Appears on Listing Screen
  ↓
Activity Completed → Stays in Listing (crossed out, moved to bottom)
  ↓
All Activities Complete → Listing → Logbook
```

---

## Key Rules

1. **Listings require acknowledgment** - Per-user state, moves out of YOUR Inbox when YOU acknowledge
2. **Tasks require claiming** - At least one person, moves to task views when claimed
3. **Activities always belong to Listings** - Cannot exist standalone
4. **Activity User Type is immutable** - Set by backend, cannot toggle
5. **Task User Type is mutable** - Can toggle between Marketing/Admin
6. **Completed Activities stay in Listing** - Move to bottom, crossed out
7. **Completed Tasks go to Logbook** - Removed from active views
8. **Listing goes to Logbook when ALL Activities complete** - Not before
9. **Action bars are card-type dependent** - Not screen dependent
10. **Inbox is the only place Listings expand inline** - Everywhere else, click navigates to Listing Screen

---

## Open Questions

1. **Logbook functionality:** Search? Filter? Chronological archive only?
2. **Tasks on Listing Screen:** Separate section or mixed with Activities?
3. **All Tasks action bar:** What actions are available in All Tasks view?
4. **Agent Screen action bar:** Define specific actions per card type
5. **Task assignment display:** What shows when unassigned vs creator-assigned vs multi-assigned?

---

## Implementation Notes

### Database Schema Requirements
- Listings table: address, agent, type, due_date, date_created, date_done, date_deleted, cm, status
- Activities table: listing_id (FK), title, notes, status, agent, address, date_created, due_date, date_claimed, date_completed, user_claimed_at, user_type (enum: marketing/admin)
- Tasks table: listing_id (FK, nullable), title, notes, status, agent, address, date_created, due_date, date_claimed, date_completed, user_claimed_at, user_type (enum: marketing/admin)
- Listing_acknowledgments table: listing_id, user_id, acknowledged_at (for per-user Inbox state)
- Task_assignments table: task_id, user_id, assigned_at (for multi-assignment)
- Activity_assignments table: activity_id, user_id, assigned_at (for multi-assignment)
- Notes table: entity_type (listing/task/activity), entity_id, author_id, content, created_at

### State Management
- Per-user Inbox filtering based on acknowledgment status
- Task claiming changes global state (moves for everyone)
- Listing acknowledgment changes per-user state (moves only for acknowledger)
- Activity completion changes Listing state (all users see update)

### UI/UX Considerations
- Haptic feedback on claim/hold interactions
- Smooth card expansion/collapse animations
- Clear visual distinction between claimed/unclaimed
- Stacked initials for multi-assignment (current user first)
- Crossed-out styling for completed Activities (still visible in Listing)
- Action bar color change when card selected
