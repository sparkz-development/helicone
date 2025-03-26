#!/bin/bash

# Pull the latest changes from the monorepo
git checkout main
git pull origin main

# Update the package from the monorepo
git subtree pull --prefix=packages/ origin main

# Push the updated package to the ai-cost-calcultator repository
git push package-repo main  # Remove 'package-branch:', use 'main' directly
