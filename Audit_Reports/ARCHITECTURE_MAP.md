# Operations Center Visual Architecture Map

## Executive Summary

**Operations Center** is a multi-platform SwiftUI app (iOS + macOS + iPadOS) for real estate operations management. The architecture follows a clean MVVM pattern with a centralized design system package.

**Key Numbers:**
- 104 Swift files total
- 18 primary screens
- 49 reusable components
- 14 data models
- 0 external dependencies in design system

---

## System Architecture Overview

```mermaid
graph TB
    subgraph "Client Applications"
        iOS[iOS App]
        macOS[macOS App]
        iPad[iPadOS App]
    end

    subgraph "Swift Architecture"
        App[Operations_CenterApp<br/>@main Entry Point]
        Auth[Authentication Flow<br/>Login/Signup/Session]
        Nav[NavigationStack<br/>Route-based]
        Features[18 Feature Screens<br/>MVVM Pattern]
        State[AppState<br/>@Observable]
    end

    subgraph "Shared Package"
        Kit[OperationsCenterKit<br/>49 Components + 14 Models]
    end

    subgraph "Data Layer"
        Repos[Repository Clients<br/>DI Pattern]
        Supa[Supabase SDK<br/>Direct CRUD]
        RT[Realtime<br/>Subscriptions]
    end

    subgraph "External Services"
        SupaDB[(Supabase<br/>PostgreSQL)]
        FastAPI[FastAPI<br/>Intelligence Only]
    end

    iOS --> App
    macOS --> App
    iPad --> App

    App --> Auth
    Auth --> Nav
    Nav --> Features
    Features --> State
    Features --> Kit
    State --> Repos
    Repos --> Supa
    Supa --> SupaDB
    Supa --> RT
    RT --> State

    Features -.-> FastAPI

    style Kit fill:#FFE5B4
    style State fill:#E5F3FF
    style SupaDB fill:#D4F4DD
```

---

## Component Hierarchy Tree

```mermaid
graph TD
    Root[Operations_CenterApp]
    Root --> AppView[AppView<br/>Auth Router]

    AppView --> Splash[SplashScreenView]
    AppView --> Login[LoginView]
    AppView --> Signup[SignupView]
    AppView --> Main[RootView]

    Main --> Primary[Primary Section]
    Main --> Browse[Browse Section]
    Main --> Settings[Settings]

    Primary --> Inbox[InboxView<br/>Work Dashboard]
    Primary --> MyTasks[MyTasksView<br/>Claimed Tasks]
    Primary --> MyListings[MyListingsView<br/>Active Properties]
    Primary --> Logbook[LogbookView<br/>Completed Work]

    Browse --> AllTasks[AllTasksView<br/>System Tasks]
    Browse --> AllListings[AllListingsView<br/>All Properties]
    Browse --> Agents[AgentsView<br/>Agent Directory]

    Agents --> AgentDetail[AgentDetailView<br/>Agent Work]
    AllListings --> ListingDetail[ListingDetailView<br/>Property Detail]
    MyListings --> ListingDetail

    Settings --> SettingsView[SettingsView<br/>Profile & Config]

    style Root fill:#FFD700
    style Main fill:#E5F3FF
    style Inbox fill:#FFE5B4
    style MyTasks fill:#FFE5B4
    style MyListings fill:#FFE5B4
```

---

## OperationsCenterKit Module Map

```mermaid
graph LR
    subgraph "OperationsCenterKit Package"
        Models[Models<br/>14 Types]
        Design[DesignSystem]
        Proto[Protocols<br/>TaskRepository]
    end

    subgraph "Models Detail"
        Core[Core Models<br/>Activity, Listing, AgentTask]
        Support[Support Models<br/>Staff, Realtor, SlackMessage]
        Composite[View Models<br/>ListingWithActivities<br/>TaskWithMessages]
    end

    subgraph "Design System"
        Tokens[Design Tokens<br/>Colors, Spacing, Typography]
        Cards[Card Components<br/>11 Types]
        Primitives[Primitives<br/>6 Types]
        States[State Components<br/>3 Types]
    end

    Models --> Core
    Models --> Support
    Models --> Composite

    Design --> Tokens
    Design --> Cards
    Design --> Primitives
    Design --> States

    style Models fill:#D4F4DD
    style Design fill:#FFE5B4
    style Proto fill:#E5F3FF
```

### OperationsCenterKit Dependency Flow

```mermaid
graph TB
    subgraph "App Features"
        F1[InboxView]
        F2[MyTasksView]
        F3[AllTasksView]
        F4[ListingDetailView]
        F5[AgentDetailView]
        F6[LogbookView]
    end

    subgraph "OperationsCenterKit Exports"
        Cards[Card Components<br/>TaskCard, ActivityCard, ListingCard]
        Models[Data Models<br/>Activity, Listing, AgentTask]
        Tokens[Design Tokens<br/>Colors, Spacing, Typography]
        States[UI States<br/>Empty, Error, Loading]
    end

    F1 --> Cards
    F1 --> Models
    F1 --> Tokens
    F1 --> States

    F2 --> Cards
    F2 --> Models

    F3 --> Cards
    F3 --> Models
    F3 --> States

    F4 --> Cards
    F4 --> Models

    F5 --> Cards
    F5 --> Models

    F6 --> Models
    F6 --> States

    style Cards fill:#FFE5B4
    style Models fill:#D4F4DD
    style Tokens fill:#E5D4FF
    style States fill:#FFE5E5
```

---

## Data Flow Architecture

```mermaid
sequenceDiagram
    participant User
    participant View
    participant Store
    participant Repo as Repository
    participant Supa as Supabase
    participant RT as Realtime
    participant AppState

    User->>View: Tap "Claim Task"
    View->>Store: await claimTask()
    Store->>Repo: repository.claimTask()
    Repo->>Supa: UPDATE activities
    Supa-->>RT: Emit change event
    RT-->>AppState: handleRealtimeChange()
    AppState->>Repo: fetchActivities()
    Repo->>Supa: SELECT * FROM activities
    Supa-->>AppState: Updated data
    AppState-->>Store: @Observable triggers
    Store-->>View: View recomputes
    View-->>User: UI Updates
```

---

## View & Component Inventory

### Primary Screens (18 Total)

| Screen | Purpose | Components Used | Navigation |
|--------|---------|-----------------|------------|
| **SplashScreenView** | Loading during auth | ProgressView | Auto-transition |
| **LoginView** | Email/password signin | Form, TextField | → RootView |
| **SignupView** | Create account | TeamSelectionCard | → RootView |
| **AppView** | Auth routing | ZStack | Root controller |
| **RootView** | Main navigation | NavigationStack | Hub for all screens |
| **InboxView** | Work dashboard | ListingCard, TaskCard | Route.inbox |
| **MyTasksView** | Claimed tasks | TaskCard, DSContextMenu | Route.myTasks |
| **MyListingsView** | User's properties | ListingBrowseCard | Route.myListings |
| **AllTasksView** | Browse all tasks | TaskCard, ActivityCard | Route.allTasks |
| **AllListingsView** | Browse properties | ListingCollapsedContent | Route.allListings |
| **ListingDetailView** | Property detail | ActivityCard, NotesSection | Route.listing(id) |
| **AgentDetailView** | Agent's work | ListingBrowseCard, TaskCard | Route.agent(id) |
| **AgentsView** | Agent directory | RealtorRow | Route.agents |
| **LogbookView** | Completed work | ListingBrowseCard | Route.logbook |
| **TeamView** | Team work (generic) | TaskCard, ActivityCard | Reusable |
| **AdminTeamView** | Admin tasks | TeamView wrapper | Via TeamView |
| **MarketingTeamView** | Marketing tasks | TeamView wrapper | Via TeamView |
| **SettingsView** | User settings | List, TeamPicker | Route.settings |

### Component Library (49 Components)

```mermaid
graph TD
    subgraph "Card Components (11)"
        CardBase[CardBase<br/>Foundation]
        CardHeader[CardHeader<br/>Title/Status]
        Expandable[ExpandableCardWrapper<br/>Animation]
        TaskCard[TaskCard<br/>Agent Tasks]
        ActivityCard[ActivityCard<br/>Property Tasks]
        ListingCard[ListingCard<br/>Full Property]
        ListingBrowse[ListingBrowseCard<br/>Collapsed]
        TaskTool[TaskToolbar<br/>Actions]
        ActivityTool[ActivityToolbar<br/>Actions]
        Slack[SlackMessagesSection<br/>Messages]
    end

    subgraph "Primitives (7)"
        Chip[DSChip<br/>Badges]
        Context[DSContextMenu<br/>Actions]
        FAB[FloatingActionButton<br/>Primary]
        Notes[NotesSection<br/>Annotations]
        NoteRow[NoteRow<br/>Single Note]
        Team[TeamToggle<br/>Filter]
        ClaimBtn[ClaimOrAssignButton]
    end

    subgraph "States (3)"
        Empty[DSEmptyState]
        Error[DSErrorState]
        Loading[DSLoadingState]
    end

    subgraph "Tokens (8)"
        Colors[Colors<br/>Semantic]
        Space[Spacing<br/>8pt Grid]
        Type[Typography<br/>Dynamic Type]
        Corner[CornerRadius]
        Shadow[Shadows]
        Anim[Animations]
        Icons[IconSizes]
        Scale[ScaleFactors]
    end
```

---

## Navigation Architecture

```mermaid
graph LR
    subgraph "Route Enum"
        R1[.inbox]
        R2[.myTasks]
        R3[.myListings]
        R4[.logbook]
        R5[.agents]
        R6[".agent(id)"]
        R7[".listing(id)"]
        R8[.allTasks]
        R9[.allListings]
        R10[.settings]
    end

    subgraph "Destination Views"
        V1[InboxView]
        V2[MyTasksView]
        V3[MyListingsView]
        V4[LogbookView]
        V5[AgentsView]
        V6[AgentDetailView]
        V7[ListingDetailView]
        V8[AllTasksView]
        V9[AllListingsView]
        V10[SettingsView]
    end

    R1 --> V1
    R2 --> V2
    R3 --> V3
    R4 --> V4
    R5 --> V5
    R6 --> V6
    R7 --> V7
    R8 --> V8
    R9 --> V9
    R10 --> V10
```

---

## State Management Architecture

```mermaid
graph TD
    subgraph "App-Level State"
        AppState["AppState<br/>@Observable @MainActor<br/>• currentUser<br/>• allTasks<br/>• authState"]
    end

    subgraph "Feature Stores"
        InboxStore["InboxStore<br/>@Observable"]
        MyTasksStore["MyTasksStore<br/>@Observable"]
        AllTasksStore["AllTasksStore<br/>@Observable"]
        ListingDetailStore["ListingDetailStore<br/>@Observable"]
        AgentDetailStore["AgentDetailStore<br/>@Observable"]
        LogbookStore["LogbookStore<br/>@Observable"]
    end

    subgraph "Repository Clients"
        TaskRepo["TaskRepositoryClient<br/>.live / .preview"]
        ListingRepo["ListingRepositoryClient<br/>.live / .preview"]
        NoteRepo["ListingNoteRepositoryClient<br/>.live / .preview"]
        RealtorRepo["RealtorRepositoryClient<br/>.live / .preview"]
    end

    AppState --> TaskRepo
    AppState --> ListingRepo

    InboxStore --> TaskRepo
    InboxStore --> ListingRepo
    InboxStore --> NoteRepo

    MyTasksStore --> TaskRepo
    AllTasksStore --> TaskRepo
    ListingDetailStore --> ListingRepo
    ListingDetailStore --> NoteRepo

    AgentDetailStore --> RealtorRepo
    LogbookStore --> TaskRepo
    LogbookStore --> ListingRepo

    style AppState fill:#FFE5B4
```

---

## Dependency Injection Pattern

```mermaid
graph LR
    subgraph "Repository Protocol"
        Proto["TaskRepository<br/>protocol"]
    end

    subgraph "Implementations"
        Live["TaskRepositoryClient.live<br/>Supabase Direct"]
        Preview["TaskRepositoryClient.preview<br/>Mock Data"]
    end

    subgraph "Injection Points"
        Store["Store Init<br/>repository: TaskRepository"]
    end

    subgraph "Selection Logic"
        Scheme["Xcode Scheme<br/>--use-preview-data"]
    end

    Proto --> Live
    Proto --> Preview

    Scheme --> Live
    Scheme --> Preview

    Live --> Store
    Preview --> Store
```

---

## Kit Component Usage Heat Map

| Component | Usage Count | Used By |
|-----------|------------|---------|
| **TaskCard** | 6 | InboxView, MyTasksView, AllTasksView, AgentDetailView, TeamView × 2 |
| **ActivityCard** | 5 | ListingDetailView, AllTasksView, AgentDetailView, TeamView × 2 |
| **ListingCard** | 1 | InboxView |
| **ListingBrowseCard** | 4 | MyListingsView, AgentDetailView, LogbookView |
| **DSContextMenu** | 8 | Most expandable card views |
| **FloatingActionButton** | 3 | MyTasksView, AllTasksView, InboxView |
| **DSEmptyState** | 10+ | All list views |
| **DSErrorState** | 8+ | All views with error handling |
| **SkeletonCard** | 2 | AllTasksView, AllListingsView |
| **NotesSection** | 1 | ListingDetailView |
| **TeamToggle** | 1 | AllTasksView |
| **Colors** | All | Every view references semantic colors |
| **Spacing** | All | Every view uses spacing tokens |

---

## File Structure Map

```
Operations Center/
├── 📱 Main App (47 files)
│   ├── App/
│   │   └── Config.swift
│   ├── Features/ (18 screens)
│   │   ├── Auth/ (4 files)
│   │   ├── MyTasks/ (2 files)
│   │   ├── MyListings/ (2 files)
│   │   ├── AllTasks/ (2 files)
│   │   ├── AllListings/ (2 files)
│   │   ├── ListingDetail/ (2 files)
│   │   ├── Agents/ (4 files)
│   │   ├── Logbook/ (2 files)
│   │   ├── AdminTeam/ (2 files)
│   │   ├── MarketingTeam/ (2 files)
│   │   ├── TeamView/ (2 files)
│   │   └── Inbox/ (1 file)
│   ├── Dependencies/ (4 clients)
│   ├── Navigation/
│   │   └── Route.swift
│   ├── State/
│   │   └── AppState.swift
│   └── Core Files
│       ├── Operations_CenterApp.swift (@main)
│       ├── ContentView.swift
│       ├── RootView.swift
│       └── Supabase.swift
│
├── 📦 OperationsCenterKit/ (49 files)
│   ├── Models/ (14 files)
│   ├── Protocols/ (1 file)
│   └── DesignSystem/
│       ├── Components/ (24 files)
│       │   ├── Cards/ (11)
│       │   ├── Primitives/ (7)
│       │   ├── States/ (3)
│       │   └── Others/ (3)
│       ├── Tokens/ (8 files)
│       ├── Extensions/ (1 file)
│       └── Haptics/ (1 file)
│
└── 🧪 Tests/ (8 files)
    ├── Unit Tests/ (6)
    └── UI Tests/ (2)
```

---

## Critical Architectural Decisions

### 1. Direct Supabase Access (No Backend for CRUD)
```
Swift App → Supabase PostgREST → PostgreSQL
         ↘ Supabase Realtime ↗
```
FastAPI reserved ONLY for AI intelligence operations.

### 2. @Observable over ObservableObject
Swift 6 pattern with automatic MainActor enforcement.

### 3. Repository Client Pattern for DI
Struct of closures enables seamless .live/.preview swapping.

### 4. Things 3 Navigation Pattern
Primary actions at top, browse sections below, settings at bottom.

### 5. OperationsCenterKit as Presentation Layer
Not a utility library—it IS the view layer extracted.

### 6. Real-time First Architecture
All changes propagate instantly via Supabase subscriptions.

---

## Architecture Health Metrics

| Metric | Value | Status |
|--------|-------|--------|
| **Total Files** | 104 Swift | ✅ Manageable |
| **Max File Size** | 390 lines (ListingCard) | ✅ Reasonable |
| **Feature Isolation** | 100% MVVM | ✅ Excellent |
| **Code Reuse** | 49 shared components | ✅ High |
| **External Dependencies** | 0 in Kit, 1 in App (Supabase) | ✅ Minimal |
| **Test Coverage** | Unit + UI tests present | ⚠️ Needs expansion |
| **Navigation Complexity** | Single enum, 10 routes | ✅ Simple |
| **State Management** | Single AppState + feature stores | ✅ Clear |
| **Hardcoded Values** | 0 in design system | ✅ Token-based |
| **Platform Support** | iOS + macOS + iPadOS | ✅ Universal |

---

## Summary

Operations Center demonstrates **ruthless simplicity** in action:

- **One pattern** (MVVM with @Observable)
- **One package** (OperationsCenterKit for all UI)
- **One state source** (AppState with real-time sync)
- **One navigation model** (Route enum)
- **Zero complexity** where it isn't needed

The architecture is optimized for:
1. **Instant responsiveness** via real-time subscriptions
2. **Maximum reuse** via the Kit package
3. **Testing isolation** via repository pattern
4. **Developer clarity** via consistent patterns

Every decision reduces cognitive load. Every component has one job. Every file has a clear purpose.

**This is how you build an app that vanishes from consciousness while users get their work done.**

---

*Generated Architecture Map - Operations Center iOS*
*Last Updated: November 2024*