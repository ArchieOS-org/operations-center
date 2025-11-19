# Premium Multiplatform Interaction Specification

**Operations Center Design System**  
Based on Apple platform conventions, Things 3 reference patterns, and Context7 research

---

## 1. Return Key Behavior Matrix

### iOS Text Input Patterns

| Context | Input Type | Return Key Label | Return Key Action | Implementation |
|---------|-----------|------------------|-------------------|----------------|
| Single-line note entry | TextField | `.done` | Submit note | Current implementation ✓ |
| Multi-line note entry | TextEditor | `.default` | Insert newline | Not yet implemented |
| Search field | TextField | `.search` | Submit search | Future |
| Form field | TextField | `.next` / `.done` | Next field / Submit | Future |

**Current Implementation (NotesSection.swift)**
```swift
TextField("Add a note...", text: $inputText)
    .lineLimit(1)
    .submitLabel(.done)
    .onSubmit(onSubmit)
```

**Recommended Pattern: Keep Single-Line TextField**
- Industry standard (Messages, Slack, Things 3): Return = Submit for quick note entry
- Multi-line notes would require explicit "expand" button → Changes UX complexity
- Current implementation is correct for inline note entry
- Justification: Speed over flexibility. Notes are quick thoughts, not essays.

### macOS Text Input Patterns

| Keyboard Input | Action | Modifier Alternative | Implementation |
|----------------|--------|---------------------|----------------|
| Return | Submit note | - | TextField.onSubmit |
| Shift+Return | N/A (single line) | - | Not needed |
| Cmd+Return | N/A (single line) | - | Reserved for future |
| Escape | Clear focus | - | FocusState binding |

**macOS Specifics:**
```swift
TextField("Add a note...", text: $inputText)
    .onSubmit(onSubmit)  // Return key
    .focused($isInputFocused)
    .onKeyPress(.escape) { isInputFocused = false; return .handled }
```

---

## 2. Focus Behavior Rules

### Auto-Focus Decision Tree

```
View Appears
    ↓
Is it a modal/sheet?
    YES → Auto-focus primary input field
    NO → Is it card expansion?
        YES → Check user intent
            - User tapped "Add Note" button? → Auto-focus
            - User tapped card to expand? → No focus
        NO → No auto-focus (respect user navigation)
```

### Implementation Rules

**DO Auto-Focus:**
- User-initiated "Add" actions (tapping FAB, "Add Note" button)
- Modal sheets with input forms
- Empty states with single input field

**DO NOT Auto-Focus:**
- Card expansion (user may be reading, not editing)
- List view navigation
- Background data refresh

**Current Implementation Recommendation:**
```swift
// NotesSection: No auto-focus on card expansion (correct)
@FocusState private var isInputFocused: Bool

// Future: Add explicit focus trigger for "Add Note" button
.onChange(of: triggerFocus) { _, shouldFocus in
    if shouldFocus { isInputFocused = true }
}
```

### Focus Clearing Rules

| Event | Clear Focus? | Reason |
|-------|-------------|---------|
| Note submitted | YES | Reset for next entry |
| Card collapsed | YES | User navigating away |
| Tap outside field | YES (macOS) | Platform convention |
| Navigation away | YES | Automatic with view removal |

**Implementation:**
```swift
onSubmit: {
    onSubmit()
    isInputFocused = false  // Clear focus after submission
}
```

### macOS Focus Indicators

**System Standard:**
- Blue ring around focused field (automatic with SwiftUI)
- 2pt ring, system accent color
- DO NOT customize unless accessibility requires it

**Tab Order:**
```swift
// Automatic tab order follows visual hierarchy
// Override only if logical order differs:
TextField("Note", text: $text)
    .focusable(true, interactions: .edit)
    .defaultFocus($focusedField, .noteInput)
```

---

## 3. Hover & Press States

### macOS Hover Effects

**Card Hover Pattern (CardBase.swift enhancement needed):**

```swift
@State private var isHovered = false

var body: some View {
    content
        .background(
            Colors.surfaceSecondary
                .opacity(isHovered ? 0.95 : 1.0)  // Subtle brighten on hover
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        #if os(macOS)
        .onContinuousHover { phase in
            switch phase {
            case .active: NSCursor.pointingHand.push()
            case .ended: NSCursor.pop()
            }
        }
        #endif
}
```

**Hover Effect Values:**

| Element | Effect | Duration | Cursor |
|---------|--------|----------|--------|
| Card | Opacity 1.0 → 0.95 | 150ms ease-in-out | pointingHand |
| Button | Scale 1.0 → 1.02 | 150ms ease-in-out | pointingHand |
| List Row | Background tint +5% | 150ms ease-in-out | arrow |
| Text Field | Border highlight | 150ms ease-in-out | iBeam (auto) |

**Principles:**
- Subtle, not web-like (avoid aggressive highlights)
- Cursor change indicates interactivity
- Animation smooths state changes
- Light mode: darken slightly; Dark mode: lighten slightly

### iOS Touch Feedback

**Existing Implementation (CardBase.swift):**
```swift
@State private var isPressed = false

.scaleEffect(isPressed ? 0.98 : 1.0)
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
.simultaneousGesture(
    DragGesture(minimumDistance: 0)
        .onChanged { _ in isPressed = true }
        .onEnded { _ in isPressed = false }
)
```

**Press Effect Values:**

| Element | Scale | Spring Response | Damping | Haptic |
|---------|-------|----------------|---------|--------|
| Card | 0.98 | 0.3s | 0.7 | selection |
| Button (primary) | 0.95 | 0.25s | 0.7 | medium impact |
| Button (secondary) | 0.97 | 0.25s | 0.7 | light impact |
| Toggle | 1.0 (no scale) | - | - | selection |

**Haptic Timing:**
```swift
// Fire haptic on press DOWN, not release
.sensoryFeedback(.impact(weight: .medium), trigger: isPressed)

// For selection feedback (toggles, pickers):
.sensoryFeedback(.selection, trigger: selectedValue)
```

---

## 4. Animation Specifications

### New Item Appearance Animation

**Pattern: Fade + Slide from Top**

```swift
ForEach(notes) { note in
    NoteRow(note: note)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .top)),
            removal: .opacity
        ))
}
.animation(.spring(response: 0.3, dampingFraction: 0.68), value: notes.count)
```

**Timing Values:**

| Animation Type | Duration | Easing | When to Use |
|---------------|----------|--------|-------------|
| New item appear | 0.3s spring (damping 0.68) | Bouncy | Adding notes, tasks |
| Item removal | 0.25s spring (damping 0.8) | Smooth | Deleting items |
| Card expand | 0.3s spring (damping 0.68) | Bouncy | Expansion/collapse |
| Button press | 0.25s spring (damping 0.7) | Snappy | All button interactions |
| Modal present | 0.4s spring (damping 0.8) | Smooth | Sheets, dialogs |

### Stagger Pattern (Future Enhancement)

**For multiple simultaneous items:**
```swift
ForEach(Array(notes.enumerated()), id: \.element.id) { index, note in
    NoteRow(note: note)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .top)),
            removal: .opacity
        ))
        .animation(
            .spring(response: 0.3, dampingFraction: 0.68)
                .delay(Double(index) * 0.05),  // 50ms stagger
            value: notes.count
        )
}
```

**Stagger Rules:**
- Use only for 3+ simultaneous items
- 50ms delay between items
- Maximum 250ms total stagger (5 items)
- Skip stagger for background data loads

### SwiftUI Animation Patterns

**Existing System (Animations.swift):**
```swift
// Use semantic names, not raw values
.animation(Animations.cardExpansion, value: isExpanded)  // ✓ Correct
.animation(.spring(response: 0.3, dampingFraction: 0.68), value: isExpanded)  // ✗ Avoid
```

**Animation Selection Guide:**

| Semantic Name | Response | Damping | Use Case |
|--------------|----------|---------|----------|
| `.cardExpansion` | 0.3s | 0.68 | Card expand/collapse |
| `.buttonPress` | 0.25s | 0.7 | Button scale feedback |
| `.quick` | 0.25s | 0.7 | Toggle, chip selection |
| `.standard` | 0.3s | 0.68 | General animations |
| `.cardExpansionSmooth` | 0.4s | 0.8 | Modal presentation |

---

## 5. Empty State Behavior

### Input Field Visibility

**Rule: Always visible, never hide input field**

**Current Implementation (Correct):**
```swift
// Input field always rendered
TextField("Add a note...", text: $inputText)

// List rendered conditionally
if !notes.isEmpty {
    VStack(spacing: Spacing.sm) {
        ForEach(notes) { note in
            NoteRow(note: note)
        }
    }
}
```

**Rationale:**
- Reduces cognitive load (no "Where's the Add button?")
- Faster task completion (no extra tap to reveal input)
- Consistent layout (no jumping UI when first item added)
- Matches Things 3, Reminders.app patterns

### Empty State Copy

**Pattern: Silent by default, contextual hint only if needed**

| Context | Empty State Message | Justification |
|---------|-------------------|---------------|
| Notes list | No message (input field is the CTA) | Input field is obvious action |
| Activities list | "No activities yet" (gray text) | Clarifies empty state vs loading |
| Search results | "No results for '[query]'" | Explains why empty |
| Network error | "Unable to load notes" + retry button | Actionable error |

**Implementation:**
```swift
// ✓ Correct: Explicit empty message for activities
if tasks.isEmpty {
    Text("No activities yet")
        .font(Typography.body)
        .foregroundStyle(.tertiary)  // Low visual weight
        .padding(.vertical, Spacing.sm)
}

// ✓ Correct: Silent empty state for notes (input is visible)
if !notes.isEmpty {
    // Render list
}
```

### Visual Weight Hierarchy

**Empty → Populated Transition:**
1. Empty: Input field at standard prominence
2. First item: Input field remains, list appears below
3. Multiple items: Input field stays top, list grows

**NO layout shift, NO animations on empty state**

---

## 6. Keyboard Shortcuts (macOS)

### Primary Shortcuts

| Shortcut | Action | Context | Implementation |
|----------|--------|---------|----------------|
| Cmd+N | New note (focus input) | Global | `.keyboardShortcut("n", modifiers: .command)` |
| Return | Submit note | Input focused | `.onSubmit()` |
| Escape | Clear focus / Dismiss sheet | Any | `.onKeyPress(.escape)` |
| Cmd+Return | N/A (reserved) | - | Future: Quick submit from anywhere |
| Cmd+W | Close window | Global | System default |
| Cmd+, | Preferences | Global | Future |

### Focus Navigation

| Shortcut | Action | Implementation |
|----------|--------|----------------|
| Tab | Next field | Automatic |
| Shift+Tab | Previous field | Automatic |
| Cmd+[ | Navigate back | NavigationStack |
| Cmd+] | Navigate forward | NavigationStack |

### Implementation Pattern

```swift
// Global shortcut (view-level)
.keyboardShortcut("n", modifiers: .command) {
    focusedField = .noteInput
}

// Field-level escape handling
TextField("Note", text: $text)
    .onKeyPress(.escape) {
        isInputFocused = false
        return .handled  // Prevent parent from handling
    }

// Conditional shortcuts
.keyboardShortcut("s", modifiers: .command)
    .disabled(noteText.isEmpty)  // Only enabled when valid
```

### Shortcut Discovery

**Menu Bar Integration (macOS):**
```swift
CommandMenu("Notes") {
    Button("New Note") {
        focusedField = .noteInput
    }
    .keyboardShortcut("n", modifiers: .command)
}
```

**Help Overlay (Future):**
- Cmd+? to show shortcut help
- Context-sensitive shortcuts based on focused view

---

## 7. Platform-Specific Considerations

### iOS Keyboard Behavior

**Keyboard Toolbar:**
```swift
TextField("Add a note...", text: $inputText)
    .toolbar {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Done") {
                isInputFocused = false
            }
        }
    }
```

**Keyboard Dismissal:**
- Tap outside → Dismiss (automatic with `.scrollDismissesKeyboard(.interactively)`)
- Drag list down → Dismiss (automatic)
- Explicit "Done" button → Dismiss (toolbar button)

**Safe Area Handling:**
```swift
// Automatic keyboard avoidance
ScrollView {
    content
}
.ignoresSafeArea(.keyboard, edges: .bottom)  // If explicit control needed
```

### macOS Window Behavior

**Resize Handling:**
```swift
// Content should adapt to window size changes
GeometryReader { geometry in
    content
        .frame(maxWidth: geometry.size.width > 600 ? 600 : nil)  // Max width constraint
}
```

**Toolbar Integration:**
```swift
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        Button("Add Note") {
            focusedField = .noteInput
        }
        .keyboardShortcut("n", modifiers: .command)
    }
}
```

### Accessibility Considerations

**VoiceOver Labels:**
```swift
TextField("Add a note...", text: $inputText)
    .accessibilityLabel("Note input field")
    .accessibilityHint("Enter text and press Return to add note")

Button("Submit") { }
    .accessibilityLabel("Add note")
    .accessibilityInputLabels(["Add", "Submit", "Create"])  // Voice shortcuts
```

**Focus Order:**
```swift
// Logical reading order for screen readers
.accessibilityElement(children: .contain)
.accessibilityLabel("Notes section")
```

**Keyboard-Only Navigation:**
- All interactive elements must be focusable
- Visible focus indicators (automatic with SwiftUI)
- Escape key should always dismiss/unfocus

---

## 8. Implementation Checklist

### Phase 1: Existing Component Enhancement (NotesSection)

- [x] Single-line TextField with Return = Submit ✓ Already implemented
- [x] Focus state management ✓ Already implemented
- [ ] Clear focus on submission
- [ ] macOS hover effect on NoteRow
- [ ] macOS cursor changes (pointingHand for clickable elements)
- [ ] Stagger animation for multiple new notes (if applicable)

### Phase 2: CardBase Enhancement

- [ ] macOS hover state (subtle opacity change)
- [ ] macOS cursor change on hover
- [ ] Verify iOS press feedback (already implemented)
- [ ] Verify haptic timing (fire on press down)

### Phase 3: Global Keyboard Shortcuts (macOS)

- [ ] Cmd+N → Focus note input
- [ ] Escape → Clear focus
- [ ] Menu bar integration for shortcuts
- [ ] Help overlay (Cmd+?)

### Phase 4: Accessibility Audit

- [ ] VoiceOver labels for all interactive elements
- [ ] Keyboard-only navigation testing
- [ ] Focus indicator visibility
- [ ] Screen reader announcement testing

---

## 9. Reference Values Quick Reference

### Animation Timing

```swift
// Spring animations (preferred)
Animations.cardExpansion    // 0.3s response, 0.68 damping
Animations.buttonPress      // 0.25s response, 0.7 damping
Animations.quick            // 0.25s response, 0.7 damping
Animations.cardExpansionSmooth  // 0.4s response, 0.8 damping

// Hover effects
Duration: 0.15s
Easing: .easeInOut
```

### Scale Effects

```swift
Card press: 0.98
Button (primary): 0.95
Button (secondary): 0.97
Hover scale (macOS): 1.02 (optional, prefer opacity)
```

### Opacity Effects

```swift
macOS hover: 0.95 (light mode), 1.05 (dark mode - via blend mode)
Disabled state: 0.5
Loading state: 0.6
```

### Haptic Feedback

```swift
Card tap: .selection
Button press: .impact(weight: .medium)
Subtle action: .impact(weight: .light)
Destructive: .impact(weight: .heavy)
Success/Error: .success / .error
```

---

## 10. Code Patterns

### TextField with Focus Management

```swift
@FocusState private var isInputFocused: Bool
@State private var inputText = ""

TextField("Add a note...", text: $inputText)
    .focused($isInputFocused)
    .submitLabel(.done)
    .onSubmit {
        submitNote()
        isInputFocused = false  // Clear focus after submission
    }
    .onKeyPress(.escape) {
        isInputFocused = false
        return .handled
    }
```

### macOS Hover Effect

```swift
@State private var isHovered = false

NoteRow(note: note)
    .background(
        Colors.surfaceSecondary
            .opacity(isHovered ? 0.95 : 1.0)
    )
    .animation(.easeInOut(duration: 0.15), value: isHovered)
    .onHover { hovering in
        isHovered = hovering
    }
    #if os(macOS)
    .onContinuousHover { phase in
        switch phase {
        case .active: NSCursor.pointingHand.push()
        case .ended: NSCursor.pop()
        }
    }
    #endif
```

### New Item Animation

```swift
ForEach(notes) { note in
    NoteRow(note: note)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .top)),
            removal: .opacity
        ))
}
.animation(Animations.cardExpansion, value: notes.count)
```

### Conditional Haptic

```swift
Button("Add Note") {
    addNote()
}
.sensoryFeedback(.impact(weight: .medium), trigger: noteCount)
```

---

## Conclusion

This specification prioritizes **speed, clarity, and platform consistency** over feature complexity. Every decision reduces cognitive load and eliminates friction.

**Core Philosophy:**
- Fewer decisions → Faster actions
- Obvious defaults → Less user hesitation
- Platform conventions → Familiar patterns
- Subtle feedback → Confident interactions

Ship interactions that vanish from the user's mind while they accomplish their work.
