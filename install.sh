#!/usr/bin/env bash

set -euo pipefail

# Constants
BINARY_NAME="llogin"
REPO_OWNER="ba3a-g"
REPO_NAME="LPU-Wireless-Autologin"
GITHUB_BASE="https://github.com/${REPO_OWNER}/${REPO_NAME}"
GITHUB_API="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}"

# Print error message and exit
error() {
    echo "Error: $1" >&2
    exit 1
}

# Get latest version from GitHub API
get_latest_version() {
    local latest_version
    latest_version=$(curl -fsSL "${GITHUB_API}/releases/latest" | 
        grep '"tag_name":' | 
        sed -E 's/.*"([^"]+)".*/\1/' |
        sed 's/^v//')
    
    if [ -z "$latest_version" ]; then
        error "Failed to fetch latest version"
    fi
    echo "$latest_version"
}

# Initialize version
VERSION="${1:-$(get_latest_version)}"

# Detect OS and architecture
detect_platform() {
    OS="$(uname -s)"
    ARCH="$(uname -m)"

    case "$OS" in
        Linux)     OS="linux" ;;
        Darwin)    OS="macos" ;;
        MINGW*|MSYS*|CYGWIN*|Windows_NT)
            OS="windows"
            ;;
        *)         error "Unsupported operating system: $OS" ;;
    esac

    case "$ARCH" in
        x86_64|amd64)      ARCH="x86_64" ;;
        arm64|aarch64)     ARCH="aarch64" ;;
        *)                 error "Unsupported architecture: $ARCH" ;;
    esac

    # Force x86_64 for Windows as that's what the workflow builds
    if [ "$OS" = "windows" ]; then
        ARCH="x86_64"
    fi
}

# Download and install the binary
install_binary() {
    local extension=""
    [ "$OS" = "windows" ] && extension=".exe"
    
    local binary_name="${BINARY_NAME}-${VERSION}-${OS}-${ARCH}${extension}"
    local download_url="${GITHUB_BASE}/releases/download/v${VERSION}/${binary_name}"
    local temp_dir
    temp_dir="$(mktemp -d)"
    local temp_file="${temp_dir}/${binary_name}"

    echo "Downloading ${BINARY_NAME} v${VERSION} for ${OS}-${ARCH}..."
    
    # Check if release exists
    if ! curl -fsSL -I "$download_url" >/dev/null 2>&1; then
        rm -rf "$temp_dir"
        error "Release v${VERSION} not found or asset unavailable"
    fi

    if ! curl -fsSL "$download_url" -o "$temp_file"; then
        rm -rf "$temp_dir"
        error "Failed to download binary"
    fi

    chmod +x "$temp_file"

    # Install to appropriate location based on OS
    if [ "$OS" = "windows" ]; then
        local install_dir="$HOME/bin"
        mkdir -p "$install_dir"
        mv "$temp_file" "$install_dir/${binary_name}"
        # Create symlink for Windows
        (cd "$install_dir" && \
         rm -f "${BINARY_NAME}${extension}" && \
         ln -s "${binary_name}" "${BINARY_NAME}${extension}")
        echo "Installed to: $install_dir/${binary_name}"
        echo "Created symlink: $install_dir/${BINARY_NAME}${extension}"
        echo "Make sure $install_dir is in your PATH"
    else
        # For Unix-like systems
        sudo mv "$temp_file" "/usr/local/bin/${binary_name}"
        # Create symlink
        sudo ln -sf "/usr/local/bin/${binary_name}" "/usr/local/bin/${BINARY_NAME}"
        echo "Installed to: /usr/local/bin/${binary_name}"
        echo "Created symlink: /usr/local/bin/${BINARY_NAME}"
    fi

    rm -rf "$temp_dir"
}

# Verify installation
verify_installation() {
    if command -v "$BINARY_NAME" >/dev/null; then
        echo "✓ Installation verified: $(command -v "$BINARY_NAME")"
        echo "Version: v${VERSION}"
    else
        error "Installation verification failed. Please check your PATH"
    fi
}

# Main execution
main() {
    echo "Installing ${BINARY_NAME} v${VERSION}..."
    
    if ! command -v curl >/dev/null; then
        error "curl is required but not installed"
    fi

    detect_platform
    install_binary
    verify_installation
    echo "Installation completed successfully!"
}

main