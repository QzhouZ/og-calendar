#!/bin/bash

# ============================================================
# OG Calendar IPA Build Script
# ============================================================
# Usage:
#   ./build_ipa.sh [options]
#
# Options:
#   -t, --team-id      Apple Team ID (paid developer or free personal team)
#   -u, --unsigned     Build unsigned IPA for Sideloadly/AltStore signing
#   -b, --bundle-id    Bundle Identifier (default: com.ogcalendar.app)
#   -m, --method       Export method: development|ad-hoc|app-store (default: development)
#   -c, --clean        Clean build folder before building
#   -h, --help         Show help
#
# Examples:
#   # 方式1: 用 Team ID 打签名 IPA
#   ./build_ipa.sh -t ABC123DEF4
#
#   # 方式2: 打包未签名 IPA，用 Sideloadly 安装
#   ./build_ipa.sh -u
#
#   # 方式3: 用免费 Apple ID 个人团队打包
#   ./build_ipa.sh -t YOUR_PERSONAL_TEAM_ID -m development
# ============================================================

set -e

# Pre-flight checks
check_xcode() {
    if ! command -v xcodebuild &> /dev/null; then
        echo -e "${RED}Error: xcodebuild not found. Please install Xcode from the App Store.${NC}"
        exit 1
    fi

    local dev_dir
    dev_dir=$(xcode-select -p 2>/dev/null || echo "")
    if [[ "$dev_dir" == *CommandLineTools* ]] || [[ -z "$dev_dir" ]]; then
        echo -e "${RED}Error: Xcode is not properly configured!${NC}"
        echo ""
        echo -e "${YELLOW}Current developer directory: ${dev_dir}${NC}"
        echo ""
        echo -e "${CYAN}To fix:${NC}"
        echo "  1. Install Xcode from the App Store (if not installed)"
        echo "  2. Run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
        echo "  3. Then retry this script"
        echo ""
        echo -e "${CYAN}To check if Xcode is installed:${NC}"
        echo "  ls /Applications/ | grep Xcode"
        exit 1
    fi

    # Check if .xcodeproj exists
    if [ ! -d "${WORKSPACE_DIR}/${PROJECT_NAME}.xcodeproj" ]; then
        echo -e "${RED}Error: ${PROJECT_NAME}.xcodeproj not found!${NC}"
        echo ""
        echo -e "${CYAN}Run setup first:${NC}"
        echo "  ./setup.sh"
        exit 1
    fi
}

# Default values
BUNDLE_ID="com.ogcalendar.app"
EXPORT_METHOD="development"
CLEAN_BUILD=false
TEAM_ID=""
UNSIGNED=false
SCHEME="OGCalendar"
PROJECT_NAME="OGCalendar"
WORKSPACE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${WORKSPACE_DIR}/build/output"
ARCHIVE_PATH="${BUILD_DIR}/${PROJECT_NAME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/ipa"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--team-id)
            TEAM_ID="$2"
            shift 2
            ;;
        -u|--unsigned)
            UNSIGNED=true
            shift
            ;;
        -b|--bundle-id)
            BUNDLE_ID="$2"
            shift 2
            ;;
        -m|--method)
            EXPORT_METHOD="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -t, --team-id      Apple Team ID (paid or free personal team)"
            echo "  -u, --unsigned     Build unsigned IPA for Sideloadly/AltStore"
            echo "  -b, --bundle-id    Bundle Identifier (default: com.ogcalendar.app)"
            echo "  -m, --method       Export method: development|ad-hoc|app-store (default: development)"
            echo "  -c, --clean        Clean build folder before building"
            echo "  -h, --help         Show help"
            echo ""
            echo "Examples:"
            echo "  # 未签名 IPA → Sideloadly 安装"
            echo "  $0 -u"
            echo ""
            echo "  # 用 Team ID 打签名 IPA"
            echo "  $0 -t ABC123DEF4"
            echo ""
            echo "  # 用免费 Apple ID 个人团队"
            echo "  $0 -t YOUR_PERSONAL_TEAM_ID"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Validate
if [ "$UNSIGNED" = false ] && [ -z "$TEAM_ID" ]; then
    echo -e "${RED}Error: Must provide --team-id or use --unsigned mode${NC}"
    echo ""
    echo -e "${CYAN}Options:${NC}"
    echo "  1. Use --unsigned to build for Sideloadly:  $0 -u"
    echo "  2. Use --team-id with your Team ID:         $0 -t YOUR_TEAM_ID"
    echo ""
    echo -e "${CYAN}How to find your Team ID:${NC}"
    echo "  - Xcode → Settings → Accounts → select your Apple ID → Team ID shown"
    echo "  - Or terminal: security find-identity -v -p codesigning"
    echo "  - Free Apple ID works too (app expires in 7 days)"
    exit 1
fi

# Run pre-flight checks (need WORKSPACE_DIR to be set)
check_xcode

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  OG Calendar IPA Build Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
if [ "$UNSIGNED" = true ]; then
    echo -e "  Mode:        ${CYAN}Unsigned (for Sideloadly/AltStore)${NC}"
else
    echo -e "  Mode:        ${CYAN}Signed (Team: ${TEAM_ID})${NC}"
fi
echo "  Bundle ID:   ${BUNDLE_ID}"
echo "  Export Method: ${EXPORT_METHOD}"
echo "  Workspace:   ${WORKSPACE_DIR}"
echo ""

# Clean
if [ "$CLEAN_BUILD" = true ]; then
    echo -e "${YELLOW}Cleaning build directory...${NC}"
    rm -rf "${BUILD_DIR}"
    echo "Cleaned."
fi

# Create build directory
mkdir -p "${BUILD_DIR}"

# ============================================================
# Unsigned build: compile without signing, package as IPA
# ============================================================
if [ "$UNSIGNED" = true ]; then
    echo -e "${YELLOW}Step 1/3: Building (unsigned)...${NC}"

    DERIVED_DATA="${BUILD_DIR}/DerivedData"

    xcodebuild clean build \
        -project "${WORKSPACE_DIR}/${PROJECT_NAME}.xcodeproj" \
        -scheme "${SCHEME}" \
        -configuration Release \
        -destination "generic/platform=iOS" \
        -derivedDataPath "${DERIVED_DATA}" \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        ENABLE_BITCODE=NO \
        PRODUCT_BUNDLE_IDENTIFIER="${BUNDLE_ID}" \
        GCC_PREPROCESSOR_DEFINITIONS="DEBUG=0" \
        | tail -20

    if [ $? -ne 0 ]; then
        echo -e "${RED}Build failed!${NC}"
        exit 1
    fi

    echo -e "${GREEN}Build succeeded!${NC}"

    echo -e "${YELLOW}Step 2/3: Packaging unsigned IPA...${NC}"

    # Find the .app bundle
    APP_PATH=$(find "${DERIVED_DATA}/Build/Products/Release-iphoneos" -name "*.app" -maxdepth 1 | head -1)

    if [ -z "$APP_PATH" ]; then
        echo -e "${RED}App bundle not found!${NC}"
        echo "Looking in: ${DERIVED_DATA}/Build/Products/Release-iphoneos"
        exit 1
    fi

    echo "  Found app: ${APP_PATH}"

    # Create IPA structure
    IPA_STAGING="${BUILD_DIR}/ipa_staging"
    rm -rf "${IPA_STAGING}"
    mkdir -p "${IPA_STAGING}/Payload"

    # Copy .app to Payload
    cp -r "${APP_PATH}" "${IPA_STAGING}/Payload/"

    # Also find and copy the Widget extension .appex if it exists
    APPEX_PATH=$(find "${DERIVED_DATA}/Build/Products/Release-iphoneos" -name "*.appex" -maxdepth 1 | head -1)
    if [ -n "$APPEX_PATH" ]; then
        echo "  Found widget: ${APPEX_PATH}"
        # Widget extensions are embedded inside the .app bundle's Plugins directory
        # They should already be inside the .app bundle if built correctly
    fi

    # Create IPA
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    FINAL_IPA="${WORKSPACE_DIR}/OGCalendar_unsigned_${TIMESTAMP}.ipa"

    echo -e "${YELLOW}Step 3/3: Creating IPA file...${NC}"

    # cd into staging to avoid including directory name in zip paths
    cd "${IPA_STAGING}"
    zip -r -q "${FINAL_IPA}" Payload/
    cd "${WORKSPACE_DIR}"

    # Cleanup staging
    rm -rf "${IPA_STAGING}"

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Unsigned Build Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "  IPA Location: ${FINAL_IPA}"
    echo "  File Size:    $(du -h "${FINAL_IPA}" | cut -f1)"
    echo ""
    echo -e "${CYAN}Next steps - Install with Sideloadly:${NC}"
    echo "  1. Download Sideloadly from https://sideloadly.io"
    echo "  2. Connect your iPhone via USB"
    echo "  3. Open Sideloadly, drag the IPA file into it"
    echo "  4. Enter your Apple ID (free account works)"
    echo "  5. Sideloadly will sign & install the app"
    echo ""
    echo -e "${YELLOW}Note: Free Apple ID signed apps expire in 7 days.${NC}"
    echo -e "${YELLOW}Re-sign with Sideloadly to renew.${NC}"
    echo ""
    exit 0
fi

# ============================================================
# Signed build: archive + export
# ============================================================
echo -e "${YELLOW}Step 1/3: Archiving...${NC}"

# Create ExportOptions.plist
EXPORT_OPTIONS="${BUILD_DIR}/ExportOptions.plist"
cat > "${EXPORT_OPTIONS}" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>${EXPORT_METHOD}</string>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
EOF

# Archive
xcodebuild archive \
    -project "${WORKSPACE_DIR}/${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME}" \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -archivePath "${ARCHIVE_PATH}" \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM="${TEAM_ID}" \
    PRODUCT_BUNDLE_IDENTIFIER="${BUNDLE_ID}" \
    | tail -20

if [ $? -ne 0 ]; then
    echo -e "${RED}Archive failed!${NC}"
    exit 1
fi

echo -e "${GREEN}Archive succeeded!${NC}"

echo -e "${YELLOW}Step 2/3: Exporting IPA...${NC}"

# Export IPA
xcodebuild -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportOptionsPlist "${EXPORT_OPTIONS}" \
    -exportPath "${EXPORT_PATH}" \
    -allowProvisioningUpdates

if [ $? -ne 0 ]; then
    echo -e "${RED}Export failed!${NC}"
    exit 1
fi

echo -e "${GREEN}Export succeeded!${NC}"

# Find IPA file
IPA_FILE=$(find "${EXPORT_PATH}" -name "*.ipa" -maxdepth 1 | head -1)

if [ -z "$IPA_FILE" ]; then
    echo -e "${RED}IPA file not found!${NC}"
    exit 1
fi

# Copy to workspace root with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FINAL_IPA="${WORKSPACE_DIR}/OGCalendar_${TIMESTAMP}.ipa"
cp "${IPA_FILE}" "${FINAL_IPA}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Signed Build Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "  IPA Location: ${FINAL_IPA}"
echo "  File Size:    $(du -h "${FINAL_IPA}" | cut -f1)"
echo ""
echo -e "${YELLOW}Note: Make sure you have configured the following in Xcode:${NC}"
echo "  1. Signing & Capabilities: Select your Team"
echo "  2. App Groups: Add 'group.com.ogcalendar.shared'"
echo "  3. Widget Extension Target: Configure signing"
echo ""
