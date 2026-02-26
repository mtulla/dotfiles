# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Quick Start

Bootstrap a new machine with a single command:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply mtulla
```

This installs chezmoi, clones this repo, runs all setup scripts (package installs, language managers, CLI tools), applies dotfiles, and sets zsh as the default shell.

## How It Works

Chezmoi orchestrates everything:

- **`.chezmoiexternal.toml.tmpl`** — downloads oh-my-zsh, zsh plugins, powerlevel10k, tpm, and (on Linux) CLI binaries like eza, lazygit, and bazelisk
- **`run_onchange_before_*`** — installs packages via apt/brew before dotfiles are applied
- **`run_onchange_after_*`** — installs language-specific tools (Node, Java, Go tools, stylua, ruff) and sets the default shell

Re-running `chezmoi apply` is fast — idempotent checks skip already-installed items. Scripts re-run only when their content changes.

## Testing

Changes can be tested in an isolated Docker container (Ubuntu 22.04) before merging to `main`.

1. Push your changes to the `testing` branch:

   ```sh
   git push origin HEAD:testing
   ```

2. Run the test script:

   ```sh
   ./test-setup.sh
   ```

   This builds a Docker image and runs `chezmoi init --apply --branch testing mtulla` inside it — the same single-command flow used on a real machine.

   Use `--no-cache` to force a full rebuild:

   ```sh
   ./test-setup.sh --no-cache
   ```

   Use `-i` / `--interactive` to drop into a zsh shell after setup completes:

   ```sh
   ./test-setup.sh -i
   ```

3. Check the summaries at the end for any failures, fix, and repeat.
