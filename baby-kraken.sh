#!/bin/bash
set -euo pipefail

# --- Colors ---
RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'; CYAN=$'\033[0;36m'; NC=$'\033[0m'

# --- Helper functions ---
info()    { echo -e "${BLUE}$*${NC}"; }
success() { echo -e "${GREEN}$*${NC}"; }
warn()    { echo -e "${YELLOW}$*${NC}"; }
error()   { echo -e "${RED}$*${NC}"; exit 1; }
confirm() { read -rp "$1 (y/yes): " ans; [[ "$ans" =~ ^(y|yes)$ ]] || error "Release cancelled."; }

# --- Check git status ---
info "Checking git status 🔍 ..."
git diff-index --quiet HEAD -- || error "You have uncommitted changes. Please commit or stash."

current_branch=$(git rev-parse --abbrev-ref HEAD)
info "Current branch: ${CYAN}${current_branch}${NC}"

is_hotfix=false
if [[ "$current_branch" == "develop" ]]; then
  success "Develop branch detected → normal release"
elif [[ "$current_branch" =~ ^hotfix/ ]]; then
  warn "Hotfix branch detected → hotfix release"
  is_hotfix=true
else
  error "You must be on 'develop' or 'hotfix/*' to create a release."
fi

# --- Show commits to be released ---
info "Collecting commits to release..."
git fetch origin master
git log --oneline --decorate --graph "origin/master..HEAD"
commit_count=$(git rev-list --count "origin/master..HEAD")
(( commit_count == 0 )) && warn "No new commits to release. Aborting." && exit 0
success "$commit_count commit(s) will be released."
confirm "Proceed?"

# --- Versioning ---
info "Fetching tags..."
git fetch --tags
latest_tag=$(git tag --sort=-v:refname | head -n1 || true)
[[ -z "$latest_tag" ]] && latest_tag="v0.0.0"
clean_tag="${latest_tag#v}"
IFS='.' read -r major minor patch <<< "$clean_tag"
major=${major:-0}; minor=${minor:-0}; patch=${patch:-0}

if [[ "$is_hotfix" == true ]]; then
  proposed="v${major}.${minor}.$((patch+1))"
else
  proposed="v${major}.$((minor+1)).0"
fi
success "Proposed version: ${CYAN}${proposed}${NC}"
read -rp "Press Enter to accept, or type custom version (vX.Y.Z): " custom
if [[ -n "$custom" ]]; then
  [[ "$custom" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || error "Invalid semantic version."
  new_version="$custom"
else
  new_version="$proposed"
fi
confirm "Proceed with version $new_version?"

# --- Release steps ---
info "Merging '$current_branch' into master..."
git checkout master
git pull --rebase origin master
git merge --no-ff "$current_branch" -m "Merge '$current_branch' for release $new_version"

info "Tagging release $new_version..."
git tag -a "$new_version" -m "Release $new_version"

info "Pushing master and tags..."
git push origin master "$new_version"

if [[ "$is_hotfix" == true ]]; then
  info "Hotfix → merging back into develop..."
  warn "Don't panic if this step fails; hotfix already out."
  git checkout develop
  git pull --rebase origin develop
  git merge --no-ff "$current_branch" -m "Merge hotfix '$current_branch' back into develop"
  git push origin develop
fi

success "Release $new_version completed successfully 🐙"
