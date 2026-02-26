#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# Linux (Debian/Ubuntu) Setup Script for Dotfiles
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

# Banner
echo -e "${BOLD}"
echo "╔══════════════════════════════════════════╗"
echo "║     Linux (Debian/Ubuntu) Dotfiles Setup ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${RESET}"

# Prerequisites
if [[ ! -f /etc/debian_version ]]; then
    error "This script is for Debian/Ubuntu only."
    exit 1
fi

if [[ $EUID -eq 0 ]]; then
    error "Do not run this script as root. It will use sudo when needed."
    exit 1
fi

if ! command_exists sudo; then
    error "sudo is required. Install it first: apt install sudo"
    exit 1
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

update_apt() {
    info "Updating apt..."
    sudo apt update || return 1
}

install_core_packages() {
    local packages=(
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
    )

    info "Installing core apt packages..."
    for pkg in "${packages[@]}"; do
        if dpkg -s "$pkg" &>/dev/null; then
            success "$pkg already installed"
        else
            info "Installing $pkg..."
            sudo apt install -y "$pkg" || return 1
        fi
    done
}

install_build_deps() {
    local packages=(
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
    for pkg in "${packages[@]}"; do
        if dpkg -s "$pkg" &>/dev/null; then
            success "$pkg already installed"
        else
            info "Installing $pkg..."
            sudo apt install -y "$pkg" || return 1
        fi
    done
}

install_pipx() {
    if command_exists pipx; then
        success "pipx already installed"
    else
        info "Installing pipx..."
        sudo apt install -y pipx || return 1
    fi
}

install_chezmoi() {
    if command_exists chezmoi; then
        success "chezmoi already installed"
    else
        info "Installing chezmoi..."
        sh -c "$(curl -fsLS get.chezmoi.io)" || return 1
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
        RUNZSH=no KEEP_ZSHRC=yes CHSH=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || return 1
    fi
}

install_pyenv() {
    export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"

    if command_exists pyenv || [[ -d "$PYENV_ROOT" ]]; then
        success "pyenv already installed"
    else
        info "Installing pyenv..."
        curl -fsSL https://pyenv.run | bash || return 1
    fi
    # Always ensure pyenv is in PATH for this session
    [[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
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
    if command_exists bat || command_exists batcat; then
        success "bat already installed"
    else
        info "Installing bat..."
        sudo apt install -y bat || return 1
    fi
}

install_eza() {
    if command_exists eza; then
        success "eza already installed"
        return 0
    fi

    info "Installing eza..."
    local tmpdir
    tmpdir="$(mktemp -d)"
    local tag url
    tag="$(github_latest_tag eza-community/eza)" || { rm -rf "$tmpdir"; return 1; }
    url="https://github.com/eza-community/eza/releases/download/${tag}/eza_${ARCH_ALT}-unknown-linux-gnu.tar.gz"
    if curl -fsSL -o "${tmpdir}/eza.tar.gz" "$url"; then
        tar -xzf "${tmpdir}/eza.tar.gz" -C "$tmpdir"
        sudo install -m 755 "${tmpdir}/eza" /usr/local/bin/eza
        success "eza installed"
    else
        error "Failed to download eza. Install manually from https://github.com/eza-community/eza/releases"
        rm -rf "$tmpdir"
        return 1
    fi
    rm -rf "$tmpdir"
}

install_lazygit() {
    if command_exists lazygit; then
        success "lazygit already installed"
        return 0
    fi

    info "Installing lazygit..."
    local tmpdir tag ver url
    tmpdir="$(mktemp -d)"
    tag="$(github_latest_tag jesseduffield/lazygit)" || { rm -rf "$tmpdir"; return 1; }
    ver="${tag#v}"
    # lazygit uses x86_64 / arm64 in release filenames
    local lg_arch="${ARCH_ALT}"
    [[ "$lg_arch" == "aarch64" ]] && lg_arch="arm64"
    url="https://github.com/jesseduffield/lazygit/releases/download/${tag}/lazygit_${ver}_Linux_${lg_arch}.tar.gz"
    if curl -fsSL -o "${tmpdir}/lazygit.tar.gz" "$url"; then
        tar -xzf "${tmpdir}/lazygit.tar.gz" -C "$tmpdir"
        sudo install "${tmpdir}/lazygit" -D -t /usr/local/bin/
        success "lazygit installed"
    else
        error "Failed to download lazygit. Install manually from https://github.com/jesseduffield/lazygit/releases"
        rm -rf "$tmpdir"
        return 1
    fi
    rm -rf "$tmpdir"
}

install_zoxide() {
    if command_exists zoxide; then
        success "zoxide already installed"
    else
        info "Installing zoxide..."
        sudo apt install -y zoxide || return 1
    fi
}

install_meslo_font() {
    local font_dir="$HOME/.local/share/fonts"
    if ls "$font_dir"/MesloLGS* &>/dev/null 2>&1; then
        success "MesloLGS Nerd Font already installed"
        return 0
    fi

    info "Installing MesloLGS Nerd Font..."
    mkdir -p "$font_dir"
    local tmpdir tag url
    tmpdir="$(mktemp -d)"
    tag="$(github_latest_tag ryanoasis/nerd-fonts)" || { rm -rf "$tmpdir"; return 1; }
    url="https://github.com/ryanoasis/nerd-fonts/releases/download/${tag}/Meslo.zip"
    if curl -fsSL -o "${tmpdir}/Meslo.zip" "$url"; then
        unzip -o "${tmpdir}/Meslo.zip" -d "$font_dir"
        fc-cache -f "$font_dir"
        success "MesloLGS Nerd Font installed"
    else
        error "Failed to download Nerd Font. Install manually from https://github.com/ryanoasis/nerd-fonts/releases"
        rm -rf "$tmpdir"
        return 1
    fi
    rm -rf "$tmpdir"
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
    if command_exists bazel; then
        success "Bazel already installed"
        return 0
    fi

    info "Installing Bazel via bazelisk..."
    local tmpdir tag url
    tmpdir="$(mktemp -d)"
    tag="$(github_latest_tag bazelbuild/bazelisk)" || { rm -rf "$tmpdir"; return 1; }
    url="https://github.com/bazelbuild/bazelisk/releases/download/${tag}/bazelisk-linux-${ARCH_GO}"
    if curl -fsSL -o "${tmpdir}/bazelisk" "$url"; then
        sudo install -m 755 "${tmpdir}/bazelisk" /usr/local/bin/bazel
        success "Bazel (bazelisk) installed"
    else
        error "Failed to download bazelisk. Install manually from https://github.com/bazelbuild/bazelisk/releases"
        rm -rf "$tmpdir"
        return 1
    fi
    rm -rf "$tmpdir"
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

    local p10k_dir="${ZSH_CUSTOM}/themes/powerlevel10k"
    if [[ -d "$p10k_dir" ]]; then
        success "Powerlevel10k already installed"
    else
        info "Installing Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir" || return 1
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
        warn "cargo not available, skipping stylua"
        return 1
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
    if command_exists google-java-format; then
        success "google-java-format already installed"
        return 0
    fi

    info "Installing google-java-format..."
    local tmpdir tag ver url gjf_dir
    tmpdir="$(mktemp -d)"
    tag="$(github_latest_tag google/google-java-format)" || { rm -rf "$tmpdir"; return 1; }
    ver="${tag#v}"
    url="https://github.com/google/google-java-format/releases/download/${tag}/google-java-format-${ver}-all-deps.jar"
    gjf_dir="/usr/local/lib/google-java-format"
    if curl -fsSL -o "${tmpdir}/google-java-format.jar" "$url"; then
        sudo mkdir -p "$gjf_dir"
        sudo install -m 644 "${tmpdir}/google-java-format.jar" "$gjf_dir/google-java-format.jar"
        sudo tee /usr/local/bin/google-java-format > /dev/null <<'WRAPPER'
#!/usr/bin/env bash
exec java -jar /usr/local/lib/google-java-format/google-java-format.jar "$@"
WRAPPER
        sudo chmod +x /usr/local/bin/google-java-format
        success "google-java-format installed"
    else
        error "Failed to download google-java-format. Install manually from https://github.com/google/google-java-format/releases"
        rm -rf "$tmpdir"
        return 1
    fi
    rm -rf "$tmpdir"
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
    current_shell="$(getent passwd "$current_user" | cut -d: -f7)"
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
run_install update_apt              "Update apt"

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

# Tier 5: Final
run_install set_default_shell          "Set zsh as default shell"
run_install apply_dotfiles             "Apply dotfiles (chezmoi)"

print_summary
