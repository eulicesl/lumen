#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: ./scripts/new-feature.sh <branch-name>"
  echo "Examples:"
  echo "  ./scripts/new-feature.sh onboarding-polish"
  echo "  ./scripts/new-feature.sh fix/chat-scroll-jump"
  exit 1
fi

RAW_NAME="$1"
BRANCH_NAME="$RAW_NAME"

if [[ ! "$BRANCH_NAME" =~ ^(feature|fix|chore|docs|refactor|release)/ ]]; then
  BRANCH_NAME="feature/$BRANCH_NAME"
fi

CURRENT_BRANCH="$(git branch --show-current)"
if [[ "$CURRENT_BRANCH" != "main" ]]; then
  echo "Error: start from main only. Current branch: $CURRENT_BRANCH"
  echo "Merge or close the current PR first, then retry from main."
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Error: working tree is not clean. Commit/stash changes first."
  git status --short
  exit 1
fi

echo "Fetching latest origin/main..."
git fetch origin

echo "Fast-forwarding local main..."
git pull --ff-only origin main

echo "Creating branch: $BRANCH_NAME"
git checkout -b "$BRANCH_NAME"

echo "Done. Next steps:"
echo "  git push -u origin $BRANCH_NAME"
echo "  open a PR back into main once work is ready"
