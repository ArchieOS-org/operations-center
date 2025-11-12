# Generate Service

Create a new service layer template for API integration.

## Instructions

When this command is used with a service name:

1. **Create service file**
   - Location: `Packages/Services/Sources/Services/{ServiceName}.swift`
   - Follow service pattern template
   - Include proper error handling

2. **Add to Package.swift**
   - Update Services package dependencies if needed
   - Ensure proper target configuration

3. **Create protocol**
   - Define protocol for testability
   - Implement concrete type
   - Consider mock implementation

## Service Types

### Supabase Service
For direct database operations:
```swift
// Packages/Services/Sources/Services/SupabaseService.swift
import Foundation
import Supabase

public protocol SupabaseServiceProtocol {
    func fetch<T: Codable>(from table: String) async throws -> [T]
    func insert<T: Codable>(_ item: T, into table: String) async throws -> T
    func update<T: Codable>(_ item: T, in table: String, id: String) async throws -> T
    func delete(from table: String, id: String) async throws
    func subscribe<T: Codable>(to table: String) -> AsyncStream<T>
}

public actor SupabaseService: SupabaseServiceProtocol {
    private let client: SupabaseClient

    public init(url: URL, key: String) {
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key
        )
    }

    public func fetch<T: Codable>(from table: String) async throws -> [T] {
        try await client
            .from(table)
            .select()
            .execute()
            .value
    }

    public func insert<T: Codable>(_ item: T, into table: String) async throws -> T {
        try await client
            .from(table)
            .insert(item)
            .select()
            .single()
            .execute()
            .value
    }

    public func update<T: Codable>(_ item: T, in table: String, id: String) async throws -> T {
        try await client
            .from(table)
            .update(item)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
    }

    public func delete(from table: String, id: String) async throws {
        try await client
            .from(table)
            .delete()
            .eq("id", value: id)
            .execute()
    }

    public func subscribe<T: Codable>(to table: String) -> AsyncStream<T> {
        AsyncStream { continuation in
            Task {
                let channel = await client.realtimeV2.channel("public:\(table)")

                for await insertion in channel.postgresChange(InsertAction.self, table: table) {
                    do {
                        let record = try insertion.decodeRecord(as: T.self)
                        continuation.yield(record)
                    } catch {
                        print("Error decoding: \\(error)")
                    }
                }
            }
        }
    }
}
```

### Vercel Agent Service
For streaming AI operations:
```swift
// Packages/Services/Sources/Services/VercelAgentService.swift
import Foundation

public protocol VercelAgentServiceProtocol {
    func classify(message: String) async throws -> AsyncStream<ClassificationChunk>
    func chat(messages: [ChatMessage]) async throws -> AsyncStream<ChatChunk>
    func status() async throws -> AgentStatus
}

public actor VercelAgentService: VercelAgentServiceProtocol {
    private let baseURL: URL
    private let session: URLSession

    public init(baseURL: URL) {
        self.baseURL = baseURL
        self.session = URLSession.shared
    }

    public func classify(message: String) async throws -> AsyncStream<ClassificationChunk> {
        let endpoint = baseURL.appendingPathComponent("/classify")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["message": message]
        request.httpBody = try JSONEncoder().encode(body)

        return try await streamSSE(request: request)
    }

    public func chat(messages: [ChatMessage]) async throws -> AsyncStream<ChatChunk> {
        let endpoint = baseURL.appendingPathComponent("/chat")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["messages": messages]
        request.httpBody = try JSONEncoder().encode(body)

        return try await streamSSE(request: request)
    }

    public func status() async throws -> AgentStatus {
        let endpoint = baseURL.appendingPathComponent("/status")
        let (data, _) = try await session.data(from: endpoint)
        return try JSONDecoder().decode(AgentStatus.self, from: data)
    }

    private func streamSSE<T: Codable>(request: URLRequest) async throws -> AsyncStream<T> {
        AsyncStream { continuation in
            Task {
                let (bytes, _) = try await session.bytes(for: request)

                var buffer = ""
                for try await byte in bytes {
                    let char = Character(UnicodeScalar(byte))
                    buffer.append(char)

                    if buffer.hasSuffix("\\n\\n") {
                        if let data = buffer
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .replacingOccurrences(of: "data: ", with: "")
                            .data(using: .utf8),
                           let chunk = try? JSONDecoder().decode(T.self, from: data) {
                            continuation.yield(chunk)
                        }
                        buffer = ""
                    }
                }
                continuation.finish()
            }
        }
    }
}

public struct ClassificationChunk: Codable {
    public let type: String
    public let confidence: Double?
    public let category: String?
}

public struct ChatChunk: Codable {
    public let content: String
    public let role: String?
}

public struct ChatMessage: Codable {
    public let role: String
    public let content: String
}

public struct AgentStatus: Codable {
    public let status: String
    public let version: String?
}
```

## Error Handling Pattern

```swift
public enum ServiceError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case notFound
    case unauthorized
}
```

## Usage Example

```swift
// In ViewModel
@MainActor
class TaskListViewModel: ObservableObject {
    @Published var tasks: [ListingTask] = []

    private let supabase: SupabaseServiceProtocol

    init(supabase: SupabaseServiceProtocol) {
        self.supabase = supabase
    }

    func loadTasks() async {
        do {
            tasks = try await supabase.fetch(from: "listing_tasks")
        } catch {
            print("Error loading tasks: \\(error)")
        }
    }
}
```

## Checklist

- [ ] Service protocol defined
- [ ] Concrete implementation created
- [ ] Error handling included
- [ ] Async/await patterns used
- [ ] Actor isolation if needed
- [ ] File in Packages/Services/
- [ ] Added to Package.swift
- [ ] Documentation comments
- [ ] Example usage provided
