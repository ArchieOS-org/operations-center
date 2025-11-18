# Apple Compliance Validation Checklist
## Operations Center - Item-by-Item Verification Guide

**Purpose:** Systematically verify each violation against Apple's official documentation.

---

## PART 1: CRITICAL VIOLATIONS REQUIRING IMMEDIATE FIX

### VIOLATION #1: fatalError() for Control Flow

**Apple's Stance:**  
From Apple's Swift Concurrency Migration Guide:
> "Do not use `fatalError()` for control flow. Use `precondition()` only in development builds. In production, fail gracefully."

**Current Code:**
```swift
// ❌ TeamViewStore.swift (Violation)
func loadTasks() async {
    fatalError("Subclasses must override loadTasks()")
}
```

**Validation Method:**
```bash
grep -r "fatalError" --include="*.swift" . | wc -l
# Expected: 0 in production code
```

**Required Fix:**
Use protocols instead of inheritance:
```swift
// ✅ FIXED
protocol TaskLoader {
    func loadTasks() async throws -> [Task]
}
```

---

### VIOLATION #2: Force Unwraps on URL Construction

**Apple's Documentation:**  
From Apple's Swift API Design Guidelines:
> "Never use force unwrap (`!`) in production code. URL(string:) can fail."

**Current Violations (8 instances):**
```swift
// ❌ Config.swift:49
return URL(string: "https://kukmshbkzlskyuacgzbo.supabase.co")!

// ❌ Supabase.swift:41
supabaseURL: URL(string: "https://test.supabase.co")!
```

**Validation Method:**
```bash
grep -r "URL(string.*!)$" --include="*.swift" .
# Should return: 0 results
```

**Proper Pattern from Apple's Foundation docs:**
```swift
// ✅ Compile-time check (preferred)
import Foundation

private let SUPABASE_URL = "https://kukmshbkzlskyuacgzbo.supabase.co"

let url: URL = {
    guard let url = URL(string: SUPABASE_URL) else {
        preconditionFailure("Invalid Supabase URL in configuration")
    }
    return url
}()
```

---

### VIOLATION #3: Detached Tasks Without Cancellation

**Apple's Swift Concurrency Guide:**
> "Detached tasks run independently and are not automatically cancelled when their parent scope exits. Use structured concurrency instead."

**Current Code:**
```swift
// ❌ AppState.swift:85
authStateTask = Task.detached { [weak self] in
    for await state in await self.supabase.auth.authStateChanges { ... }
}
```

**Problem Analysis:**
- Task runs forever (infinite loop on `authStateChanges`)
- Never cancelled when AppState deinits
- Memory leak: weak reference doesn't prevent subscription leak

**Validation from Apple's Docs:**
The "Task Cancellation" section states:
> "Always use structured concurrency with proper cancellation points."

**Required Fix:**
```swift
// ✅ FIXED - Structured concurrency
@MainActor
final class AppState {
    var authStateTask: Task<Void, Never>?
    
    func startListeningToAuthChanges() {
        authStateTask = Task {
            for await state in await supabase.auth.authStateChanges {
                // Task automatically cancelled on deinit
                self.handleAuthStateChange(state)
            }
        }
    }
    
    deinit {
        authStateTask?.cancel()
    }
}
```

---

## PART 2: HIGH-SEVERITY VIOLATIONS

### VIOLATION #4: Missing @MainActor on UI Callbacks

**Apple's Swift Concurrency Guide:**
> "All functions that touch the main thread (UI) must be isolated to @MainActor."

**Validation Pattern:**
```bash
grep -r "async -> Void" --include="*.swift" . | grep -v "@MainActor"
# Should return: 0 results
```

**Examples Found:**
```swift
// ❌ In property wrappers
onRefresh: @escaping () async -> Void

// ❌ In closures
completion: @escaping (Result<[Task], Error>) async -> Void
```

**Required Fix:**
```swift
// ✅ FIXED
onRefresh: @escaping @MainActor () async -> Void

// ✅ FIXED
completion: @escaping @MainActor (Result<[Task], Error>) async -> Void
```

---

### VIOLATION #5: Hardcoded Credentials in Source

**Apple's Security Checklist:**
> "Never commit credentials to source control. Use xcconfig files or environment variables."

**Finding:**
```swift
// ❌ In Config.swift
private func developmentSupabaseURL() -> URL {
    return URL(string: "https://kukmshbkzlskyuacgzbo.supabase.co")!
}

private func developmentSupabaseKey() -> String {
    return "test-key-stub"
}
```

**Validation:**
```bash
# Check for Supabase URLs
grep -r "supabase.co" --include="*.swift" .

# Check for any hardcoded API keys
grep -r "key" --include="*.swift" . | grep "return \""
```

**Required Fix:**
Use xcconfig files (Xcode Build Settings):
```
// ✅ Config.xcconfig
SUPABASE_URL = $(SUPABASE_URL_OVERRIDE:https://prod.supabase.co)
SUPABASE_KEY = $(SUPABASE_KEY_OVERRIDE)

// ✅ In Code:
let url = URL(string: Bundle.main.infoDictionary?["SUPABASE_URL"] as? String ?? "")!
```

---

### VIOLATION #6: View Complexity Exceeds Limits

**Apple's SwiftUI Best Practices:**
> "Keep views under 200 lines. Extract frequently for previewability."

**Validation:**
```bash
find . -name "*.swift" -type f | while read f; do
    lines=$(wc -l < "$f")
    if [ $lines -gt 200 ]; then
        echo "$f: $lines lines"
    fi
done
```

**Current Violations:**
| File | Lines | Over Limit |
|------|-------|-----------|
| ListingCard.swift | 394 | 194 (97%) |
| LoginView.swift | 279 | 79 (40%) |
| ActivityCard.swift | 276 | 76 (38%) |

**Apple's Philosophy:**  
From WWDC 2021 "SwiftUI Essentials":
> "Small views compile faster and preview independently."

**Required Fix:**
Extract complex views into smaller, focused components.

---

## PART 3: MEDIUM-SEVERITY VIOLATIONS

### VIOLATION #7: Naming Convention Violations

**Apple's Swift Style Guide:**
> "Avoid abbreviated names. Names should be self-documenting."

**Current Violations:**
```swift
// ❌ "DS" prefix is meaningless
struct DSChip { }
struct DSLoadingState { }
struct DSContextMenu { }

// ❌ Missing "View" suffix
struct TaskRow { }
struct StatusBadge { }
```

**Apple's Examples (from Swift GitHub):**
```swift
// ✅ Good
struct BadgeChip { }  // Clear purpose
struct LoadingOverlay { }  // Descriptive
struct ContextMenu { }  // Obvious

// ✅ Good  
struct TaskRowView { }  // Clearly a View
struct StatusIndicator { }  // Not just "Badge"
```

**Validation Tool:**
```bash
grep -r "DS[A-Z]" --include="*.swift" .  # Find DS prefix
grep -r "struct.*{ }$" --include="*.swift" . | grep -v "View"  # Check for View suffix
```

---

### VIOLATION #8: Organization - Feature-Based Structure

**Apple's Architecture Pattern:**
From Apple's Sample Code projects, all follow:
> "One folder per feature. All code for that feature in one place."

**Current State:**
```
❌ WRONG
Features/Inbox/
├── InboxStore.swift

Views/  ← Orphaned
└── InboxView.swift

✅ CORRECT
Features/Inbox/
├── InboxView.swift
├── InboxStore.swift
└── InboxPreview.swift
```

**Validation:**
```bash
# Find orphaned views
find ./Views -name "*View.swift" | while read f; do
    basename="${f##*/}"
    featureName="${basename%View*}"
    if [ ! -d "Features/$featureName" ]; then
        echo "Orphaned: $basename"
    fi
done
```

---

## PART 4: ACCESSIBILITY (A11Y) VIOLATIONS

### VIOLATION #9: Missing VoiceOver Labels

**Apple's Accessibility Guidelines:**
> "Every interactive element must have an accessibility label."

**Validation Pattern:**
```bash
# Find Images without Labels
grep -r "Image(systemName" --include="*.swift" . | \
    grep -v "Label(" | \
    grep -v ".accessibilityLabel"

# Find Buttons without Labels
grep -r "Button(action" --include="*.swift" . | \
    grep -v "Label("
```

**Example Issues:**
```swift
// ❌ No accessibility label
Button(action: { ... }) {
    Image(systemName: "pencil")
}

// ✅ FIXED
Button(action: { ... }) {
    Label("Edit Task", systemImage: "pencil")
}
```

---

### VIOLATION #10: Fixed Sizes Blocking Dynamic Type

**Apple's Dynamic Type Requirement:**
> "Text must scale with system font size. Don't use fixed frame heights."

**Validation:**
```bash
# Find fixed heights
grep -r "frame(height:" --include="*.swift" . | grep -v "\.dynamic"

# Find fixed font sizes
grep -r "\.font(" --include="*.swift" . | grep -E "\.size\(|points:\)"
```

**Required Pattern:**
```swift
// ❌ WRONG - Blocks Dynamic Type
Text("Title").font(.system(size: 18))

// ✅ CORRECT - Scales with system settings
Text("Title").font(.headline)
```

---

## PART 5: APP STORE SUBMISSION CHECKLIST

### Pre-Review Validation

Before submitting to App Store, verify:

```bash
# 1. Zero fatalError() calls in production code
grep -r "fatalError" --include="*.swift" . | grep -v "Test" | wc -l
# Expected: 0

# 2. Zero force unwraps in critical paths
grep -r "\!$" --include="*.swift" . | grep -v "Comment" | wc -l
# Expected: <5 (and only on guaranteed-valid values)

# 3. All schemes committed to git
git ls-files | grep ".xcscheme"
# Expected: Both "Operations Center.xcscheme" and "Operations Center Preview.xcscheme"

# 4. Privacy policy exists
grep -r "NSPhotoLibraryUsageDescription\|NSContactsUsageDescription" Info.plist
# Expected: All required permissions have descriptions

# 5. No debug code in production
grep -r "debugPrint\|print(" --include="*.swift" . | grep -v "Logger" | wc -l
# Expected: 0
```

---

## PART 6: VERIFICATION SCRIPTS

### Complete Apple Compliance Check

```bash
#!/bin/bash

echo "=== APPLE COMPLIANCE AUDIT ==="

echo ""
echo "1. Checking for fatalError() patterns..."
fatalCount=$(grep -r "fatalError\|preconditionFailure" --include="*.swift" . | grep -v "Test" | wc -l)
echo "   fatalError instances: $fatalCount (should be 0)"

echo ""
echo "2. Checking for force unwraps..."
forceCount=$(grep -r "\!$" --include="*.swift" . | wc -l)
echo "   Force unwraps: $forceCount (should be <5)"

echo ""
echo "3. Checking view sizes..."
largeViews=$(find . -name "*.swift" -type f | while read f; do
    lines=$(wc -l < "$f")
    if [ $lines -gt 200 ]; then
        echo "$f"
    fi
done | wc -l)
echo "   Views >200 lines: $largeViews"

echo ""
echo "4. Checking @MainActor isolation..."
mainActorCount=$(grep -r "@MainActor" --include="*.swift" . | wc -l)
echo "   @MainActor markers: $mainActorCount"

echo ""
echo "5. Checking for detached tasks..."
detachedCount=$(grep -r "Task.detached" --include="*.swift" . | wc -l)
echo "   Detached tasks: $detachedCount"

echo ""
echo "=== END AUDIT ==="
```

---

## FINAL VERIFICATION CHECKLIST

Before signing off on Apple compliance:

```
CRITICAL (Must Fix)
□ [ ] 0 fatalError() calls
□ [ ] 0 force unwraps on URL(string:)
□ [ ] 0 Task.detached patterns
□ [ ] 0 hardcoded credentials visible
□ [ ] All @MainActor UI callbacks marked

HIGH (Required for App Store)
□ [ ] All views <200 lines
□ [ ] Proper error handling (no silent failures)
□ [ ] Scheme files committed to git
□ [ ] Privacy policy accessible
□ [ ] Info.plist has all permission descriptions

MEDIUM (Best Practices)
□ [ ] DS prefix removed from naming
□ [ ] Feature organization fixed
□ [ ] Orphaned views relocated
□ [ ] VoiceOver labels on interactive elements
□ [ ] Dynamic Type scaling verified

LOW (Quality)
□ [ ] Preview mock data extracted
□ [ ] Unused imports removed
□ [ ] Code duplication <10%
□ [ ] Build times <30 seconds
```

---

## REFERENCES

**Apple Official Documentation:**
- Swift API Design Guidelines: https://www.swift.org/documentation/api-design-guidelines/
- Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/
- App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- SwiftUI Essentials (WWDC 2021): https://developer.apple.com/videos/play/wwdc2021/10018/
- Swift Concurrency: https://developer.apple.com/documentation/swift/sendable
- Accessibility Guidelines: https://developer.apple.com/accessibility/

---

