# Operations Center - Error Handling & Edge Cases Audit Report

## Severity Classification

**CRITICAL** - App crash risk, data corruption, silent failures
**HIGH** - User confusion, incomplete operations, poor recovery
**MEDIUM** - Degraded UX, missing validation, edge cases not handled
**LOW** - Cosmetic issues, minor improvements

---

## CRITICAL ISSUES

### 1. **Fatal Force Unwraps in Production Code**

**Location:** `/apps/Operations Center/Operations Center/Supabase.swift:71`
```swift
redirectToURL: URL(string: "operationscenter://")!,
```

**Issue:** Force unwrap of a URL that should never fail. While the hardcoded URL is safe, this pattern teaches bad habits. If this URL ever becomes dynamic from config, the force unwrap will crash.

**Risk:** App crash in production if config changes
**Status:** Will crash

**Location:** `/apps/Operations Center/Operations Center/App/Config.swift:49, 67`
```swift
return URL(string: "https://kukmshbkzlskyuacgzbo.supabase.co")!
return URL(string: "https://operations-center.vercel.app")!
```

**Issue:** Hardcoded URLs force-unwrapped. These are "safe" because the strings are valid, but they bypass error handling entirely.

**Risk:** Code smell that will crash if config becomes dynamic
**Status:** Potential crash point

---

### 2. **fatalError() in Production Code - Mandatory Override Not Enforced**

**Location:** `/apps/Operations Center/Operations Center/Features/TeamView/TeamViewStore.swift:114`
```swift
func loadTasks() async {
    fatalError("Subclasses must override loadTasks()")
}
```

**Issue:** This is an abstract method in a base class. The protocol declares it:
```swift
protocol TeamViewStore: Observable {
    func loadTasks() async
}
```

But the base class doesn't force subclasses to override it. If a subclass accidentally forgets to implement `loadTasks()`, the app **will crash when that method is called**.

**Risk:** App crash at runtime
**Status:** Will crash if a subclass doesn't implement loadTasks()

---

### 3. **Missing Error Handling in Supabase Initialization**

**Location:** `/apps/Operations Center/Operations Center/Supabase.swift:94`
```swift
#else
// Release builds MUST have config - fail loudly
fatalError("Failed to initialize Supabase client: \(error.localizedDescription)")
#endif
```

**Issue:** In release builds, missing config causes immediate fatal crash. There's no graceful degradation, no fallback, no user-facing error message.

**Risk:** Any missing environment variable = app crashes on launch
**Status:** Will crash

---

### 4. **Config.swift fatalError() in DEBUG Mode**

**Location:** `/apps/Operations Center/Operations Center/App/Config.swift:94`
```swift
#if DEBUG
fatalError("Configuration error: \(error.localizedDescription)")
```

**Issue:** During development, config errors crash the app rather than logging. This makes debugging harder - the app should try to continue with stub data.

**Risk:** Development friction, hard to debug
**Status:** Will crash in DEBUG

---

### 5. **Silent Failures in Data Caching**

**Location:** `/apps/Operations Center/Operations Center/State/AppState.swift:213-221`
```swift
private func loadCachedData() {
    if let data = UserDefaults.standard.data(forKey: "cached_tasks"),
       let tasks = try? JSONDecoder().decode([Activity].self, from: data) {
        allTasks = tasks
    }
}

private func saveCachedData() {
    if let data = try? JSONEncoder().encode(allTasks) {
        UserDefaults.standard.set(data, forKey: "cached_tasks")
    }
}
```

**Issue:** Both decode and encode use `try?` which silently swallows all errors:
- Decode failure → empty tasks (user sees nothing)
- Encode failure → cache never updates (stale data)
- No logging of what went wrong
- User has no idea data is corrupted or cache failed

**Risk:** Silent data loss, stale UI, user confusion
**Status:** Silent failure

---

## HIGH SEVERITY ISSUES

### 6. **Supabase .value Extraction - Implicit Force Unwrap**

**Locations:** Multiple files
- `TaskRepositoryClient.swift:152, 169, 202, 216, 235...`
- `ListingRepositoryClient.swift:66, 84, 97, 112, 146, 160, 177...`
- `ListingNoteRepositoryClient.swift:41, 61, 84`
- `AppState.swift:186`

```swift
let response: [Activity] = try await supabase
    .from("activities")
    .select("*, listings(*)")
    .execute()
    .value  // <-- THIS CAN THROW
```

**Issue:** The `.value` property on Supabase responses can throw if:
- Decode fails
- Network error occurs
- Server returns unexpected response
- JSON is malformed

But the error is not caught. It propagates up and crashes the view if not handled at the top level.

**Risk:** Unhandled errors crash features
**Status:** Will throw and propagate

**Example Crash Path:**
1. `TaskRepositoryClient.fetchActivities()` calls `.value`
2. Network glitch causes decode to fail
3. Error is thrown but not documented
4. AppState.fetchTasks() catches it and sets errorMessage
5. BUT: If realtime subscription also fails, it overwrites the error

---

### 7. **Realtime Subscription Error Overwrites UI State**

**Location:** `/apps/Operations Center/Operations Center/State/AppState.swift:139-145`
```swift
for await change in channel.postgresChange(AnyAction.self, table: "activities") {
    await self.handleRealtimeChange(change)
}
} catch {
    self.errorMessage = "Realtime subscription error: \(error.localizedDescription)"
}
```

**Issue:** 
- Realtime subscription failure overwrites any existing error message
- If user just saw a network error, realtime failure clears it
- Error messages are not queued or accumulated
- User sees latest error, loses context of what happened first

**Risk:** User confusion, lost error context
**Status:** Data loss (errors get overwritten)

---

### 8. **No Error Recovery for Missing Listing Data**

**Location:** `/apps/Operations Center/Operations Center/Dependencies/TaskRepositoryClient.swift:108-112`
```swift
nonisolated private func mapActivityResponse(_ row: ActivityResponse) -> ActivityWithDetails? {
    guard let listing = row.listing else {
        // Logging removed to avoid introducing MainActor isolation in this pure mapping function
        return nil
    }
```

**Issue:** 
- When listing data is missing, activities are silently dropped
- The comment says "logging removed" - so we KNOW it's a problem but disabled it
- Activity rows are returned from DB but filtered out silently
- User never knows why activities are missing
- If the listing table is corrupted, users get empty task lists

**Risk:** Silent data loss, user confusion
**Status:** Silent failure with no visibility

---

### 9. **No Validation on Supabase Response Counts**

All repository methods fetch from Supabase but never validate:
- Is the response empty when it shouldn't be?
- Did the server return all requested data?
- Is pagination being handled?

**Example:** `fetchAcknowledgedListingIds()` returns empty set if there's an error in the query, user can't tell if they haven't acknowledged anything or if the query failed.

**Risk:** Silent data loss, inconsistent state
**Status:** Silent failure

---

### 10. **Email to Staff Name Lookup Can Silently Fail**

**Location:** `/apps/Operations Center/Operations Center/Dependencies/ListingNoteRepositoryClient.swift:48-64`
```swift
let session = try await supabase.auth.session
let userEmail = session.user.email ?? ""  // <-- CAN BE EMPTY

// Fetch user's display name from staff table by email
let staff: [Staff] = try await supabase
    .from("staff")
    .select()
    .eq("email", value: userEmail)
    .execute()
    .value

let userName = staff.first?.name  // <-- CAN BE NIL
```

**Issue:**
- If session.user.email is nil, userEmail becomes "" (empty string)
- Query searches for staff with email "" → finds nothing
- userName becomes nil
- Note is created with nil createdByName
- User adds note but it shows as "by (unknown)"

**Risk:** Poor UX, confused audit trail, data quality issues
**Status:** Silent degradation

---

## MEDIUM SEVERITY ISSUES

### 11. **Test Helpers Use fatalError() for Unimplemented Methods**

**Location:** `/apps/Operations Center/Operations CenterTests/Helpers/TaskRepositoryTestHelpers.swift:20-31`
```swift
fetchTasks: { fatalError("TaskRepositoryClient.fetchTasks is unimplemented") },
fetchActivities: { fatalError("TaskRepositoryClient.fetchActivities is unimplemented") },
```

**Issue:** If a test forgets to mock a method, it crashes instead of providing helpful feedback.

**Better approach:** Return a predictable error or assertion failure with context.

**Risk:** Test crashes, hard to debug tests
**Status:** Will crash in tests

---

### 12. **No Input Validation on Task/Listing IDs**

**Locations:**
- `TaskRepositoryClient.deleteTask(taskId, deletedBy)` - no validation of taskId
- `ListingRepositoryClient.deleteListing(listingId, deletedBy)` - no validation of listingId
- `ListingNoteRepositoryClient.deleteNote(noteId)` - no validation of noteId

**Issue:** Empty strings or invalid IDs are passed directly to Supabase. If a user passes "" as a task ID:
```swift
try await repository.deleteTask("", userId)  // Deletes all tasks!
```

**Risk:** Data corruption, accidental mass deletion
**Status:** No guard clauses

---

### 13. **Email Validation is Weak**

**Location:** `/apps/Operations Center/Operations Center/Features/Auth/LoginView.swift:327-331`
```swift
private func isValidEmail(_ email: String) -> Bool {
    // Simple email validation
    let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
    return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
}
```

**Issue:** 
- Pattern allows invalid emails: "a+b@c.co" (no domain letters before @)
- Pattern requires minimum 2 letters in TLD (rejects valid .io, .co, .tv)
- User can enter invalid email, attempt login, get generic Supabase error
- No guidance on what's wrong

**Risk:** Poor UX, user frustration
**Status:** Missing validation feedback

---

### 14. **No Timeout Handling for Network Requests**

All Supabase queries use default timeouts (usually 30 seconds). If network is slow:
- User sees infinite loading
- No "tap to cancel" option
- No progress indication
- User doesn't know if it's loading or hung

**Risk:** User frustration, abandonment
**Status:** No timeout handling

---

### 15. **OAuth URL Force Unwrap**

**Location:** `/apps/Operations Center/Operations Center/Features/Auth/AuthenticationStore.swift:131`
```swift
try await supabaseClient.auth.signInWithOAuth(
    provider: .google,
    redirectTo: URL(string: "operationscenter://")!
)
```

**Issue:** Force unwrap of URL. Safe because hardcoded, but same problem as elsewhere - teaches bad patterns.

**Risk:** Code smell, future crash risk
**Status:** Will crash if URL becomes dynamic

---

### 16. **No Handling for Authentication State Changes During Operations**

**Scenario:**
1. User taps "Claim Task"
2. Authentication expires mid-request
3. `authClient.currentUserId()` throws
4. Error caught: "Failed to claim task"
5. User doesn't know it's an auth issue vs. network issue

**Issue:** No special handling for auth errors. User gets generic "Failed to claim task" when they should be re-directed to login.

**Risk:** User confusion, poor UX
**Status:** Missing auth error special case

---

### 17. **Error Messages Not Localized**

All error messages are hardcoded English strings. App should support multiple languages/regions.

**Examples:**
- "Failed to claim task" 
- "Failed to delete activity"
- "Realtime subscription error"

**Risk:** International users see English errors
**Status:** No localization

---

## LOW SEVERITY ISSUES

### 18. **try? in Tests Hides Errors**

**Location:** `/apps/Operations Center/Operations CenterTests/Features/MyTasks/MyTasksStoreTests.swift:118`
```swift
try? await Task.sleep(nanoseconds: 1_000_000)
```

**Issue:** Tests use `try?` which hides errors. Should be `try` to fail loud if something goes wrong.

**Risk:** Test failures hidden, harder to debug
**Status:** Masking errors

---

### 19. **Error Messages Don't Suggest Recovery**

Error messages are terse and don't guide users to solutions:
- "Failed to claim task" (What should I do?)
- "Realtime subscription error" (Is this critical?)
- "Fetch tasks failed" (Am I offline?)

**Better:**
- "Can't claim task - check your connection and try again"
- "Realtime updates paused - tap to retry"
- "Can't load tasks - you may be offline"

**Risk:** User frustration
**Status:** UX issue

---

### 20. **No Explicit Timeout UI for Long Operations**

When operations take >3 seconds, UI should show:
- "Still loading..."
- "Tap to cancel"
- Estimated time remaining

Currently just spinning ProgressView forever.

**Risk:** User anxiety, abandonment
**Status:** UX issue

---

## SUMMARY OF CRASH RISKS

### Will Definitely Crash:
1. **fatalError()** in TeamViewStore if subclass doesn't override loadTasks()
2. **fatalError()** in Config if Supabase config is missing in release builds
3. **Force unwraps** on URLs (though hardcoded, so very unlikely)

### Will Crash in Error Scenarios:
1. Unhandled `.value` exceptions from Supabase queries if they fail
2. Missing environment variables in release builds

### Silent Failures (No Crash, No Error Shown):
1. Cache decode/encode failures
2. Missing listing data (activities silently dropped)
3. Staff name lookup failures (note shows "unknown" user)
4. Realtime subscription errors overwrite UI state

### Data Corruption Risks:
1. No ID validation on deletes (could delete all records if empty string passed)
2. No validation of batch operations

### Error Handling Grade: **D+**

---

## RECOMMENDATIONS

### Immediate (Today):
1. Remove fatalError() from TeamViewStore - use protocol requirement enforcement
2. Add validation to delete methods - reject empty IDs
3. Log cache failures instead of silently swallowing them
4. Stop force-unwrapping URLs even if hardcoded

### High Priority (This Week):
1. Implement proper error queue instead of overwriting errorMessage
2. Add special handling for AuthClientError in repositories
3. Validate Supabase response counts and log discrepancies
4. Add timeout UI for operations >3 seconds

### Medium Priority (Next Sprint):
1. Implement proper email validation with clear feedback
2. Add recovery suggestions to all error messages
3. Handle missing listing data more gracefully (show placeholder)
4. Test error paths systematically

### Future:
1. Implement error analytics/logging
2. Localize error messages
3. Add network state monitoring
4. Implement exponential backoff for retries

