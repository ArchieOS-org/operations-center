# La-Paz Operations Center - Deployment Guide

**Last Updated**: 2025-11-11
**Version**: 2.0.0

---

## Overview

This guide covers deploying the La-Paz Operations Center to production, including:
- Applying database migrations to Supabase production
- Deploying FastAPI backend to Vercel
- Verifying deployment and testing endpoints

---

## Prerequisites

### Required Tools

1. **Supabase CLI** (for database migrations)
   ```bash
   brew install supabase/tap/supabase
   supabase --version
   ```

2. **Vercel CLI** (for deployment)
   ```bash
   npm install -g vercel
   vercel --version
   ```

3. **Python 3.11+** with dependencies
   ```bash
   python --version
   pip install -r requirements.txt
   ```

### Required Credentials

1. **Supabase Production**:
   - Project URL (`SUPABASE_URL`)
   - Service Role Key (`SUPABASE_SERVICE_KEY`)
   - Database connection string

2. **Vercel**:
   - Account access
   - Project linked to GitHub repo (recommended)

---

## Step 1: Apply Migrations to Supabase Production

### Option A: Using Supabase Dashboard (Recommended for First Deploy)

1. **Login to Supabase Dashboard**
   - Go to https://app.supabase.com
   - Select your project: `la-paz`

2. **Navigate to SQL Editor**
   - Click "SQL Editor" in left sidebar
   - Click "+ New query"

3. **Apply Each Migration in Order**

   Run migrations in this exact order:

   #### Migration 1: Staff Table
   ```sql
   -- Copy content from migrations/004_create_staff_table.sql
   ```

   #### Migration 2: Realtors Table
   ```sql
   -- Copy content from migrations/005_create_realtors_table.sql
   ```

   #### Migration 3: Listing Tasks Table
   ```sql
   -- Copy content from migrations/006_create_listing_tasks_table.sql
   ```

   #### Migration 4: Stray Tasks Table
   ```sql
   -- Copy content from migrations/007_create_stray_tasks_table.sql
   ```

   #### Migration 5: Slack Messages Table
   ```sql
   -- Copy content from migrations/008_create_slack_messages_table.sql
   ```

   #### Migration 6: Update Listings Table
   ```sql
   -- Copy content from migrations/009_update_listings_table.sql
   ```

4. **Verify Tables Created**
   ```sql
   -- Check all tables exist
   SELECT table_name
   FROM information_schema.tables
   WHERE table_schema = 'public'
   AND table_name IN (
     'staff',
     'realtors',
     'listing_tasks',
     'stray_tasks',
     'slack_messages'
   );
   ```

   Expected output: 5 rows showing all table names.

### Option B: Using Supabase CLI (Advanced)

1. **Login to Supabase**
   ```bash
   supabase login
   ```

2. **Link to Production Project**
   ```bash
   supabase link --project-ref <your-project-id>
   ```

   Find your project ID in Supabase Dashboard under Settings > General.

3. **Push Migrations to Production**
   ```bash
   # Copy migrations to supabase/migrations folder
   cp migrations/*.sql supabase/migrations/

   # Push to production
   supabase db push --db-url "postgresql://[connection-string]"
   ```

   ⚠️ **Warning**: This will apply all migrations. Ensure you have a database backup first.

4. **Verify Migrations**
   ```bash
   supabase db diff
   ```

   Should show no differences if migrations applied successfully.

---

## Step 2: Configure Environment Variables

### Vercel Environment Variables

1. **Login to Vercel Dashboard**
   - Go to https://vercel.com
   - Select project: `la-paz`

2. **Navigate to Settings > Environment Variables**

3. **Add Required Variables**:

   ```bash
   # Supabase Configuration
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

   # OpenAI (for LangChain classifier)
   OPENAI_API_KEY=sk-...

   # Slack (optional)
   SLACK_BOT_TOKEN=xoxb-...
   SLACK_SIGNING_SECRET=...

   # Environment
   ENVIRONMENT=production
   ```

4. **Set Environment Scope**:
   - Production: ✅ Checked
   - Preview: ✅ Checked (optional)
   - Development: ❌ Unchecked

---

## Step 3: Deploy to Vercel

### Option A: Deploy via GitHub (Recommended)

1. **Push Code to GitHub**
   ```bash
   git add .
   git commit -m "feat: complete La-Paz v2.0 implementation with new routers"
   git push origin main
   ```

2. **Automatic Deployment**
   - Vercel will automatically detect the push
   - Build and deploy will start automatically
   - Monitor progress at https://vercel.com/your-org/la-paz

3. **Verify Deployment**
   - Wait for "Deployment Ready" status
   - Click "Visit" to open deployed site

### Option B: Deploy via Vercel CLI

1. **Login to Vercel**
   ```bash
   vercel login
   ```

2. **Deploy to Production**
   ```bash
   cd /Users/noahdeskin/conductor/operations-center/.conductor/la-paz
   vercel --prod
   ```

3. **Confirm Deployment Settings**
   - Framework Preset: `Other`
   - Build Command: (leave empty)
   - Output Directory: (leave empty)
   - Install Command: `pip install -r requirements.txt`

4. **Wait for Deployment**
   ```
   🔍 Inspecting code...
   ✅ Deployment complete!
   🚀 Production: https://la-paz.vercel.app
   ```

---

## Step 4: Verify Deployment

### 1. Health Check Endpoints

```bash
# Root endpoint
curl https://la-paz.vercel.app/

# Expected:
# {"status":"ok","message":"La-Paz Operations Center API","version":"2.0.0","docs":"/docs"}

# Health check
curl https://la-paz.vercel.app/health

# Expected:
# {"status":"healthy","database":"connected","timestamp":"..."}

# Operations status
curl https://la-paz.vercel.app/v1/operations/status

# Expected:
# {"staff_service":"operational","realtors_service":"operational",...}
```

### 2. API Documentation

Visit interactive API docs:
- **Swagger UI**: https://la-paz.vercel.app/docs
- **ReDoc**: https://la-paz.vercel.app/redoc

### 3. Test Staff Endpoint

```bash
# Create a test staff member
curl -X POST https://la-paz.vercel.app/v1/operations/staff/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@lapaz.com",
    "name": "Test User",
    "role": "operations",
    "status": "active"
  }'

# Expected: 201 Created with staff member data including auto-generated staff_id
```

### 4. Test Realtors Endpoint

```bash
# Create a test realtor
curl -X POST https://la-paz.vercel.app/v1/operations/realtors/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "agent@test.com",
    "name": "Test Agent",
    "license_number": "CA-12345",
    "status": "active"
  }'

# Expected: 201 Created with realtor data including auto-generated realtor_id
```

### 5. Test List Endpoints

```bash
# List all staff members
curl https://la-paz.vercel.app/v1/operations/staff/

# Expected: {"staff":[],"total":1,"limit":50,"offset":0}

# List all realtors
curl https://la-paz.vercel.app/v1/operations/realtors/

# Expected: {"realtors":[],"total":1,"limit":50,"offset":0}
```

---

## Step 5: Configure Row Level Security (RLS) Policies

### Important Security Step

After migrations are applied, you **must** configure RLS policies in Supabase to restrict data access.

1. **Navigate to Authentication > Policies** in Supabase Dashboard

2. **Create Policies for Each Table**:

   #### Staff Table Policies
   ```sql
   -- Enable RLS
   ALTER TABLE staff ENABLE ROW LEVEL SECURITY;

   -- Policy: Allow service role full access
   CREATE POLICY "Service role has full access" ON staff
   FOR ALL USING (auth.role() = 'service_role');

   -- Policy: Staff can view active staff
   CREATE POLICY "Staff can view active staff" ON staff
   FOR SELECT USING (deleted_at IS NULL);
   ```

   #### Realtors Table Policies
   ```sql
   -- Enable RLS
   ALTER TABLE realtors ENABLE ROW LEVEL SECURITY;

   -- Policy: Allow service role full access
   CREATE POLICY "Service role has full access" ON realtors
   FOR ALL USING (auth.role() = 'service_role');

   -- Policy: Realtors can view their own data
   CREATE POLICY "Realtors can view own data" ON realtors
   FOR SELECT USING (deleted_at IS NULL);
   ```

   #### Listing Tasks Table Policies
   ```sql
   -- Enable RLS
   ALTER TABLE listing_tasks ENABLE ROW LEVEL SECURITY;

   -- Policy: Allow service role full access
   CREATE POLICY "Service role has full access" ON listing_tasks
   FOR ALL USING (auth.role() = 'service_role');
   ```

   #### Stray Tasks Table Policies
   ```sql
   -- Enable RLS
   ALTER TABLE stray_tasks ENABLE ROW LEVEL SECURITY;

   -- Policy: Allow service role full access
   CREATE POLICY "Service role has full access" ON stray_tasks
   FOR ALL USING (auth.role() = 'service_role');
   ```

   #### Slack Messages Table Policies
   ```sql
   -- Enable RLS
   ALTER TABLE slack_messages ENABLE ROW LEVEL SECURITY;

   -- Policy: Allow service role full access
   CREATE POLICY "Service role has full access" ON slack_messages
   FOR ALL USING (auth.role() = 'service_role');
   ```

3. **Verify RLS is Enabled**
   ```sql
   SELECT tablename, rowsecurity
   FROM pg_tables
   WHERE schemaname = 'public'
   AND tablename IN ('staff', 'realtors', 'listing_tasks', 'stray_tasks', 'slack_messages');
   ```

   All should show `rowsecurity = true`.

---

## Troubleshooting

### Migration Errors

**Problem**: "relation already exists"
```
ERROR: relation "staff" already exists
```

**Solution**: Table already created. Skip this migration or use `DROP TABLE IF EXISTS` first.

---

**Problem**: "foreign key constraint violation"
```
ERROR: insert or update on table "listing_tasks" violates foreign key constraint
```

**Solution**: Ensure parent tables (listings, realtors, staff) exist before creating child tables.

---

### Deployment Errors

**Problem**: "Module not found: backend.routers.staff"
```
ModuleNotFoundError: No module named 'backend.routers.staff'
```

**Solution**:
1. Verify all router files exist in `backend/routers/`
2. Ensure `__init__.py` exists in each directory
3. Redeploy with `vercel --force`

---

**Problem**: "Supabase connection timeout"
```
HTTPException: 500 Internal Server Error - Database error: Connection timeout
```

**Solution**:
1. Verify `SUPABASE_URL` and `SUPABASE_SERVICE_KEY` in Vercel environment variables
2. Check Supabase project is active (not paused)
3. Verify database is reachable from Vercel's network

---

### API Errors

**Problem**: 404 Not Found on all endpoints
```
{"detail":"Not Found"}
```

**Solution**:
1. Check Vercel function logs for errors
2. Verify `vercel.json` routing configuration
3. Ensure `api/v1/*.py` files have `handler = app` export

---

**Problem**: 500 Internal Server Error
```
{"detail":"Internal Server Error"}
```

**Solution**:
1. Check Vercel function logs: `vercel logs`
2. Look for Python errors or missing dependencies
3. Verify all environment variables are set correctly

---

## Rollback Procedures

### Rollback Migrations

If migrations cause issues, rollback using:

```sql
-- Drop new tables (in reverse order)
DROP TABLE IF EXISTS slack_messages CASCADE;
DROP TABLE IF EXISTS stray_tasks CASCADE;
DROP TABLE IF EXISTS listing_tasks CASCADE;
DROP TABLE IF EXISTS realtors CASCADE;
DROP TABLE IF EXISTS staff CASCADE;

-- Remove realtor_id column from listings
ALTER TABLE listings DROP COLUMN IF EXISTS realtor_id;
```

⚠️ **Warning**: This will delete all data in these tables.

### Rollback Deployment

If deployment has critical issues:

```bash
# Via Vercel Dashboard
1. Go to Deployments
2. Find previous working deployment
3. Click "..." > "Promote to Production"

# Via Vercel CLI
vercel rollback
```

---

## Post-Deployment Checklist

- [ ] All 6 migrations applied successfully
- [ ] RLS policies configured for all tables
- [ ] Environment variables set in Vercel
- [ ] Deployment completed without errors
- [ ] Health check endpoints return 200 OK
- [ ] API documentation accessible at /docs
- [ ] Test staff creation endpoint works
- [ ] Test realtor creation endpoint works
- [ ] Test listing tasks endpoint works
- [ ] Test stray tasks endpoint works
- [ ] Test slack messages endpoint works
- [ ] Monitor Vercel logs for errors: `vercel logs --follow`
- [ ] Verify database connections in production
- [ ] Test Slack webhook integration (if configured)

---

## Monitoring

### Vercel Logs

```bash
# Real-time logs
vercel logs --follow

# Function-specific logs
vercel logs --follow api/v1/staff.py

# Error logs only
vercel logs --follow | grep ERROR
```

### Supabase Logs

1. Navigate to Supabase Dashboard > Logs
2. Select "Database" to see query logs
3. Select "API" to see API request logs

---

## Next Steps

After successful deployment:

1. ✅ Configure monitoring and alerting
2. ✅ Set up database backups (Supabase Pro)
3. ✅ Add custom domain to Vercel project
4. ✅ Configure CORS for production domains
5. ✅ Set up API rate limiting (if needed)
6. ✅ Document API endpoints for team
7. ✅ Create postman/insomnia collection
8. ✅ Set up CI/CD pipeline (if using GitHub Actions)

---

## Support

**Issues?** Check:
- Vercel deployment logs
- Supabase database logs
- Project documentation in README files

**Contact**:
- Internal team Slack channel
- GitHub issues (if using GitHub)
