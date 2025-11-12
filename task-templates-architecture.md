# Task Template Architecture - Mermaid Diagrams

## Database Schema Relationships

```mermaid
erDiagram
    LISTING_TYPES ||--o{ LISTING_TYPE_TASK_TEMPLATES : "has many"
    LISTING_TYPES ||--o{ LISTINGS : "categorizes"
    LISTINGS ||--o{ TASKS : "has many"
    LISTING_TYPE_TASK_TEMPLATES ||..o{ TASKS : "template for"

    LISTING_TYPES {
        uuid id PK
        text name UK "e.g., 'New Rental', 'Sale'"
        text description
        text icon_name "SF Symbol name"
        text color "Hex color"
        boolean active
        int display_order
        timestamptz created_at
        timestamptz updated_at
    }

    LISTING_TYPE_TASK_TEMPLATES {
        uuid id PK
        uuid listing_type_id FK
        text title "Task title"
        text description
        text default_status "pending|in_progress|completed"
        int display_order
        boolean required
        int estimated_duration_minutes
        jsonb metadata "Flexible custom properties"
        timestamptz created_at
        timestamptz updated_at
    }

    LISTINGS {
        uuid id PK
        uuid listing_type_id FK
        text address
        text status
        timestamptz created_at
    }

    TASKS {
        uuid id PK
        uuid listing_id FK
        text title "From template"
        text description
        text status
        timestamptz created_at
    }
```

## Data Flow: Creating a New Listing with Tasks

```mermaid
sequenceDiagram
    actor User
    participant SwiftApp as Swift App
    participant Supabase as Supabase Database

    User->>SwiftApp: Create new listing (type: "New Rental")

    SwiftApp->>Supabase: 1. INSERT INTO listings<br/>(address, listing_type_id)
    Supabase-->>SwiftApp: listing_id

    SwiftApp->>Supabase: 2. SELECT * FROM listing_type_task_templates<br/>WHERE listing_type_id = ?<br/>ORDER BY display_order
    Supabase-->>SwiftApp: [task_templates]

    Note over SwiftApp: Map templates to actual tasks

    SwiftApp->>Supabase: 3. INSERT INTO tasks (bulk insert)<br/>[{listing_id, title, description, status}]
    Supabase-->>SwiftApp: [created_tasks]

    SwiftApp-->>User: Show listing with pre-populated tasks
```

## Template Management Flow

```mermaid
flowchart TD
    Start([Admin needs to change tasks<br/>for listing type]) --> Method{How to modify?}

    Method -->|Option 1| Dashboard[Open Supabase Dashboard]
    Method -->|Option 2| AdminUI[Use Admin UI in Swift App<br/>future enhancement]

    Dashboard --> Edit1[Navigate to<br/>listing_type_task_templates table]
    Edit1 --> Modify1[Edit/Add/Delete rows directly]

    AdminUI --> Edit2[Visual template editor]
    Edit2 --> Modify2[Swift app writes to Supabase]

    Modify1 --> Save[Changes saved to database]
    Modify2 --> Save

    Save --> RealTime[Supabase Realtime publishes changes]
    RealTime --> AllClients[All Swift clients receive update]
    AllClients --> Refresh[Next listing creation uses<br/>updated templates]

    Refresh --> End([No deployment needed!])

    style Dashboard fill:#4A90E2,color:#fff
    style AdminUI fill:#E24A4A,color:#fff
    style Save fill:#50C878,color:#fff
    style End fill:#50C878,color:#fff
```

## Architecture Comparison

```mermaid
flowchart LR
    subgraph Recommended["✅ RECOMMENDED: Database Storage"]
        direction TB
        DB[(Supabase<br/>listing_type_task_templates)]
        Swift1[Swift App] -->|Direct SELECT| DB
        Dashboard1[Supabase Dashboard] -->|Edit| DB
        AdminPanel1[Admin UI<br/>optional] -->|UPDATE| DB
        DB -.->|Realtime| Swift1

        style DB fill:#50C878,color:#fff
    end

    subgraph NotRecommended1["❌ Frontend Storage"]
        direction TB
        SwiftCode[Swift Code<br/>Hardcoded Templates]
        AppUpdate[Requires App Store<br/>Submission for Changes]
        SwiftCode --> AppUpdate

        style SwiftCode fill:#E24A4A,color:#fff
        style AppUpdate fill:#E24A4A,color:#fff
    end

    subgraph NotRecommended2["❌ Backend Storage"]
        direction TB
        Vercel[Vercel/FastAPI<br/>Config File]
        Deploy[Requires Redeployment<br/>for Changes]
        Vercel --> Deploy

        style Vercel fill:#E24A4A,color:#fff
        style Deploy fill:#E24A4A,color:#fff
    end

    style Recommended fill:#E8F5E9
    style NotRecommended1 fill:#FFEBEE
    style NotRecommended2 fill:#FFEBEE
```

## Example: New Rental Listing Type with Tasks

```mermaid
flowchart TD
    ListingType["Listing Type: 'New Rental'<br/>🏠 #4A90E2"]

    ListingType --> T1[Task 1: Schedule professional photos<br/>⏱️ 30 min | Required ✓]
    ListingType --> T2[Task 2: Set competitive pricing<br/>⏱️ 15 min | Required ✓]
    ListingType --> T3[Task 3: Post to rental platforms<br/>⏱️ 45 min | Required ✓]
    ListingType --> T4[Task 4: Screen applicants<br/>⏱️ 60 min | Optional]
    ListingType --> T5[Task 5: Schedule showings<br/>⏱️ 20 min | Optional]

    T1 --> Instance1["Actual Listing:<br/>123 Main St"]
    T2 --> Instance1
    T3 --> Instance1
    T4 --> Instance1
    T5 --> Instance1

    Instance1 --> ActualTask1[✅ Task: Schedule professional photos<br/>Status: Completed]
    Instance1 --> ActualTask2[⏳ Task: Set competitive pricing<br/>Status: In Progress]
    Instance1 --> ActualTask3[⏹️ Task: Post to rental platforms<br/>Status: Pending]
    Instance1 --> ActualTask4[⏹️ Task: Screen applicants<br/>Status: Pending]
    Instance1 --> ActualTask5[⏹️ Task: Schedule showings<br/>Status: Pending]

    style ListingType fill:#4A90E2,color:#fff
    style Instance1 fill:#9C27B0,color:#fff
    style ActualTask1 fill:#50C878,color:#fff
    style ActualTask2 fill:#FFA500,color:#fff
```

## System Architecture Overview

```mermaid
C4Context
    title System Context: Task Template Management

    Person(user, "Property Manager", "Uses app to manage listings")
    Person(admin, "Admin", "Configures task templates")

    System_Boundary(app, "Operations Center") {
        Container(swift, "Swift App", "SwiftUI, iOS/macOS", "Multi-platform property management")
        ContainerDb(supabase, "Supabase", "PostgreSQL + Realtime", "Data storage & sync")
        Container(fastapi, "FastAPI", "Python, Vercel", "AI Intelligence Only")
    }

    Rel(user, swift, "Creates listings", "SwiftUI")
    Rel(admin, supabase, "Edits templates", "Dashboard")
    Rel(swift, supabase, "CRUD operations", "Direct SQL")
    Rel(swift, fastapi, "AI classification", "HTTP/SSE")

    UpdateRelStyle(swift, fastapi, $offsetX="-50", $offsetY="-30")

    UpdateLayoutConfig($c4ShapeInRow="3", $c4BoundaryInRow="1")
```

