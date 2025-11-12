# Refactor Component

Extract a SwiftUI view into a separate component file and organize it properly.

## Instructions

When this command is used, analyze the provided code and:

1. **Identify the view to extract**
   - Find views that are nested or complex (>50 lines)
   - Look for views that could be reused

2. **Determine proper location**
   - **Reusable UI component** → `Packages/DesignSystem/Sources/DesignSystem/Components/`
   - **Feature-specific view** → `Packages/Features/Sources/Features/{FeatureName}/`
   - **Platform-specific** → `{macOS|iOS}/{ComponentName}.swift`

3. **Extract to new file**
   - Create file named `{ComponentName}.swift`
   - One component per file
   - Include necessary imports
   - Add documentation comments

4. **Update dependencies**
   - Add component to Package.swift if needed
   - Update imports in original file
   - Verify build will succeed

5. **Follow naming conventions**
   - Views: `NounView` or `Noun` (e.g., `TaskListView`, `TaskRow`)
   - Keep names descriptive and concise

## Example

Before:
```swift
// TaskListView.swift (200 lines)
struct TaskListView: View {
    var body: some View {
        List {
            ForEach(tasks) { task in
                HStack {
                    Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                    Text(task.title)
                    // ... 30 more lines
                }
            }
        }
    }
}
```

After:
```swift
// TaskListView.swift (clean)
struct TaskListView: View {
    var body: some View {
        List(tasks) { task in
            TaskRow(task: task)
        }
    }
}

// Packages/DesignSystem/Sources/DesignSystem/Components/TaskRow.swift
/// A reusable row component for displaying a task
public struct TaskRow: View {
    let task: Task

    public init(task: Task) {
        self.task = task
    }

    public var body: some View {
        HStack {
            Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
            Text(task.title)
        }
    }
}
```

## Rules

- Max 200 lines per file
- Extract early, extract often
- Prefer composition over complexity
- Always add documentation
