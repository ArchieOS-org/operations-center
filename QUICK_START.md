# Quick Start Guide - CORRECTED

**Fixed version of the local development setup**

---

## ✅ Corrected Setup Instructions

### Step 1: Install Supabase CLI (CORRECT METHOD)

**DO NOT use `npm install -g supabase`** - it's not supported!

Use **Homebrew** instead:

```bash
# Install via Homebrew (macOS)
brew install supabase/tap/supabase

# Verify installation
supabase --version
```

### Step 2: Navigate to Correct Directory

```bash
# Use FULL path to workspace
cd /Users/noahdeskin/conductor/operations-center/.conductor/la-paz

# Verify you're in the right place
pwd
ls -la  # Should see backend/, migrations/, README*.md files
```

### Step 3: Initialize Supabase (if not already done)

```bash
# Initialize Supabase
supabase init

# This creates a supabase/ folder with:
# - config.toml
# - seed.sql (optional)
```

### Step 4: Start Supabase Local Services

```bash
# Start local Supabase (runs Docker containers)
supabase start

# Output will show connection details:
#   API URL: http://localhost:54321
#   DB URL: postgresql://postgres:postgres@localhost:54322/postgres
#   Studio URL: http://localhost:54323
#   anon key: eyJhbGci... (copy this)
#   service_role key: eyJhbGci... (copy this)
```

### Step 5: Configure Environment

```bash
# Create .env.local with the ACTUAL keys from supabase start output
cat > .env.local <<'EOF'
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=<paste anon key from supabase start>
SUPABASE_SERVICE_KEY=<paste service_role key from supabase start>
DATABASE_URL=postgresql://postgres:postgres@localhost:54322/postgres
EOF
```

### Step 6: Apply Migrations

```bash
# Copy migrations to Supabase folder
mkdir -p supabase/migrations
cp migrations/*.sql supabase/migrations/

# Apply all migrations
supabase db reset
```

### Step 7: Install Python Dependencies

```bash
# Already done! Your requirements.txt is already installed
# If you need to reinstall:
pip install -r requirements.txt
```

### Step 8: Start FastAPI Server

```bash
# Run with hot reload
uvicorn backend.main:app --reload --env-file .env.local

# Or run directly:
python -m backend.main
```

### Step 9: Test the API

```bash
# Open in browser
open http://localhost:8000/docs

# Or test with curl
curl http://localhost:8000/
curl http://localhost:8000/health
curl http://localhost:8000/v1/operations/status
```

---

## 🎯 What You Should See

### Terminal Output (Success):

```
🚀 Starting La-Paz API server...
✅ Database connection ready (Supabase)
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
INFO:     Started reloader process [12345] using WatchFiles
INFO:     Started server process [12346]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

### Browser (http://localhost:8000/docs):

You should see the **FastAPI Swagger UI** with:
- ✅ Root endpoint `/`
- ✅ Health check `/health`
- ✅ Operations status `/v1/operations/status`

### Supabase Studio (http://localhost:54323):

You should see all your database tables:
- ✅ `staff`
- ✅ `realtors`
- ✅ `listing_tasks`
- ✅ `stray_tasks`
- ✅ `slack_messages`
- ✅ `listings` (with new `realtor_id` column)

---

## 🔧 Troubleshooting

### "command not found: supabase"

**Fix:**
```bash
# Install via Homebrew
brew install supabase/tap/supabase

# Add to PATH if needed
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### "Error loading ASGI app. Could not import module backend.main"

**Fix:**
```bash
# Make sure you're in the correct directory
cd /Users/noahdeskin/conductor/operations-center/.conductor/la-paz

# Make sure backend/__init__.py exists
touch backend/__init__.py

# Try running from project root
python -m uvicorn backend.main:app --reload
```

### "Port already in use"

**Fix:**
```bash
# Stop Supabase
supabase stop

# Or kill the process
lsof -ti:8000 | xargs kill -9
lsof -ti:54321 | xargs kill -9
```

### "Connection refused" to database

**Fix:**
```bash
# Check if Supabase is running
supabase status

# If not running
supabase start

# If still issues, reset
supabase stop
supabase start
```

---

## ✅ Verification Checklist

- [ ] Supabase CLI installed (`supabase --version` works)
- [ ] In correct directory (`pwd` shows `.../la-paz`)
- [ ] Supabase initialized (`supabase/` folder exists)
- [ ] Supabase running (`supabase status` shows services)
- [ ] Migrations applied (`supabase db reset` completed)
- [ ] `.env.local` created with correct keys
- [ ] FastAPI server started (no import errors)
- [ ] Can access http://localhost:8000/docs
- [ ] Can access http://localhost:54323 (Supabase Studio)
- [ ] All tables visible in Supabase Studio

---

## 🚀 Next Steps After Setup

1. **Verify Database Tables:**
   ```bash
   # Open Supabase Studio
   open http://localhost:54323

   # Click "Table Editor"
   # You should see: staff, realtors, listing_tasks, stray_tasks, slack_messages
   ```

2. **Test API Endpoints:**
   ```bash
   # Test root endpoint
   curl http://localhost:8000/

   # Should return:
   # {"status":"ok","message":"La-Paz Operations Center API","version":"2.0.0","docs":"/docs"}
   ```

3. **Add Sample Data:**
   ```bash
   # Use Supabase Studio to insert test data
   # Or use SQL:
   supabase db connect

   INSERT INTO staff (staff_id, email, name, role, status)
   VALUES ('01HWQK0000ADMIN0000000000', 'admin@test.com', 'Admin User', 'admin', 'active');
   ```

4. **Start Developing:**
   - Create router files in `backend/routers/`
   - Use templates from `README_API.md`
   - Test endpoints at http://localhost:8000/docs

---

## 📚 Reference Documentation

- **Database Schema:** `README_DATABASE.md`
- **API Endpoints:** `README_API.md`
- **Migration Guide:** `README_MIGRATION.md`
- **Local Development:** `README_LOCAL_DEV.md`
- **Implementation Status:** `IMPLEMENTATION_STATUS.md`

---

## 💡 Pro Tips

1. **Keep Supabase Studio open** - Great for debugging database issues
2. **Use FastAPI docs** - http://localhost:8000/docs for testing endpoints
3. **Watch logs** - See FastAPI logs in terminal for errors
4. **Hot reload works** - Edit code, save, API auto-reloads
5. **Reset database anytime** - `supabase db reset` reapplies all migrations

---

## 🎉 You're Ready!

Your local environment is now set up correctly. Start building your API by:

1. Creating router files (see `README_API.md` for templates)
2. Completing database access layer (3 files remaining)
3. Testing with sample data
4. Deploying to Vercel when ready

**Happy coding!** 🚀
