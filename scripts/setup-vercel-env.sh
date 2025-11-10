#!/bin/bash
# Vercel Environment Variables Setup Script
# Run this script to add all required environment variables to Vercel

set -e  # Exit on error

echo "=========================================="
echo "Vercel Environment Variables Setup"
echo "=========================================="
echo ""

# Check if vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    echo "❌ Vercel CLI not found. Installing..."
    npm install -g vercel
fi

echo "✅ Vercel CLI installed"
echo ""

# Check if logged in
echo "Checking Vercel authentication..."
if ! vercel whoami &> /dev/null; then
    echo "⚠️  Not logged in to Vercel. Please authenticate:"
    vercel login
fi

echo "✅ Authenticated to Vercel"
echo ""

# Link project if not already linked
if [ ! -f ".vercel/project.json" ]; then
    echo "⚠️  Project not linked. Linking to Vercel..."
    vercel link
fi

echo "✅ Project linked"
echo ""

# Add Supabase credentials (already known)
echo "Adding Supabase credentials..."

echo "https://kukmshbkzlskyuacgzbo.supabase.co" | vercel env add SUPABASE_URL production
echo "https://kukmshbkzlskyuacgzbo.supabase.co" | vercel env add SUPABASE_URL preview
echo "https://kukmshbkzlskyuacgzbo.supabase.co" | vercel env add SUPABASE_URL development

echo "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt1a21zaGJremxza3l1YWNnemJvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mjc5NTI5MCwiZXhwIjoyMDc4MzcxMjkwfQ.lPA0E6yPwDBJ6SWnqy0jp68FH3rjdNFtI28JDMXRTLs" | vercel env add SUPABASE_KEY production
echo "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt1a21zaGJremxza3l1YWNnemJvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mjc5NTI5MCwiZXhwIjoyMDc4MzcxMjkwfQ.lPA0E6yPwDBJ6SWnqy0jp68FH3rjdNFtI28JDMXRTLs" | vercel env add SUPABASE_KEY preview
echo "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt1a21zaGJremxza3l1YWNnemJvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mjc5NTI5MCwiZXhwIjoyMDc4MzcxMjkwfQ.lPA0E6yPwDBJ6SWnqy0jp68FH3rjdNFtI28JDMXRTLs" | vercel env add SUPABASE_KEY development

echo "✅ Supabase credentials added"
echo ""

# Add other environment variables (will prompt for values)
echo "=========================================="
echo "Now adding credentials from your old project..."
echo "=========================================="
echo ""

echo "📋 Tip: Get these values from /Users/noahdeskin/archieos-backend-1/.env"
echo ""

echo "Adding OPENAI_API_KEY..."
vercel env add OPENAI_API_KEY production
vercel env add OPENAI_API_KEY preview
vercel env add OPENAI_API_KEY development

echo "Adding SLACK_SIGNING_SECRET..."
vercel env add SLACK_SIGNING_SECRET production
vercel env add SLACK_SIGNING_SECRET preview
vercel env add SLACK_SIGNING_SECRET development

echo "Adding SLACK_BOT_TOKEN..."
vercel env add SLACK_BOT_TOKEN production
vercel env add SLACK_BOT_TOKEN preview
vercel env add SLACK_BOT_TOKEN development

echo ""
echo "=========================================="
echo "Optional: Add LangSmith credentials"
echo "=========================================="
echo ""
echo "Get your LangSmith API key from: https://smith.langchain.com"
echo ""
read -p "Do you want to add LangSmith credentials? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Adding LANGCHAIN_API_KEY..."
    vercel env add LANGCHAIN_API_KEY production
    vercel env add LANGCHAIN_API_KEY preview
    vercel env add LANGCHAIN_API_KEY development
    echo "✅ LangSmith credentials added"
else
    echo "⏭️  Skipping LangSmith (you can add it later)"
fi

echo ""
echo "=========================================="
echo "✅ Environment Variables Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Verify variables: vercel env ls"
echo "2. Deploy to production: vercel --prod"
echo "3. Update Slack webhook URL"
echo ""
