# Claude Code Rules for Operations Center SwiftUI App

## Overview

This SwiftUI multi-platform app (macOS + iOS) connects to:
- **Supabase** (direct) for all CRUD operations
- **Vercel FastAPI** with LangChain agents for AI operations

This document defines code organization rules to prevent messy AI-generated code.

---

## Architecture Principles

### Two-API Pattern
```
SwiftUI App
├─→ Supabase (90% of calls)
│   └─→ All CRUD, real-time, auth
└─→ Vercel Agents (10% of calls)
    └─→ AI classification, chat, streaming
```

### Package Structure
```
Operations Center/
├── Packages/
│   ├── DesignSystem/     # Reusable UI components
│   ├── Services/         # Supabase + Vercel clients
│   ├── Features/         # Feature modules
│   └── Models/           # Shared data models
├── Shared/               # Multi-platform shared code
├── macOS/                # macOS-specific code
└── iOS/                  # iOS-specific code
```

---

## File Organization Rules

### Rule 1: One Component Per File
✅ **Good:**
```
TaskRow.swift           // Contains only TaskRow
TaskListView.swift      // Contains only TaskListView
```

❌ **Bad:**
```
Components.swift        // Contains 10 different views
```

### Rule 2: Maximum 200 Lines Per File
When a file exceeds 200 lines:
1. Extract nested views to separate files
2. Move complex logic to ViewModel
3. Extract reusable components to DesignSystem

### Rule 3: Extract Early
Don't wait for duplication. If a view could be reused, extract it immediately.

---

## Package Placement Guidelines

### DesignSystem Package
**Location:** `Packages/DesignSystem/Sources/DesignSystem/`

**Contains:**
- `Components/` - Reusable UI components (TaskRow, ActionButton, EmptyState)
- `Tokens/` - Design tokens (Spacing, Typography, Colors)
- `Modifiers/` - Custom view modifiers

**When to use:**
- ✅ Component used in 2+ places
- ✅ Pure UI with no business logic
- ✅ Could work across multiple features
- ❌ Feature-specific logic
- ❌ Only used once

**Example:**
```swift
// Packages/DesignSystem/Sources/DesignSystem/Components/TaskRow.swift
import SwiftUI

/// A reusable row component for displaying a task
public struct TaskRow: View {
    let task: Task
    let onTap: () -> Void

    public init(task: Task, onTap: @escaping () -> Void) {
        self.task = task
        self.onTap = onTap
    }

    public var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isComplete ? .green : Colors.secondary)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(task.title)
                    .font(Typography.body)

                if let subtitle = task.subtitle {
                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundColor(Colors.secondary)
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

### Services Package
**Location:** `Packages/Services/Sources/Services/`

**Contains:**
- `SupabaseService.swift` - Direct database operations
- `VercelAgentService.swift` - AI agent streaming
- Related protocols and error types

**Pattern:**
```swift
// Protocol for testability
public protocol SupabaseServiceProtocol {
    func fetch<T: Codable>(from table: String) async throws -> [T]
}

// Concrete implementation
public actor SupabaseService: SupabaseServiceProtocol {
    private let client: SupabaseClient
    // ...
}
```

### Features Package
**Location:** `Packages/Features/Sources/Features/{FeatureName}/`

**Contains:**
- Feature-specific views
- ViewModels
- Feature-specific logic

**Structure:**
```
Features/
├── Tasks/
│   ├── TaskListView.swift
│   ├── TaskListViewModel.swift
│   ├── TaskDetailView.swift
│   └── TaskDetailViewModel.swift
├── Messages/
│   ├── MessageListView.swift
│   └── MessageListViewModel.swift
└── Realtors/
    └── ...
```

### Models Package
**Location:** `Packages/Models/Sources/Models/`

**Contains:**
- Data models matching database schema
- Codable structs
- Enums

**Pattern:**
```swift
// Packages/Models/Sources/Models/Task.swift
import Foundation

public struct Task: Identifiable, Codable {
    public let id: String
    public var title: String
    public var isComplete: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case isComplete = "is_complete"
    }
}
```

---

## Naming Conventions

### Views
- **Pattern:** `NounView` or `Noun`
- **Examples:**
  - `TaskListView` - List of tasks
  - `TaskRow` - Single task row (no View suffix for small components)
  - `TaskDetailView` - Task details

### ViewModels
- **Pattern:** `NounViewModel`
- **Examples:**
  - `TaskListViewModel`
  - `TaskDetailViewModel`

### Services
- **Pattern:** `NounService`
- **Examples:**
  - `SupabaseService`
  - `VercelAgentService`

### Files
- **Pattern:** Match the primary type name
- **Examples:**
  - `TaskRow.swift` contains `struct TaskRow`
  - `TaskListViewModel.swift` contains `class TaskListViewModel`

---

## Multi-Platform Patterns

### Shared Code
**Location:** `Shared/`

**Contains:**
- Models (data structures)
- ViewModels (business logic)
- Service clients
- Utilities

**Example:**
```swift
// Shared/Models/Task.swift - Used by both macOS and iOS
struct Task: Identifiable, Codable {
    let id: String
    var title: String
}
```

### Platform-Specific UI
**Pattern:** Use `#if os()` for platform differences or separate files

**Compile-time detection:**
```swift
#if os(macOS)
    .frame(minWidth: 800, minHeight: 600)
#else
    .navigationBarTitleDisplayMode(.large)
#endif
```

**Separate files:**
```
macOS/TaskListView.swift        // NavigationSplitView
iOS/TaskListView.swift          // NavigationStack
```

### NavigationSplitView (macOS)
```swift
// macOS: Three-column layout
NavigationSplitView {
    Sidebar(selection: $selection)
} detail: {
    TaskListView(section: selection)
}
.frame(minWidth: 800, minHeight: 600)
```

### NavigationStack (iOS)
```swift
// iOS: Stack-based navigation
NavigationStack(path: $path) {
    TaskListView()
        .navigationTitle("Tasks")
}
```

---

## Design System Usage

### Always Use Tokens
❌ **Bad:**
```swift
.padding(16)
.font(.system(size: 14))
```

✅ **Good:**
```swift
.padding(Spacing.md)
.font(Typography.body)
```

### Design Tokens Structure
```swift
// Packages/DesignSystem/Sources/DesignSystem/Tokens/Spacing.swift
public enum Spacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
}

// Packages/DesignSystem/Sources/DesignSystem/Tokens/Typography.swift
public enum Typography {
    public static let title = Font.title
    public static let body = Font.body
    public static let caption = Font.caption
}

// Packages/DesignSystem/Sources/DesignSystem/Tokens/Colors.swift
public enum Colors {
    public static let primary = Color.accentColor
    public static let secondary = Color.secondary
    public static let background = Color(uiColor: .systemBackground)
}
```

---

## Code Quality Checklist

### Before Committing AI-Generated Code

- [ ] **File Size:** No files exceed 200 lines
- [ ] **Organization:** Components in correct packages
- [ ] **Naming:** All files follow naming conventions
- [ ] **Duplication:** No duplicate code
- [ ] **Design System:** Using tokens, not hardcoded values
- [ ] **Documentation:** Public APIs have doc comments
- [ ] **Builds:** Code builds successfully in Xcode
- [ ] **Tests:** Added tests for new functionality
- [ ] **Multi-Platform:** Tested on both macOS and iOS

---

## Refactoring Triggers

### When to Refactor

1. **File > 200 lines**
   - Extract nested views
   - Move logic to ViewModel
   - Split into multiple files

2. **Duplicate Code**
   - Extract to DesignSystem component
   - Create shared utility function
   - Use view modifiers

3. **Complex View**
   - Break into sub-views
   - Extract to separate files
   - Use composition

4. **API Calls in Views**
   - Move to ViewModel
   - Use Services package
   - Implement proper error handling

---

## Available Claude Commands

Use these commands to maintain code quality:

- `/refactor-component` - Extract view to separate file
- `/check-organization` - Analyze project structure
- `/extract-design-system` - Find reusable components
- `/sync-models` - Update models from database schema
- `/generate-service` - Create new service template

---

## Database Integration

### Supabase Direct Pattern
```swift
// In ViewModel
@MainActor
class TaskListViewModel: ObservableObject {
    @Published var tasks: [Task] = []

    private let supabase: SupabaseServiceProtocol

    func loadTasks() async {
        do {
            tasks = try await supabase.fetch(from: "listing_tasks")
        } catch {
            // Handle error
        }
    }
}
```

### Real-time Subscriptions
```swift
func subscribeToTasks() {
    Task {
        for await task in supabase.subscribe(to: "listing_tasks") as AsyncStream<Task> {
            tasks.append(task)
        }
    }
}
```

### Vercel Agent Streaming
```swift
func classifyMessage(_ text: String) async {
    do {
        for try await chunk in vercelAgent.classify(message: text) {
            // Update UI with streaming response
            classification.append(chunk.content)
        }
    } catch {
        // Handle error
    }
}
```

---

## Things 3-Inspired UX Patterns

### Calm Lists
- Generous spacing (use `Spacing.md`)
- Minimal chrome
- Clear hierarchy
- `.listStyle(.plain)`

### Non-Modal Flows
- Use sidebars instead of modals
- Split views for navigation
- Contextual actions

### Platform-Native
- Respect macOS/iOS idioms
- Use system components
- Follow Apple HIG

---

## Summary

**Golden Rules:**
1. One component per file, max 200 lines
2. Extract early, extract often
3. Use design tokens, never hardcoded values
4. Reusable → DesignSystem, Feature-specific → Features
5. Services for API calls, ViewModels for logic, Views for UI
6. Test on both macOS and iOS
7. Document public APIs
8. Run `/check-organization` regularly

**Questions to Ask:**
- Is this component reusable? → DesignSystem
- Is this view > 200 lines? → Extract
- Am I using hardcoded values? → Use tokens
- Is there API logic in the view? → Move to ViewModel
- Does this duplicate existing code? → Extract to component

**Remember:** Clean code with AI requires discipline. Follow these rules religiously.
