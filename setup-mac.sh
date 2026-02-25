#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# macOS Setup Script for Dotfiles
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

# -----------------------------------------------------------------------------
# 1. Banner
# -----------------------------------------------------------------------------
echo -e "${BOLD}"
echo "╔══════════════════════════════════════════╗"
echo "║       macOS Dotfiles Setup Script        ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${RESET}"

# -----------------------------------------------------------------------------
# 2. Prerequisites
# -----------------------------------------------------------------------------
if [[ "$(uname)" != "Darwin" ]]; then
    error "This script is for macOS only."
    exit 1
fi

if ! command_exists brew; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
else
    success "Homebrew already installed"
fi

# Ensure Xcode CLT is installed (needed for compilation)
if ! xcode-select -p &>/dev/null; then
    info "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Press Enter after Xcode CLT installation completes..."
    read -r
else
    success "Xcode Command Line Tools already installed"
fi

# -----------------------------------------------------------------------------
# 3. Update Homebrew
# -----------------------------------------------------------------------------
info "Updating Homebrew..."
brew update

# -----------------------------------------------------------------------------
# 4. Core brew packages
# -----------------------------------------------------------------------------
BREW_PACKAGES=(
    zsh
    git
    neovim
    tmux
    fzf
    ripgrep
    golang
    zsh-syntax-highlighting
)

info "Installing core brew packages..."
for pkg in "${BREW_PACKAGES[@]}"; do
    if brew list "$pkg" &>/dev/null; then
        success "$pkg already installed"
    else
        info "Installing $pkg..."
        brew install "$pkg" || error "Failed to install $pkg"
    fi
done

# -----------------------------------------------------------------------------
# 5. Build dependencies
# -----------------------------------------------------------------------------
BUILD_DEPS=(openssl readline sqlite3 xz zlib tcl-tk)

info "Installing build dependencies..."
for pkg in "${BUILD_DEPS[@]}"; do
    if brew list "$pkg" &>/dev/null; then
        success "$pkg already installed"
    else
        info "Installing $pkg..."
        brew install "$pkg" || error "Failed to install $pkg"
    fi
done

# -----------------------------------------------------------------------------
# 6. chezmoi
# -----------------------------------------------------------------------------
if command_exists chezmoi; then
    success "chezmoi already installed"
else
    info "Installing chezmoi..."
    brew install chezmoi
fi

# -----------------------------------------------------------------------------
# 7. WezTerm
# -----------------------------------------------------------------------------
if brew list --cask wezterm &>/dev/null || [[ -d "/Applications/WezTerm.app" ]]; then
    success "WezTerm already installed"
else
    info "Installing WezTerm..."
    brew install --cask wezterm || error "Failed to install WezTerm"
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

# zsh-syntax-highlighting is installed via brew above; it's sourced by oh-my-zsh plugin

if brew list powerlevel10k &>/dev/null; then
    success "Powerlevel10k already installed"
else
    info "Installing Powerlevel10k..."
    brew install powerlevel10k
fi
# Symlink into oh-my-zsh themes if not already there
P10K_THEME_DIR="${ZSH_CUSTOM}/themes/powerlevel10k"
if [[ ! -d "$P10K_THEME_DIR" ]]; then
    P10K_BREW_DIR="$(brew --prefix)/share/powerlevel10k"
    if [[ -d "$P10K_BREW_DIR" ]]; then
        ln -s "$P10K_BREW_DIR" "$P10K_THEME_DIR"
        success "Symlinked Powerlevel10k into Oh My Zsh themes"
    fi
fi

# -----------------------------------------------------------------------------
# 10. pyenv + nvm
# -----------------------------------------------------------------------------
if command_exists pyenv; then
    success "pyenv already installed"
else
    info "Installing pyenv..."
    brew install pyenv
fi

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
CLI_TOOLS=(bat eza lazygit zoxide)

for tool in "${CLI_TOOLS[@]}"; do
    if brew list "$tool" &>/dev/null; then
        success "$tool already installed"
    else
        info "Installing $tool..."
        brew install "$tool" || error "Failed to install $tool"
    fi
done

# -----------------------------------------------------------------------------
# 12. MesloLGS Nerd Font Mono
# -----------------------------------------------------------------------------
if brew list --cask font-meslo-lg-nerd-font &>/dev/null; then
    success "MesloLGS Nerd Font already installed"
else
    info "Installing MesloLGS Nerd Font..."
    brew install --cask font-meslo-lg-nerd-font || error "Failed to install Nerd Font"
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

# Also install via brew for consistency on Mac
for tool in gofumpt goimports; do
    if brew list "$tool" &>/dev/null; then
        success "brew: $tool already installed"
    else
        info "Installing $tool via brew..."
        brew install "$tool" || error "Failed to install $tool via brew"
    fi
done

# Rust tools (stylua)
if command_exists stylua; then
    success "stylua already installed"
else
    if command_exists cargo; then
        info "Installing stylua via cargo..."
        cargo install stylua || error "Failed to install stylua"
    else
        info "Installing stylua via brew..."
        brew install stylua || error "Failed to install stylua"
    fi
fi

# Python tools (ruff)
if command_exists ruff; then
    success "ruff already installed"
else
    info "Installing ruff..."
    brew install ruff || error "Failed to install ruff"
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
if brew list bazelisk &>/dev/null || command_exists bazel; then
    success "Bazel (bazelisk) already installed"
else
    info "Installing Bazel via bazelisk..."
    brew install bazelisk || error "Failed to install bazelisk"
fi

# -----------------------------------------------------------------------------
# 18. google-java-format
# -----------------------------------------------------------------------------
if brew list google-java-format &>/dev/null; then
    success "google-java-format already installed"
else
    info "Installing google-java-format..."
    brew install google-java-format || error "Failed to install google-java-format"
fi

# -----------------------------------------------------------------------------
# 19. Set zsh as default shell
# -----------------------------------------------------------------------------
CURRENT_SHELL="$(dscl . -read /Users/"$USER" UserShell | awk '{print $2}')"
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
