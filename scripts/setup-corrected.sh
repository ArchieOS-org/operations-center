#!/bin/bash

# CORRECTED Local Development Setup Script
# Fixes the errors from the original setup

set -e

echo "🔧 La-Paz Local Development Setup (CORRECTED)"
echo "=============================================="
echo ""

# Check if we're in the right directory
EXPECTED_DIR="/Users/noahdeskin/conductor/operations-center/.conductor/la-paz"
CURRENT_DIR=$(pwd)

if [ "$CURRENT_DIR" != "$EXPECTED_DIR" ]; then
    echo "❌ Wrong directory!"
    echo "Current: $CURRENT_DIR"
    echo "Expected: $EXPECTED_DIR"
    echo ""
    echo "Run this command first:"
    echo "  cd $EXPECTED_DIR"
    exit 1
fi

echo "✅ Correct directory: $CURRENT_DIR"
echo ""

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found"
    echo ""
    echo "Installing via Homebrew..."
    echo "⚠️  NOTE: DO NOT use 'npm install -g supabase' - it's not supported!"
    echo ""

    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew not found. Install it first:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi

    brew install supabase/tap/supabase
    echo "✅ Supabase CLI installed via Homebrew"
else
    echo "✅ Supabase CLI already installed ($(supabase --version))"
fi

echo ""

# Initialize Supabase (if not already done)
if [ ! -d "supabase" ]; then
    echo "📦 Initializing Supabase..."
    supabase init
    echo "✅ Supabase initialized"
else
    echo "✅ Supabase already initialized"
fi

echo ""

# Start Supabase local services
echo "🔧 Starting local Supabase services..."
supabase start

echo ""

# Get local connection details
echo "📋 Local Connection Details:"
echo ""
supabase status

echo ""

# Copy migrations to supabase folder
if [ ! -d "supabase/migrations" ]; then
    echo "📂 Creating migrations folder..."
    mkdir -p supabase/migrations
fi

echo "📝 Copying migration files..."
cp migrations/*.sql supabase/migrations/ 2>/dev/null || echo "⚠️  No migration files found or already copied"

# Apply migrations
echo ""
echo "🔄 Applying database migrations..."
supabase db reset

echo ""
echo "✅ Local development environment is ready!"
echo ""
echo "📍 Access Points:"
echo "   - API: http://localhost:8000 (after starting FastAPI)"
echo "   - Database Studio: http://localhost:54323"
echo "   - PostgreSQL: postgresql://postgres:postgres@localhost:54322/postgres"
echo ""
echo "⚙️  Create .env.local file:"
echo "   Run: ./scripts/create-env-local.sh"
echo ""
echo "🏃 To start the FastAPI server:"
echo "   uvicorn backend.main:app --reload --env-file .env.local"
echo ""
echo "🛑 To stop Supabase:"
echo "   supabase stop"
echo ""
