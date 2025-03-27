#!/bin/bash
set -e  # Exit on any error

echo "Starting safe synchronization process..."

# Step 1: Update local Helicone fork from upstream
echo "Updating Helicone fork from upstream..."

# Check if upstream remote exists, add if it doesn't
if ! git remote | grep -q "upstream"; then
  echo "Adding upstream remote..."
  git remote add upstream https://github.com/helicone/helicone.git
fi

# Fetch and merge changes from upstream
echo "Fetching from upstream..."
git fetch upstream

echo "Merging upstream changes..."
git merge upstream/main

echo "Pushing changes to your fork..."
git push origin main

echo "Helicone fork updated successfully!"

# Step 2: Sync packages to AI Cost Calculator

# Create a temporary directory for the sync
TEMP_DIR=$(mktemp -d)
echo "Created temporary directory: $TEMP_DIR"

# Check if the target remote exists, add if it doesn't
if ! git remote | grep -q "ai-cost-calculator"; then
  git remote add ai-cost-calculator git@github.com:sparkz-development/ai-cost-calcultator.git
fi

# Clone the target repository
echo "Cloning the target repository..."
git clone git@github.com:sparkz-development/ai-cost-calcultator.git "$TEMP_DIR/target"

# Copy only the specific packages needed
echo "Copying necessary packages..."
mkdir -p "$TEMP_DIR/target/packages"

# Get packages to sync from environment variable or use default
# Usage example: PACKAGES_TO_SYNC="cost llm-mapper some-other-package" ./sync_with_helicone.sh
if [ -n "$PACKAGES_TO_SYNC" ]; then
  # Convert space-separated string to array
  read -ra PACKAGES_ARRAY <<< "$PACKAGES_TO_SYNC"
  echo "Using packages from environment variable: ${PACKAGES_ARRAY[*]}"
else
  # Default packages if not specified
  PACKAGES_ARRAY=("cost" "llm-mapper")
  echo "Using default packages: ${PACKAGES_ARRAY[*]}"
fi

for pkg in "${PACKAGES_ARRAY[@]}"; do
  if [ -d "packages/$pkg" ]; then
    echo "Copying package: $pkg"
    cp -r "packages/$pkg" "$TEMP_DIR/target/packages/"
    
    # Remove any potential secrets (add specific patterns as needed)
    find "$TEMP_DIR/target/packages/$pkg" -type f -name "*.env*" -delete
    find "$TEMP_DIR/target/packages/$pkg" -type f -name "*config*" -exec sed -i '' -e 's/sk-[a-zA-Z0-9]\{48\}/REMOVED_API_KEY/g' {} \;
    find "$TEMP_DIR/target/packages/$pkg" -type f -exec sed -i '' -e 's/[a-zA-Z0-9]\{32,64\}-[a-zA-Z0-9]\{16,64\}/REMOVED_POSSIBLE_KEY/g' {} \;
  else
    echo "Package not found: $pkg - skipping"
  fi
done

# Also copy necessary configuration files from the packages root
echo "Copying package configuration files..."
cp "packages/package.json" "$TEMP_DIR/target/packages/" 2>/dev/null || echo "package.json not found"
cp "packages/package-lock.json" "$TEMP_DIR/target/packages/" 2>/dev/null || echo "package-lock.json not found"
cp "packages/tsconfig.json" "$TEMP_DIR/target/packages/" 2>/dev/null || echo "tsconfig.json not found"
cp "packages/README.md" "$TEMP_DIR/target/packages/" 2>/dev/null || echo "README.md not found"

# Commit and push changes in the target repo
echo "Committing and pushing changes..."
cd "$TEMP_DIR/target"
git add .
git commit -m "Sync selected packages from helicone repo" || echo "No changes to commit"
git push origin main || echo "Push failed - you may need to resolve conflicts manually"

# Clean up
echo "Cleaning up temporary directory..."
rm -rf "$TEMP_DIR"

echo "Sync process completed!"
