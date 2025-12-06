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
  echo "${YELLOW}No new commits to release. Aborting.${NC}"
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

# Strip leading v from latest tag if present
latest_tag=$(git tag --sort=-v:refname | head -n 1 || true)

# Fallback to 0.0.0 if no tag exists
if [[ -z "$latest_tag" ]]; then
  latest_tag="v0.0.0"
fi

clean_tag="${latest_tag#v}"

# Fallback numeric defaults if clean_tag is empty or malformed
IFS='.' read -r major minor patch <<< "$clean_tag"
major=${major:-0}
minor=${minor:-0}
patch=${patch:-0}

if [[ "$is_hotfix" == true ]]; then
  proposed_version="v${major}.${minor}.$((patch + 1))"
  echo "${YELLOW}Hotfix release detected → proposing PATCH bump${NC}"
else
  proposed_version="v${major}.$((minor + 1)).0"
  echo "${BLUE}Normal release detected → proposing MINOR bump${NC}"
fi

echo "${GREEN}Proposed next version: ${CYAN}${proposed_version}${NC}"
echo "${GREEN}Press Enter to accept, or type a custom semantic version (with leading 'v'):${NC}"
read -r custom_version

# If user provided custom version → validate it
if [[ -n "$custom_version" ]]; then
  # Validate semantic versioning format vX.Y.Z
  if [[ "$custom_version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    new_version="$custom_version"
    echo "${GREEN}Using custom version: ${CYAN}${new_version}${NC}"
  else
    echo "${RED}Invalid semantic version. Must follow vX.Y.Z (e.g. v1.4.0).${NC}"
    exit 1
  fi
else
  new_version="$proposed_version"
fi

echo "${GREEN}Proceed with version ${CYAN}${new_version}${GREEN}? (y/yes)${NC}"
read -r final_confirm

if [[ ! "$final_confirm" =~ ^(y|yes)$ ]]; then
  echo "${RED}Release cancelled.${NC}"
fi

echo -e "${BLUE}Merging '${current_branch}' into master...${NC}"
git checkout master
git pull origin master --rebase
git merge --no-ff "$current_branch" -m "Merge branch '$current_branch' for release $new_version"

echo -e "${BLUE}Tagging release ${new_version}...${NC}"
git tag -a "$new_version" -m "Release $new_version"

echo -e "${BLUE}Pushing master and tags to origin...${NC}"
git push origin master
git push origin "$new_version"

if [[ "$is_hotfix" == true ]]; then
  echo -e "${BLUE}Hotfix release → merging back into develop...${NC}"
  echo -e "${BLUE}Don't panic if this step fails, the hotfix is already out${NC}"
  git checkout develop
  git pull origin develop --rebase
  git merge --no-ff "$current_branch" -m "Merge hotfix '$current_branch' back into develop"
  git push origin develop
fi

echo -e "${GREEN}Release $new_version completed successfully!${NC}"