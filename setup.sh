#!/bin/bash

# ============================================================
# OG Calendar - Project Setup Script
# ============================================================
# This script generates the Xcode project using xcodegen
# and sets up the App Group entitlements.
#
# Prerequisites:
#   - Xcode 16+
#   - xcodegen (install: brew install xcodegen)
#
# Usage:
#   ./setup.sh
# ============================================================

set -e

WORKSPACE_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🔧 OG Calendar - Project Setup"
echo "================================"
echo ""

# Check xcodegen
if ! command -v xcodegen &> /dev/null; then
    echo "⚠️  xcodegen not found. Installing..."
    brew install xcodegen
fi

# Generate Xcode project
echo "📦 Generating Xcode project..."
cd "${WORKSPACE_DIR}"
xcodegen generate

if [ $? -eq 0 ]; then
    echo "✅ Xcode project generated successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Open OGCalendar.xcodeproj in Xcode"
    echo "   2. Select your Development Team in Signing & Capabilities"
    echo "   3. Add App Group 'group.com.ogcalendar.shared' to both targets"
    echo "   4. Build & Run (Cmd+R)"
    echo ""
    echo "🛠  To build IPA from command line:"
    echo "   ./build/build_ipa.sh -t YOUR_TEAM_ID"
    echo ""
else
    echo "❌ Failed to generate Xcode project"
    exit 1
fi
