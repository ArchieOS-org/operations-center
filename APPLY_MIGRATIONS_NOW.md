# Apply Database Migrations - Quick Guide

**The Supabase CLI is having connection issues. Use the Dashboard instead (5 minutes).**

---

## Step 1: Open Supabase Dashboard

1. Go to: **https://app.supabase.com/project/kukmshbkzlskyuacgzbo**
2. Click **"SQL Editor"** in the left sidebar
3. Click **"+ New query"** button

---

## Step 2: Copy & Paste Migration SQL

Copy the entire contents of `APPLY_MIGRATIONS.sql` file and paste into the SQL editor.

**File location**: `/Users/noahdeskin/conductor/operations-center/.conductor/la-paz/APPLY_MIGRATIONS.sql`

Or run this command to view the file:
```bash
cat APPLY_MIGRATIONS.sql
```

---

## Step 3: Run the Migration

1. Click the **"Run"** button (or press Cmd/Ctrl + Enter)
2. Wait for execution to complete (~5-10 seconds)
3. Check for **"Success"** message

---

## Step 4: Verify Tables Created

Run this query in a new SQL Editor tab:

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN (
    'staff',
    'realtors',
    'listings',
    'listing_tasks',
    'stray_tasks',
    'slack_messages'
)
ORDER BY table_name;
```

**Expected output**: 6 rows showing all table names.

---

## Step 5: Deploy to Vercel

Once migrations are applied, deploy the backend:

```bash
# Commit the migrations
git add .
git commit -m "feat: Add database migrations for staff/realtor separation"
git push origin python-api-endpoints

# Deploy to Vercel (triggers auto-deploy)
# Or manually: vercel --prod
```

---

## Troubleshooting

**Issue**: "relation already exists"
**Solution**: Table already created, this is OK. Continue.

**Issue**: "foreign key constraint violation"
**Solution**: Ensure you ran the entire `APPLY_MIGRATIONS.sql` file (not just part of it).

**Issue**: "column does not exist"
**Solution**: Listings table might need to be created first. Check if listings table exists:
```sql
SELECT * FROM information_schema.tables WHERE table_name = 'listings';
```

---

## What This Migration Does

✅ Creates `staff` table (internal team members)
✅ Creates `realtors` table (external agents)
✅ Creates `listings` table (if doesn't exist)
✅ Creates `listing_tasks` table (property-specific tasks)
✅ Creates `stray_tasks` table (realtor-specific tasks)
✅ Creates `slack_messages` table (message tracking)
✅ Adds `realtor_id` column to listings table
✅ Creates all indexes for performance
✅ Sets up auto-update triggers for timestamps
✅ Adds foreign key constraints with proper CASCADE rules

---

## Next: Test the API

After deployment, test endpoints:

```bash
# Health check
curl https://la-paz.vercel.app/health

# API docs
open https://la-paz.vercel.app/docs

# Create test staff member
curl -X POST https://la-paz.vercel.app/v1/operations/staff/ \
  -H "Content-Type: application/json" \
  -d '{"email":"test@lapaz.com","name":"Test User","role":"operations"}'
```

---

**Total time**: 5-10 minutes
**Difficulty**: Easy (copy/paste in Dashboard)
