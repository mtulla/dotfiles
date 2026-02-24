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
# 4. Core apt packages
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
    golang-go
    zsh-syntax-highlighting
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
# 5. Build dependencies (needed for pyenv, treesitter, etc.)
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
# 6. chezmoi
# -----------------------------------------------------------------------------
if command_exists chezmoi; then
    success "chezmoi already installed"
else
    info "Installing chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)" || error "Failed to install chezmoi"
fi

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
# 9. Oh My Zsh + plugins + Powerlevel10k
# -----------------------------------------------------------------------------
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
export ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"

if [[ -d "$ZSH" ]]; then
    success "Oh My Zsh already installed"
else
    info "Installing Oh My Zsh (unattended)..."
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || error "Failed to install Oh My Zsh"
fi

if [[ -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]]; then
    success "zsh-autosuggestions already installed"
else
    info "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" || error "Failed to install zsh-autosuggestions"
fi

# zsh-syntax-highlighting is installed via apt above; it's sourced by oh-my-zsh plugin

P10K_DIR="${ZSH_CUSTOM}/themes/powerlevel10k"
if [[ -d "$P10K_DIR" ]]; then
    success "Powerlevel10k already installed"
else
    info "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR" || error "Failed to install Powerlevel10k"
fi

# -----------------------------------------------------------------------------
# 10. pyenv + nvm
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
# 11. CLI tools (eza, lazygit, zoxide)
# -----------------------------------------------------------------------------

# eza — download binary from GitHub releases
if command_exists eza; then
    success "eza already installed"
else
    info "Installing eza..."
    TMPDIR="$(mktemp -d)"
    EZA_TAG="$(github_latest_tag eza-community/eza)"
    EZA_URL="https://github.com/eza-community/eza/releases/download/${EZA_TAG}/eza_${ARCH_ALT}-unknown-linux-gnu.tar.gz"
    if curl -fsSL -o "${TMPDIR}/eza.tar.gz" "$EZA_URL"; then
        tar -xzf "${TMPDIR}/eza.tar.gz" -C "$TMPDIR"
        sudo install -m 755 "${TMPDIR}/eza" /usr/local/bin/eza
        success "eza installed"
    else
        error "Failed to download eza. Install manually from https://github.com/eza-community/eza/releases"
    fi
    rm -rf "$TMPDIR"
fi

# lazygit — download binary from GitHub releases
if command_exists lazygit; then
    success "lazygit already installed"
else
    info "Installing lazygit..."
    TMPDIR="$(mktemp -d)"
    LG_TAG="$(github_latest_tag jesseduffield/lazygit)"
    LG_VER="${LG_TAG#v}"
    LG_URL="https://github.com/jesseduffield/lazygit/releases/download/${LG_TAG}/lazygit_${LG_VER}_Linux_${ARCH_ALT}.tar.gz"
    if curl -fsSL -o "${TMPDIR}/lazygit.tar.gz" "$LG_URL"; then
        tar -xzf "${TMPDIR}/lazygit.tar.gz" -C "$TMPDIR"
        sudo install "${TMPDIR}/lazygit" -D -t /usr/local/bin/
        success "lazygit installed"
    else
        error "Failed to download lazygit. Install manually from https://github.com/jesseduffield/lazygit/releases"
    fi
    rm -rf "$TMPDIR"
fi

# zoxide — available in default repos
if command_exists zoxide; then
    success "zoxide already installed"
else
    info "Installing zoxide..."
    sudo apt install -y zoxide || error "Failed to install zoxide"
fi

# -----------------------------------------------------------------------------
# 12. MesloLGS Nerd Font Mono
# -----------------------------------------------------------------------------
FONT_DIR="$HOME/.local/share/fonts"
if ls "$FONT_DIR"/MesloLGS* &>/dev/null 2>&1; then
    success "MesloLGS Nerd Font already installed"
else
    info "Installing MesloLGS Nerd Font..."
    mkdir -p "$FONT_DIR"
    TMPDIR="$(mktemp -d)"
    NF_TAG="$(github_latest_tag ryanoasis/nerd-fonts)"
    NF_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${NF_TAG}/Meslo.zip"
    if curl -fsSL -o "${TMPDIR}/Meslo.zip" "$NF_URL"; then
        unzip -o "${TMPDIR}/Meslo.zip" -d "$FONT_DIR"
        fc-cache -f "$FONT_DIR"
        success "MesloLGS Nerd Font installed"
    else
        error "Failed to download Nerd Font. Install manually from https://github.com/ryanoasis/nerd-fonts/releases"
    fi
    rm -rf "$TMPDIR"
fi

# -----------------------------------------------------------------------------
# 13. TPM (Tmux Plugin Manager)
# -----------------------------------------------------------------------------
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ -d "$TPM_DIR" ]]; then
    success "TPM already installed"
else
    info "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR" || error "Failed to install TPM"
fi

# -----------------------------------------------------------------------------
# 14. Node.js via nvm + npm global packages
# -----------------------------------------------------------------------------
# Source nvm for this session
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
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
# 15. Go tools + Rust tools + Python tools
# -----------------------------------------------------------------------------
# Ensure GOPATH/bin is in PATH
export GOPATH="${GOPATH:-$HOME/go}"
export PATH="$GOPATH/bin:$PATH"

# Go tools
if command_exists go; then
    GO_TOOLS=(
        "mvdan.cc/gofumpt@latest"
        "golang.org/x/tools/cmd/goimports@latest"
    )
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

# Rust tools (stylua)
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

# Python tools (ruff)
if command_exists ruff; then
    success "ruff already installed"
else
    if command_exists pip3; then
        info "Installing ruff via pip..."
        pip3 install --user ruff || error "Failed to install ruff"
    elif command_exists pip; then
        info "Installing ruff via pip..."
        pip install --user ruff || error "Failed to install ruff"
    else
        warn "pip not available, skipping ruff"
    fi
fi

# -----------------------------------------------------------------------------
# 16. SDKMAN
# -----------------------------------------------------------------------------
export SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"
if [[ -d "$SDKMAN_DIR" ]]; then
    success "SDKMAN already installed"
else
    info "Installing SDKMAN..."
    curl -s "https://get.sdkman.io" | bash || error "Failed to install SDKMAN"
fi

# Source SDKMAN for this session
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

# -----------------------------------------------------------------------------
# 17. Bazel
# -----------------------------------------------------------------------------
if command_exists bazel; then
    success "Bazel already installed"
else
    info "Installing Bazel via bazelisk..."
    TMPDIR="$(mktemp -d)"
    BZL_TAG="$(github_latest_tag bazelbuild/bazelisk)"
    BZL_URL="https://github.com/bazelbuild/bazelisk/releases/download/${BZL_TAG}/bazelisk-linux-${ARCH_GO}"
    if curl -fsSL -o "${TMPDIR}/bazelisk" "$BZL_URL"; then
        sudo install -m 755 "${TMPDIR}/bazelisk" /usr/local/bin/bazel
        success "Bazel (bazelisk) installed"
    else
        error "Failed to download bazelisk. Install manually from https://github.com/bazelbuild/bazelisk/releases"
    fi
    rm -rf "$TMPDIR"
fi

# -----------------------------------------------------------------------------
# 18. google-java-format
# -----------------------------------------------------------------------------
if command_exists google-java-format; then
    success "google-java-format already installed"
else
    info "Installing google-java-format..."
    TMPDIR="$(mktemp -d)"
    GJF_TAG="$(github_latest_tag google/google-java-format)"
    GJF_VER="${GJF_TAG#v}"
    GJF_URL="https://github.com/google/google-java-format/releases/download/${GJF_TAG}/google-java-format-${GJF_VER}-all-deps.jar"
    GJF_DIR="/usr/local/lib/google-java-format"
    if curl -fsSL -o "${TMPDIR}/google-java-format.jar" "$GJF_URL"; then
        sudo mkdir -p "$GJF_DIR"
        sudo install -m 644 "${TMPDIR}/google-java-format.jar" "$GJF_DIR/google-java-format.jar"
        sudo tee /usr/local/bin/google-java-format > /dev/null <<'WRAPPER'
#!/usr/bin/env bash
exec java -jar /usr/local/lib/google-java-format/google-java-format.jar "$@"
WRAPPER
        sudo chmod +x /usr/local/bin/google-java-format
        success "google-java-format installed"
    else
        error "Failed to download google-java-format. Install manually from https://github.com/google/google-java-format/releases"
    fi
    rm -rf "$TMPDIR"
fi

# -----------------------------------------------------------------------------
# 19. Set zsh as default shell
# -----------------------------------------------------------------------------
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
ZSH_PATH="$(which zsh)"
if [[ "$CURRENT_SHELL" == *zsh* ]]; then
    success "Default shell is already zsh"
else
    info "Setting zsh as default shell..."
    if grep -qF "$ZSH_PATH" /etc/shells; then
        chsh -s "$ZSH_PATH"
    else
        echo "$ZSH_PATH" | sudo tee -a /etc/shells
        chsh -s "$ZSH_PATH"
    fi
fi

# -----------------------------------------------------------------------------
# 20. Summary
# -----------------------------------------------------------------------------
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗"
echo "║            Setup Complete!                ║"
echo "╚══════════════════════════════════════════╝${RESET}"
echo ""
echo "Next steps:"
echo "  1. chezmoi init --apply <github-user>    # deploy dotfiles"
echo "  2. Open a new terminal                   # zsh + Powerlevel10k loads"
echo "  3. tmux, then prefix + I                 # install tmux plugins"
echo "  4. nvim                                  # Lazy.nvim auto-installs plugins"
echo "  5. Verify: fzf, eza, zoxide, lazygit     # test CLI tools"
echo ""
