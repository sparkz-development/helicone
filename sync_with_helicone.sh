#!/bin/bash
set -e  # Exit on any error

# First, commit any local changes to avoid "working tree has modifications" error
git add .
git commit -m "Auto-commit changes before sync" || echo "No changes to commit"

# Pull the latest changes from the helicone repo
git checkout main
git pull origin main

# Update the package from the helicone repo
git subtree pull --prefix=packages/ origin main

# Check if the target remote exists, add if it doesn't
if ! git remote | grep -q "ai-cost-calculator"; then
  git remote add ai-cost-calculator git@github.com:sparkz-development/ai-cost-calcultator.git
fi

# Fetch from the target repo to ensure we're up to date
git fetch ai-cost-calculator

# First try to merge any changes from the target repo
git pull ai-cost-calculator main --allow-unrelated-histories || echo "Could not pull from target repo"

# Push the updated package to the ai-cost-calculator repository
# Using --force-with-lease is safer than --force as it protects against overwriting others' work
git push ai-cost-calculator main --force-with-lease || {
  echo "Push failed, trying with --force"
  git push ai-cost-calculator main --force
}
