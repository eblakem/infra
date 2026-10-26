#!/usr/bin/env bash
# Rebuild this laptop from a fresh Arch install. See README.md.
#
#   bash bootstrap.sh              # work laptop (default)
#   bash bootstrap.sh --personal   # skip DisplayLink, camera, Citrix
#
# Run as your normal user, not root. You'll be asked for your sudo password.
# Safe to re-run: everything it does is idempotent.
set -euo pipefail

REPO=https://github.com/eblakem/infra.git
DIR="$HOME/infra"
PERSONAL=0
[[ "${1:-}" == "--personal" ]] && PERSONAL=1

if [[ $EUID -eq 0 ]]; then
    echo "Run this as your normal user, not root - it uses sudo when needed." >&2
    exit 1
fi

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

step "Installing git, ansible and the GitHub CLI"
sudo pacman -Syu --needed --noconfirm git ansible github-cli

step "Logging in to GitHub (dotfiles is a private repo)"
if ! gh auth status &>/dev/null; then
    gh auth login --hostname github.com --git-protocol https --web
fi
gh auth setup-git

step "Fetching the infra repo"
if [[ -d "$DIR/.git" ]]; then
    git -C "$DIR" pull --ff-only
else
    git clone "$REPO" "$DIR"
fi

step "Running the playbook (asks for your sudo password once)"
cd "$DIR/local"
if (( PERSONAL )); then
    ansible-playbook main.yml --ask-become-pass --skip-tags work
else
    ansible-playbook main.yml --ask-become-pass
fi

if (( ! PERSONAL )); then
    step "Building AUR-only packages with yay"
    mapfile -t aur < <(grep -vE '^\s*(#|$)' "$DIR/aur-packages.txt")
    yay -S --needed --noconfirm "${aur[@]}"
fi

step "Done. Reboot, then work through 'After the first boot' in README.md"
