# Research Prompt: SourceKit-LSP Startup Failure with SwiftLens MCP Server

## Problem Statement

SourceKit-LSP is failing to start when invoked by SwiftLens MCP Server, with the error: **"SourceKit-LSP process died during startup"**. The process starts but immediately crashes with no stderr output, making debugging difficult.

## System Environment

- **OS**: macOS (darwin 25.0.0)
- **Xcode**: 26.1.1
- **Swift**: Apple Swift version 6.2.1 (swiftlang-6.2.1.4.8 clang-1700.4.4.1)
- **SourceKit-LSP Path**: `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp`
- **Python**: 3.13.9 (used for SwiftLens)
- **SwiftLens Version**: 0.2.14 (local installation at `/Users/noahdeskin/swiftlens`)

## Project Structure

- **Project Type**: Xcode project (`.xcodeproj`) with embedded Swift Package
- **Main Project**: `/Users/noahdeskin/conductor/operations-center/.conductor/minsk/apps/Operations Center/Operations Center.xcodeproj`
- **Swift Package**: `/Users/noahdeskin/conductor/operations-center/.conductor/minsk/apps/Operations Center/Packages/OperationsCenterKit/`
- **Package.swift**: Exists in OperationsCenterKit directory
- **Index Store**: Exists at both:
  - `.build/index/store` (Swift Package Manager index)
  - Xcode DerivedData index: `/Users/noahdeskin/Library/Developer/Xcode/DerivedData/Operations_Center-ahulgpyvnaelixadbzybypqrxwir/Index.noindex/DataStore`

## What We've Set Up

1. **SwiftLens MCP Server**: Configured and running via Python 3.13 virtual environment
2. **buildServer.json**: Created using `xcode-build-server` tool with configuration:
   ```json
   {
     "name": "xcode build server",
     "version": "0.2",
     "bspVersion": "2.0",
     "languages": ["c", "cpp", "objective-c", "objective-cpp", "swift"],
     "argv": ["/opt/homebrew/bin/xcode-build-server"],
     "indexStorePath": "/Users/noahdeskin/Library/Developer/Xcode/DerivedData/Operations_Center-ahulgpyvnaelixadbzybypqrxwir/Index.noindex/DataStore",
     "kind": "manual"
   }
   ```
3. **Compilation Database**: Created `.compile` file with build information parsed from xcodebuild logs
4. **SourceKit-LSP Config**: Created `.sourcekit-lsp/config.json` with compilation database search paths
5. **Xcode Build**: Successfully built the project to generate build logs and index store

## What We've Tried

1. ✅ Built Swift Package with index store: `swift build -Xswiftc -index-store-path -Xswiftc .build/index/store`
2. ✅ Built Xcode project: `xcodebuild -project "Operations Center.xcodeproj" -scheme "Operations Center" -destination 'generic/platform=iOS Simulator' build`
3. ✅ Configured xcode-build-server: `xcode-build-server parse -a <build_log>` to create buildServer.json
4. ✅ Created SourceKit-LSP config directory with compilation database search paths
5. ✅ Verified SourceKit-LSP binary exists and is accessible via `xcrun --find sourcekit-lsp`
6. ✅ Verified environment: `swift_check_environment` shows SourceKit-LSP is available

## Current Error Details

**Error Message**:
```
LSP client initialization failed. Manager error: Failed to create LSP client after 3 attempts: 
Failed to create LSP client for /Users/noahdeskin/conductor/operations-center/.conductor/minsk/apps/Operations Center/Packages/OperationsCenterKit: 
Failed to start SourceKit-LSP: SourceKit-LSP process died during startup. stderr: . 
Fallback error: Failed to start SourceKit-LSP: SourceKit-LSP process died during startup. stderr: .
```

**Key Observations**:
- Process starts but immediately dies
- No stderr output (empty stderr)
- Happens consistently on every attempt
- SwiftLens retries 3 times before giving up
- Error occurs when SwiftLens tries to initialize LSP client for the Swift Package directory

## What Works

- ✅ SwiftLens MCP server is running and responding
- ✅ Non-LSP tools work: `swift_get_file_imports`, `swift_validate_file`, `swift_search_pattern`
- ✅ Environment checks pass: SourceKit-LSP binary is found
- ✅ Xcode project builds successfully
- ✅ Index stores exist and contain data (150 units, 1992 records)

## What Doesn't Work

- ❌ All LSP-based semantic analysis tools fail:
  - `swift_get_symbols_overview`
  - `swift_find_symbol_references`
  - `swift_get_symbol_definition`
  - `swift_get_hover_info`
  - Any tool requiring SourceKit-LSP connection

## Research Questions

1. **Why does SourceKit-LSP crash immediately on startup when invoked by SwiftLens?**
   - Is there a known issue with SourceKit-LSP and Python subprocess invocation?
   - Are there required environment variables or working directory settings?
   - Does SourceKit-LSP need specific stdio handling that SwiftLens isn't providing?

2. **Is there a compatibility issue between:**
   - SwiftLens 0.2.14 and SourceKit-LSP from Xcode 26.1.1?
   - Python 3.13 and SourceKit-LSP?
   - The way SwiftLens spawns SourceKit-LSP vs. how other LSP clients do it?

3. **For Xcode projects with embedded Swift Packages:**
   - Should SourceKit-LSP be started from the Xcode project root or the Swift Package root?
   - Does SourceKit-LSP need the `buildServer.json` to be in a specific location?
   - Are there additional configuration files or environment variables needed?

4. **Known issues or workarounds:**
   - Are there GitHub issues in the SwiftLens or sourcekit-lsp repositories about this?
   - Are there environment variables that need to be set (e.g., `SOURCEKIT_LSP_INDEX_STORE_PATH`)?
   - Does SourceKit-LSP require specific command-line arguments for Xcode projects?

5. **Alternative approaches:**
   - Should we use a different LSP client library or approach?
   - Is there a way to enable verbose logging from SourceKit-LSP to see why it's crashing?
   - Can we test SourceKit-LSP independently to verify it works outside of SwiftLens?

## Additional Context

- SwiftLens uses `swiftlens-core` library (version >=0.1.9) which handles the LSP client connection
- The error originates from `swiftlens-core`'s LSP client manager
- SwiftLens is configured to use the virtual environment Python: `/Users/noahdeskin/swiftlens/venv/bin/python`
- The project is a mixed Xcode/Swift Package Manager setup (common in iOS development)

## Expected Outcome

Find the root cause and solution for why SourceKit-LSP crashes when started by SwiftLens, enabling full semantic analysis capabilities for the Swift codebase.

---

**Please research:**
1. SourceKit-LSP startup requirements and common failure modes
2. SwiftLens GitHub issues related to SourceKit-LSP crashes
3. Best practices for integrating SourceKit-LSP with Xcode projects
4. Known compatibility issues between SourceKit-LSP versions and LSP client libraries
5. Environment variables or configuration needed for SourceKit-LSP to work properly

