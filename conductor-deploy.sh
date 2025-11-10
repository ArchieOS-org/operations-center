#!/bin/bash
set -e  # Exit on any error

# ============================================================================
# Operations Center Deployment Script
# ============================================================================
# This script handles deployment for both backend (Vercel) and frontend (Xcode)
# Usage:
#   ./conductor-deploy.sh --backend       Deploy backend to Vercel
#   ./conductor-deploy.sh --frontend      Build frontend for release
#   ./conductor-deploy.sh --all           Deploy both backend and frontend
#   ./conductor-deploy.sh --help          Show this help message
# ============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DEPLOY_BACKEND=false
DEPLOY_FRONTEND=false
PRODUCTION=false

# ============================================================================
# Helper Functions
# ============================================================================

show_help() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Operations Center Deployment Script"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Usage:"
    echo "  ./conductor-deploy.sh [options]"
    echo ""
    echo "Options:"
    echo "  --backend          Deploy backend to Vercel"
    echo "  --frontend         Build frontend for release"
    echo "  --all              Deploy both backend and frontend"
    echo "  --prod             Deploy to production (default: preview)"
    echo "  --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./conductor-deploy.sh --backend           # Deploy backend preview"
    echo "  ./conductor-deploy.sh --backend --prod    # Deploy backend to production"
    echo "  ./conductor-deploy.sh --frontend          # Build frontend release"
    echo "  ./conductor-deploy.sh --all --prod        # Full production deployment"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

log_info() {
    echo -e "${BLUE}ℹ${NC}  $1"
}

log_success() {
    echo -e "${GREEN}✅${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠️${NC}  $1"
}

log_error() {
    echo -e "${RED}❌${NC} $1"
}

# ============================================================================
# Parse Arguments
# ============================================================================

if [ $# -eq 0 ]; then
    log_error "No deployment target specified"
    show_help
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --backend)
            DEPLOY_BACKEND=true
            shift
            ;;
        --frontend)
            DEPLOY_FRONTEND=true
            shift
            ;;
        --all)
            DEPLOY_BACKEND=true
            DEPLOY_FRONTEND=true
            shift
            ;;
        --prod|--production)
            PRODUCTION=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# ============================================================================
# Pre-deployment Checks
# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Operations Center Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$PRODUCTION" = true ]; then
    log_warning "PRODUCTION DEPLOYMENT MODE"
    log_info "This will deploy to production environment"
    echo ""
    read -p "Are you sure you want to deploy to PRODUCTION? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        log_info "Deployment cancelled"
        exit 0
    fi
else
    log_info "Preview deployment mode (use --prod for production)"
fi

echo ""

# ============================================================================
# Backend Deployment (Vercel)
# ============================================================================

deploy_backend() {
    echo ""
    echo "─────────────────────────────────────────────────────────────────────"
    echo "🐍 Deploying Backend to Vercel"
    echo "─────────────────────────────────────────────────────────────────────"
    echo ""

    # Check if Vercel CLI is installed
    if ! command -v vercel &> /dev/null; then
        log_error "Vercel CLI not found"
        log_info "Install with: npm install -g vercel"
        exit 1
    fi

    log_success "Vercel CLI found: $(vercel --version)"

    # Check if backend directory exists
    if [ ! -d "$CONDUCTOR_ROOT_PATH/backend" ]; then
        log_error "Backend directory not found at $CONDUCTOR_ROOT_PATH/backend"
        exit 1
    fi

    # Check for .env file
    if [ ! -f "$CONDUCTOR_WORKSPACE_PATH/.env" ] && [ ! -f "$CONDUCTOR_ROOT_PATH/.env" ]; then
        log_warning "No .env file found - make sure environment variables are set in Vercel"
    fi

    # Navigate to backend directory
    cd "$CONDUCTOR_ROOT_PATH/backend" || exit 1

    # Run tests before deploying (if pytest is available)
    if command -v pytest &> /dev/null; then
        log_info "Running backend tests..."
        if pytest --quiet; then
            log_success "Tests passed"
        else
            log_error "Tests failed - aborting deployment"
            exit 1
        fi
    else
        log_warning "pytest not found - skipping tests"
    fi

    # Run linter (if ruff is available)
    if command -v ruff &> /dev/null; then
        log_info "Running linter..."
        if ruff check . --quiet; then
            log_success "Linter passed"
        else
            log_warning "Linter found issues (continuing anyway)"
        fi
    fi

    # Deploy to Vercel
    log_info "Deploying to Vercel..."
    if [ "$PRODUCTION" = true ]; then
        vercel deploy --prod > "$CONDUCTOR_WORKSPACE_PATH/deployment-url.txt" 2>&1
    else
        vercel deploy > "$CONDUCTOR_WORKSPACE_PATH/deployment-url.txt" 2>&1
    fi

    # Check deployment status
    if [ $? -eq 0 ]; then
        DEPLOYMENT_URL=$(cat "$CONDUCTOR_WORKSPACE_PATH/deployment-url.txt" | tail -n1)
        echo ""
        log_success "Backend deployed successfully!"
        log_info "Deployment URL: $DEPLOYMENT_URL"
        echo ""

        # Save deployment URL to clipboard (macOS)
        echo "$DEPLOYMENT_URL" | pbcopy 2>/dev/null && log_info "URL copied to clipboard"
    else
        echo ""
        log_error "Deployment failed"
        cat "$CONDUCTOR_WORKSPACE_PATH/deployment-url.txt"
        exit 1
    fi

    cd "$CONDUCTOR_WORKSPACE_PATH" || exit 1
}

# ============================================================================
# Frontend Deployment (Xcode Archive)
# ============================================================================

deploy_frontend() {
    echo ""
    echo "─────────────────────────────────────────────────────────────────────"
    echo "🖥️  Building Frontend (macOS App)"
    echo "─────────────────────────────────────────────────────────────────────"
    echo ""

    # Check if xcodebuild is available
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode not found"
        log_info "Install Xcode from the Mac App Store"
        exit 1
    fi

    log_success "Xcode found: $(xcodebuild -version | head -n1)"

    # Check if XcodeGen is available
    if ! command -v xcodegen &> /dev/null; then
        log_error "XcodeGen not found"
        log_info "Install with: brew install xcodegen"
        exit 1
    fi

    # Check if frontend directory exists
    FRONTEND_DIR="$CONDUCTOR_ROOT_PATH/apps/operations-center-macos"
    if [ ! -d "$FRONTEND_DIR" ]; then
        log_error "Frontend directory not found at $FRONTEND_DIR"
        exit 1
    fi

    cd "$FRONTEND_DIR" || exit 1

    # Generate Xcode project
    log_info "Generating Xcode project with XcodeGen..."
    if xcodegen; then
        log_success "Xcode project generated"
    else
        log_error "Failed to generate Xcode project"
        exit 1
    fi

    # Run tests
    log_info "Running frontend tests..."
    if xcodebuild test -scheme OperationsCenter -quiet 2>&1 | grep -q "Test Succeeded"; then
        log_success "Tests passed"
    else
        log_warning "Tests failed or no tests found (continuing anyway)"
    fi

    # Build for release
    log_info "Building for release..."
    BUILD_DIR="$CONDUCTOR_WORKSPACE_PATH/build"
    mkdir -p "$BUILD_DIR"

    if [ "$PRODUCTION" = true ]; then
        log_info "Creating archive for App Store submission..."
        xcodebuild archive \
            -scheme OperationsCenter \
            -configuration Release \
            -archivePath "$BUILD_DIR/OperationsCenter.xcarchive" \
            | grep -E '^(==|Build|Archive)' || true

        if [ -d "$BUILD_DIR/OperationsCenter.xcarchive" ]; then
            echo ""
            log_success "Archive created successfully!"
            log_info "Archive location: $BUILD_DIR/OperationsCenter.xcarchive"
            echo ""
            log_info "Next steps for App Store submission:"
            log_info "  1. Open Xcode"
            log_info "  2. Window → Organizer"
            log_info "  3. Select archive and click 'Distribute App'"
            log_info "  4. Follow the App Store submission wizard"
            echo ""
        else
            log_error "Archive creation failed"
            exit 1
        fi
    else
        log_info "Building debug version..."
        xcodebuild build \
            -scheme OperationsCenter \
            -configuration Debug \
            -derivedDataPath "$BUILD_DIR" \
            | grep -E '^(==|Build)' || true

        echo ""
        log_success "Debug build completed!"
        log_info "Build location: $BUILD_DIR"
        echo ""
    fi

    cd "$CONDUCTOR_WORKSPACE_PATH" || exit 1
}

# ============================================================================
# Execute Deployment
# ============================================================================

if [ "$DEPLOY_BACKEND" = true ]; then
    deploy_backend
fi

if [ "$DEPLOY_FRONTEND" = true ]; then
    deploy_frontend
fi

# ============================================================================
# Deployment Summary
# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ Deployment Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$DEPLOY_BACKEND" = true ] && [ -f "$CONDUCTOR_WORKSPACE_PATH/deployment-url.txt" ]; then
    DEPLOYMENT_URL=$(cat "$CONDUCTOR_WORKSPACE_PATH/deployment-url.txt" | tail -n1)
    echo "Backend Deployment: $DEPLOYMENT_URL"
fi

if [ "$DEPLOY_FRONTEND" = true ]; then
    echo "Frontend Build: $BUILD_DIR"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
