#!/bin/bash
set -e  # Exit on any error

echo "Starting safe synchronization process..."

# Parse command line options
FORCE_PUSH=false
CONFLICT_STRATEGY="abort"  # Options: abort, manual, force

while getopts "fc:hp:" opt; do
  case $opt in
    f)
      FORCE_PUSH=true
      echo "Force push enabled (use with caution!)"
      ;;
    c)
      CONFLICT_STRATEGY=$OPTARG
      echo "Conflict strategy set to: $CONFLICT_STRATEGY"
      ;;
    h)
      echo "Usage: ./sync_with_helicone.sh [-f] [-c conflict_strategy] [-p packages]"
      echo "  -f                  Force push changes (use with caution)"
      echo "  -c conflict_strategy  How to handle conflicts: abort (default), manual, force"
      echo "  -p packages         Space-separated packages to sync (default: cost llm-mapper)"
      echo "  -h                  Show this help message"
      exit 0
      ;;
    p)
      PACKAGES_TO_SYNC=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Configure logging
LOG_FILE="sync_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "Logging to $LOG_FILE"

# Create a temporary directory for the sync
TEMP_DIR=$(mktemp -d)
echo "Created temporary directory: $TEMP_DIR"

# Create a backup directory
BACKUP_DIR="${TEMP_DIR}/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo "Created backup directory: $BACKUP_DIR"

# Check if the target remote exists, add if it doesn't
if ! git remote | grep -q "ai-cost-calculator"; then
  git remote add ai-cost-calculator git@github.com:sparkz-development/ai-cost-calcultator.git
fi

# Clone the target repository
echo "Cloning the target repository..."
git clone git@github.com:sparkz-development/ai-cost-calcultator.git "$TEMP_DIR/target"

# Create a backup of the target repository state
echo "Creating backup of current target repository state..."
cp -r "$TEMP_DIR/target" "$BACKUP_DIR/target_original"

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

# Track which packages were successfully copied
SUCCESSFUL_PACKAGES=()
FAILED_PACKAGES=()

echo "Copying necessary packages..."
for pkg in "${PACKAGES_ARRAY[@]}"; do
  if [ -d "packages/$pkg" ]; then
    echo "Copying package: $pkg"
    
    # Backup target package if it exists (to preserve possible customizations)
    if [ -d "$TEMP_DIR/target/$pkg" ]; then
      echo "Backing up existing package: $pkg"
      cp -r "$TEMP_DIR/target/$pkg" "$BACKUP_DIR/"
    fi
    
    # Copy new version directly to the root of the target repository
    cp -r "packages/$pkg" "$TEMP_DIR/target/"
    
    # Remove any potential secrets (add specific patterns as needed)
    find "$TEMP_DIR/target/$pkg" -type f -name "*.env*" -delete
    find "$TEMP_DIR/target/$pkg" -type f -name "*config*" -exec sed -i '' -e 's/sk-[a-zA-Z0-9]\{48\}/REMOVED_API_KEY/g' {} \;
    find "$TEMP_DIR/target/$pkg" -type f -exec sed -i '' -e 's/[a-zA-Z0-9]\{32,64\}-[a-zA-Z0-9]\{16,64\}/REMOVED_POSSIBLE_KEY/g' {} \;
    
    SUCCESSFUL_PACKAGES+=("$pkg")
  else
    echo "Package not found: $pkg - skipping"
    FAILED_PACKAGES+=("$pkg")
  fi
done

# Commit and push changes
echo "Committing and pushing changes..."
cd "$TEMP_DIR/target"

# Stage the changes
git add .

# Check if there are changes to commit
if git diff-index --quiet HEAD; then
  echo "No changes to commit"
  echo "Sync process completed with no changes!"
  # Clean up
  echo "Cleaning up temporary directory..."
  rm -rf "$TEMP_DIR"
  exit 0
fi

# Create commit
COMMIT_MSG="Sync packages from Helicone ($(date +%Y-%m-%d))"
if [ ${#SUCCESSFUL_PACKAGES[@]} -gt 0 ]; then
  COMMIT_MSG+=$'\n\nSynced packages:'
  for pkg in "${SUCCESSFUL_PACKAGES[@]}"; do
    COMMIT_MSG+=$'\n'"- $pkg"
  done
fi

git commit -m "$COMMIT_MSG"

# Try to pull latest changes to integrate any independent updates
echo "Checking for updates in target repository..."
if ! $FORCE_PUSH; then
  if ! git pull --rebase origin main; then
    echo "CONFLICT: The target repository has changes that conflict with the sync."
    
    case "$CONFLICT_STRATEGY" in
      "abort")
        echo "Aborting due to conflicts. Sync was not completed."
        echo "You can resolve conflicts manually or run with -c force to override."
        git rebase --abort
        # Preserve the backup
        echo "Backup preserved at: $BACKUP_DIR"
        echo "Temporary directory preserved at: $TEMP_DIR for manual resolution"
        echo "After resolving conflicts, run: cd $TEMP_DIR/target && git push origin main"
        exit 1
        ;;
      "manual")
        echo "Conflicts detected. Please resolve them manually."
        echo "Working directory preserved at: $TEMP_DIR/target"
        echo "After resolving conflicts, run: cd $TEMP_DIR/target && git push origin main"
        echo "Backup of original state preserved at: $BACKUP_DIR"
        exit 1
        ;;
      "force")
        echo "Force resolving conflicts by overwriting target changes (as requested)..."
        git rebase --abort
        ;;
      *)
        echo "Unknown conflict strategy: $CONFLICT_STRATEGY"
        echo "Aborting sync."
        exit 1
        ;;
    esac
  fi
fi

# Push changes
if $FORCE_PUSH; then
  echo "Force pushing changes as requested (overwriting any remote changes)..."
  git push -f origin main
else
  echo "Pushing changes..."
  git push origin main
fi

# Report sync status
echo "====== SYNC SUMMARY ======"
echo "Packages successfully synced: ${SUCCESSFUL_PACKAGES[*]:-none}"
echo "Packages that failed to sync: ${FAILED_PACKAGES[*]:-none}"
echo "Commit message: $COMMIT_MSG"
echo "Backup created at: $BACKUP_DIR"
echo "Log file: $LOG_FILE"
echo "=========================="

# Clean up
echo "Cleaning up temporary directory..."
rm -rf "$TEMP_DIR"

echo "Sync process completed!"
