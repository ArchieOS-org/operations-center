# Extract Design System

Find reusable components and move them to the DesignSystem package.

## Instructions

When this command is used:

1. **Scan for reusable patterns**
   - Views used in multiple places
   - Styling patterns repeated across files
   - Common UI elements (buttons, cards, lists)

2. **Identify candidates**
   - Used in 2+ features → Strong candidate
   - Contains hardcoded styling → Should use tokens
   - Generic and not feature-specific → Must move

3. **Extract to DesignSystem**
   - Move to `Packages/DesignSystem/Sources/DesignSystem/Components/`
   - Make public with proper initializer
   - Add documentation
   - Use design tokens (Spacing, Typography, Colors)

4. **Update all references**
   - Add DesignSystem import to consuming files
   - Replace implementations with component usage
   - Verify builds succeed

## Component Categories

### Components/
Reusable UI building blocks:
- `TaskRow.swift` - Display a task
- `SectionHeader.swift` - Section headers
- `EmptyState.swift` - Empty state views
- `ActionButton.swift` - Primary action buttons
- `LoadingIndicator.swift` - Loading states

### Tokens/
Design values:
- `Spacing.swift` - Spacing constants
- `Typography.swift` - Font styles
- `Colors.swift` - Color definitions (using system colors)

### Modifiers/
Custom view modifiers:
- `CardStyle.swift` - Card container styling
- `ListRowStyle.swift` - Consistent row styling

## Example Extraction

**Before** (in TaskListView.swift):
```swift
VStack {
    Image(systemName: "tray")
        .font(.system(size: 48))
        .foregroundColor(.gray)
    Text("No tasks")
        .font(.headline)
    Text("Create your first task to get started")
        .font(.subheadline)
        .foregroundColor(.secondary)
}
.padding(24)
```

**After** (extracted to DesignSystem):
```swift
// Packages/DesignSystem/Sources/DesignSystem/Components/EmptyState.swift
public struct EmptyState: View {
    let icon: String
    let title: String
    let message: String

    public init(icon: String, title: String, message: String) {
        self.icon = icon
        self.title = title
        self.message = message
    }

    public var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(Colors.secondary)
            Text(title)
                .font(Typography.title)
            Text(message)
                .font(Typography.caption)
                .foregroundColor(Colors.secondary)
        }
        .padding(Spacing.lg)
    }
}

// Usage in TaskListView.swift
import DesignSystem

EmptyState(
    icon: "tray",
    title: "No tasks",
    message: "Create your first task to get started"
)
```

## Criteria for Extraction

✅ **Extract if:**
- Used in 2+ places
- Could be reused with different data
- Has no feature-specific logic
- Contains styling that should be consistent

❌ **Don't extract if:**
- Only used once
- Tightly coupled to feature logic
- Less than 10 lines
- Platform-specific implementation

## Post-Extraction Checklist

- [ ] Component is in DesignSystem/Components/
- [ ] Uses design tokens (not hardcoded values)
- [ ] Has public initializer
- [ ] Has documentation comments
- [ ] All usages updated
- [ ] Package.swift updated if needed
- [ ] Builds successfully
- [ ] Tested on both macOS and iOS
