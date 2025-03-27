# Syncing Helicone Packages to AI Cost Calculator

## Quick Start

To sync packages from Helicone to the AI Cost Calculator repository:

```bash
# Run the sync script (automatically updates your fork and syncs default packages: cost and llm-mapper)
./sync_with_helicone.sh
```

## What This Script Does

This script:

1. Automatically updates your Helicone fork from the upstream repository
2. Safely copies the `cost` and `llm-mapper` packages to the AI Cost Calculator repository 
3. Removes any potential secrets or API keys in the process

## Running the Sync

### Prerequisites

- Git command line tools
- SSH access to both repositories
- Bash shell environment

### Basic Usage

Run the script without any parameters:

```bash
./sync_with_helicone.sh
```

This will:
1. Update your Helicone fork from upstream
2. Sync the default packages (`cost` and `llm-mapper`)

### Syncing Specific Packages

You can specify which packages to sync using the `PACKAGES_TO_SYNC` environment variable:

```bash
# Sync only the cost package
PACKAGES_TO_SYNC="cost" ./sync_with_helicone.sh

# Sync multiple specific packages
PACKAGES_TO_SYNC="cost llm-mapper" ./sync_with_helicone.sh

# Sync a different package
PACKAGES_TO_SYNC="some-other-package" ./sync_with_helicone.sh
```

### Workflow Diagram

```mermaid
flowchart LR
    A([Start]) --> B[Run sync script]
    B --> C[Script updates Helicone fork]
    C --> D[Script syncs packages]
    D --> E{Check results}
    E -->|Success| F([Done])
    E -->|Errors| G[Resolve issues]
    G --> B
```

## Troubleshooting

If you encounter errors during the sync:

1. Ensure you have SSH access to both repositories
2. Check that the target branch (main) exists in the target repository
3. Look for merge conflicts if the push fails
4. Check for upstream merge errors (if your local fork has diverged significantly)

## Security Notes

The script includes security measures to protect sensitive information:
- Automatically removes `.env` files
- Sanitizes configuration files
- Removes potential API keys from all files
