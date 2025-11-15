#!/bin/bash
# Validate Xcode project configuration
# Checks schemes, project files, and git tracking status
#
# Usage:
#   ./tools/scripts/validate-xcode.sh

set -e

XCODE_PROJECT="apps/Operations Center/Operations Center.xcodeproj"
SCHEMES_DIR="$XCODE_PROJECT/xcshareddata/xcschemes"
REQUIRED_SCHEMES=("Operations Center.xcscheme" "Operations Center Preview.xcscheme")

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Xcode Project Validation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

ERRORS=0
WARNINGS=0

# Check 1: Project file exists
echo -e "${BLUE}[1/5]${NC} Checking project file..."
if [ ! -f "$XCODE_PROJECT/project.pbxproj" ]; then
    echo -e "${RED}  ✗ ERROR: project.pbxproj not found${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}  ✓ project.pbxproj exists${NC}"
fi

# Check 2: Schemes directory exists
echo -e "${BLUE}[2/5]${NC} Checking schemes directory..."
if [ ! -d "$SCHEMES_DIR" ]; then
    echo -e "${RED}  ✗ ERROR: Schemes directory not found: $SCHEMES_DIR${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}  ✓ Schemes directory exists${NC}"
fi

# Check 3: Required schemes exist
echo -e "${BLUE}[3/5]${NC} Checking required schemes..."
MISSING_SCHEMES=()
for scheme in "${REQUIRED_SCHEMES[@]}"; do
    if [ ! -f "$SCHEMES_DIR/$scheme" ]; then
        MISSING_SCHEMES+=("$scheme")
    fi
done

if [ ${#MISSING_SCHEMES[@]} -gt 0 ]; then
    echo -e "${RED}  ✗ ERROR: Missing required schemes:${NC}"
    for scheme in "${MISSING_SCHEMES[@]}"; do
        echo -e "${RED}    - $scheme${NC}"
    done
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}  ✓ All required schemes found${NC}"
fi

# Check 4: Validate scheme XML
echo -e "${BLUE}[4/5]${NC} Validating scheme XML..."
if [ -d "$SCHEMES_DIR" ]; then
    INVALID_SCHEMES=()
    for scheme_file in "$SCHEMES_DIR"/*.xcscheme; do
        if [ -f "$scheme_file" ]; then
            if ! xmllint --noout "$scheme_file" 2>/dev/null; then
                INVALID_SCHEMES+=("$(basename "$scheme_file")")
            fi
        fi
    done

    if [ ${#INVALID_SCHEMES[@]} -gt 0 ]; then
        echo -e "${RED}  ✗ ERROR: Invalid XML in schemes:${NC}"
        for scheme in "${INVALID_SCHEMES[@]}"; do
            echo -e "${RED}    - $scheme${NC}"
        done
        ERRORS=$((ERRORS + 1))
    else
        echo -e "${GREEN}  ✓ All schemes have valid XML${NC}"
    fi
fi

# Check 5: Git tracking status
echo -e "${BLUE}[5/5]${NC} Checking git tracking status..."
if [ -d "$SCHEMES_DIR" ]; then
    UNTRACKED_SCHEMES=()
    for scheme_file in "$SCHEMES_DIR"/*.xcscheme; do
        if [ -f "$scheme_file" ]; then
            if ! git ls-files --error-unmatch "$scheme_file" &>/dev/null; then
                UNTRACKED_SCHEMES+=("$(basename "$scheme_file")")
            fi
        fi
    done

    if [ ${#UNTRACKED_SCHEMES[@]} -gt 0 ]; then
        echo -e "${YELLOW}  ⚠  WARNING: Untracked schemes found:${NC}"
        for scheme in "${UNTRACKED_SCHEMES[@]}"; do
            echo -e "${YELLOW}    - $scheme${NC}"
        done
        echo -e "${YELLOW}    Run: git add \"$SCHEMES_DIR/\"*.xcscheme${NC}"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${GREEN}  ✓ All schemes are tracked by git${NC}"
    fi
fi

# List all schemes
echo ""
echo -e "${BLUE}Available Schemes:${NC}"
if [ -d "$SCHEMES_DIR" ]; then
    for scheme_file in "$SCHEMES_DIR"/*.xcscheme; do
        if [ -f "$scheme_file" ]; then
            scheme_name=$(basename "$scheme_file")
            if git ls-files --error-unmatch "$scheme_file" &>/dev/null; then
                echo -e "  ${GREEN}✓${NC} $scheme_name (tracked)"
            else
                echo -e "  ${YELLOW}⚠${NC} $scheme_name (untracked)"
            fi
        fi
    done
else
    echo -e "  ${RED}None found${NC}"
fi

# Summary
echo ""
echo -e "${BLUE}========================================${NC}"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ Validation passed${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠  Validation passed with $WARNINGS warning(s)${NC}"
    exit 0
else
    echo -e "${RED}✗ Validation failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    exit 1
fi
