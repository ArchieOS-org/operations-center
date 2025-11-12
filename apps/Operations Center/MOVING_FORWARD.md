# Moving Forward: Operations Center Development Plan

## Foundation Complete ✅

You now have:
- ✅ Multi-platform Xcode project created
- ✅ SPM package structure with 4 packages
- ✅ Claude Code commands for code organization
- ✅ CLAUDE.md with comprehensive rules
- ✅ Design tokens (Spacing, Typography, Colors)
- ✅ Service templates (SupabaseService, VercelAgentService)
- ✅ Model templates (Task example)

---

## Architecture Summary

### Two APIs
```
SwiftUI App
├─→ Supabase (Direct)
│   • All CRUD operations
│   • Real-time subscriptions
│   • Authentication
│
└─→ Vercel FastAPI (Agents)
    • POST /classify (streaming)
    • POST /chat (streaming)
    • GET /status
```

### Package Structure
```
Packages/
├── DesignSystem/      # Reusable UI (tokens, components)
├── Services/          # API clients (Supabase, Vercel)
├── Models/            # Data models (Task, Staff, etc.)
└── Features/          # Feature modules (Tasks, Messages)
```

---

## Phase 1: Core Implementation (Week 1)

### 1.1 Complete Service Implementations

**Priority: HIGH**

#### SupabaseService
File: `Packages/Services/Sources/Services/SupabaseService.swift`

- [ ] Implement `fetch<T>(from:)` method
- [ ] Implement `insert<T>(_:into:)` method
- [ ] Implement `update<T>(_:in:id:)` method
- [ ] Implement `delete(from:id:)` method
- [ ] Implement `subscribe<T>(to:)` method for real-time
- [ ] Add proper error handling
- [ ] Test with Supabase project

**Context7 Usage:**
```bash
# Get Supabase Swift SDK documentation
/check context7: Supabase Swift SDK CRUD operations and real-time
```

#### VercelAgentService
File: `Packages/Services/Sources/Services/VercelAgentService.swift`

- [ ] Implement `classify(message:)` with SSE streaming
- [ ] Implement `chat(messages:)` with SSE streaming
- [ ] Implement `status()` endpoint
- [ ] Implement `streamSSE<T>(request:)` helper
- [ ] Test streaming with Vercel deployment

**Context7 Usage:**
```bash
# Get URLSession streaming documentation
/check context7: URLSession AsyncStream SSE streaming
```

### 1.2 Create Core Models

**Priority: HIGH**

Based on your Supabase schema, create models for:

- [ ] `Staff.swift` (maps to `staff` table)
- [ ] `Realtor.swift` (maps to `realtors` table)
- [ ] `ListingTask.swift` (maps to `listing_tasks` table)
- [ ] `StrayTask.swift` (maps to `stray_tasks` table)
- [ ] `Listing.swift` (maps to `listings` table)
- [ ] `SlackMessage.swift` (maps to `slack_messages` table)

**Use the Task.swift template as reference for:**
- Proper CodingKeys (snake_case → camelCase)
- Identifiable conformance
- Public initializers with defaults
- Computed properties

**Claude Command:**
```bash
/sync-models
# This will help you create models matching the database schema
```

### 1.3 Configure Xcode Project

**Priority: HIGH**

- [ ] Add local package dependencies to Xcode project:
  - DesignSystem
  - Services
  - Models
  - Features (when ready)
- [ ] Configure Supabase URL and key (use environment variables or Config.plist)
- [ ] Configure Vercel API URL
- [ ] Set up proper iOS and macOS targets
- [ ] Verify project builds successfully

---

## Phase 2: First Feature - Task Management (Week 2)

### 2.1 Build Core Components

**Priority: HIGH**

#### Create DesignSystem Components

1. **TaskRow** - Display a task in a list
   ```swift
   // Packages/DesignSystem/Sources/DesignSystem/Components/TaskRow.swift
   public struct TaskRow: View {
       let task: Task
       let onTap: () -> Void
       // TODO: Implement using Spacing and Typography tokens
   }
   ```

2. **EmptyState** - Show when no data
   ```swift
   // Packages/DesignSystem/Sources/DesignSystem/Components/EmptyState.swift
   public struct EmptyState: View {
       let icon: String
       let title: String
       let message: String
       // TODO: Implement
   }
   ```

3. **LoadingIndicator** - Show during async operations
   ```swift
   // Packages/DesignSystem/Sources/DesignSystem/Components/LoadingIndicator.swift
   public struct LoadingIndicator: View {
       // TODO: Implement
   }
   ```

**Claude Command:**
```bash
/extract-design-system
# Use this to identify more reusable components as you build
```

### 2.2 Build Task List Feature

**Priority: HIGH**

#### Create ViewModel
```swift
// Packages/Features/Sources/Features/Tasks/TaskListViewModel.swift
@MainActor
class TaskListViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var isLoading = false
    @Published var error: Error?

    private let supabase: SupabaseServiceProtocol

    init(supabase: SupabaseServiceProtocol) {
        self.supabase = supabase
    }

    func loadTasks() async {
        // TODO: Implement
    }

    func createTask(_ task: Task) async {
        // TODO: Implement
    }

    func toggleComplete(_ task: Task) async {
        // TODO: Implement
    }

    func subscribeToTasks() {
        // TODO: Implement real-time updates
    }
}
```

#### Create macOS View
```swift
// macOS/TaskListView.swift
struct TaskListView: View {
    @StateObject private var viewModel: TaskListViewModel

    var body: some View {
        NavigationSplitView {
            // Sidebar
        } detail: {
            // Task list with TaskRow components
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}
```

#### Create iOS View
```swift
// iOS/TaskListView.swift
struct TaskListView: View {
    @StateObject private var viewModel: TaskListViewModel

    var body: some View {
        NavigationStack {
            // Task list with TaskRow components
        }
        .navigationTitle("Tasks")
    }
}
```

### 2.3 Test Multi-Platform

**Priority: HIGH**

- [ ] Run on macOS simulator
- [ ] Run on iOS simulator
- [ ] Test CRUD operations
- [ ] Test real-time updates
- [ ] Verify UI adapts correctly to each platform

---

## Phase 3: Agent Integration (Week 3)

### 3.1 Message Classification Feature

**Priority: MEDIUM**

1. **Create SlackMessage model** (if not done in Phase 1.2)
2. **Create MessageListView**
   - Show pending Slack messages
   - Display classification status
3. **Create ClassificationViewModel**
   - Call VercelAgentService.classify()
   - Stream and display results
   - Show confidence scores
4. **Add classification UI**
   - Progress indicator during streaming
   - Display results with confidence badges
   - Manual override option

### 3.2 Streaming UI Patterns

**Priority: MEDIUM**

Learn and implement streaming response patterns:

```swift
// Example streaming pattern
Button("Classify Message") {
    Task {
        do {
            for try await chunk in vercelAgent.classify(message: text) {
                // Update UI progressively
                classification.append(chunk.content ?? "")
            }
        } catch {
            // Handle error
        }
    }
}
```

**Context7 Usage:**
```bash
# Get AsyncStream and streaming UI patterns
/check context7: SwiftUI AsyncStream progressive updates
```

---

## Phase 4: Polish & Expansion (Week 4+)

### 4.1 Additional Features

**Priority: LOW (Future)**

- [ ] Staff management views
- [ ] Realtor management views
- [ ] Listing details
- [ ] Task notes
- [ ] Search functionality
- [ ] Filters and sorting

### 4.2 Code Quality

**Priority: ONGOING**

Run these commands regularly:

```bash
/check-organization     # Analyze structure
/refactor-component     # Extract large files
/extract-design-system  # Find reusable components
```

### 4.3 Testing

**Priority: MEDIUM**

- [ ] Unit tests for ViewModels
- [ ] Unit tests for Services
- [ ] Integration tests
- [ ] UI tests for critical flows

---

## Development Workflow

### Daily Workflow

1. **Start in Claude Code**
   - Write/edit Swift files
   - Generate components
   - Refactor code

2. **Test in Xcode**
   - Build project
   - Run on simulator
   - Fix build errors
   - Test functionality

3. **Iterate**
   - Back to Claude Code for fixes
   - Repeat until working

4. **Check Organization**
   ```bash
   /check-organization
   ```

5. **Commit**
   - Only commit when code is clean
   - Follow pre-commit checklist

### Pre-Commit Checklist

- [ ] Code builds without errors
- [ ] Tested on both macOS and iOS
- [ ] No files exceed 200 lines
- [ ] Components in correct packages
- [ ] Using design tokens (not hardcoded values)
- [ ] Documentation added for public APIs
- [ ] No code duplication
- [ ] Naming conventions followed

---

## Key Resources

### Context7 Topics to Research

As you implement features, research these topics:

1. **Supabase Swift SDK**
   - CRUD operations
   - Real-time subscriptions
   - Authentication
   - Error handling

2. **SwiftUI Multi-Platform**
   - NavigationSplitView (macOS)
   - NavigationStack (iOS)
   - Platform detection
   - Shared code patterns

3. **AsyncStream & Streaming**
   - URLSession streaming
   - SSE parsing
   - Progressive UI updates
   - Error handling

4. **SwiftUI Architecture**
   - MVVM patterns
   - @StateObject vs @ObservedObject
   - @Published properties
   - Task lifecycle

### Claude Commands Reference

```bash
/refactor-component          # Extract view to separate file
/check-organization         # Analyze project structure
/extract-design-system      # Find reusable components
/sync-models               # Update models from database
/generate-service          # Create new service template
```

### Key Files Reference

```
CLAUDE.md                   # Code organization rules
.claude/commands/*.md       # Command definitions
Packages/*/Package.swift    # Package configurations
```

---

## Success Metrics

### Phase 1 Complete When:
- ✅ Services fully implemented and tested
- ✅ Core models created (6+ models)
- ✅ Project builds on both platforms
- ✅ Can fetch data from Supabase

### Phase 2 Complete When:
- ✅ Task list displays on macOS and iOS
- ✅ Can create, update, delete tasks
- ✅ Real-time updates working
- ✅ UI is clean and Things 3-inspired

### Phase 3 Complete When:
- ✅ Message classification streaming works
- ✅ Can display classification results
- ✅ Confidence scores shown in UI
- ✅ Agent integration patterns established

---

## Common Pitfalls to Avoid

1. **Don't skip the design system**
   - Always use Spacing, Typography, Colors
   - Extract reusable components early

2. **Don't let files grow too large**
   - Max 200 lines per file
   - Extract views immediately

3. **Don't hardcode API credentials**
   - Use environment variables
   - Use Config.plist for configuration

4. **Don't forget multi-platform**
   - Test on both macOS and iOS regularly
   - Use platform-specific UI where needed

5. **Don't skip error handling**
   - Every async operation needs try/catch
   - Show user-friendly error messages

6. **Don't forget real-time**
   - Use Supabase subscriptions for live updates
   - Test with multiple clients

---

## Getting Help

### When You're Stuck

1. **Use Context7**
   ```bash
   /check context7: [your question]
   ```

2. **Check CLAUDE.md**
   - Review code organization rules
   - Check package placement guidelines

3. **Run check-organization**
   ```bash
   /check-organization
   ```

4. **Review existing examples**
   - Look at Task.swift for model patterns
   - Look at SupabaseService.swift for service patterns

---

## Next Immediate Steps

1. **Implement SupabaseService methods** (2-3 hours)
   - Use Context7 for Supabase Swift SDK
   - Test with your Supabase project
   - Verify CRUD operations work

2. **Create remaining models** (2-3 hours)
   - Staff, Realtor, ListingTask, StrayTask, Listing, SlackMessage
   - Follow Task.swift pattern
   - Verify Codable works with Supabase

3. **Configure Xcode project** (1 hour)
   - Add package dependencies
   - Set up configuration
   - Verify builds

4. **Build first view** (3-4 hours)
   - TaskListView for macOS and iOS
   - Use DesignSystem components
   - Connect to SupabaseService

**Total estimated time to first working feature: 8-12 hours**

---

## Remember

- **Keep it simple** - Things 3 inspiration is about UX, not visual design
- **Extract early** - Don't wait for duplication
- **Use tokens** - Never hardcode spacing/fonts/colors
- **Test both platforms** - macOS and iOS have different idioms
- **Run commands** - Use `/check-organization` regularly
- **Commit often** - But only when code is clean

**The architecture is in place. Now build features!** 🚀
