#!/bin/bash

set -euo pipefail

# Colors
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'

echo "${BLUE}Checking git status 🔍 ... ${NC}"

if ! git diff-index --quiet HEAD --; then
  echo "${RED}You have uncommitted changes. Please commit or stash them before releasing.${NC}"
  exit 1
fi

current_branch=$(git rev-parse --abbrev-ref HEAD)
echo "${BLUE}Current branch: ${CYAN}${current_branch}${NC}"

is_hotfix=false

if [[ "$current_branch" == "develop" ]]; then
  echo "${GREEN}Develop branch detected => normal release${NC}"
elif [[ "$current_branch" =~ ^hotfix/ ]]; then
  echo "${YELLOW}Hotfix branch detected => hotfix release${NC}"
  is_hotfix=true
else
  echo "${RED}You must be on 'develop' or 'hotfix/*' to create a release.${NC}"
  exit 1
fi

echo "${BLUE}Collecting commits that would be released...${NC}"

target_branch="master"
git fetch origin "$target_branch"

echo "${CYAN}Commits that will be included in the release:${NC}"
git log --oneline --decorate --graph "origin/$target_branch..HEAD"

commit_count=$(git rev-list --count "origin/$target_branch..HEAD")

if [[ "$commit_count" -eq 0 ]]; then
  echo "${YELLOW}⚠ No new commits to release. Aborting.${NC}"
  exit 0
fi

echo "${GREEN}${commit_count} commit(s) will be released.${NC}"
echo "${GREEN}Do you want to proceed? (y/yes):${NC}"
read -r answer

if [[ ! "$answer" =~ ^(y|yes)$ ]]; then
  echo "${RED}Release cancelled.${NC}"
  exit 1
fi

echo -e "${BLUE}Fetching tags...${NC}"
git fetch --tags

latest_tag=$(git tag --sort=-v:refname | head -n 1 || true)

if [[ -z "$latest_tag" ]]; then
  latest_tag="0.0.0"
fi

echo -e "${BLUE}Latest tag: ${CYAN}${latest_tag}${NC}"