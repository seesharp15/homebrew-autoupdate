#!/bin/sh
# Point the locally installed Homebrew tap (domt4/autoupdate) at a fork so
# that `brew autoupdate` runs the fork's code, or restore it to upstream.
#
# Usage:
#   scripts/setup-dev-env.sh [branch]      Point the tap at the fork
#                                          (default branch: main).
#   scripts/setup-dev-env.sh --restore     Point the tap back at upstream.
#
# The fork URL can be overridden with the FORK_URL environment variable.
#
# Note: the launchd job does NOT run the tap directly. `brew autoupdate
# start` copies a generated script to ~/Library/Application Support, so an
# already scheduled job keeps running its old code until it is regenerated.
# This script prints the reinstall reminder when a job is installed.

set -eu

FORK_URL="${FORK_URL:-git@github.com:seesharp15/homebrew-autoupdate.git}"
UPSTREAM_URL="https://github.com/DomT4/homebrew-autoupdate"
TAP_DIR="$(brew --repository)/Library/Taps/domt4/homebrew-autoupdate"

if [ ! -d "$TAP_DIR" ]
then
  echo "==> Tap not installed; tapping domt4/autoupdate first"
  brew tap domt4/autoupdate
fi

if [ "${1:-}" = "--restore" ]
then
  echo "==> Pointing tap at upstream: $UPSTREAM_URL"
  git -C "$TAP_DIR" remote set-url origin "$UPSTREAM_URL"
  branch="main"
else
  branch="${1:-main}"
  echo "==> Pointing tap at fork: $FORK_URL ($branch)"
  git -C "$TAP_DIR" remote set-url origin "$FORK_URL"
fi

git -C "$TAP_DIR" fetch origin
git -C "$TAP_DIR" reset --hard "origin/$branch"
echo "==> Tap now at: $(git -C "$TAP_DIR" log --oneline -1)"

if [ -e "$HOME/Library/LaunchAgents/com.github.domt4.homebrew-autoupdate.plist" ]
then
  echo ""
  echo "A scheduled autoupdate job is installed. It still runs the previously"
  echo "generated script; to regenerate it from the code the tap now points at:"
  echo "  brew autoupdate delete && brew autoupdate start <interval> <options>"
fi
