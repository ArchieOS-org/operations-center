# Local Development Guide

**Project**: La-Paz Operations Center
**Purpose**: Run the entire stack locally for development and testing
**Last Updated**: 2025-11-11

---

## Overview

Unlike the AWS version that used **Docker + LocalStack** to simulate DynamoDB, this new system uses **real PostgreSQL** locally, giving you an exact match with production.

---

## 🎯 Quick Start (Recommended)

### **Option 1: Supabase CLI (Full Stack)**

The easiest way to get started with a complete local Supabase environment:

```bash
# 1. Install Supabase CLI
npm install -g supabase

# 2. Run setup script
chmod +x scripts/local-dev-setup.sh
./scripts/local-dev-setup.sh

# 3. Start FastAPI
pip install -r requirements.txt
uvicorn backend.main:app --reload

# 4. Access your local environment
# - API: http://localhost:8000/docs
# - Database UI: http://localhost:54323
# - PostgreSQL: localhost:54322
```

**That's it!** Your full stack is running locally with:
- ✅ PostgreSQL database
- ✅ Supabase Studio (database UI)
- ✅ Auth server
- ✅ Storage
- ✅ All migrations applied automatically

---

## 📋 Comparison: All Local Development Options

| Feature | Supabase CLI | Docker Compose | Native PostgreSQL |
|---------|-------------|----------------|-------------------|
| **Setup Time** | 2 minutes | 3 minutes | 5 minutes |
| **Docker Required?** | Yes (automatic) | Yes (manual) | No |
| **Database UI** | Supabase Studio ✅ | Optional (pgAdmin) | None (use CLI) |
| **Auth Server** | Included ✅ | Not included | Not included |
| **Storage** | Included ✅ | Not included | Not included |
| **Matches Supabase** | 100% | Database only | Database only |
| **Auto-migrations** | Yes ✅ | On startup only | Manual |
| **Best For** | Full stack development | Database-only work | Lightweight setup |

---

## Option 1: Supabase CLI (Recommended)

### **Installation**

```bash
# Install Supabase CLI globally
npm install -g supabase

# Verify installation
supabase --version
```

### **Initialize Project**

```bash
# In your project directory
cd /Users/noahdeskin/conductor/operations-center/.conductor/la-paz

# Initialize (creates supabase/ directory)
supabase init
```

This creates:
```
supabase/
├── config.toml          # Supabase configuration
├── seed.sql            # Optional seed data
└── .gitignore
```

### **Start Local Environment**

```bash
# Start all Supabase services
supabase start

# Output shows:
# ✅ Started supabase local development setup.
#
#          API URL: http://localhost:54321
#      GraphQL URL: http://localhost:54321/graphql/v1
#           DB URL: postgresql://postgres:postgres@localhost:54322/postgres
#       Studio URL: http://localhost:54323
#     Inbucket URL: http://localhost:54324
#       JWT secret: super-secret-jwt-token-with-at-least-32-characters-long
#         anon key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
# service_role key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### **Apply Migrations**

```bash
# Copy migrations to supabase folder
cp migrations/*.sql supabase/migrations/

# Apply all migrations (resets database)
supabase db reset

# Or push specific migrations
supabase db push
```

### **Environment Variables**

Create `.env.local`:

```bash
# Supabase Local
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...  # From supabase start output
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...  # From supabase start output

# Database Direct Connection
DATABASE_URL=postgresql://postgres:postgres@localhost:54322/postgres
```

### **Start FastAPI**

```bash
# Install dependencies
pip install -r requirements.txt

# Run with local environment
uvicorn backend.main:app --reload --env-file .env.local

# Access
open http://localhost:8000/docs
```

### **Access Supabase Studio**

```bash
# Open database management UI
open http://localhost:54323
```

**Studio Features:**
- View/edit tables
- Run SQL queries
- Manage auth users
- View storage buckets
- Real-time data updates

### **Stop Services**

```bash
# Stop Supabase
supabase stop

# Stop and remove all data
supabase stop --no-backup
```

---

## Option 2: Docker Compose (Database Only)

If you just need PostgreSQL without the full Supabase stack:

### **Start Services**

```bash
# Start PostgreSQL
docker-compose up -d

# View logs
docker-compose logs -f postgres

# With pgAdmin UI
docker-compose --profile with-ui up -d
```

### **Apply Migrations**

```bash
# Migrations are auto-applied on first start from migrations/ folder

# To re-apply manually:
docker-compose exec postgres psql -U postgres -d la_paz_dev -f /docker-entrypoint-initdb.d/004_create_staff_table.sql
# ... repeat for each migration
```

### **Environment Variables**

```bash
# .env.local for Docker Compose
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/la_paz_dev
SUPABASE_URL=http://localhost:5432  # Just for compatibility
```

### **Access Database**

```bash
# Via psql CLI
docker-compose exec postgres psql -U postgres -d la_paz_dev

# Via pgAdmin (if running with --profile with-ui)
open http://localhost:5050
# Login: admin@lapaz.local / admin
# Add server: postgres / postgres / postgres / la_paz_dev
```

### **Stop Services**

```bash
# Stop containers
docker-compose down

# Stop and remove data volumes
docker-compose down -v
```

---

## Option 3: Native PostgreSQL (No Docker)

### **Install PostgreSQL**

```bash
# macOS (Homebrew)
brew install postgresql@15

# Start service
brew services start postgresql@15

# Verify
psql --version
```

### **Create Database**

```bash
# Create database
createdb la_paz_dev

# Connect
psql -d la_paz_dev
```

### **Apply Migrations**

```bash
# Apply each migration file
psql -d la_paz_dev -f migrations/004_create_staff_table.sql
psql -d la_paz_dev -f migrations/005_create_realtors_table.sql
psql -d la_paz_dev -f migrations/006_create_listing_tasks_table.sql
psql -d la_paz_dev -f migrations/007_create_stray_tasks_table.sql
psql -d la_paz_dev -f migrations/008_create_slack_messages_table.sql
psql -d la_paz_dev -f migrations/009_update_listings_table.sql

# Or use a script
./scripts/apply-migrations-native.sh
```

### **Environment Variables**

```bash
# .env.local for native PostgreSQL
DATABASE_URL=postgresql://postgres@localhost:5432/la_paz_dev
```

### **Database Management Tools**

```bash
# Command line
psql -d la_paz_dev

# GUI options:
# - Postico (macOS): https://eggerapps.at/postico/
# - pgAdmin: https://www.pgadmin.org/
# - DBeaver: https://dbeaver.io/
```

---

## Workflow Comparison

### **AWS DynamoDB (Old System)**

```bash
# Start LocalStack
docker-compose up localstack

# Apply DynamoDB table definitions
aws dynamodb create-table --endpoint-url http://localhost:4566 ...

# Seed data
node scripts/seed-dynamodb-local.js

# Run application
npm run dev

# Test
curl http://localhost:3000/tasks
```

**Issues:**
- ❌ LocalStack doesn't perfectly match real DynamoDB
- ❌ Complex table definitions in code
- ❌ No visual table browser
- ❌ Slow query performance
- ❌ Limited debugging tools

### **Supabase PostgreSQL (New System)**

```bash
# Start Supabase
supabase start

# Migrations auto-applied
# (or: supabase db reset)

# Run application
uvicorn backend.main:app --reload

# Visual database browser
open http://localhost:54323

# Test
curl http://localhost:8000/v1/operations/staff
```

**Benefits:**
- ✅ Exact match with production PostgreSQL
- ✅ Visual Studio for database management
- ✅ SQL migrations (version controlled)
- ✅ Fast query performance
- ✅ Standard PostgreSQL tools work

---

## Development Workflow

### **Daily Development**

```bash
# 1. Start local environment
supabase start  # or docker-compose up -d

# 2. Start FastAPI
uvicorn backend.main:app --reload

# 3. Develop with hot reload
# - Edit code in backend/
# - API auto-reloads on save
# - Use http://localhost:8000/docs for testing

# 4. View database
open http://localhost:54323

# 5. When done
supabase stop  # or docker-compose down
```

### **Adding New Migrations**

```bash
# 1. Create migration file
touch migrations/010_add_new_feature.sql

# 2. Write SQL
cat > migrations/010_add_new_feature.sql <<EOF
ALTER TABLE staff ADD COLUMN timezone TEXT;
EOF

# 3. Apply to local
supabase db reset  # Reapplies all migrations

# 4. Test
# Use Studio or psql to verify

# 5. Commit
git add migrations/010_add_new_feature.sql
git commit -m "Add timezone to staff"
```

### **Testing with Sample Data**

```bash
# Option 1: Use Supabase Studio
# - Open http://localhost:54323
# - Click table
# - Click "Insert" button
# - Fill form

# Option 2: SQL seed file
cat > supabase/seed.sql <<EOF
INSERT INTO staff (staff_id, email, name, role, status)
VALUES
  ('01HWQK0000ADMIN0000000000', 'admin@test.com', 'Admin User', 'admin', 'active'),
  ('01HWQK0000STAFF0000000001', 'jane@test.com', 'Jane Doe', 'operations', 'active');

INSERT INTO realtors (realtor_id, email, name, status)
VALUES
  ('01HWQK0000REALTOR000000', 'agent@test.com', 'Test Agent', 'active');
EOF

# Apply seed data
supabase db reset  # Includes seed.sql
```

---

## Debugging

### **View Database Logs**

```bash
# Supabase CLI
supabase db logs

# Docker Compose
docker-compose logs -f postgres

# Native PostgreSQL
tail -f /usr/local/var/log/postgresql@15.log
```

### **Connect to Database Directly**

```bash
# Supabase CLI
supabase db connect

# Docker Compose
docker-compose exec postgres psql -U postgres -d la_paz_dev

# Native
psql -d la_paz_dev
```

### **Check Table Structure**

```sql
-- List all tables
\dt

-- Describe staff table
\d staff

-- View indexes
\di

-- View foreign keys
SELECT
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY';
```

---

## Environment Variables Reference

### **Supabase CLI**

```bash
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=<from supabase start>
SUPABASE_SERVICE_KEY=<from supabase start>
DATABASE_URL=postgresql://postgres:postgres@localhost:54322/postgres
```

### **Docker Compose**

```bash
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/la_paz_dev
```

### **Native PostgreSQL**

```bash
DATABASE_URL=postgresql://postgres@localhost:5432/la_paz_dev
```

---

## Troubleshooting

### **"Port already in use"**

```bash
# Supabase CLI
supabase stop
lsof -ti:54321 | xargs kill -9

# Docker Compose
docker-compose down
lsof -ti:5432 | xargs kill -9
```

### **"Migration failed"**

```bash
# Reset database completely
supabase db reset --no-backup

# Or with Docker
docker-compose down -v
docker-compose up -d
```

### **"Can't connect to database"**

```bash
# Check if running
supabase status  # or docker-compose ps

# Check connection
pg_isready -h localhost -p 54322  # Supabase
pg_isready -h localhost -p 5432   # Docker/Native

# Test connection
psql -h localhost -p 54322 -U postgres -d postgres
```

---

## Performance Tips

1. **Use Connection Pooling**
   - Supabase CLI includes pgBouncer automatically
   - For Docker/Native, configure in `backend/database/supabase_client.py`

2. **Index Usage**
   - All indexes are created by migrations
   - Use `EXPLAIN ANALYZE` to check query performance

3. **Dev vs Prod**
   - Local uses `postgres` superuser for simplicity
   - Production uses RLS policies (not enforced locally by default)

---

## Next Steps

1. ✅ Choose your local development method (Supabase CLI recommended)
2. ✅ Run setup script or manual steps
3. ✅ Start FastAPI server
4. ✅ Test API endpoints at http://localhost:8000/docs
5. ✅ View database at http://localhost:54323 (Supabase Studio)
6. ✅ Add sample data for testing
7. ✅ Start developing!

**See other README files for:**
- Database schema: `README_DATABASE.md`
- API endpoints: `README_API.md`
- Production migration: `README_MIGRATION.md`
- Implementation status: `IMPLEMENTATION_STATUS.md`
