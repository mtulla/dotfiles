#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# macOS Setup Script for Dotfiles
# Installs all dependencies for zsh + neovim + tmux
#
# Each install is isolated — a failure in one does not block the rest.
# =============================================================================

# === PREAMBLE ================================================================

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

# Banner
echo -e "${BOLD}"
echo "╔══════════════════════════════════════════╗"
echo "║       macOS Dotfiles Setup Script        ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${RESET}"

# Prerequisites
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

# === RUNNER INFRASTRUCTURE ===================================================

FAILED_INSTALLS=()
SUCCEEDED_INSTALLS=()

run_install() {
    local func_name="$1"
    local description="${2:-$func_name}"
    echo ""
    info "--- ${description} ---"
    if "$func_name"; then
        SUCCEEDED_INSTALLS+=("$description")
    else
        error "FAILED: ${description}"
        FAILED_INSTALLS+=("$description")
    fi
}

print_summary() {
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════╗"
    if [[ ${#FAILED_INSTALLS[@]} -eq 0 ]]; then
        echo "║            Setup Complete!                ║"
    else
        echo "║         Setup Completed with Errors       ║"
    fi
    echo -e "╚══════════════════════════════════════════╝${RESET}"
    echo ""

    if [[ ${#SUCCEEDED_INSTALLS[@]} -gt 0 ]]; then
        echo -e "${GREEN}Succeeded:${RESET}"
        for item in "${SUCCEEDED_INSTALLS[@]}"; do
            echo -e "  ${GREEN}✓${RESET} ${item}"
        done
        echo ""
    fi

    if [[ ${#FAILED_INSTALLS[@]} -gt 0 ]]; then
        echo -e "${RED}Failed:${RESET}"
        for item in "${FAILED_INSTALLS[@]}"; do
            echo -e "  ${RED}✗${RESET} ${item}"
        done
        echo ""
        echo "Re-run the script to retry failed installs."
        echo ""
    fi

    echo "Next steps:"
    echo "  1. Open a new terminal                   # zsh + Powerlevel10k loads"
    echo "  2. tmux, then prefix + I                 # install tmux plugins"
    echo "  3. nvim                                  # Lazy.nvim auto-installs plugins"
    echo "  4. Verify: fzf, eza, zoxide, lazygit     # test CLI tools"
    echo ""

    if [[ ${#FAILED_INSTALLS[@]} -gt 0 ]]; then
        return 1
    fi
}

# === INSTALL FUNCTIONS =======================================================

update_brew() {
    info "Updating Homebrew..."
    brew update || return 1
}

install_core_packages() {
    local packages=(
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
    for pkg in "${packages[@]}"; do
        if brew list "$pkg" &>/dev/null; then
            success "$pkg already installed"
        else
            info "Installing $pkg..."
            brew install "$pkg" || return 1
        fi
    done
}

install_build_deps() {
    local packages=(openssl readline sqlite3 xz zlib tcl-tk)

    info "Installing build dependencies..."
    for pkg in "${packages[@]}"; do
        if brew list "$pkg" &>/dev/null; then
            success "$pkg already installed"
        else
            info "Installing $pkg..."
            brew install "$pkg" || return 1
        fi
    done
}

install_pipx() {
    if command_exists pipx; then
        success "pipx already installed"
    else
        info "Installing pipx..."
        brew install pipx || return 1
    fi
}

install_chezmoi() {
    if command_exists chezmoi; then
        success "chezmoi already installed"
    else
        info "Installing chezmoi..."
        brew install chezmoi || return 1
    fi
}

install_rust() {
    if command_exists rustup; then
        success "Rust (rustup) already installed"
    else
        info "Installing Rust via rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || return 1
    fi
    # Always ensure cargo is in PATH for this session
    # shellcheck disable=SC1091
    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
}

install_ohmyzsh() {
    export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
    export ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"

    if [[ -d "$ZSH" ]]; then
        success "Oh My Zsh already installed"
    else
        info "Installing Oh My Zsh (unattended)..."
        RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || return 1
    fi
}

install_pyenv() {
    if command_exists pyenv; then
        success "pyenv already installed"
    else
        info "Installing pyenv..."
        brew install pyenv || return 1
    fi
}

install_nvm() {
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

    if [[ -d "$NVM_DIR" ]] && [[ -s "$NVM_DIR/nvm.sh" ]]; then
        success "nvm already installed"
    else
        info "Installing nvm..."
        mkdir -p "$NVM_DIR"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash || return 1
    fi
    # Always source nvm for this session
    # Temporarily disable nounset — nvm.sh references unbound variables
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        set +u
        # shellcheck disable=SC1091
        \. "$NVM_DIR/nvm.sh"
        set -u
    fi
}

install_bat() {
    if brew list bat &>/dev/null; then
        success "bat already installed"
    else
        info "Installing bat..."
        brew install bat || return 1
    fi
}

install_eza() {
    if brew list eza &>/dev/null; then
        success "eza already installed"
    else
        info "Installing eza..."
        brew install eza || return 1
    fi
}

install_lazygit() {
    if brew list lazygit &>/dev/null; then
        success "lazygit already installed"
    else
        info "Installing lazygit..."
        brew install lazygit || return 1
    fi
}

install_zoxide() {
    if brew list zoxide &>/dev/null; then
        success "zoxide already installed"
    else
        info "Installing zoxide..."
        brew install zoxide || return 1
    fi
}

install_meslo_font() {
    if brew list --cask font-meslo-lg-nerd-font &>/dev/null; then
        success "MesloLGS Nerd Font already installed"
    else
        info "Installing MesloLGS Nerd Font..."
        brew install --cask font-meslo-lg-nerd-font || return 1
    fi
}

install_tpm() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [[ -d "$tpm_dir" ]]; then
        success "TPM already installed"
    else
        info "Installing TPM..."
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir" || return 1
    fi
}

install_sdkman() {
    export SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"

    if [[ -d "$SDKMAN_DIR" ]]; then
        success "SDKMAN already installed"
    else
        info "Installing SDKMAN..."
        curl -s "https://get.sdkman.io" | bash || return 1
    fi
    # Temporarily disable nounset — sdkman-init.sh references $ZSH_VERSION
    # which is unbound in bash
    if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
        set +u
        # shellcheck disable=SC1091
        source "$SDKMAN_DIR/bin/sdkman-init.sh"
        set -u
    fi
}

install_bazel() {
    if brew list bazelisk &>/dev/null || command_exists bazel; then
        success "Bazel (bazelisk) already installed"
    else
        info "Installing Bazel via bazelisk..."
        brew install bazelisk || return 1
    fi
}

install_zsh_autosuggestions() {
    export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
    export ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"

    if [[ -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]]; then
        success "zsh-autosuggestions already installed"
    else
        info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" || return 1
    fi
}

install_powerlevel10k() {
    export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
    export ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"

    if brew list powerlevel10k &>/dev/null; then
        success "Powerlevel10k already installed"
    else
        info "Installing Powerlevel10k..."
        brew install powerlevel10k || return 1
    fi
    # Symlink into oh-my-zsh themes if not already there
    local p10k_theme_dir="${ZSH_CUSTOM}/themes/powerlevel10k"
    if [[ ! -d "$p10k_theme_dir" ]]; then
        local p10k_brew_dir
        p10k_brew_dir="$(brew --prefix)/share/powerlevel10k"
        if [[ -d "$p10k_brew_dir" ]]; then
            ln -s "$p10k_brew_dir" "$p10k_theme_dir"
            success "Symlinked Powerlevel10k into Oh My Zsh themes"
        fi
    fi
}

install_node() {
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    # Temporarily disable nounset — nvm references unbound variables
    set +u
    # shellcheck disable=SC1091
    [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"

    if command_exists node; then
        success "Node.js already installed ($(node --version))"
        set -u
    else
        if command_exists nvm; then
            info "Installing Node.js LTS via nvm..."
            nvm install --lts || { set -u; return 1; }
            nvm use --lts || { set -u; return 1; }
            set -u
        else
            set -u
            warn "nvm not available, skipping Node.js install"
            return 1
        fi
    fi
}

install_go_tools() {
    export GOPATH="${GOPATH:-$HOME/go}"
    export PATH="$GOPATH/bin:$PATH"

    if ! command_exists go; then
        warn "Go not available, skipping Go tools"
        return 1
    fi

    # Determine Go minor version to pick compatible tool versions
    local go_ver go_minor
    go_ver="$(go env GOVERSION)"  # e.g., go1.18.1
    go_minor="${go_ver#go1.}"
    go_minor="${go_minor%%.*}"

    local tools=()
    if (( go_minor >= 22 )); then
        tools=(
            "mvdan.cc/gofumpt@latest"
            "golang.org/x/tools/cmd/goimports@latest"
        )
    else
        warn "Go ${go_ver} is old; installing pinned compatible tool versions"
        tools=(
            "mvdan.cc/gofumpt@v0.4.0"
            "golang.org/x/tools/cmd/goimports@v0.14.0"
        )
    fi

    for tool in "${tools[@]}"; do
        local tool_name
        tool_name="$(basename "${tool%%@*}")"
        if command_exists "$tool_name"; then
            success "go: $tool_name already installed"
        else
            info "Installing go tool: $tool_name..."
            go install "$tool" || return 1
        fi
    done
}

install_go_tools_brew() {
    for tool in gofumpt goimports; do
        if brew list "$tool" &>/dev/null; then
            success "brew: $tool already installed"
        else
            info "Installing $tool via brew..."
            brew install "$tool" || return 1
        fi
    done
}

install_stylua() {
    if command_exists stylua; then
        success "stylua already installed"
        return 0
    fi

    # Ensure cargo is in PATH
    # shellcheck disable=SC1091
    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

    if command_exists cargo; then
        info "Installing stylua via cargo..."
        cargo install stylua || return 1
    else
        info "Installing stylua via brew..."
        brew install stylua || return 1
    fi
}

install_ruff() {
    if command_exists ruff; then
        success "ruff already installed"
        return 0
    fi

    if command_exists pipx; then
        info "Installing ruff via pipx..."
        pipx install ruff || return 1
    else
        warn "pipx not available, skipping ruff"
        return 1
    fi
}

install_java() {
    export SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"
    # Ensure SDKMAN is sourced
    if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
        set +u
        # shellcheck disable=SC1091
        source "$SDKMAN_DIR/bin/sdkman-init.sh"
        set -u
    fi

    if command_exists java; then
        success "Java already installed ($(java -version 2>&1 | head -1))"
    else
        if command_exists sdk; then
            info "Installing Java via SDKMAN..."
            set +u
            sdk install java 25.0.2-zulu || { set -u; return 1; }
            set -u
        else
            warn "SDKMAN not available, skipping Java install"
            return 1
        fi
    fi
}

install_npm_globals() {
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    # Temporarily disable nounset — nvm references unbound variables
    set +u
    # shellcheck disable=SC1091
    [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"
    set -u

    if ! command_exists npm; then
        warn "npm not available, skipping global npm packages"
        return 1
    fi

    local packages=(prettier fixjson)
    for pkg in "${packages[@]}"; do
        if npm list -g "$pkg" &>/dev/null; then
            success "npm: $pkg already installed"
        else
            info "Installing npm global: $pkg..."
            npm install -g "$pkg" || return 1
        fi
    done
}

install_google_java_format() {
    if brew list google-java-format &>/dev/null; then
        success "google-java-format already installed"
    else
        info "Installing google-java-format..."
        brew install google-java-format || return 1
    fi
}

apply_dotfiles() {
    # chezmoi may be installed in ~/bin when running as non-root
    [[ -d "$HOME/bin" ]] && export PATH="$HOME/bin:$PATH"

    if ! command_exists chezmoi; then
        warn "chezmoi not available, skipping dotfiles"
        return 1
    fi

    info "Applying dotfiles with chezmoi..."
    chezmoi init --apply --branch testing mtulla || return 1
}

set_default_shell() {
    local current_shell zsh_path current_user
    current_user="${USER:-$(whoami)}"
    current_shell="$(dscl . -read /Users/"$current_user" UserShell | awk '{print $2}')"
    zsh_path="$(which zsh)"
    if [[ "$current_shell" == *zsh* ]]; then
        success "Default shell is already zsh"
    else
        info "Setting zsh as default shell..."
        if grep -qF "$zsh_path" /etc/shells; then
            chsh -s "$zsh_path" || return 1
        else
            echo "$zsh_path" | sudo tee -a /etc/shells
            chsh -s "$zsh_path" || return 1
        fi
    fi
}

# === ORCHESTRATION ===========================================================

# Tier 0: Package manager
run_install update_brew             "Update Homebrew"

# Tier 1: Core packages (depend only on package manager)
run_install install_core_packages   "Core packages"
run_install install_build_deps      "Build dependencies"
run_install install_pipx            "pipx"
run_install install_bat             "bat"
run_install install_zoxide          "zoxide"

# Tier 2: Tools that need curl/git from Tier 1
run_install install_chezmoi         "chezmoi"
run_install install_rust            "Rust (rustup)"
run_install install_ohmyzsh         "Oh My Zsh"
run_install install_pyenv           "pyenv"
run_install install_nvm             "nvm"
run_install install_eza             "eza"
run_install install_lazygit         "lazygit"
run_install install_meslo_font      "MesloLGS Nerd Font"
run_install install_tpm             "TPM"
run_install install_sdkman          "SDKMAN"
run_install install_bazel           "Bazel (bazelisk)"

# Tier 3: Depend on Tier 2 installs
run_install install_zsh_autosuggestions "zsh-autosuggestions"
run_install install_powerlevel10k      "Powerlevel10k"
run_install install_node               "Node.js (via nvm)"
run_install install_go_tools           "Go tools (gofumpt, goimports)"
run_install install_stylua             "stylua"
run_install install_ruff               "ruff"
run_install install_java               "Java (via SDKMAN)"

# Tier 4: Depend on Tier 3
run_install install_npm_globals        "npm globals (prettier, fixjson)"
run_install install_google_java_format "google-java-format"
run_install install_go_tools_brew      "Go tools (brew)"

# Tier 5: Final
run_install set_default_shell          "Set zsh as default shell"
run_install apply_dotfiles             "Apply dotfiles (chezmoi)"

print_summary
