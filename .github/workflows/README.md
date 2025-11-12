# GitHub Actions Workflows

This directory contains GitHub Actions workflows for the Operations Center project. Each workflow follows Context7 best practices and the Steve Jobs philosophy: ruthlessly simple, one purpose, perfectly executed.

## Workflows

### 1. Swift CI (`swift-ci.yml`)

**Purpose:** Build and test multi-platform SwiftUI app (iOS + macOS + iPadOS)

**Triggers:**
- Push to `main` (Swift-related files only)
- Pull requests to `main` (Swift-related files only)

**Jobs:**
- **SwiftLint:** Enforce code style with zero warnings
- **Build and Test:** Matrix build across iOS Simulator and macOS
- **Code Quality:** Check for compiler warnings and build time compliance

**Key Features:**
- Uses `--quiet` flag on xcodebuild (prevents context flooding)
- Caches Swift Package Manager dependencies
- Matrix strategy for multi-platform coverage
- Path filters to avoid unnecessary runs

**Requirements:**
- macOS runner (macos-14)
- Xcode 16.1

---

### 2. Python Backend CI (`python-ci.yml`)

**Purpose:** Test, lint, and validate Python FastAPI intelligence layer

**Triggers:**
- Push to `main` (Python-related files only)
- Pull requests to `main` (Python-related files only)

**Jobs:**
- **Lint and Format:** Ruff linting and formatting checks
- **Type Check:** mypy static type analysis
- **Test:** pytest with coverage >80% enforcement
- **Agent Complexity:** Validate agent architecture and endpoint count

**Key Features:**
- Tests against Python 3.11 and 3.12
- Pip dependency caching
- Coverage threshold enforcement (80%)
- Architecture validation (5 endpoint limit)

**Requirements:**
- Ubuntu runner
- Python 3.11+

---

### 3. Vercel Deployment (`vercel-deploy.yml`)

**Purpose:** Deploy FastAPI intelligence layer to Vercel

**Triggers:**
- Push to `main` (backend files only) → Production
- Pull requests to `main` (backend files only) → Preview

**Jobs:**
- **Validate Environment:** Check required env vars reminder
- **Deploy Preview:** PR preview deployments with auto-comment
- **Deploy Production:** Production deployment with health check

**Key Features:**
- Separate preview and production environments
- Automatic PR comments with deployment URLs
- Health check verification post-deployment
- Environment variable validation reminder

**Requirements:**
- Vercel CLI
- `VERCEL_TOKEN` secret
- `VERCEL_ORG_ID` secret
- `VERCEL_PROJECT_ID` secret

---

### 4. PR Validation (`pr-validation.yml`)

**Purpose:** Comprehensive PR validation before merge

**Triggers:**
- Pull requests to `main` (all changes)

**Jobs:**
- **Validate PR:** Check for secrets, validate commits, check PR size, verify architecture
- **Security Scan:** Run safety checks on Python dependencies
- **All Checks Complete:** Final summary

**Key Features:**
- Detects potential secrets in diffs
- Validates commit message quality
- Warns on large PRs (>20 files or >1000 lines)
- Enforces architecture compliance (no CRUD in FastAPI)
- Reminds about trash/ archival for deletions

**Requirements:**
- Ubuntu runner

---

## Setup Instructions

### Required Secrets

Add these secrets to your GitHub repository settings:

#### Vercel Deployment
```
VERCEL_TOKEN          # Vercel authentication token
VERCEL_ORG_ID         # Your Vercel organization ID
VERCEL_PROJECT_ID     # Your Vercel project ID
```

### Required Environment Variables (Vercel Dashboard)

Configure these in your Vercel project dashboard:

```
SUPABASE_URL              # Supabase project URL
SUPABASE_SERVICE_KEY      # Supabase service role key
OPENAI_API_KEY            # OpenAI API key (or ANTHROPIC_API_KEY)
SLACK_BOT_TOKEN           # Slack bot token
SLACK_SIGNING_SECRET      # Slack signing secret
TWILIO_ACCOUNT_SID        # (Optional) Twilio account SID
TWILIO_AUTH_TOKEN         # (Optional) Twilio auth token
```

### Getting Vercel Secrets

1. **VERCEL_TOKEN:**
   ```bash
   vercel login
   vercel token create
   ```

2. **VERCEL_ORG_ID and VERCEL_PROJECT_ID:**
   ```bash
   cd apps/backend
   vercel link
   cat .vercel/project.json
   ```

---

## Workflow Design Principles

Following Context7 best practices and Operations Center architecture:

1. **Single Responsibility**
   - Each workflow has one clear purpose
   - Jobs are focused and composable

2. **Fast Feedback**
   - Path filters prevent unnecessary runs
   - Parallel jobs where independent
   - Caching for speed (SPM, pip)

3. **Matrix Strategy**
   - Swift: iOS Simulator + macOS
   - Python: Multiple Python versions

4. **Quality Gates**
   - SwiftLint: Zero warnings
   - Coverage: 80% minimum
   - Type checking: Strict mypy
   - Architecture: 5 endpoint limit

5. **Security First**
   - Secret detection in PRs
   - Security scanning (safety)
   - No credentials in code

6. **Architecture Enforcement**
   - No CRUD in FastAPI (intelligence only)
   - Trash/ archival for deletions
   - Agent complexity checks

---

## Workflow Status Badges

Add these to your README.md:

```markdown
![Swift CI](https://github.com/YOUR_USERNAME/operations-center/workflows/Swift%20CI/badge.svg)
![Python CI](https://github.com/YOUR_USERNAME/operations-center/workflows/Python%20Backend%20CI/badge.svg)
![Vercel](https://github.com/YOUR_USERNAME/operations-center/workflows/Vercel%20Deployment/badge.svg)
![PR Validation](https://github.com/YOUR_USERNAME/operations-center/workflows/PR%20Validation/badge.svg)
```

---

## Troubleshooting

### Swift CI Fails

**Xcode version mismatch:**
```yaml
# Update DEVELOPER_DIR in swift-ci.yml
env:
  DEVELOPER_DIR: /Applications/Xcode_YOUR_VERSION.app/Contents/Developer
```

**SwiftLint not found:**
- Workflow installs it automatically
- Ensure `.swiftlint.yml` exists in project root

### Python CI Fails

**Coverage below 80%:**
- Add more tests
- Review untested code paths

**mypy errors:**
- Fix type hints
- Update type stubs

### Vercel Deployment Fails

**Missing secrets:**
- Verify all secrets are set in GitHub Settings → Secrets
- Check Vercel environment variables in dashboard

**Health check fails:**
- Verify `/status` endpoint exists in `main.py`
- Check Vercel deployment logs

### PR Validation Fails

**Secrets detected:**
- Remove secrets from diff
- Use environment variables

**Large PR warning:**
- Break PR into smaller, focused changes
- Follow single responsibility principle

---

## Philosophy

**"Simple can be harder than complex: You have to work hard to get your thinking clean to make it simple."**

These workflows embody:
- **Subtraction:** Only what's necessary
- **Speed:** Fast feedback loops
- **Clarity:** Obvious purpose
- **Quality:** Zero compromise

Every workflow serves intelligence. Every check enforces simplicity. Every gate protects quality.

Delete complexity. Ship confidence.
