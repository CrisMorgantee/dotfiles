#!/bin/sh
set -eu

# Ensure XDG-style directories exist before externals are applied.
# This avoids bootstrap failures on clean machines when a git-repo
# external targets a directory under ~/.config.

mkdir -p "${HOME}/.config"
mkdir -p "${HOME}/.config/nvim"

exit 0
