#!/bin/bash
# Pre-commit hook to verify Xcode schemes are tracked
# Prevents schemes from being lost when committing
#
# Installation:
#   cp tools/scripts/pre-commit-verify-schemes.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit

set -e

XCODE_PROJECT="apps/Operations Center/Operations Center.xcodeproj"
SCHEMES_DIR="$XCODE_PROJECT/xcshareddata/xcschemes"
REQUIRED_SCHEMES=("Operations Center.xcscheme" "Operations Center Preview.xcscheme")

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Verifying Xcode schemes are tracked..."

# Check if schemes directory exists
if [ ! -d "$SCHEMES_DIR" ]; then
    echo -e "${YELLOW}⚠️  Warning: Schemes directory not found: $SCHEMES_DIR${NC}"
    echo "This may be intentional if you haven't created any schemes yet."
    exit 0
fi

# Find all .xcscheme files
SCHEME_FILES=$(find "$SCHEMES_DIR" -name "*.xcscheme" 2>/dev/null || true)

if [ -z "$SCHEME_FILES" ]; then
    echo -e "${YELLOW}⚠️  Warning: No .xcscheme files found in $SCHEMES_DIR${NC}"
    exit 0
fi

# Check each scheme file
MISSING_SCHEMES=()
UNTRACKED_SCHEMES=()

while IFS= read -r scheme_file; do
    scheme_name=$(basename "$scheme_file")

    # Check if file is tracked by git
    if ! git ls-files --error-unmatch "$scheme_file" &>/dev/null; then
        UNTRACKED_SCHEMES+=("$scheme_name")
    fi
done <<< "$SCHEME_FILES"

# Check for required schemes
for required_scheme in "${REQUIRED_SCHEMES[@]}"; do
    scheme_path="$SCHEMES_DIR/$required_scheme"
    if [ ! -f "$scheme_path" ]; then
        MISSING_SCHEMES+=("$required_scheme")
    fi
done

# Report issues
ERRORS=0

if [ ${#UNTRACKED_SCHEMES[@]} -gt 0 ]; then
    echo -e "${RED}❌ ERROR: Untracked Xcode schemes detected!${NC}"
    echo ""
    echo "The following scheme files exist but are NOT tracked by git:"
    for scheme in "${UNTRACKED_SCHEMES[@]}"; do
        echo -e "  ${RED}✗${NC} $scheme"
    done
    echo ""
    echo "To fix this, run:"
    echo -e "  ${GREEN}git add \"$SCHEMES_DIR/\"*.xcscheme${NC}"
    echo ""
    ERRORS=1
fi

if [ ${#MISSING_SCHEMES[@]} -gt 0 ]; then
    echo -e "${RED}❌ ERROR: Required Xcode schemes are missing!${NC}"
    echo ""
    echo "The following schemes are required but not found:"
    for scheme in "${MISSING_SCHEMES[@]}"; do
        echo -e "  ${RED}✗${NC} $scheme"
    done
    echo ""
    echo "Create these schemes in Xcode and mark them as 'Shared'."
    echo ""
    ERRORS=1
fi

if [ $ERRORS -eq 1 ]; then
    echo -e "${RED}Commit blocked. Fix the issues above and try again.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All Xcode schemes are properly tracked${NC}"
exit 0
