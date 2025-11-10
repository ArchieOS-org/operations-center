# Applications

This directory contains all client applications for Operations Center.

## Structure

```
apps/
├── operations-center-macos/    # macOS supervisor dashboard (Swift + SwiftUI)
├── operations-center-ios/      # iOS mobile app (future)
└── shared-ui/                  # Shared SwiftUI components
```

## macOS App (operations-center-macos)

### Features
- Real-time message classification monitoring
- Conversation history dashboard
- Manual classification override
- User management
- Analytics and reporting

### Tech Stack
- **Language:** Swift 6.0
- **UI Framework:** SwiftUI (macOS 14+)
- **Networking:** URLSession with swift-openapi-generator
- **Data Persistence:** SwiftData
- **Authentication:** AppAuth-iOS (OAuth 2.0 + PKCE)
- **Secure Storage:** KeychainAccess

### Project Management
- **XcodeGen** for project.yml management
- **SPM** for dependency management

### Getting Started

```bash
cd operations-center-macos

# Generate Xcode project
xcodegen

# Open in Xcode
open OperationsCenter.xcodeproj

# Or build from command line
xcodebuild -scheme OperationsCenter -configuration Debug
```

### Development

```bash
# Run tests
xcodebuild test -scheme OperationsCenter

# Or use swift-testing
swift test
```

## iOS App (operations-center-ios)

Coming soon. Will share code with macOS app via shared-ui/.

## Shared UI Components

Reusable SwiftUI views and design tokens shared across platforms.

See `shared-ui/README.md` for design system documentation.

## Deployment

- **macOS:** TestFlight → Mac App Store
- **iOS:** TestFlight → App Store (future)

See `../docs/deployment.md` for distribution details.
