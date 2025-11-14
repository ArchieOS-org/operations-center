# COMPREHENSIVE iOS WHITE SCREEN DEBUG RESEARCH REQUEST

## CRITICAL ISSUE SUMMARY
**Symptom**: iOS app displays white screen on physical iPhone and gets killed by iOS watchdog after ~20 seconds
**Xcode Output**: "Attaching to operation center on Noah's iPhone" followed by "Message from debugger: killed"
**Root Cause Evidence**: 33 failed WebSocket connection attempts to non-existent preview URL before watchdog timeout

---

## COMPLETE ERROR LOG FROM DEVICE (248 lines)

```
Failed to send CA Event for app launch measurements for ca_event_type: 0 event_name: com.apple.app_launch_measurement.FirstFramePresentationMetric
Initial session emitted after attempting to refresh the local stored session.
This is incorrect behavior and will be fixed in the next major release since it's a breaking change.
To opt-in to the new behavior now, set `emitLocalSessionAsInitialSession: true` in your AuthClient configuration.
The new behavior ensures that the locally stored session is always emitted, regardless of its validity or expiration.
If you rely on the initial session to opt users in, you need to add an additional check for `session.isExpired` in the session.

Check https://github.com/supabase/supabase-swift/pull/822 for more information.
Initial session emitted after attempting to refresh the local stored session.
This is incorrect behavior and will be fixed in the next major release since it's a breaking change.
To opt-in to the new behavior now, set `emitLocalSessionAsInitialSession: true` in your AuthClient configuration.
The new behavior ensures that the locally stored session is always emitted, regardless of its validity or expiration.
If you rely on the initial session to opt users in, you need to add an additional check for `session.isExpired` in the session.

Check https://github.com/supabase/supabase-swift/pull/822 for more information.
Failed to send CA Event for app launch measurements for ca_event_type: 1 event_name: com.apple.app_launch_measurement.ExtendedLaunchMetrics
Connection 1: received failure notification
Connection 1: failed to connect 12:8, reason -1
Connection 1: encountered error(12:8)
Task <6D233C43-FB54-43AF-B045-481005150516>.<1> HTTP load failed, 0/0 bytes (error code: -1003 [12:8])
Task <6D233C43-FB54-43AF-B045-481005150516>.<1> finished with error [-1003] Error Domain=NSURLErrorDomain Code=-1003 "A server with the specified hostname could not be found." UserInfo={NSErrorFailingURLStringKey=https://preview.supabase.co/realtime/v1/websocket?apikey=preview-anon-key&vsn=1.0.0, NSErrorFailingURLKey=https://preview.supabase.co/realtime/v1/websocket?apikey=preview-anon-key&vsn=1.0.0, _NSURLErrorRelatedURLSessionTaskErrorKey=(
    "LocalWebSocketTask <6D233C43-FB54-43AF-B045-481005150516>.<1>"
), _NSURLErrorFailingURLSessionTaskErrorKey=LocalWebSocketTask <6D233C43-FB54-43AF-B045-481005150516>.<1>, NSLocalizedDescription=A server with the specified hostname could not be found.}

[... 31 MORE IDENTICAL WEBSOCKET CONNECTION FAILURES TO https://preview.supabase.co/realtime/v1/websocket ...]

Connection 33: received failure notification
Connection 33: failed to connect 12:8, reason -1
Connection 33: encountered error(12:8)
Task <BA82C23F-3B8C-4AA9-A6AF-AA5B7EB3A1B5>.<1> HTTP load failed, 0/0 bytes (error code: -1003 [12:8])
Task <BA82C23F-3B8C-4AA9-A6AF-AA5B7EB3A1B5>.<1> finished with error [-1003] Error Domain=NSURLErrorDomain Code=-1003 "A server with the specified hostname could not be found." UserInfo={NSErrorFailingURLStringKey=https://preview.supabase.co/realtime/v1/websocket?apikey=preview-anon-key&vsn=1.0.0, NSErrorFailingURLKey=https://preview.supabase.co/realtime/v1/websocket?apikey=preview-anon-key&vsn=1.0.0, _NSURLErrorRelatedURLSessionTaskErrorKey=(
    "LocalWebSocketTask <BA82C23F-3B8C-4AA9-A6AF-AA5B7EB3A1B5>.<1>"
), _NSURLErrorFailingURLSessionTaskErrorKey=LocalWebSocketTask <BA82C23F-3B8C-4AA9-A6AF-AA5B7EB3A1B5>.<1>, NSLocalizedDescription=A server with the specified hostname could not be found.}
Message from debugger: killed
```

**KEY OBSERVATION**: App attempts to connect to `https://preview.supabase.co` (a fake URL for previews) instead of production Supabase URL `https://kukmshbkzlskyuacgzbo.supabase.co`

---

## TECHNICAL ENVIRONMENT

- **macOS Version**: 26.0.1 (Build 25A362)
- **Xcode Version**: 26.1.1 (Build 17B100)
- **Swift Version**: 6.1
- **iOS Deployment Target**: iOS 18.5+
- **Physical Device**: iPhone (Noah's iPhone)
- **Device iOS Version**: iOS 26.1 (inferred from simulator list)
- **Simulator OS**: iOS 26.1 available

### Key Frameworks & Dependencies:
- **Supabase Swift SDK**: Latest version
- **swift-dependencies** (PointFree): For dependency injection
- **SwiftUI**: Primary UI framework
- **@Observable macro**: Swift 6 observation
- **@MainActor**: All AppState operations on main thread

---

## COMPLETE APP ARCHITECTURE

### App Entry Point: `Operations_CenterApp.swift`
```swift
import SwiftUI
import Dependencies
import OperationsCenterKit

@main
struct Operations_CenterApp: App {
    @Dependency(\.appState) private var appState

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
    }
}
```

**CRITICAL ISSUE**: Using `@Dependency` inside `@main` struct violates swift-dependencies best practices. The `@Dependency` property wrapper triggers initialization at app launch, creating AppState synchronously.

### Root View: `RootView.swift`
```swift
struct RootView: View {
    @Environment(AppState.self) private var appState
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                // Navigation structure...
            }
            .navigationTitle("Operations Center")
            .navigationDestination(for: Route.self) { route in
                destinationView(for: route)
            }
        }
        .task {
            // Start async operations after app launches
            await appState.startup()
        }
    }
}
```

**KEY EXECUTION PATH**:
1. App launches → Operations_CenterApp body evaluates
2. `@Dependency(\.appState)` accessed → Creates AppState
3. AppState.init() runs SYNCHRONOUSLY
4. RootView renders
5. `.task { await appState.startup() }` fires ASYNCHRONOUSLY

### App State: `AppState.swift` (COMPLETE FILE - 256 LINES)

```swift
import Foundation
import Supabase
import Dependencies
import OperationsCenterKit

@Observable
@MainActor
final class AppState {
    // MARK: - State

    var allTasks: [ListingTask] = []
    var currentUser: User?
    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    @ObservationIgnored
    @Dependency(\.supabaseClient) var supabaseClient

    @ObservationIgnored
    @Dependency(\.taskRepository) var taskRepository

    @ObservationIgnored
    private var realtimeSubscription: Task<Void, Never>?

    @ObservationIgnored
    private var authStateTask: Task<Void, Never>?

    /// Skip network operations in preview/test mode
    @ObservationIgnored
    private var shouldPerformNetworkOperations: Bool {
        AppConfig.Environment.current != .preview
    }

    // MARK: - Initialization

    init() {
        // Load cached data immediately for instant UI
        loadCachedData()
        // Network work deferred to startup() - called after app launches
    }

    // MARK: - Startup

    /// Start async operations after app launch
    /// Call this from .task modifier in RootView
    func startup() async {
        guard shouldPerformNetworkOperations else {
            print("⚠️ Preview mode: Skipping network operations")
            loadPreviewData()
            return
        }

        await setupAuthStateListener()
        await fetchTasks()
        await setupPermanentRealtimeSync()
    }

    deinit {
        realtimeSubscription?.cancel()
        authStateTask?.cancel()
    }

    // MARK: - Authentication

    private func setupAuthStateListener() async {
        guard shouldPerformNetworkOperations else { return }

        // Listen for auth state changes
        authStateTask = Task {
            for await state in supabaseClient.auth.authStateChanges {
                if [.initialSession, .signedIn, .signedOut].contains(state.event) {
                    currentUser = state.session?.user

                    // Refresh tasks when auth state changes
                    if state.session != nil {
                        await fetchTasks()
                    }
                }
            }
        }
    }

    // MARK: - Real-time Sync

    private func setupPermanentRealtimeSync() async {
        guard shouldPerformNetworkOperations else { return }

        // Cancel any existing subscription
        realtimeSubscription?.cancel()

        let channel = supabaseClient.realtimeV2.channel("all_tasks")

        realtimeSubscription = Task {
            do {
                // Setup listener BEFORE subscribing
                let listenerTask = Task {
                    for await change in channel.postgresChange(AnyAction.self, table: "listing_tasks") {
                        await handleRealtimeChange(change)
                    }
                }

                // Now subscribe to start receiving events
                try await channel.subscribeWithError()

                // Keep listener running
                await listenerTask.value
            } catch {
                await MainActor.run {
                    errorMessage = "Realtime subscription error: \(error.localizedDescription)"
                }
            }
        }
    }

    // ... rest of AppState implementation
}
```

---

## DEPENDENCY INJECTION ARCHITECTURE

### Config.swift (RECENTLY MODIFIED)

```swift
enum AppConfig {
    enum Environment {
        case production
        case local
        case preview

        static var current: Environment {
            // Always return production for real implementations
            // swift-dependencies handles preview mode automatically
            return .production
        }
    }

    static var supabaseURL: URL {
        // Production URL - swift-dependencies handles preview mode
        return URL(string: "https://kukmshbkzlskyuacgzbo.supabase.co")!
    }

    static var supabaseAnonKey: String {
        // Production key - swift-dependencies handles preview mode
        return "sb_publishable_lMBva69x9lCLnWU2fNDB9g_ZY-McsO9"
    }
}
```

### SupabaseClient+Dependency.swift (RECENTLY MODIFIED)

```swift
private enum SupabaseClientKey: DependencyKey {
    static var liveValue: SupabaseClient {
        // ALWAYS return real implementation
        // swift-dependencies automatically uses previewValue in previews
        return SupabaseClient(
            supabaseURL: URL(string: "https://kukmshbkzlskyuacgzbo.supabase.co")!,
            supabaseKey: "sb_publishable_lMBva69x9lCLnWU2fNDB9g_ZY-McsO9",
            options: SupabaseClientOptions(
                db: .init(schema: "public"),
                auth: .init(
                    flowType: .pkce,
                    emitLocalSessionAsInitialSession: true
                ),
                global: .init(
                    headers: ["x-client-info": "operations-center-ios/1.0.0"]
                )
            )
        )
    }

    static let previewValue: SupabaseClient = {
        SupabaseClient(
            supabaseURL: URL(string: "https://preview.supabase.co")!,
            supabaseKey: "preview-anon-key"
        )
    }()
}

extension SupabaseClient: @retroactive TestDependencyKey {
    public static let testValue: SupabaseClient = SupabaseClientKey.testValue
    public static let previewValue: SupabaseClient = SupabaseClientKey.previewValue
}

extension DependencyValues {
    var supabaseClient: SupabaseClient {
        get { self[SupabaseClientKey.self] }
        set { self[SupabaseClientKey.self] = newValue }
    }
}
```

### AppState+Dependency.swift (RECENTLY MODIFIED)

```swift
private enum AppStateKey: DependencyKey {
    static var liveValue: AppState {
        // ALWAYS return real implementation
        // swift-dependencies automatically uses previewValue in previews
        return AppState()
    }

    static let previewValue: AppState = {
        withDependencies {
            $0.supabaseClient = .previewValue
            $0.context = .preview
        } operation: {
            AppState()
        }
    }()

    static let testValue = AppState()
}

extension DependencyValues {
    var appState: AppState {
        get { self[AppStateKey.self] }
        set { self[AppStateKey.self] = newValue }
    }
}
```

---

## TROUBLESHOOTING HISTORY (CHRONOLOGICAL)

### Attempt 1: Xcode Derived Data Cache
**Action**: Cleared derived data with `rm -rf ~/Library/Developer/Xcode/DerivedData/*`
**Error**: "invalid reuse after initialization failure"
**Result**: Build error resolved, but white screen persisted

### Attempt 2: Identified Preview Mode Bug
**Discovery**: App was connecting to `https://preview.supabase.co` on physical device
**Root Cause**: All `liveValue` implementations were checking `#if DEBUG` and returning `previewValue`
**Code Before**:
```swift
static var liveValue: SupabaseClient {
    if AppConfig.Environment.current == .preview {
        return previewValue  // 🔴 VIOLATED swift-dependencies pattern
    }
    // ... real implementation
}
```

### Attempt 3: Fixed Dependency Pattern (LATEST)
**Action**: Modified 3 dependency files to follow swift-dependencies pattern
**Files Changed**:
- `SupabaseClient+Dependency.swift`
- `TaskRepositoryClient.swift`
- `AppState+Dependency.swift`

**Code After**:
```swift
static var liveValue: SupabaseClient {
    // ALWAYS return real implementation
    // swift-dependencies automatically uses previewValue in previews
    return SupabaseClient(/* production config */)
}
```

**Also Modified**: `Config.swift` to always return `.production`

**Build Status**: Not yet built and tested on device (build command had wrong simulator version)

---

## CURRENT HYPOTHESIS

### Theory 1: @Dependency in @main Struct (MOST LIKELY)
**Issue**: Using `@Dependency(\.appState)` directly in the `@main` struct causes synchronous initialization at app launch.

**Evidence**:
- swift-dependencies docs recommend against property wrappers in app entry points
- AppState.init() is called BEFORE window renders
- AppState.init() accesses `@Dependency(\.supabaseClient)` which may trigger early evaluation
- Physical device has stricter timing than simulator

**Expected Behavior**:
- App struct should NOT hold dependencies
- Dependencies should be injected AFTER app launches
- Use `.environment()` with manually constructed objects

**Proposed Fix**:
```swift
@main
struct Operations_CenterApp: App {
    // Remove @Dependency - construct manually
    private let appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
    }
}
```

### Theory 2: Supabase Auth Listener Blocking Main Thread
**Issue**: `setupAuthStateListener()` in `startup()` uses `for await` loop that may block

**Evidence**:
```swift
authStateTask = Task {
    for await state in supabaseClient.auth.authStateChanges {
        // This async stream may not yield immediately
        currentUser = state.session?.user
        if state.session != nil {
            await fetchTasks()  // More async work
        }
    }
}
```

**Problem**: If `authStateChanges` stream doesn't emit initial value, the Task hangs
**iOS Watchdog**: Kills app if main thread blocked >20 seconds during launch

**Proposed Fix**: Make listener truly non-blocking:
```swift
authStateTask = Task.detached {
    for await state in supabaseClient.auth.authStateChanges {
        await MainActor.run {
            currentUser = state.session?.user
        }
    }
}
```

### Theory 3: Lazy Dependency Evaluation
**Issue**: AppState uses eager `@Dependency` properties that evaluate at init time

**Evidence**:
```swift
@ObservationIgnored
@Dependency(\.supabaseClient) var supabaseClient  // Evaluated at init()
```

**Problem**: If AppState.init() is called before dependency context is established, may get preview values

**Proposed Fix**: Lazy evaluation:
```swift
@ObservationIgnored
private var _supabaseClient: SupabaseClient?

var supabaseClient: SupabaseClient {
    if _supabaseClient == nil {
        @Dependency(\.supabaseClient) var client
        _supabaseClient = client
    }
    return _supabaseClient!
}
```

### Theory 4: Supabase SDK Initialization Blocking
**Issue**: SupabaseClient initialization with `emitLocalSessionAsInitialSession: true` may block

**Evidence from logs**:
```
Initial session emitted after attempting to refresh the local stored session.
This is incorrect behavior and will be fixed in the next major release
```

**Problem**: Supabase SDK attempting to restore session synchronously at init

**Proposed Fix**: Defer auth init until after app launches:
```swift
options: SupabaseClientOptions(
    auth: .init(
        flowType: .pkce,
        // Remove this - defer session restore
        // emitLocalSessionAsInitialSession: true
    )
)
```

---

## SPECIFIC QUESTIONS FOR RESEARCH

1. **swift-dependencies Best Practices**: What is the authoritative pattern for injecting dependencies into SwiftUI `@main` app structs? Should `@Dependency` EVER be used in the app entry point?

2. **iOS Watchdog Timeout**: What are the EXACT time limits for app launch phases? How does iOS measure "time to first frame" vs "time to interactive"?

3. **Supabase Swift SDK**:
   - Does `SupabaseClient` initialization perform any network calls?
   - Does `emitLocalSessionAsInitialSession: true` cause synchronous blocking?
   - Can `auth.authStateChanges` stream hang indefinitely?
   - What's the recommended initialization pattern for iOS apps?

4. **swift-dependencies Context**: When is the dependency context established? At what point in the SwiftUI lifecycle does swift-dependencies know it's NOT in a preview?

5. **@Observable + @Dependency Interaction**: Are there known issues with using `@Dependency` inside `@Observable` classes in Swift 6?

6. **Xcode 26.1.1 / iOS 26.1**: Are there any known breaking changes in these versions related to:
   - App launch lifecycle
   - Dependency injection timing
   - WebSocket initialization
   - SwiftUI scene initialization

---

## REQUESTED RESEARCH OUTPUT

### 1. Diagnostic Hypotheses (Ranked)
Provide top 5 most likely root causes based on:
- The error pattern (33 WebSocket failures → watchdog kill)
- swift-dependencies architecture
- iOS app launch lifecycle
- Supabase SDK behavior
- Code patterns shown above

### 2. Specific Code Fixes
For each hypothesis, provide:
- EXACT code to change (with file names)
- Complete code snippet (before/after)
- Explanation of WHY this fixes the issue
- Risk assessment (what could break)

### 3. Debugging Instrumentation
Provide logging/instrumentation code to add at:
- App launch entry point
- Dependency initialization
- Each async boundary
- Supabase client init
- Auth listener setup
- Realtime subscription setup

### 4. Step-by-Step Investigation Plan
1-10 numbered steps with:
- What to check
- What tool to use (Xcode debugger, Instruments, Console.app)
- What to look for
- How to interpret results

### 5. Authoritative Sources
Citations to:
- Apple Developer documentation (WWDC sessions, guides)
- PointFree swift-dependencies docs
- Supabase Swift SDK documentation
- Known issues in iOS 26.1 / Xcode 26.1.1
- Stack Overflow / GitHub issues matching this pattern

### 6. Quick Win Diagnostics
What is the FASTEST way to determine:
- If dependencies are using preview vs live values?
- If app is hanging in a specific async function?
- If Supabase client initialization is the blocker?
- If the @main struct dependency is the problem?

---

## ADDITIONAL CONTEXT

### Git Commit History (Last 10)
```
77b7ba5 Fix iOS white screen issue on physical device
736f097 Your commit message
fe5ea26 Add listing card UI with context menu and enhanced model
0271756 Reorganize OperationsCenterKit to follow Swift package best practices
adc33f3 Reorganize Swift codebase to feature-based architecture
9783dae Switch Context7 MCP to remote HTTP server
69757c0 Add Context7 MCP server configuration
50e9afb Fix Slack message intake data flow
e6a3eaf Add entity creation pipeline: classification → database
8ed3da3 Lock in Steve Jobs persona for Operations Center
```

### What Works:
- ✅ App builds successfully
- ✅ App runs in Simulator (not yet tested after latest changes)
- ✅ All type checking passes
- ✅ SwiftUI previews work (preview mode correctly shows mock data)

### What Fails:
- ❌ App freezes with white screen on physical iPhone
- ❌ 33 WebSocket connection attempts to preview URL
- ❌ iOS watchdog kills app after ~20 seconds
- ❌ No console output after "Attaching to operation center"

### Device-Specific Observations:
- Physical device shows the issue
- Simulator does NOT show the issue (but hasn't been tested with latest changes)
- Error log shows attempts to connect to preview URL on physical device
- This suggests dependency context detection failing on device

---

## FINAL NOTE TO RESEARCH AGENT

You have COMPLETE information about:
- The codebase architecture
- The error symptoms
- The dependency injection pattern
- The frameworks being used
- What we've already tried
- The current code state

Your job: Provide ACTIONABLE, SPECIFIC, CODE-LEVEL fixes ranked by likelihood of success. Don't speculate - cite sources. Don't hedge - make clear recommendations. This is a production blocker affecting real users.

If you need to make assumptions, STATE THEM EXPLICITLY and explain the reasoning.

Focus on: swift-dependencies context detection, iOS app launch lifecycle, Supabase SDK initialization timing, and @main struct dependency injection anti-patterns.

Thank you.
