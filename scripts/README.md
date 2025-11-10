# Scripts

This directory contains build, deployment, and maintenance scripts for the monorepo.

## Available Scripts

```
scripts/
├── setup.sh                # Initial setup for new developers
├── sync-types.sh           # Sync types from OpenAPI spec
├── test-all.sh             # Run all tests (backend + frontend)
├── lint-all.sh             # Run all linters
├── deploy-backend.sh       # Deploy backend to Vercel
├── deploy-frontend.sh      # Deploy macOS app to TestFlight
└── clean.sh                # Clean all build artifacts
```

## Usage

### Initial Setup
```bash
./scripts/setup.sh
```
Installs all dependencies for backend (Python) and frontend (Swift).

### Type Generation
```bash
./scripts/sync-types.sh
```
Generates Python and Swift types from `shared/types/openapi.yaml`.

### Testing
```bash
# Run all tests
./scripts/test-all.sh

# Run backend tests only
cd backend && pytest

# Run frontend tests only
cd apps/operations-center-macos && xcodebuild test -scheme OperationsCenter
```

### Linting
```bash
./scripts/lint-all.sh
```
Runs:
- `ruff` (Python)
- `mypy` (Python type checking)
- `swiftlint` (Swift)

### Deployment
```bash
# Deploy backend (requires Vercel CLI)
./scripts/deploy-backend.sh

# Deploy macOS app (requires Xcode and App Store Connect credentials)
./scripts/deploy-frontend.sh
```

### Cleanup
```bash
./scripts/clean.sh
```
Removes:
- Python `__pycache__/`, `.pytest_cache/`, `.mypy_cache/`
- Swift `.build/`, `DerivedData/`
- Generated Xcode projects

## Script Standards

- All scripts use `#!/usr/bin/env bash`
- Exit on error (`set -e`)
- Use colors for output (green = success, red = error)
- Print what they're doing
- Check prerequisites before running

## Adding New Scripts

1. Create script in `scripts/`
2. Make executable: `chmod +x scripts/your-script.sh`
3. Add to this README
4. Use consistent error handling and output

## CI/CD Integration

These scripts are used in GitHub Actions:
- `test-all.sh` runs on every PR
- `lint-all.sh` runs on every PR
- `deploy-backend.sh` runs on merge to main
- `deploy-frontend.sh` runs on release tags

See `.github/workflows/` for CI configuration.
