#!/bin/bash

# La-Paz Local Development Setup Script
# This script sets up a local Supabase environment for development

set -e

echo "🚀 La-Paz Local Development Setup"
echo "=================================="
echo ""

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found. Installing..."
    npm install -g supabase
    echo "✅ Supabase CLI installed"
else
    echo "✅ Supabase CLI already installed"
fi

# Initialize Supabase (if not already done)
if [ ! -d "supabase" ]; then
    echo "📦 Initializing Supabase..."
    supabase init
    echo "✅ Supabase initialized"
else
    echo "✅ Supabase already initialized"
fi

# Start Supabase local services
echo "🔧 Starting local Supabase services..."
supabase start

# Get local connection details
echo ""
echo "📋 Local Connection Details:"
supabase status

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
echo "🏃 To start the FastAPI server:"
echo "   uvicorn backend.main:app --reload"
echo ""
echo "🛑 To stop Supabase:"
echo "   supabase stop"
echo ""
