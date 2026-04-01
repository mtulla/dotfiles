#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Linux (Debian/Ubuntu) Setup Script for Dotfiles
# Installs all dependencies for zsh + neovim + tmux + wezterm
# =============================================================================

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

info()    { echo -e "${BOLD}[INFO]${RESET} $*"; }
success() { echo -e "${GREEN}[OK]${RESET}   $*"; }
warn()    { echo -e "${YELLOW}[SKIP]${RESET} $*"; }
error()   { echo -e "${RED}[ERR]${RESET}  $*"; }

command_exists() { command -v "$1" &>/dev/null; }

# Helper to get latest GitHub release tag
github_latest_tag() {
    curl -fsSL "https://api.github.com/repos/$1/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/'
}

# Detect architecture
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64)  ARCH_DEB="amd64"; ARCH_ALT="x86_64"; ARCH_GO="amd64" ;;
    aarch64) ARCH_DEB="arm64"; ARCH_ALT="aarch64"; ARCH_GO="arm64" ;;
    *)       error "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# -----------------------------------------------------------------------------
# 1. Banner
# -----------------------------------------------------------------------------
echo -e "${BOLD}"
echo "╔══════════════════════════════════════════╗"
echo "║     Linux (Debian/Ubuntu) Dotfiles Setup ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${RESET}"

# -----------------------------------------------------------------------------
# 2. Prerequisites
# -----------------------------------------------------------------------------
if [[ ! -f /etc/debian_version ]]; then
    error "This script is for Debian/Ubuntu only."
    exit 1
fi

if [[ $EUID -eq 0 ]]; then
    error "Do not run this script as root. It will use sudo when needed."
    exit 1
fi

# Make sure sudo is available
if ! command_exists sudo; then
    error "sudo is required. Install it first: apt install sudo"
    exit 1
fi

# -----------------------------------------------------------------------------
# 3. Update package manager
# -----------------------------------------------------------------------------
info "Updating apt..."
sudo apt update

# -----------------------------------------------------------------------------
# 4. Neovim PPA (apt ships 0.6.1 on 22.04, need >= 0.8 for lazy.nvim)
# -----------------------------------------------------------------------------
if ! grep -rq "neovim-ppa" /etc/apt/sources.list.d/ 2>/dev/null; then
    info "Adding neovim unstable PPA..."
    sudo add-apt-repository -y ppa:neovim-ppa/unstable
    sudo apt-get update -qq
fi

# -----------------------------------------------------------------------------
# 5. Core apt packages
# -----------------------------------------------------------------------------
APT_PACKAGES=(
    zsh
    git
    curl
    neovim
    tmux
    fzf
    ripgrep
    unzip
    zip
    fontconfig
    golang-go
    zsh-syntax-highlighting
    pipx
)

info "Installing core apt packages..."
for pkg in "${APT_PACKAGES[@]}"; do
    if dpkg -s "$pkg" &>/dev/null; then
        success "$pkg already installed"
    else
        info "Installing $pkg..."
        sudo apt install -y "$pkg" || error "Failed to install $pkg"
    fi
done

# -----------------------------------------------------------------------------
# 6. Build dependencies (needed for pyenv, treesitter, etc.)
# -----------------------------------------------------------------------------
BUILD_DEPS=(
    build-essential
    libssl-dev
    zlib1g-dev
    libbz2-dev
    libreadline-dev
    libsqlite3-dev
    libncursesw5-dev
    xz-utils
    tk-dev
    libxml2-dev
    libxmlsec1-dev
    libffi-dev
    liblzma-dev
)

info "Installing build dependencies..."
for pkg in "${BUILD_DEPS[@]}"; do
    if dpkg -s "$pkg" &>/dev/null; then
        success "$pkg already installed"
    else
        info "Installing $pkg..."
        sudo apt install -y "$pkg" || error "Failed to install $pkg"
    fi
done

# -----------------------------------------------------------------------------
# 7. WezTerm
# -----------------------------------------------------------------------------
if command_exists wezterm; then
    success "WezTerm already installed"
else
    info "Installing WezTerm..."
    TMPDIR="$(mktemp -d)"
    WEZTERM_TAG="$(github_latest_tag wez/wezterm)"
    # Remove leading 'v' if present for the filename, but keep for URL
    WEZTERM_VER="${WEZTERM_TAG#v}"
    # WezTerm uses a date-based tag like 20240203-110809-5046fc22
    WEZTERM_DEB="wezterm-${WEZTERM_VER}.Ubuntu22.04.${ARCH_DEB}.deb"
    WEZTERM_URL="https://github.com/wez/wezterm/releases/download/${WEZTERM_TAG}/WezTerm-${WEZTERM_VER}-Ubuntu22.04.${ARCH_DEB}.deb"
    info "Downloading WezTerm ${WEZTERM_TAG}..."
    if curl -fsSL -o "${TMPDIR}/${WEZTERM_DEB}" "$WEZTERM_URL"; then
        sudo dpkg -i "${TMPDIR}/${WEZTERM_DEB}" || sudo apt install -f -y
        success "WezTerm installed"
    else
        # Try Ubuntu 24.04 variant
        WEZTERM_URL="https://github.com/wez/wezterm/releases/download/${WEZTERM_TAG}/WezTerm-${WEZTERM_VER}-Ubuntu24.04.${ARCH_DEB}.deb"
        if curl -fsSL -o "${TMPDIR}/${WEZTERM_DEB}" "$WEZTERM_URL"; then
            sudo dpkg -i "${TMPDIR}/${WEZTERM_DEB}" || sudo apt install -f -y
            success "WezTerm installed"
        else
            error "Failed to download WezTerm. Install manually from https://github.com/wez/wezterm/releases"
        fi
    fi
    rm -rf "$TMPDIR"
fi

# -----------------------------------------------------------------------------
# 8. Rust via rustup
# -----------------------------------------------------------------------------
if command_exists rustup; then
    success "Rust (rustup) already installed"
else
    info "Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # shellcheck disable=SC1091
    source "$HOME/.cargo/env"
fi

# -----------------------------------------------------------------------------
# 9. pyenv + nvm
# -----------------------------------------------------------------------------
export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
if command_exists pyenv || [[ -d "$PYENV_ROOT" ]]; then
    success "pyenv already installed"
else
    info "Installing pyenv..."
    curl -fsSL https://pyenv.run | bash
fi
# Add pyenv to PATH for this session
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [[ -d "$NVM_DIR" ]] && [[ -s "$NVM_DIR/nvm.sh" ]]; then
    success "nvm already installed"
else
    info "Installing nvm..."
    mkdir -p "$NVM_DIR"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
fi

# -----------------------------------------------------------------------------
# 10. CLI tools (bat, zoxide — eza, lazygit, fonts handled by chezmoi external)
# -----------------------------------------------------------------------------

# bat
if command_exists bat || command_exists batcat; then
    success "bat already installed"
else
    info "Installing bat..."
    sudo apt install -y bat || error "Failed to install bat"
fi

# zoxide — available in default repos
if command_exists zoxide; then
    success "zoxide already installed"
else
    info "Installing zoxide..."
    sudo apt install -y zoxide || error "Failed to install zoxide"
fi

# -----------------------------------------------------------------------------
# 11. Node.js via nvm + npm global packages
# -----------------------------------------------------------------------------
# Source nvm for this session (nvm.sh uses unbound variables)
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
set +u
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if command_exists node; then
    success "Node.js already installed ($(node --version))"
else
    if command_exists nvm; then
        info "Installing Node.js LTS via nvm..."
        nvm install --lts
        nvm use --lts
    else
        warn "nvm not available, skipping Node.js install"
    fi
fi
set -u

if command_exists npm; then
    NPM_GLOBALS=(prettier fixjson)
    for pkg in "${NPM_GLOBALS[@]}"; do
        if npm list -g "$pkg" &>/dev/null; then
            success "npm: $pkg already installed"
        else
            info "Installing npm global: $pkg..."
            npm install -g "$pkg" || error "Failed to install $pkg"
        fi
    done
else
    warn "npm not available, skipping global npm packages"
fi

# -----------------------------------------------------------------------------
# 12. Go tools + Rust tools + Python tools
# -----------------------------------------------------------------------------
# Ensure GOPATH/bin is in PATH
export GOPATH="${GOPATH:-$HOME/go}"
export PATH="$GOPATH/bin:$PATH"

# Go tools (version-aware: latest requires Go 1.22+)
if command_exists go; then
    go_ver="$(go env GOVERSION)"  # e.g., go1.18.1
    go_minor="${go_ver#go1.}"
    go_minor="${go_minor%%.*}"

    if (( go_minor >= 22 )); then
        GO_TOOLS=(
            "mvdan.cc/gofumpt@latest"
            "golang.org/x/tools/cmd/goimports@latest"
        )
    else
        warn "Go ${go_ver} is old; installing pinned compatible tool versions"
        GO_TOOLS=(
            "mvdan.cc/gofumpt@v0.4.0"
            "golang.org/x/tools/cmd/goimports@v0.14.0"
        )
    fi

    for tool in "${GO_TOOLS[@]}"; do
        tool_name="$(basename "${tool%%@*}")"
        if command_exists "$tool_name"; then
            success "go: $tool_name already installed"
        else
            info "Installing go tool: $tool_name..."
            go install "$tool" || error "Failed to install $tool_name"
        fi
    done
else
    warn "Go not available, skipping Go tools"
fi

# Rust tools (stylua, tree-sitter-cli)
# Ensure cargo is in PATH
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

if command_exists stylua; then
    success "stylua already installed"
else
    if command_exists cargo; then
        info "Installing stylua via cargo..."
        cargo install stylua || error "Failed to install stylua"
    else
        warn "cargo not available, skipping stylua"
    fi
fi

if command_exists tree-sitter; then
    success "tree-sitter-cli already installed"
else
    if command_exists cargo; then
        info "Installing tree-sitter-cli via cargo..."
        cargo install tree-sitter-cli || error "Failed to install tree-sitter-cli"
    else
        warn "cargo not available, skipping tree-sitter-cli"
    fi
fi

# Python tools (ruff via pipx)
if command_exists ruff; then
    success "ruff already installed"
else
    if command_exists pipx; then
        info "Installing ruff via pipx..."
        export PIPX_HOME="${PIPX_HOME:-$HOME/.local/pipx}"
        export PIPX_BIN_DIR="${PIPX_BIN_DIR:-$HOME/.local/bin}"
        pipx install ruff || error "Failed to install ruff"
    else
        warn "pipx not available, skipping ruff"
    fi
fi

# -----------------------------------------------------------------------------
# 13. SDKMAN + Java
# -----------------------------------------------------------------------------
export SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"
if [[ -d "$SDKMAN_DIR" ]]; then
    success "SDKMAN already installed"
else
    info "Installing SDKMAN..."
    curl -s "https://get.sdkman.io" | bash || error "Failed to install SDKMAN"
fi

# Source SDKMAN for this session (sdkman-init.sh uses unbound variables)
set +u
# shellcheck disable=SC1091
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

if command_exists java; then
    success "Java already installed ($(java -version 2>&1 | head -1))"
else
    if command_exists sdk; then
        info "Installing Java via SDKMAN..."
        sdk install java 25.0.2-zulu || error "Failed to install Java"
    else
        warn "SDKMAN not available, skipping Java install"
    fi
fi
set -u

# -----------------------------------------------------------------------------
# 14. google-java-format
# -----------------------------------------------------------------------------
if command_exists google-java-format; then
    success "google-java-format already installed"
else
    info "Installing google-java-format..."
    TMPDIR="$(mktemp -d)"
    GJF_TAG="$(github_latest_tag google/google-java-format)"
    GJF_VER="${GJF_TAG#v}"
    GJF_URL="https://github.com/google/google-java-format/releases/download/${GJF_TAG}/google-java-format-${GJF_VER}-all-deps.jar"
    GJF_DIR="$HOME/.local/lib/google-java-format"
    if curl -fsSL -o "${TMPDIR}/google-java-format.jar" "$GJF_URL"; then
        mkdir -p "$GJF_DIR"
        install -m 644 "${TMPDIR}/google-java-format.jar" "$GJF_DIR/google-java-format.jar"
        mkdir -p "$HOME/.local/bin"
        cat > "$HOME/.local/bin/google-java-format" <<'WRAPPER'
#!/usr/bin/env bash
exec java -jar "$HOME/.local/lib/google-java-format/google-java-format.jar" "$@"
WRAPPER
        chmod +x "$HOME/.local/bin/google-java-format"
        success "google-java-format installed"
    else
        error "Failed to download google-java-format. Install manually from https://github.com/google/google-java-format/releases"
    fi
    rm -rf "$TMPDIR"
fi

# -----------------------------------------------------------------------------
# 15. Claude Code CLI
# -----------------------------------------------------------------------------
if command_exists claude; then
    success "Claude Code already installed"
else
    info "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash || error "Failed to install Claude Code"
fi

# -----------------------------------------------------------------------------
# 16. Set zsh as default shell
# -----------------------------------------------------------------------------
CURRENT_SHELL="$(getent passwd "$(whoami)" | cut -d: -f7)"
ZSH_PATH="$(which zsh)"
if [[ "$CURRENT_SHELL" == *zsh* ]]; then
    success "Default shell is already zsh"
else
    info "Setting zsh as default shell..."
    if ! grep -qF "$ZSH_PATH" /etc/shells; then
        echo "$ZSH_PATH" | sudo tee -a /etc/shells
    fi
    # Support non-interactive chsh in Docker tests
    if [[ -n "${CHEZMOI_TEST_PASSWORD:-}" ]]; then
        echo "$CHEZMOI_TEST_PASSWORD" | chsh -s "$ZSH_PATH"
    else
        chsh -s "$ZSH_PATH"
    fi
fi

# -----------------------------------------------------------------------------
# 17. Summary
# -----------------------------------------------------------------------------
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗"
echo "║            Setup Complete!                ║"
echo "╚══════════════════════════════════════════╝${RESET}"
echo ""
echo "Next steps:"
echo "  1. chezmoi init --apply <github-user>    # deploy dotfiles + external deps"
echo "  2. Open a new terminal                   # zsh + Powerlevel10k loads"
echo "  3. tmux, then prefix + I                 # install tmux plugins"
echo "  4. nvim                                  # Lazy.nvim auto-installs plugins"
echo "  5. Verify: fzf, eza, zoxide, lazygit     # test CLI tools"
echo ""
