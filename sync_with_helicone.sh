#!/bin/bash

# Pull latest changes from the monorepo
git checkout main
git pull origin main

# Update the package branch
git subtree pull --prefix=packages/ origin main

# Push to the package repository
git push package-repo package-branch:main
