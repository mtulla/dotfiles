# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Testing

Changes to dotfiles can be tested in an isolated Docker container (Ubuntu 22.04) before merging to `main`.

1. Push your changes to the `testing` branch:

   ```sh
   git push origin HEAD:testing
   ```

2. Run the test script:

   ```sh
   ./test-setup.sh
   ```

   This builds a Docker image, runs `setup-linux.sh` inside it, and at the end calls `chezmoi init --apply --branch testing mtulla` to pull your dotfiles from the `testing` branch.

   Use `--no-cache` to force a full rebuild:

   ```sh
   ./test-setup.sh --no-cache
   ```

   Use `-i` / `--interactive` to drop into a zsh shell after setup completes so you can poke around:

   ```sh
   ./test-setup.sh -i
   ```

3. Check the summary at the end for any failures, fix, and repeat.
