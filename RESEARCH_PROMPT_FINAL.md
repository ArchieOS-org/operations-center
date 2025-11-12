# Prompt: Evidence-Based Claude Code Methodology for Building Multi-Platform SwiftUI App (Things 3-Inspired) Connecting to Existing Supabase + Vercel/LangChain Backend

## Role & Lens

Act as a **Claude Code methodology expert** and **multi-platform SwiftUI architect**. Produce **actionable guidance** for using Claude Code to build a **clean, organized SwiftUI frontend** inspired by Things 3's simplicity. The frontend will connect to TWO existing APIs: **Supabase directly** (database) and **Vercel FastAPI with LangChain agents**. Address concerns about **maintaining code quality when using AI** and **preventing messy codebases**.

## Research Requirements (Deep Web Search)

Do **not** rely solely on prior training. Perform **deep, current web research** across:
- **Claude Code** best practices for SwiftUI/Xcode projects
- **Multi-platform SwiftUI** architecture (macOS + iOS shared code patterns)
- **Things 3 UI/UX patterns** (what makes it simple and effective)
- **Component library architecture** in SwiftUI
- **Apple HIG** and default design system usage
- **Reusable SwiftUI components** best practices
- **Monorepo structure** for Swift apps + backend
- **Xcode project organization** for AI-assisted development
- **Code organization strategies** to prevent "spaghetti code" with AI
- Supabase Swift SDK direct integration
- Vercel serverless streaming from Swift

- **Freshness:** Prefer sources from the last **18 months**; include publish date.
- **Citations:** Use **inline citations** `[Title – Site, YYYY-MM-DD](URL)` after relevant guidance.
- **Dates:** Start with "**As of <today's date>**" (timezone **America/Toronto**).

## Context & Core Concerns

### The Transition
We're building a **NEW SwiftUI frontend** to replace/augment an existing system. The backend infrastructure already exists and is working:

**Existing Backend:**
- Python FastAPI with LangChain agents
- Deployed on Vercel
- Supabase PostgreSQL database (9 tables)
- Message classification, task management logic

**New Frontend (Building Now):**
- Multi-platform SwiftUI app (macOS + iOS)
- Will connect directly to Supabase for data
- Will call Vercel API for agent operations
- Starting from scratch (no existing codebase)

### The Challenge
- **Starting from scratch** (no existing Things 3 codebase to reference)
- **Multi-platform** (macOS + iOS with shared components)
- **Monorepo** (Swift app + existing Python backend together)
- **AI-assisted development** (Claude Code primary tool)
- **Code quality concerns:** How to keep it clean when coding with AI?
- **Component reusability:** Need unified design system
- **Testing workflow:** Claude Code for coding, Xcode for testing
- **Two-API integration:** Clean patterns for Supabase + Vercel

### Current Architecture
- **Backend (Existing):** Python FastAPI with LangChain agents on Vercel
- **Frontend (Building Now):** SwiftUI (macOS 14+ / iOS 17+)
- **Database:** Supabase PostgreSQL (9 existing tables)
- **Design System:** Apple defaults (no custom design)
- **Year 1:** Operations management (no chat yet)

### Two-API Architecture
The new SwiftUI frontend will connect to TWO separate APIs:

**API #1: Supabase Direct**
- Direct connection from Swift to Supabase
- All CRUD operations (staff, realtors, tasks, listings)
- Real-time subscriptions
- Auth via Supabase JWT

**API #2: Vercel Agent API**
- Python FastAPI with LangChain agents
- Deployed on Vercel
- Message classification, AI operations
- Endpoints discovered as frontend needs emerge

### Key Questions to Address
1. How do I start a multi-platform Xcode project and integrate it into a monorepo?
2. How do I structure components for reusability across platforms?
3. How do I use Claude Code effectively without creating a "jumblefuck of code"?
4. What patterns from Things 3 should I adopt (and how to implement them)?
5. How do I maintain organization when AI is writing most of the code?

## Goals

1. Define **project setup** for multi-platform Swift in monorepo
2. Create **Things 3-inspired patterns** that work in SwiftUI
3. Establish **component library architecture** with Apple defaults
4. Build **code organization system** that scales with AI development
5. Design **Claude Code workflow** that maintains quality
6. Document **multi-platform patterns** (shared vs platform-specific)
7. Provide **safeguards against messy code** when using AI

-----

## What to Deliver

### 1) Multi-Platform Project Setup & Monorepo Integration

**Initial Setup Workflow:**
```
1. Create multi-platform app in Xcode
2. Structure for monorepo compatibility
3. Integrate into existing repo with backend
4. Configure for Claude Code development
```

**Xcode Project Structure:**
```
operations-center/ (monorepo root)
├── backend/ (existing Python/FastAPI)
├── apps/
│   └── OperationsApp/ (Xcode project)
│       ├── OperationsApp.xcodeproj
│       ├── Shared/ (macOS + iOS code)
│       ├── macOS/ (macOS-specific)
│       ├── iOS/ (iOS-specific)
│       └── Packages/ (SPM local packages)
│           ├── DesignSystem/
│           ├── Services/
│           └── Features/
```

**Why This Structure:**
- Keeps Swift code together in `apps/`
- Backend stays separate
- SPM packages for modularity
- Easy to work with in both Xcode and Claude Code

**Claude Code Integration:**
- Work in `apps/OperationsApp/` directory
- Claude can edit Swift files directly
- Test in Xcode after Claude edits
- Commit from monorepo root

### 2) Things 3-Inspired UI Patterns (What to Adopt)

**What Makes Things 3 Great:**
- **Calm simplicity:** Generous whitespace, minimal chrome
- **Clear hierarchy:** Projects → Areas → Tasks
- **Non-modal flows:** Sidebars, split views, no pop-ups
- **Contextual actions:** Swipe gestures, keyboard shortcuts
- **Platform-native:** Respects macOS/iOS idioms

**SwiftUI Implementation Patterns:**

**Pattern: Calm Lists**
```swift
// Things-like: Simple, spacious, clear
List(tasks) { task in
    TaskRow(task: task)
        .padding(.vertical, 8)  // Generous spacing
}
.listStyle(.plain)             // Remove visual noise
```

**Pattern: Sidebar Navigation (macOS)**
```swift
NavigationSplitView {
    // Sidebar: Projects/Areas
    List(sections, selection: $selection) { section in
        Label(section.name, systemImage: section.icon)
    }
} detail: {
    // Detail: Tasks
    TaskList(section: selection)
}
```

**Pattern: Platform-Adaptive**
```swift
#if os(macOS)
    .frame(minWidth: 800, minHeight: 600)    // macOS: wide canvas
#else
    .navigationBarTitleDisplayMode(.large)   // iOS: standard nav
#endif
```

**What NOT to Copy:**
- Don't replicate visual design (keep Apple defaults)
- Don't copy animations/transitions
- Don't assume their tech stack
- Focus on **UX patterns**, not aesthetics

### 3) Component Library Architecture

**Design System Structure:**
```swift
// DesignSystem Package
public enum Spacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
}

public enum Typography {
    public static let body = Font.body      // Apple default
    public static let title = Font.title
    public static let caption = Font.caption
}

// Use system colors for automatic dark mode
public enum Colors {
    public static let primary = Color.accentColor
    public static let secondary = Color.secondary
    public static let background = Color(uiColor: .systemBackground)
}
```

**Reusable Component Pattern:**
```swift
// TaskRow: Used everywhere
public struct TaskRow: View {
    let task: Task
    let onTap: () -> Void

    public var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isComplete ? .green : .secondary)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(task.title)
                    .font(Typography.body)

                if let subtitle = task.subtitle {
                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(Spacing.md)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}
```

**Component Organization:**
```
DesignSystem/
├── Sources/
│   ├── Tokens/          # Spacing, colors, typography
│   ├── Components/      # Reusable UI components
│   │   ├── TaskRow.swift
│   │   ├── SectionHeader.swift
│   │   ├── EmptyState.swift
│   │   └── ActionButton.swift
│   └── Modifiers/       # Custom view modifiers
└── Tests/
```

### 4) Preventing "Jumblefuck Code" with Claude Code

**Core Strategy: Structure Before Scale**

**Rule 1: One Component Per File**
```swift
// ✅ Good: TaskRow.swift
struct TaskRow: View { ... }

// ❌ Bad: AllComponents.swift with 20 views
```

**Rule 2: Extract Early**
```swift
// When Claude generates this:
var body: some View {
    VStack {
        // 50 lines of view code
    }
}

// Immediately refactor to:
var body: some View {
    TaskListContent()
}

private struct TaskListContent: View { ... }
```

**Rule 3: Claude Code Commands for Organization**
```
/.claude/commands/refactor-view.md
→ "Extract this view into a separate component"
→ "Move to appropriate package"
→ "Add documentation"
```

**Rule 4: Review Cycles**
```markdown
After Claude generates code:
1. Does it belong in a package?
2. Is it reusable → Move to DesignSystem
3. Is it feature-specific → Keep in Features/
4. Run SwiftLint/SwiftFormat
5. Test in Xcode
```

### 5) Claude Code Workflow for Clean Code

**Development Pattern:**
```
1. Define feature in plain English
2. Claude generates initial code
3. Review for organization
4. Ask Claude to refactor if messy
5. Move components to packages
6. Test in Xcode
7. Commit with clear message
```

**`CLAUDE.md` Rules:**
```markdown
# Code Organization Rules

## File Structure
- One view per file
- Max 200 lines per file
- Extract complex views immediately

## Component Rules
- Reusable components → DesignSystem package
- Feature-specific views → Features package
- API integrations → Services package

## Naming Conventions
- Views: NounView (TaskListView, TaskRow)
- ViewModels: NounViewModel (TaskListViewModel)
- Services: NounService (SupabaseService)

## Before Committing
- Run SwiftLint
- Verify in Xcode
- Check package dependencies
- Update documentation
```

**`.claude/` Commands:**
```markdown
/refactor-component
→ Extract view to separate file
→ Move to appropriate package
→ Add documentation

/check-organization
→ Analyze file structure
→ Identify coupling issues
→ Suggest improvements

/extract-design-system
→ Find reusable components
→ Move to DesignSystem package
→ Update imports
```

### 6) Multi-Platform Patterns

**Shared Code Pattern:**
```swift
// Shared/Models/Task.swift
// Used by both macOS and iOS
struct Task: Identifiable, Codable {
    let id: String
    var title: String
    var isComplete: Bool
}
```

**Platform-Specific UI:**
```swift
// macOS/TaskListView_macOS.swift
struct TaskListView: View {
    var body: some View {
        NavigationSplitView {
            Sidebar()
        } detail: {
            TaskList()
        }
        .frame(minWidth: 800)  // macOS needs minimum size
    }
}

// iOS/TaskListView_iOS.swift
struct TaskListView: View {
    var body: some View {
        NavigationStack {
            TaskList()
        }
        .navigationTitle("Tasks")
    }
}
```

**Platform Detection:**
```swift
// Use #if for compile-time
#if os(macOS)
    // macOS-specific code
#else
    // iOS-specific code
#endif

// Use @available for runtime
if #available(macOS 14, iOS 17, *) {
    // New API
} else {
    // Fallback
}
```

### 7) Package Architecture for Reusability

**SPM Package Structure:**
```
Packages/
├── DesignSystem/           # UI components
│   ├── Package.swift
│   └── Sources/DesignSystem/
│       ├── Components/
│       └── Tokens/
│
├── Services/               # API integrations
│   └── Sources/Services/
│       ├── SupabaseService.swift
│       └── VercelAgentService.swift
│
├── Features/               # Feature modules
│   └── Sources/Features/
│       ├── Tasks/
│       ├── Messages/
│       └── Realtors/
│
└── Models/                 # Shared data models
    └── Sources/Models/
        ├── Task.swift
        └── Message.swift
```

**Dependency Rules:**
```swift
// Package.swift
let package = Package(
    name: "OperationsApp",
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0")
    ],
    targets: [
        // DesignSystem has no dependencies
        .target(name: "DesignSystem"),

        // Services depend on Supabase
        .target(name: "Services", dependencies: ["Supabase"]),

        // Features depend on Services + DesignSystem
        .target(name: "Features", dependencies: ["Services", "DesignSystem"]),

        // App depends on everything
        .target(name: "App", dependencies: ["Features", "Services", "DesignSystem"])
    ]
)
```

### 8) Testing Workflow (Claude Code + Xcode)

**Development Cycle:**
```
1. Work in Claude Code:
   - Edit Swift files
   - Generate components
   - Refactor code

2. Test in Xcode:
   - Build project
   - Run on simulator
   - Fix build errors
   - Test functionality

3. Iterate:
   - Back to Claude Code for fixes
   - Repeat until working
```

**Claude Code Testing Commands:**
```markdown
/generate-tests
→ Create unit tests for view models
→ Mock Supabase/Vercel services

/test-build
→ Verify code compiles
→ Check for common issues
→ Suggest fixes
```

### 9) Supabase Direct + Vercel Integration

**Service Layer:**
```swift
// Services/SupabaseService.swift
public class SupabaseService {
    private let client: SupabaseClient

    public func getTasks() async throws -> [Task] {
        try await client.from("listing_tasks").select()
    }

    public func subscribeToTasks() async {
        await client.channel("tasks")
            .on("postgres_changes") { ... }
    }
}

// Services/VercelAgentService.swift
public class VercelAgentService {
    private let baseURL = URL(string: "https://app.vercel.app/api")!

    public func classifyMessage(_ text: String) async throws -> Classification {
        // SSE streaming from Vercel
    }
}
```

**ViewModels Use Services:**
```swift
// Features/Tasks/TaskListViewModel.swift
@MainActor
class TaskListViewModel: ObservableObject {
    @Published var tasks: [Task] = []

    private let supabase: SupabaseService
    private let agents: VercelAgentService

    func loadTasks() async {
        tasks = try await supabase.getTasks()  // Supabase direct
    }

    func analyzeTask(_ task: Task) async {
        let analysis = try await agents.analyze(task)  // Vercel agent
    }
}
```

### 10) Discovery Methodology

**Feature Development:**
```
1. Build feature with Supabase first
2. Use Apple default components
3. Keep it simple (Things 3 style)
4. Extract reusable parts to DesignSystem
5. If need AI → Add Vercel endpoint
6. Document decision
```

**Refactoring Triggers:**
```
When to refactor with Claude Code:
- File > 200 lines → Extract components
- Duplicate code → Create reusable component
- Complex view → Break into sub-views
- API calls in views → Move to ViewModels
```

### 11) Code Quality Safeguards

**Pre-Commit Checklist:**
```markdown
Before committing AI-generated code:
□ Ran SwiftLint (no warnings)
□ Ran SwiftFormat
□ Built in Xcode (no errors)
□ Tested on simulator
□ Components in correct packages
□ No duplicate code
□ Documentation added
□ Tests pass
```

**Claude Code Review Command:**
```markdown
/.claude/commands/review-code.md

Prompt: "Review this code for:
1. Proper file organization
2. Component reusability
3. Package placement
4. Code duplication
5. SwiftUI best practices
Suggest refactorings if needed."
```

### 12) Documentation Strategy

**Track Decisions:**
```markdown
## Architecture Decision Log

### Component Organization
Decision: One component per file, max 200 lines
Reason: Maintain clarity with AI-generated code
Date: 2024-01-15

### Things 3 Patterns Adopted
- Sidebar navigation (macOS)
- Calm list styling
- Non-modal detail views
Reason: Proven UX patterns for productivity apps

### Design System
Decision: Apple defaults, no custom design
Reason: Focus on functionality, leverage system
```

---

## Output Format

- Start with **"As of <today's date> (America/Toronto)"**
- Focus on **preventing messy AI-generated code**
- Emphasize **Things 3 UX patterns** (not visual design)
- Show **multi-platform architecture** clearly
- Include **component reusability** strategies
- Provide **practical Claude Code workflows**

## Success Criteria

Using this methodology, I can:
- **Create multi-platform app** starting from Xcode project
- **Integrate into monorepo** cleanly with backend
- **Build Things 3-inspired UX** with original design
- **Maintain clean code** when using Claude Code
- **Create reusable components** with Apple defaults
- **Scale architecture** without becoming messy
- **Test efficiently** with Claude Code + Xcode workflow
- **Prevent spaghetti code** through organization rules