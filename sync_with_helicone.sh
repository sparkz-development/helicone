#!/bin/bash
set -e  # Exit on any error

echo "Starting safe synchronization process..."

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
cp -r package.json tsconfig.json "$TEMP_DIR/target/"

# Commit and push changes
echo "Committing and pushing changes..."
cd "$TEMP_DIR/target"
git add .
git diff-index --quiet HEAD || git commit -m "Sync packages from Helicone ($(date +%Y-%m-%d))"
if [ $? -eq 0 ]; then
  git push origin main
else
  echo "No changes to commit"
fi

# Clean up
echo "Cleaning up temporary directory..."
rm -rf "$TEMP_DIR"

echo "Sync process completed!"
