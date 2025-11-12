# Shared Python Utilities

This package contains shared Python utilities and helpers used across the Operations Center monorepo.

## Purpose

Provides common functionality for:
- **Backend API** (`apps/backend/api/`)
- **Future Python services** (workers, agents, etc.)
- **Scripts and tools** (`tools/scripts/`)

## Installation

### Development (Editable Mode)

From the monorepo root:
```bash
pip install -e libs/shared-utils
```

This is automatically done by `tools/scripts/setup.sh`.

### In Requirements Files

Add to your service's `requirements.txt`:
```txt
# Internal shared utilities (editable install)
-e ../../libs/shared-utils
```

## Package Structure

```
shared-utils/
├── pyproject.toml           # Package metadata and dependencies
├── src/
│   └── shared_utils/
│       ├── __init__.py      # Package initialization
│       └── py.typed         # Type checking marker
└── README.md
```

## Usage

```python
from shared_utils import some_utility

# Use shared functionality
```

## Adding New Utilities

1. Create a new module in `src/shared_utils/`:
   ```bash
   touch src/shared_utils/your_module.py
   ```

2. Export it in `__init__.py`:
   ```python
   from .your_module import your_function

   __all__ = ["your_function"]
   ```

3. The utility is now available across the monorepo:
   ```python
   from shared_utils import your_function
   ```

## Common Utilities to Add

Consider adding modules for:
- **Logging** - Structured logging configuration
- **Config** - Environment variable management
- **Database** - Supabase connection helpers
- **Authentication** - JWT token validation
- **Error Handling** - Custom exception classes
- **Validation** - Pydantic models for shared data structures
- **Constants** - Shared enums and constants

## Testing

```bash
cd libs/shared-utils
pytest tests/
```

## Type Checking

This package includes `py.typed` for PEP 561 compliance, enabling type checkers like mypy to validate usage:

```bash
mypy apps/backend/api/  # Will check shared_utils imports too
```

## Dependencies

- **Python 3.11+** required
- Dependencies defined in `pyproject.toml`
- Keep dependencies minimal - only add what's truly shared

## Best Practices

1. **Keep it generic** - Only code used by 2+ services belongs here
2. **Maintain backwards compatibility** - Breaking changes affect all services
3. **Document thoroughly** - Include docstrings and type hints
4. **Test comprehensively** - High test coverage required
5. **Version carefully** - Use semantic versioning (0.1.0 → 0.2.0 → 1.0.0)
