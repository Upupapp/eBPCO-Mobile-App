#!/bin/sh
# Point git at this repository's committed hooks.
#
# Git does not version .git/hooks, so a hook can only be shipped by committing
# it elsewhere and pointing core.hooksPath at it — which every clone must do
# once, by hand. That hand step is the weak link and is stated plainly in
# CLAUDE.md rather than hidden here.
set -e
cd "$(git rev-parse --show-toplevel)"
git config core.hooksPath scripts/hooks
echo "core.hooksPath = $(git config --get core.hooksPath)"
echo "Installed. 'git push' now runs analyze + the full test suite first."
