# Database Migrations - CLEANUP REQUIRED

## Current State (Needs Review)

This directory contains **duplicate migrations** that need to be cleaned up before production deployment.

### Potential Duplicates

**Initial migrations (001-009):**
- 001: Create tasks table
- 002: Create task_notes table
- 003: Create listings tables
- 004: Create staff table
- 005: Create realtors table
- 006: Create listing_tasks table
- 007: Create stray_tasks table
- 008: Create slack_messages table
- 009: Update listings table

**Later migrations (010-014) - Appear to recreate same tables:**
- 010: Create staff_and_realtors (duplicates 004-005?)
- 011: Create listings_if_needed (duplicates 003?)
- 012: Create task_tables (duplicates 001-002,006-007?)
- 013: Create slack_messages (duplicates 008?)
- 014: Add realtor_to_listings (should be additive)

**Combined migration:**
- 20251111194927_apply_migrations.sql - Unknown contents

## Action Required

Before deploying to production:

1. **Check production database** - Which migrations have been applied?
2. **Identify duplicates** - Do 010-014 duplicate 001-009?
3. **Archive unused migrations** - Move duplicates to trash/
4. **Keep only applied migrations** - Maintain linear migration history
5. **Use proper timestamps** - Future migrations should use `supabase migration new`

## Best Practice

Migrations should be:
- **Immutable** - Never edit applied migrations
- **Linear** - No duplicate table creations
- **Timestamped** - Use Supabase CLI format: `YYYYMMDDHHMMSS_description.sql`
- **Idempotent** - Safe to run multiple times

## Next Steps

Run this to check applied migrations in production:
```bash
supabase db remote diff
```

Then clean up this directory based on what's actually applied.
