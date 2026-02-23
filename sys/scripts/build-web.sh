#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
FLUTTER_DIR="$PROJECT_ROOT/sys/frontend/user/mobile/serifu"
NGINX_WEB_DIR="$PROJECT_ROOT/sys/backend/nginx/web"

echo "=== Serifu Web Build ==="

# Navigate to Flutter project
cd "$FLUTTER_DIR"

# Clean previous build
echo "[1/4] Cleaning previous build..."
flutter clean

# Get dependencies
echo "[2/4] Getting dependencies..."
flutter pub get

# Build web release
echo "[3/4] Building Flutter web (release)..."
flutter build web --release --base-href /

# Copy build output to nginx directory
echo "[4/4] Copying build to nginx/web/..."
rm -rf "$NGINX_WEB_DIR"
cp -r "$FLUTTER_DIR/build/web" "$NGINX_WEB_DIR"

echo ""
echo "=== Build complete ==="
echo "Output: $NGINX_WEB_DIR"
echo ""
echo "To deploy, run:"
echo "  cd $PROJECT_ROOT/sys/backend && docker-compose -f docker-compose.prod.yml up --build -d"
