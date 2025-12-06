#/bin/bash

set -euo pipefail

# Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
NC="\033[0m"

echo "${BLUE}Checking git status 🔍 ... ${NC}"

if ! git diff-index --quiet HEAD --; then
  echo "${RED}You have uncommitted changes. Please commit or stash them before releasing.${NC}"
  exit 1
fi

current_branch=$(git rev-parse --abbrev-ref HEAD)
echo "${BLUE}Current branch: ${CYAN}${current_branch}${NC}"

is_hotfix=false

if [["$current_branch" == "develop" ]]; then
  echo "${GREEN}On develop normal release${NC}"
elif [[ "$current_branch" =~ ^hotfix/ ]]; then
  echo "${YELLOW}Hotfix detected${NC}"
  is_hotfix=true
else
  echo "${RED}You must be on 'develop' or 'hotfix/*' to create a release.${NC}"
  exit 1
fi