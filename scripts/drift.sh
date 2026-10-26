#!/usr/bin/env bash
# Compare explicitly installed packages with the playbook's package lists, so
# the playbook keeps up with what's actually on the laptop.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

{
    grep -E '^\s+- [a-z0-9]' "$ROOT/local/vars/packages.yml" | sed -E 's/^\s+- //'
    grep -vE '^\s*(#|$)' "$ROOT/aur-packages.txt"
} | sort -u > "$tmp/playbook"
# chaotic-* are installed by tasks/pacman.yml, not the package lists
pacman -Qqe | grep -v '^chaotic-' | sort -u > "$tmp/explicit"
pacman -Qq | sort -u > "$tmp/installed"

echo "Installed but not in the playbook (add to vars/packages.yml, or remove):"
comm -23 "$tmp/explicit" "$tmp/playbook" | sed 's/^/  /'
echo
echo "In the playbook but not installed (drop from the list, or install):"
comm -13 "$tmp/installed" "$tmp/playbook" | sed 's/^/  /'
