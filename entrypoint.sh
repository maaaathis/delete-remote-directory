#!/bin/sh -l

set -e  # Stop script on error
set -u  # Fail if trying to access an undefined variable

# Capture inputs from workflow
TARGET_DIRECTORY=${1}
TARGET_GITHUB_USERNAME=${2}
TARGET_REPOSITORY_NAME=${3}
GITHUB_SERVER=${4}
USER_EMAIL=${5}
USER_NAME=${6}
TARGET_REPOSITORY_USERNAME=${7:-$TARGET_GITHUB_USERNAME}  # Use TARGET_GITHUB_USERNAME as default
USER_NAME=${USER_NAME:-$TARGET_GITHUB_USERNAME}  # Use TARGET_GITHUB_USERNAME as default
TARGET_BRANCH=${8}
COMMIT_MESSAGE=${9}

# Check for required API token
if [[ -z "$API_TOKEN_GITHUB" ]]; then
  echo "::error::API_TOKEN_GITHUB is empty. Please fill in."
  exit 1
fi

# Build GIT_CMD_REPOSITORY with authentication
GIT_CMD_REPOSITORY="https://$TARGET_REPOSITORY_USERNAME:$API_TOKEN_GITHUB@$GITHUB_SERVER/$TARGET_REPOSITORY_USERNAME/$TARGET_REPOSITORY_NAME.git"

# Create temporary clone directory
CLONE_DIR=$(mktemp -d)

echo "[+] Git version"
git --version

echo "[+] Enable git lfs"
git lfs install

echo "[+] Cloning destination git repository $TARGET_GITHUB_USERNAME/$TARGET_REPOSITORY_NAME:$TARGET_BRANCH"

# Git configuration
git config --global user.email "$USER_EMAIL"
git config --global user.name "$USER_NAME"
git config --global http.version HTTP/1.1

# Clone with error handling
git clone --single-branch --depth 1 --branch "$TARGET_BRANCH" "$GIT_CMD_REPOSITORY" "$CLONE_DIR" || {
  echo "::error::Could not clone the destination repository."
  echo "::error::Please verify the target repository exists and the API_TOKEN_GITHUB has access."
  exit 1
}

TEMP_DIR=$(mktemp -d)
# This mv has been the easier way to be able to remove files that were there
# but not anymore. Otherwise we had to remove the files from "$CLONE_DIR",
# including "." and with the exception of ".git/"
mv "$CLONE_DIR/.git" "$TEMP_DIR/.git"

# Prepare target directory
ABSOLUTE_TARGET_DIRECTORY="$CLONE_DIR/$TARGET_DIRECTORY"

# Delete target directory
echo "[+] Deleting $ABSOLUTE_TARGET_DIRECTORY"
rm -rf "$ABSOLUTE_TARGET_DIRECTORY"

echo "[+] Listing Current Directory Location"
ls -al

echo "[+] Listing root Location"
ls -al /

mv "$TEMP_DIR/.git" "$CLONE_DIR/.git"


# Sanitize commit message (remove references to origin)
COMMIT_MESSAGE=${COMMIT_MESSAGE//ORIGIN_COMMIT/}
COMMIT_MESSAGE=${COMMIT_MESSAGE//$GITHUB_REF/}

# Set safe directory for git
git config --global --add safe.directory "$CLONE_DIR"

# Add changes and commit (skip if no changes)
echo "[+] Adding git commit"
git add .
git status &> /dev/null || git commit --message "$COMMIT_MESSAGE"

# Pull latest changes (rebase to avoid merge conflicts)
echo "[+] Pull latest changes"
git pull --rebase

# Push changes to target branch with --set-upstream
echo "[+] Pushing git commit"
git push "$GIT_CMD_REPOSITORY" --set-upstream "$TARGET_BRANCH"
