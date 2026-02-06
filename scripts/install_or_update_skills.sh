#!/usr/bin/env bash
set -e

# This script installs or updates the agent_skills repository and syncs skills
# to ~/.claude/skills (using cp for better IDE integration; some IDEs don't support symlinks).

REPO_URL="https://github.com/DeerHide/agent_skills.git"
REPO_DIR="$HOME/.deerhide/repositories/agent_skills"
SKILLS_DEST="$HOME/.claude/skills"
ALIAS_NAME="deerhide_agents_skills_update"
ALIAS_LINE="alias ${ALIAS_NAME}='\$HOME/.deerhide/repositories/agent_skills/scripts/install_or_update_skills.sh'"

# Helpers for consistent output
info() { echo "  $*"; }
section() { echo ""; echo "==> $*"; }

section "DeerHide agent_skills — install or update"
echo "  Destination: $SKILLS_DEST"
echo ""

# 1. Clone or update the repository
section "Repository"
mkdir -p "$HOME/.deerhide/repositories"
if [ -d "$REPO_DIR/.git" ]; then
  info "Updating existing clone..."
  git -C "$REPO_DIR" pull --quiet
  info "Repository updated."
else
  info "Cloning $REPO_URL ..."
  git clone --quiet "$REPO_URL" "$REPO_DIR"
  info "Repository cloned."
fi

# 2. Create ~/.claude/skills if it doesn't exist
mkdir -p "$SKILLS_DEST"

# 3. Install or update skills (copy each skill dir; skip template)
section "Skills"
skill_count=0
for dir in "$REPO_DIR"/skills/*/; do
  [ -d "$dir" ] || continue
  name=$(basename "$dir")
  if [ "$name" = "template" ]; then
    continue
  fi
  cp -r "$dir" "$SKILLS_DEST/"
  info "$name"
  skill_count=$((skill_count + 1))
done
info "Installed/updated $skill_count skill(s) → $SKILLS_DEST"

# 4. Add alias to detected rc files if not already present
section "Shell alias"
alias_added=0
for rc in .bashrc .zshrc .profile; do
  rcfile="$HOME/$rc"
  if [ -f "$rcfile" ]; then
    if grep -q "$ALIAS_NAME" "$rcfile" 2>/dev/null; then
      info "  $rc: alias already present (skipped)"
    else
      printf '\n# DeerHide agent_skills updater\n%s\n' "$ALIAS_LINE" >> "$rcfile"
      info "  $rc: alias added"
      alias_added=$((alias_added + 1))
    fi
  fi
done
if [ "$alias_added" -gt 0 ]; then
  info "Run \`source \$HOME/.zshrc\` (or your rc file) to use the alias."
fi
info "To update again later: $ALIAS_NAME"

section "Done"
echo "  Skills: $skill_count  |  Path: $SKILLS_DEST"
echo ""
