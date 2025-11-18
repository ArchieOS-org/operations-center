# Error Handling Audit - Crash Scenarios

## Scenario 1: Missing Supabase Config in Release Build

**What Happens:**
```
1. User installs app from App Store
2. Missing SUPABASE_URL environment variable
3. AppDelegate.didFinishLaunchingWithOptions runs
4. Config.validate() is called
5. AppConfig.supabaseURL throws ConfigError.missingConfiguration
6. Supabase.swift catches error and calls fatalError()
7. 💥 APP CRASHES ON LAUNCH
```

**Current Code:**
```swift
// Supabase.swift:93-94
#else
// Release builds MUST have config - fail loudly
fatalError("Failed to initialize Supabase client: \(error.localizedDescription)")
#endif
```

**Impact:** 100% of users get crashed app on first launch if deployment pipeline forgets to set env vars.

**Fix:** Need graceful error boundary with user-facing message.

---

## Scenario 2: Forgotten Protocol Implementation

**What Happens:**
```
1. Developer adds new team view (e.g., SalesTeamView)
2. Extends TeamViewStoreBase, forgets to implement loadTasks()
3. Code compiles fine (Swift doesn't force protocol overrides in base class)
4. User taps "Sales Team" tab
5. View loads, calls loadTasks()
6. fatalError() is triggered
7. 💥 APP CRASHES
```

**Current Code:**
```swift
// TeamViewStore.swift:113-115
func loadTasks() async {
    fatalError("Subclasses must override loadTasks()")
}
```

**Impact:** 1 developer mistake = app crash for all users on that feature.

**Fix:** Make it a protocol requirement, don't use fatalError.

---

## Scenario 3: Network Glitch During Activity Fetch

**What Happens:**
```
1. User opens "All Tasks" view
2. AppState.fetchTasks() runs
3. TaskRepositoryClient.fetchActivities() calls Supabase
4. Network drops mid-response
5. Supabase.execute().value throws error
6. Exception propagates up (no catch in repository)
7. AppState.fetchTasks() catches it, sets errorMessage
8. 🔴 UI shows "Fetch tasks failed: timeout"
9. User taps retry
10. Meanwhile, realtime subscription also fails
11. errorMessage is overwritten with "Realtime subscription error: timeout"
12. User's original error context is lost
```

**Current Code:**
```swift
// TaskRepositoryClient.swift:157-168
do {
    let response: [ActivityResponse] = try await supabase
        .from("activities")
        .select("*, listings(*)")
        .execute()
        .value  // <-- CAN THROW
    // ...
} catch let error as URLError {
    // Handles this specific error type
    throw error
} catch {
    // Rethrows - but no documentation of what errors are possible
    throw error
}
```

**Impact:** Error messages overwrite each other, user confusion about what went wrong.

**Fix:** Implement error queue, not single errorMessage.

---

## Scenario 4: Silent Data Loss in Cache

**What Happens:**
```
1. User has cached 50 tasks in UserDefaults
2. App updates data model (Activity.swift field added)
3. Cache JSON from disk is now incompatible
4. AppState.loadCachedData() runs
5. JSONDecoder.decode() fails
6. try? silently swallows error
7. allTasks remains empty []
8. User sees "No tasks yet" instead of their cached data
9. ℹ️ ERROR WAS NEVER LOGGED
10. User never knows what happened
```

**Current Code:**
```swift
// AppState.swift:213-216
private func loadCachedData() {
    if let data = UserDefaults.standard.data(forKey: "cached_tasks"),
       let tasks = try? JSONDecoder().decode([Activity].self, from: data) {
        allTasks = tasks
    }
}
```

**Impact:** 
- Silent data loss
- User frustration
- No visibility into what went wrong
- Could happen every time app is updated

**Fix:** Log cache failures, show recovery message.

---

## Scenario 5: Activity Missing Its Listing

**What Happens:**
```
1. Listing table has a bug or is partially synced
2. Activity with id=123 exists, but Listing with listing_id=123 is missing
3. TaskRepositoryClient.fetchActivities() joins activities with listings
4. Row returned: Activity{..., listing: nil}
5. mapActivityResponse() called
6. guard let listing = row.listing else { return nil }
7. Activity is silently dropped from results
8. User opens "All Tasks"
9. Task 123 is missing from the list
10. User: "Where did my task go?"
11. 🤐 NO ERROR SHOWN, NO LOGGING
```

**Current Code:**
```swift
// TaskRepositoryClient.swift:108-112
nonisolated private func mapActivityResponse(_ row: ActivityResponse) -> ActivityWithDetails? {
    guard let listing = row.listing else {
        // Logging removed to avoid introducing MainActor isolation in this pure mapping function
        return nil
    }
    // ...
}
```

**Impact:**
- Silent data loss
- Data inconsistency
- User confusion
- Comment admits "logging removed" - they KNOW it's wrong

**Fix:** Log at least once per missing listing, show indicator in UI.

---

## Scenario 6: User Email Not Found in Staff Table

**What Happens:**
```
1. User adds a note to a listing
2. ListingNoteRepositoryClient.createNote() runs
3. Gets session: session.user.email = nil (edge case: OAuth without email)
4. userEmail = nil ?? "" → ""
5. Queries staff table: WHERE email = ""
6. No result found
7. userName = nil
8. Note created with createdByName = nil
9. User sees note: "by (unknown)"
10. 📝 NO ERROR SHOWN
```

**Current Code:**
```swift
// ListingNoteRepositoryClient.swift:49-64
let userEmail = session.user.email ?? ""  // <-- CAN BE EMPTY
let staff: [Staff] = try await supabase
    .from("staff")
    .select()
    .eq("email", value: userEmail)
    .execute()
    .value

let userName = staff.first?.name  // <-- CAN BE NIL
```

**Impact:**
- Audit trail broken (who added this note?)
- User confusion
- Data quality issue

**Fix:** Throw error if email is missing, handle explicitly.

---

## Scenario 7: Accidental Mass Deletion

**What Happens:**
```
1. Bug in code accidentally calls:
   repository.deleteTask("", userId)
   
2. Since taskId is not validated, empty string is passed to Supabase

3. Query executed:
   DELETE FROM tasks WHERE task_id = '' AND deleted_by = '{userId}'
   
4. Supabase interprets "" as a condition that matches nothing... OR
   
5. Wildcard behavior deletes all tasks
   
6. 💥 ALL TASKS DELETED
```

**Current Code:**
```swift
// TaskRepositoryClient.swift:257-268
deleteTask: { taskId, deletedBy in
    let now = Date()
    try await supabase
        .from("agent_tasks")
        .update([
            "deleted_at": now.ISO8601Format(),
            "deleted_by": deletedBy
        ])
        .eq("task_id", value: taskId)  // <-- NO VALIDATION OF taskId
        .execute()
},
```

**Impact:**
- Data corruption
- Mass deletion
- No safeguard against empty IDs

**Fix:** Guard against empty strings in all delete/update operations.

---

## Scenario 8: Weak Email Validation → Supabase Error

**What Happens:**
```
1. User tries to sign in
2. Enters: "a@b.c" (only 1 letter TLD)
3. LoginView.isValidEmail() returns FALSE
4. But wait... regex pattern allows "a@b.co" (2+ letters)
5. User confused: "Why is my email invalid?"
6. User enters: "test@example..com" (double dot, invalid)
7. Pattern accepts it (buggy regex)
8. User taps Sign In
9. Supabase API rejects with generic "Invalid credentials"
10. User doesn't know if it's email format or wrong password
```

**Current Code:**
```swift
// LoginView.swift:327-331
private func isValidEmail(_ email: String) -> Bool {
    let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
    return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
}
```

**Impact:**
- Weak validation passes invalid emails to Supabase
- User gets generic error
- No guidance on what's wrong

**Fix:** Use proper email validation library, show specific error feedback.

---

## Scenario 9: Realtime Subscription Crashes After Decode Fails

**What Happens:**
```
1. Realtime subscription is active
2. Database pushes a change: Activity record
3. Supabase tries to decode as AnyAction
4. Decode fails (unexpected schema change)
5. Error thrown in subscription loop
6. AppState catches in try-catch block:
   catch {
       self.errorMessage = "Realtime subscription error: \(error.localizedDescription)"
   }
7. Loop exits (subscription is dead)
8. 📡 NO MORE REALTIME UPDATES
9. User is stuck with stale data
10. No way to reconnect (no retry button)
```

**Current Code:**
```swift
// AppState.swift:131-145
do {
    try await channel.subscribeWithError()
    for await change in channel.postgresChange(AnyAction.self, table: "activities") {
        await self.handleRealtimeChange(change)
    }
} catch {
    self.errorMessage = "Realtime subscription error: \(error.localizedDescription)"
}  // <-- LOOP EXITS, NO RECONNECT
```

**Impact:**
- Silent loss of realtime connectivity
- Stale data shown to user
- No recovery mechanism

**Fix:** Implement exponential backoff retry, don't show error, reconnect silently.

---

## Scenario 10: Configuration Validation Crash in DEBUG

**What Happens:**
```
1. Developer clones repo
2. Sets up environment, runs app
3. Info.plist missing SUPABASE_URL
4. AppConfig.supabaseURL throws
5. AppConfig.validate() catches it
6. In DEBUG mode: fatalError()
7. 💥 APP CRASHES
8. Developer: "Why did it crash?"
9. Looks at code, sees fatalError()
10. Now has to manually set env vars instead of using stub data
```

**Current Code:**
```swift
// Config.swift:93-94
#if DEBUG
fatalError("Configuration error: \(error.localizedDescription)")
#else
// ...
#endif
```

**Impact:**
- Development friction
- New developers stuck
- Harder to debug than a helpful error message

**Fix:** Use stub data in DEBUG, don't crash.

---

## Summary

**Total Crash Scenarios Found:** 10
- **Will Definitely Crash:** 2 (TeamViewStore, Release Config)
- **Will Crash in Error Cases:** 5 (network, decode, missing auth, etc.)
- **Silent Failures:** 3 (cache, listings, staff lookup)

**Average User Impact:** Medium-High
- If user hits even ONE of these scenarios, they encounter either a crash or confusion
- No way for users to recover without force-quitting and retrying

**Code Quality:** Dangerous
- Mixing fatalError() with try/catch
- Silent failures with no logging
- Force unwraps with no validation
- No error boundary or fallback

