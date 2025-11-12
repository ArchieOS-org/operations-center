#!/bin/bash
set -e  # Exit on any error

echo "🚀 Setting up Operations Center workspace..."
echo ""

# ============================================================================
# 1. Check Python version
# ============================================================================
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 is not installed"
    echo "   Please install Python 3.11+ from https://www.python.org/downloads/"
    echo ""
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
REQUIRED_VERSION="3.11"
if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "❌ Error: Python $PYTHON_VERSION found, but 3.11+ required"
    echo "   Please upgrade Python to 3.11 or higher"
    echo ""
    exit 1
fi
echo "✅ Python $PYTHON_VERSION detected"

# ============================================================================
# 2. Check for package manager (pip or uv)
# ============================================================================
PACKAGE_MANAGER=""
if command -v uv &> /dev/null; then
    PACKAGE_MANAGER="uv"
    echo "✅ Package manager: uv (fast!)"
elif command -v pip3 &> /dev/null; then
    PACKAGE_MANAGER="pip3"
    echo "✅ Package manager: pip3"
else
    echo "❌ Error: Neither pip3 nor uv found"
    echo "   Please install pip or uv for Python package management"
    echo "   uv is recommended: https://github.com/astral-sh/uv"
    echo ""
    exit 1
fi

# ============================================================================
# 3. Setup environment file (.env)
# ============================================================================
if [ ! -f "$CONDUCTOR_WORKSPACE_PATH/.env" ]; then
    if [ -f "$CONDUCTOR_ROOT_PATH/.env.example" ]; then
        cp "$CONDUCTOR_ROOT_PATH/.env.example" "$CONDUCTOR_WORKSPACE_PATH/.env"
        echo "✅ Created .env from .env.example"
        echo "⚠️  IMPORTANT: Update .env with your API keys and credentials"
    elif [ -f "$CONDUCTOR_ROOT_PATH/.env" ]; then
        # If root has .env but no .env.example, symlink it
        ln -s "$CONDUCTOR_ROOT_PATH/.env" "$CONDUCTOR_WORKSPACE_PATH/.env"
        echo "✅ Symlinked .env from root repository"
    else
        echo "⚠️  No .env.example or .env found - you'll need to create one manually"
        echo "   Required variables:"
        echo "   - OPENAI_API_KEY or ANTHROPIC_API_KEY"
        echo "   - SUPABASE_URL and SUPABASE_KEY"
        echo "   - LANGCHAIN_API_KEY (for LangSmith observability)"
    fi
else
    echo "✅ .env already exists"
fi

# ============================================================================
# 4. Install Python dependencies (backend)
# ============================================================================
if [ -f "$CONDUCTOR_ROOT_PATH/backend/requirements.txt" ]; then
    echo ""
    echo "📦 Installing Python backend dependencies..."

    # Create or activate virtual environment (optional but recommended)
    if [ ! -d "$CONDUCTOR_WORKSPACE_PATH/.venv" ]; then
        echo "   Creating Python virtual environment..."
        python3 -m venv "$CONDUCTOR_WORKSPACE_PATH/.venv"
    fi

    # Install dependencies
    cd "$CONDUCTOR_WORKSPACE_PATH" || exit 1
    if [ "$PACKAGE_MANAGER" = "uv" ]; then
        uv pip install -r "$CONDUCTOR_ROOT_PATH/backend/requirements.txt"
    else
        source "$CONDUCTOR_WORKSPACE_PATH/.venv/bin/activate"
        pip3 install -r "$CONDUCTOR_ROOT_PATH/backend/requirements.txt"
    fi

    echo "✅ Python dependencies installed"
else
    echo "⚠️  No backend/requirements.txt found - skipping Python dependencies"
fi

# ============================================================================
# 5. Check for frontend tools (Xcode, XcodeGen)
# ============================================================================
echo ""
if command -v xcodebuild &> /dev/null; then
    XCODE_VERSION=$(xcodebuild -version | head -n1)
    echo "✅ $XCODE_VERSION detected"
else
    echo "⚠️  Xcode not found - install from App Store for macOS/iOS development"
fi

if command -v xcodegen &> /dev/null; then
    echo "✅ XcodeGen found (for generating Xcode projects)"
else
    echo "⚠️  XcodeGen not found - install via 'brew install xcodegen' for frontend work"
fi

# ============================================================================
# 6. Check for Vercel CLI (for deployment)
# ============================================================================
if command -v vercel &> /dev/null; then
    echo "✅ Vercel CLI found (for backend deployment)"
else
    echo "⚠️  Vercel CLI not found - install via 'npm i -g vercel' for deployments"
fi

# ============================================================================
# 7. Display summary and next steps
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ Workspace setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Next steps:"
echo ""
echo "  Backend Development:"
echo "    cd backend"
echo "    source ../.venv/bin/activate  # Activate virtual environment"
echo "    python -m api.dev              # Start development server"
echo "    pytest                         # Run tests"
echo ""
echo "  Frontend Development (macOS app):"
echo "    cd apps/operations-center-macos"
echo "    xcodegen                       # Generate Xcode project"
echo "    open OperationsCenter.xcodeproj"
echo ""
echo "  Deployment:"
echo "    ./conductor-deploy.sh --backend    # Deploy backend to Vercel"
echo "    ./conductor-deploy.sh --frontend   # Build frontend for release"
echo ""
echo "  Environment:"
echo "    Edit .env with your API keys and credentials"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
