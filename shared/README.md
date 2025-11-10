# Shared

This directory contains shared code, types, and utilities used across backend and frontend.

## Structure

```
shared/
├── types/              # Shared type definitions
│   ├── openapi.yaml    # OpenAPI spec (source of truth)
│   └── README.md       # Type generation docs
├── constants/          # Shared constants
└── docs/               # Shared documentation
```

## OpenAPI Specification

The `types/openapi.yaml` file is the **single source of truth** for API contracts between backend and frontend.

### Generating Client Code

**Python (Backend):**
```bash
cd shared/types
# Using openapi-python-client or similar
openapi-python-client generate --path openapi.yaml --output ../../backend/api-client
```

**Swift (Frontend):**
```bash
cd shared/types
# Using swift-openapi-generator
swift run swift-openapi-generator generate \
  --mode types \
  --mode client \
  --output-directory ../../apps/operations-center-macos/Sources/APIClient \
  openapi.yaml
```

### Workflow

1. Design API in `openapi.yaml`
2. Generate Python server stubs → implement in `backend/`
3. Generate Swift client code → use in `apps/`
4. Keep in sync with `scripts/sync-types.sh`

## Shared Constants

Platform-agnostic constants like:
- Classification message types
- Task keys and group keys
- Listing types
- API endpoints

## Benefits

- **Type safety:** Backend and frontend use identical types
- **Single source of truth:** API contract in one place
- **Auto-generated docs:** Swagger UI from OpenAPI spec
- **Reduced drift:** Changes propagate automatically

## Tools

- **OpenAPI Generator** - Multi-language client/server generation
- **swift-openapi-generator** - Swift type-safe client generation
- **Swagger UI** - Interactive API documentation

See `../docs/type-generation.md` for detailed guide.
