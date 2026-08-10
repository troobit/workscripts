#!/usr/bin/env bash

set -e

FILE_PATH="$1"

if [ -z "$FILE_PATH" ]; then
    echo "provide a file path to purge from git history"
    echo "Usage: $0 path/to/file.txt"
    exit 1
fi

# 2. Safety Check: Ensure git-filter-repo is installed
if ! command -v git-filter-repo &> /dev/null; then
    echo "'git-filter-repo' is required"
    echo "'brew install git-filter-repo'"
    exit 1
fi

# 3. One confirmation prompt
echo "'$FILE_PATH' will be removed from all local commits and branches."
read -rp "Proceed? (y/N): " CONFIRMATION

if [[ ! "$CONFIRMATION" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# 4. Remove the file from all history
echo "Purging '$FILE_PATH'..."
git filter-repo --path "$FILE_PATH" --invert-paths --force

echo "$FILE_PATH" >> .gitignore

git add .gitignore

