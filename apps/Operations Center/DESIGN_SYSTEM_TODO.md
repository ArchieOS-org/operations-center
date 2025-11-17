# Design System Migration: Cards → Rows

## Overview
Migrating from card-based layouts to white row-based lists with a reusable Rows kit.

**Goal:** Replace card-based layouts with clean row-based lists. All non-home screens should render through shared list scaffolds and row components instead of one-off stacks or card chrome.

## Progress Tracking

### ✅ Phase 0: Analysis & Planning
- [x] Explore current design system structure
- [x] Document all card components and their usage
- [x] Identify screens requiring migration
- [x] Create tracking documentation

### ✅ Phase 1: Build Rows Kit Foundation
- [x] Create Rows folder structure
  - [x] DesignSystem/Components/Rows/Base
  - [x] DesignSystem/Components/Rows/Specialized
  - [x] DesignSystem/Components/Rows/Containers
- [x] Implement base components
  - [x] OCRow - Generic row primitive
  - [x] OCRowStyle - Default paddings and separator insets
  - [x] OCSectionHeader - Standard section header with optional count

### ✅ Phase 2: Implement Specialized Rows
- [x] OCListingRow - Canonical listing representation
- [x] OCTaskRow - General task row for standalone tasks
- [x] OCActivityRow - Row representation for property tasks
- [x] OCCheckboxRow - Reusable checkbox row
- [x] OCMessageRow - Author + timestamp + text row
- [x] OCAgentRow - Agent list row

### ✅ Phase 3: Implement Container Components
- [x] OCListScaffold - Shared scaffold for list-based screens
- [x] OCEmptyState - Lightweight empty-state view

### ✅ Phase 4: Migrate Browse Screens
- [x] AllListingsView - Replace ListingCollapsedContent with OCListingRow
- [x] MyListingsView - Replace ListingBrowseCard with OCListingRow
- [x] AgentsView - Extract RealtorRow to OCAgentRow
- [x] LogbookView - Migrate to row-based layout

### ✅ Phase 5: Migrate Task Screens
- [ ] AllTasksView - Complex view with @Observable issues, postponed
- [x] ListingDetailView - Replace note rows with OCMessageRow
- [x] MyTasksView - Task management with OCTaskRow

### ✅ Phase 6: Migrate Complex Screens
- [x] InboxView - Mixed content with OCListingRow and OCTaskRow

### ⏳ Phase 7: Clean Up
- [ ] Remove deprecated card components
- [ ] Update documentation
- [ ] Run full test suite
- [ ] Manual smoke test

## Design Decisions

### Row vs Card
- **Rows:** White background, no shadows, no card chrome, plain list style
- **Cards:** Tinted backgrounds, dual-layer shadows, 12pt corner radius (being deprecated)

### Spacing Standards
- **Horizontal:** `Spacing.listRowHorizontal` (16pt)
- **Vertical:** `Spacing.listRowVertical` (8pt)
- **Screen edges:** `Spacing.screenEdge` (16pt)
- **Section spacing:** Consistent 16pt between sections

### Color Usage
- **Row background:** `Colors.surfacePrimary` (system background)
- **Separators:** System default
- **No tinting** - Clean white rows instead of blue/orange tints

### Typography Hierarchy
- **Primary text:** `Typography.cardTitle` (.headline.semibold)
- **Secondary text:** `Typography.cardSubtitle` (.subheadline)
- **Metadata:** `Typography.cardMeta` (.caption)
- **Chip labels:** `Typography.chipLabel` (.caption2.medium)

### Animation Standards
- **Expansion:** Spring(0.3s, 0.7 damping) - matching ExpandableCardWrapper
- **No press animations** - Rows don't scale on press like cards did

## Migration Strategy

### Per-Screen Process
1. **Identify** current card usage
2. **Replace** with appropriate row component
3. **Wrap** in OCListScaffold if needed
4. **Preserve** all existing behaviors
5. **Build & Test** to verify no regressions
6. **Review** layout matches design intent

### Testing Requirements
- [ ] Build passes with no warnings
- [ ] All existing tests pass
- [ ] Visual regression testing
- [ ] Performance: List scrolling remains smooth
- [ ] Accessibility: VoiceOver announces correctly
- [ ] Dark mode: Proper color adaptation

## Component Mapping

| Old Component | New Component | Notes |
|--------------|---------------|-------|
| TaskCard | OCTaskRow | Preserve expansion, messages section |
| ActivityCard | OCActivityRow | Keep checkbox interactions |
| ListingCard | OCListingRow | Expandable with notes/activities |
| ListingBrowseCard | OCListingRow | Non-expandable variant |
| ListingCollapsedContent | OCListingRow | Core content only |
| CardHeader | (integrated into rows) | No separate header component |
| ExpandableCardWrapper | OCRow with expansionStyle | Built into base row |
| SlackMessagesSection | (reuse as-is) | Keep for expanded content |
| ActivitiesSection | (reuse as-is) | Keep for expanded content |
| NotesSection | (reuse as-is) | Keep for expanded content |
| NoteRow | OCMessageRow | Generalized for notes and messages |

## Code Quality Checklist

- [ ] Public APIs are obvious and self-documenting
- [ ] No fragile one-off hacks
- [ ] Builds green after each change
- [ ] SwiftLint warnings at zero
- [ ] No unused imports or properties
- [ ] Proper @MainActor usage
- [ ] Performance profiled for large lists

## Notes

- Keep home screen flexible for now - focus on list screens first
- Reuse existing tokens - don't add new ones unless necessary
- Preserve all existing behaviors - UX should be identical or clearly improved
- Small, reversible changes - each step should build green

---

*Last Updated: 2025-11-16*
*Status: Phase 6 Complete (7/8 screens migrated)*

## Migration Summary

### Completed Today
- ✅ **Phase 1-3**: Base rows, specialized rows, and container components fully implemented
- ✅ **Phase 4**: All browse screens successfully migrated
  - AllListingsView: Using OCListingRow + OCListScaffold
  - MyListingsView: Using OCListingRow + OCListScaffold
  - AgentsView: Using OCAgentRow + OCListScaffold
  - LogbookView: Using mixed rows + OCListScaffold
- ✅ **Phase 5**: Task and detail screen migrations
  - ListingDetailView: Using OCMessageRow for notes + OCListScaffold
  - MyTasksView: Using OCTaskRow + OCListScaffold
- ✅ **Phase 6**: Complex mixed content screen
  - InboxView: Using mixed OCListingRow and OCTaskRow + OCListScaffold

### Known Issues
- AllTasksView migration blocked due to @Observable ForEach binding issues
- Complex expandable sections may need special handling

### Next Steps
- Consider alternative approach for AllTasksView (final remaining screen)
- Begin card component deprecation
- Update documentation