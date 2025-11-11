# Check Organization

Analyze the project structure and identify organizational issues.

## Instructions

When this command is used, analyze the codebase and report on:

1. **File Size Issues**
   - Files exceeding 200 lines
   - Suggest extraction candidates
   - Identify overly complex views

2. **Package Placement**
   - Components in wrong packages
   - Missing package dependencies
   - Circular dependencies

3. **Code Duplication**
   - Similar code across files
   - Candidates for extraction to DesignSystem
   - Repeated patterns that should be components

4. **Naming Conventions**
   - Files not following conventions
   - Views without proper suffixes
   - Inconsistent naming patterns

5. **Dependency Graph**
   - Visualize package dependencies
   - Identify coupling issues
   - Suggest improvements

## Report Format

```markdown
# Organization Analysis Report

## Summary
- Total files analyzed: X
- Issues found: Y
- Recommendations: Z

## Issues by Category

### File Size (Priority: High)
- `TaskListView.swift`: 247 lines (max 200)
  → Extract `TaskRowContent` to separate component
  → Move complex logic to ViewModel

### Package Placement (Priority: Medium)
- `CustomButton.swift` in Features/Tasks/
  → Should be in DesignSystem/Components/
  → Used in 3+ features, should be shared

### Code Duplication (Priority: Medium)
- Similar code in:
  - `TaskListView.swift:45-60`
  - `MessageListView.swift:32-47`
  → Extract to `ListEmptyState` component

### Naming Conventions (Priority: Low)
- `list.swift` → Should be `TaskListView.swift`
- `button.swift` → Should be `ActionButton.swift`

## Recommendations

1. Extract 3 components to DesignSystem
2. Refactor 2 large files
3. Consolidate duplicate code
4. Rename 4 files

## Dependency Graph
```
App → Features → Services
       ↓           ↓
   DesignSystem  Models
```
```

## Usage

Run this command:
- After major changes
- Before committing
- When adding new features
- Weekly as maintenance
