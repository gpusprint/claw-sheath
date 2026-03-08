#!/bin/bash
set -e

# Claw Sheath Installation Script

echo "Installing Claw Sheath..."

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     machine=linux;;
    Darwin*)    machine=darwin;;
    *)          machine="UNKNOWN"
esac

if [ "$machine" = "UNKNOWN" ]; then
    echo "Error: OS ${OS} is not supported. Only macOS and Linux are supported."
    exit 1
fi

# Detect Architecture
ARCH="$(uname -m)"
case "${ARCH}" in
    x86_64)     arch=amd64;;
    amd64)      arch=amd64;;
    arm64)      arch=arm64;;
    aarch64)    arch=arm64;;
    *)          arch="UNKNOWN"
esac

if [ "$arch" = "UNKNOWN" ]; then
    echo "Error: Architecture ${ARCH} is not supported."
    exit 1
fi

echo "Detected OS: $machine, Architecture: $arch"

# Define directories
INSTALL_DIR="$HOME/.claw-sheath"

echo "Cleaning previous installation (if any)..."
rm -rf "$INSTALL_DIR"

# Create installation directory
mkdir -p "$INSTALL_DIR"

GITHUB_REPO="gpusprint/claw-sheath"

echo "Retrieving Claw Sheath repository files..."
if [ -d "src" ] && [ -f "config.yml" ]; then
    echo "Using local repository files..."
    cp -R src "$INSTALL_DIR/"
    cp config.yml "$INSTALL_DIR/"
    if [ -f "README.md" ]; then
        cp README.md "$INSTALL_DIR/"
    fi
else
    echo "Cloning from GitHub ($GITHUB_REPO)..."
    # Clone to a temporary directory
    TMP_DIR=$(mktemp -d)
    git clone --depth 1 "https://github.com/${GITHUB_REPO}.git" "$TMP_DIR"
    
    cp -R "$TMP_DIR/src" "$INSTALL_DIR/"
    cp "$TMP_DIR/config.yml" "$INSTALL_DIR/"
    if [ -f "$TMP_DIR/README.md" ]; then
        cp "$TMP_DIR/README.md" "$INSTALL_DIR/"
    fi
    rm -rf "$TMP_DIR"
fi


BIN_TARGET="sheath-verifier-${machine}-${arch}"

echo "Downloading sheath-verifier binary for ${machine}/${arch}..."
DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/latest/download/${BIN_TARGET}"

if ! curl -fsSL -o "$INSTALL_DIR/sheath-verifier" "$DOWNLOAD_URL"; then
    echo "Error: Failed to download $DOWNLOAD_URL"
    echo "Please check your internet connection or the repository."
    # Fallback to local build if go is installed and src directory exists
    if [ -d "$INSTALL_DIR/src/verifier" ] && command -v go >/dev/null 2>&1; then
        echo "Attempting to build locally as fallback..."
        cd "$INSTALL_DIR/src/verifier"
        go build -o "$INSTALL_DIR/sheath-verifier" main.go
        cd - > /dev/null
    else
        exit 1
    fi
else
    chmod +x "$INSTALL_DIR/sheath-verifier"
fi

# Set permissions
chmod +x "$INSTALL_DIR/src/cs"
chmod +x "$INSTALL_DIR/src/sheath-env.sh"

echo ""
echo "Installation complete!"
echo "--------------------------------------------------------"
echo "Claw Sheath has been installed to: $INSTALL_DIR"
echo ""
echo "Your configuration file is located at:"
echo "  $INSTALL_DIR/config.yml"
echo ""
# Detect shell
USER_SHELL=$(basename "$SHELL")
PROFILE_FILE=""

case "$USER_SHELL" in
    zsh)
        PROFILE_FILE="~/.zshrc"
        ;;
    bash)
        # Check if .bashrc or .bash_profile exists, prefer .bashrc
        if [ -f "$HOME/.bashrc" ]; then
            PROFILE_FILE="~/.bashrc"
        elif [ -f "$HOME/.bash_profile" ]; then
            PROFILE_FILE="~/.bash_profile"
        else
            PROFILE_FILE="~/.bashrc"
        fi
        ;;
    fish)
        PROFILE_FILE="~/.config/fish/config.fish"
        ;;
    *)
        PROFILE_FILE="~/.profile"
        ;;
esac

echo "To use the 'cs' wrapper command, please add the 'src' directory to your PATH."
echo "Add the following line to your $PROFILE_FILE:"

if [ "$USER_SHELL" = "fish" ]; then
    echo "  set -gx PATH \"\$HOME/.claw-sheath/src\" \$PATH"
else
    echo "  export PATH=\"\$HOME/.claw-sheath/src:\$PATH\""
fi

echo ""
echo "After adding it, restart your terminal or reload your shell profile:"
echo "  source $PROFILE_FILE"
echo ""
echo "Then, you can protect your AI agents simply by prefixing their commands:"
echo "  cs openclaw agent --agent main --message \"Run rm important.txt\""
echo "  cs claude"
echo "--------------------------------------------------------"
echo "Stay productive. Stay safe."
