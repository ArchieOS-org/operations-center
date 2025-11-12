# GitHub Actions Quick Start

## Get Up and Running in 5 Minutes

### Step 1: Add Secrets to GitHub

Go to **Settings → Secrets and variables → Actions → New repository secret**:

```
VERCEL_TOKEN
VERCEL_ORG_ID
VERCEL_PROJECT_ID
```

**Get these values:**
```bash
# 1. Login to Vercel
vercel login

# 2. Create token
vercel token create

# 3. Link project and get IDs
cd apps/backend
vercel link
cat .vercel/project.json
```

### Step 2: Configure Vercel Environment Variables

Go to **Vercel Dashboard → Your Project → Settings → Environment Variables**:

```
SUPABASE_URL
SUPABASE_SERVICE_KEY
OPENAI_API_KEY
SLACK_BOT_TOKEN
SLACK_SIGNING_SECRET
```

### Step 3: Test Locally (Optional)

```bash
# Test Swift build
cd apps/operations-center
xcodebuild -scheme "Operations Center" \
  -destination 'platform=macOS' \
  build --quiet

# Test Python
cd apps/backend/api
python -m pytest
ruff check .
mypy .
```

### Step 4: Push and Watch

```bash
git add .github/workflows
git commit -m "Add comprehensive GitHub Actions workflows"
git push
```

Go to **Actions tab** in GitHub to watch workflows run.

---

## What Happens Next

### On Every Push to Main:
- ✅ Swift CI builds for iOS + macOS
- ✅ Python CI tests + lints backend
- ✅ Vercel deploys to production
- ✅ All quality gates enforced

### On Every Pull Request:
- ✅ Swift CI validates app changes
- ✅ Python CI validates backend changes
- ✅ Vercel creates preview deployment
- ✅ PR validation checks secrets/architecture
- ✅ Auto-comment with preview URLs

---

## Required Status Checks

Add these to **Settings → Branches → Branch protection rules** for `main`:

- [x] Swift CI / SwiftLint
- [x] Swift CI / Build and Test (iOS)
- [x] Swift CI / Build and Test (macOS)
- [x] Python Backend CI / Lint and Format
- [x] Python Backend CI / Type Checking
- [x] Python Backend CI / Test
- [x] PR Validation / Validate PR
- [x] PR Validation / Security Scan

---

## Troubleshooting

**Workflows not running?**
- Check path filters match your changes
- Verify workflows are enabled in Settings → Actions

**Secrets missing?**
- Double-check secret names (case-sensitive)
- Ensure secrets are set at repository level, not environment level

**Build failing?**
- Check Xcode version matches (`DEVELOPER_DIR`)
- Verify dependencies are in `requirements.txt`

---

## Next Steps

1. **Add status badges** to README.md
2. **Enable required status checks** for branch protection
3. **Review first workflow run** and iterate
4. **Set up notifications** for failed workflows

---

Simple. Fast. Perfect.
