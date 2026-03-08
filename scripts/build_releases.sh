#!/bin/bash
set -euo pipefail

# Repo root (always run from repo root regardless of where the script lives)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERIFIER_DIR="$REPO_ROOT/src/verifier"
OUT_DIR="$REPO_ROOT/releases"

mkdir -p "$OUT_DIR"

# Build matrix
OS_LIST=("linux" "darwin")
ARCH_LIST=("amd64" "arm64")

# Embed version from git tag if available
VERSION="${GITHUB_REF_NAME:-$(git -C "$REPO_ROOT" describe --tags --always 2>/dev/null || echo "dev")}"
LDFLAGS="-s -w -X main.Version=$VERSION"

echo "Building Claw Sheath Verifier $VERSION for multiple platforms..."
echo ""

cd "$VERIFIER_DIR"

# Ensure dependencies are available
go mod download

for GOOS in "${OS_LIST[@]}"; do
    for GOARCH in "${ARCH_LIST[@]}"; do
        BIN_NAME="sheath-verifier-$GOOS-$GOARCH"
        OUT_PATH="$OUT_DIR/$BIN_NAME"
        echo "  Building $GOOS/$GOARCH -> releases/$BIN_NAME"
        GOOS=$GOOS GOARCH=$GOARCH go build -trimpath -ldflags "$LDFLAGS" -o "$OUT_PATH" .
    done
done

echo ""
echo "Builds completed successfully:"
ls -lh "$OUT_DIR"/sheath-verifier-* | awk '{print "  " $NF, $5}'
