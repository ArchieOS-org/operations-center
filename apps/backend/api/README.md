# Backend Services

This directory contains all Python backend services for Operations Center.

## Structure

```
backend/
├── classifier/          # Message classification service (LangChain)
├── api/                 # API endpoints (FastAPI or Vercel Functions)
├── shared/              # Shared Python utilities
└── tests/               # Backend tests
```

## Getting Started

### Prerequisites
- Python 3.11+
- pip or uv (recommended)

### Installation

```bash
cd backend
pip install -r requirements.txt
```

### Development

```bash
# Run tests
pytest

# Run linter
ruff check .

# Run type checker
mypy .
```

## Recommended Services

### 1. Message Classifier (from migration)
The classification service uses LangChain for optimal structured output.

See: `../migration/python-langchain-optimal/` for implementation.

### 2. API Layer
FastAPI or Vercel Functions for webhooks and dashboard APIs.

### 3. Shared Utilities
Common code shared across services (auth, logging, etc.).

## Deployment

- **Vercel Serverless Functions** - For webhooks and APIs
- **Modal** - For long-running agents (if needed)
- **AWS Lambda** - Alternative for existing infrastructure

See `../docs/deployment.md` for details.
