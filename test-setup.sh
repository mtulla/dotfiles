#!/usr/bin/env bash
set -uo pipefail

# Build and run the Linux setup script inside a Docker container.
# Usage: ./test-setup.sh [--no-cache] [-i|--interactive]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="dotfiles-setup-test"

build_args=()
interactive=false
for arg in "$@"; do
    case "$arg" in
        --no-cache) build_args+=("--no-cache") ;;
        -i|--interactive) interactive=true ;;
    esac
done

echo "==> Building Docker image..."
docker build \
    "${build_args[@]}" \
    -f "${SCRIPT_DIR}/Dockerfile.test" \
    -t "$IMAGE_NAME" \
    "$SCRIPT_DIR" || exit 1

echo ""
echo "==> Running setup-linux.sh in container..."
tty_flag=()
if [ -t 0 ]; then
    tty_flag=("-it")
fi

run_cmd=()
if [ "$interactive" = true ]; then
    run_cmd=(bash -c "/home/testuser/setup-linux.sh; exec zsh")
fi
docker run --rm "${tty_flag[@]}" "$IMAGE_NAME" "${run_cmd[@]}"
