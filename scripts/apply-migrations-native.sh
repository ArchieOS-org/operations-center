#!/bin/bash

# Apply all migrations to local PostgreSQL database
# For use with native PostgreSQL installation (no Docker)

set -e

# Configuration
DB_NAME="${DATABASE_NAME:-la_paz_dev}"
DB_USER="${DATABASE_USER:-postgres}"
DB_HOST="${DATABASE_HOST:-localhost}"
DB_PORT="${DATABASE_PORT:-5432}"

echo "🔄 Applying migrations to PostgreSQL"
echo "====================================="
echo "Database: $DB_NAME"
echo "Host: $DB_HOST:$DB_PORT"
echo "User: $DB_USER"
echo ""

# Check if database exists
if ! psql -h $DB_HOST -p $DB_PORT -U $DB_USER -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
    echo "❌ Database '$DB_NAME' does not exist. Create it first:"
    echo "   createdb -h $DB_HOST -p $DB_PORT -U $DB_USER $DB_NAME"
    exit 1
fi

# Find all migration files
MIGRATION_DIR="migrations"
if [ ! -d "$MIGRATION_DIR" ]; then
    echo "❌ Migration directory not found: $MIGRATION_DIR"
    exit 1
fi

# Get all migration files in order
MIGRATIONS=$(ls -1 $MIGRATION_DIR/*.sql 2>/dev/null | sort)

if [ -z "$MIGRATIONS" ]; then
    echo "❌ No migration files found in $MIGRATION_DIR"
    exit 1
fi

# Apply each migration
for migration in $MIGRATIONS; do
    filename=$(basename "$migration")
    echo "📝 Applying: $filename"

    if psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "$migration" > /dev/null 2>&1; then
        echo "   ✅ Success"
    else
        echo "   ❌ Failed"
        echo ""
        echo "Error applying migration: $filename"
        echo "To see the error, run:"
        echo "  psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f $migration"
        exit 1
    fi
done

echo ""
echo "✅ All migrations applied successfully!"
echo ""
echo "📊 Database tables:"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "\dt" | grep "public |"
echo ""
echo "🔗 Connect to database:"
echo "   psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME"
echo ""
