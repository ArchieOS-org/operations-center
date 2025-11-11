#!/bin/bash

# Create .env.local with actual Supabase local keys

set -e

echo "🔑 Creating .env.local file..."
echo ""

# Check if Supabase is running
if ! supabase status &>/dev/null; then
    echo "❌ Supabase is not running!"
    echo "Run 'supabase start' first"
    exit 1
fi

# Get Supabase status and extract keys
STATUS=$(supabase status)

API_URL=$(echo "$STATUS" | grep "API URL:" | awk '{print $3}')
ANON_KEY=$(echo "$STATUS" | grep "anon key:" | awk '{print $3}')
SERVICE_KEY=$(echo "$STATUS" | grep "service_role key:" | awk '{print $3}')
DB_URL=$(echo "$STATUS" | grep "DB URL:" | awk '{print $3}')

# Create .env.local file
cat > .env.local <<EOF
# Supabase Local Development Configuration
# Auto-generated from 'supabase status'

# Supabase API
SUPABASE_URL=$API_URL
SUPABASE_ANON_KEY=$ANON_KEY
SUPABASE_SERVICE_KEY=$SERVICE_KEY

# Database Direct Connection
DATABASE_URL=$DB_URL

# Application Settings
ENVIRONMENT=local
DEBUG=true
LOG_LEVEL=info
EOF

echo "✅ Created .env.local with actual keys from Supabase"
echo ""
echo "📄 Contents:"
cat .env.local
echo ""
echo "🚀 You can now start FastAPI:"
echo "   uvicorn backend.main:app --reload --env-file .env.local"
echo ""
