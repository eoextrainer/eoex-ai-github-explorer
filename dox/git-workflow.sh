#!/bin/bash
# git-workflow.sh: Stage, commit, push, and rollback with savepoints for EOEX ARI Agent
# Usage:
#   ./scripts/git-workflow.sh stage "msg"
#   ./scripts/git-workflow.sh commit "msg"
#   ./scripts/git-workflow.sh push
#   ./scripts/git-workflow.sh rollback <commit-ref>
#   ./scripts/git-workflow.sh log

set -e
REPO_DIR=$(git rev-parse --show-toplevel)
cd "$REPO_DIR"

case "$1" in
  stage)
    git add .
    echo "[GIT] All changes staged."
    ;;
  commit)
    if [ -z "$2" ]; then
      echo "[GIT] Commit message required."
      exit 1
    fi
    HASH=$(git commit -m "$2" | grep -oE '^[\[a-z0-9]+\]' | tr -d '[]')
    echo "[GIT] Commit created: $HASH"
    ;;
  push)
    git push
    echo "[GIT] Changes pushed to remote."
    ;;
  rollback)
    if [ -z "$2" ]; then
      echo "[GIT] Commit reference required (hash or message substring)."
      exit 1
    fi
    # Try by hash first
    if git rev-parse "$2" >/dev/null 2>&1; then
      git reset --hard "$2"
      echo "[GIT] Rolled back to commit $2."
    else
      # Try by message substring
      HASH=$(git log --pretty=oneline | grep "$2" | head -n1 | awk '{print $1}')
      if [ -n "$HASH" ]; then
        git reset --hard "$HASH"
        echo "[GIT] Rolled back to commit $HASH (matched by message)."
      else
        echo "[GIT] No commit found for reference: $2"
        exit 1
      fi
    fi
    ;;
  log)
    git log --oneline --graph --decorate --all
    ;;
  *)
    echo "Usage: $0 [stage|commit|push|rollback|log] [message|commit-ref]"
    exit 1
    ;;
esac
