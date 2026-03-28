#!/usr/bin/env bash
#
# Deploy to Vercel from your machine (CLI), using a one-off git identity for
# any local commit — does not change your global git config.
#
# Why: Vercel CLI deploys the current files; you don't need GitHub to trigger
# the build. If you still want commits attributed to another name/email for
# this repo only, set AUTHOR_* below or export them before running.
#
# Usage (from repo root):
#   chmod +x scripts/vercel-deploy.sh
#   ./scripts/vercel-deploy.sh
#
# Prerequisites:
#   - npm / Node (for npx)
#   - Logged in:  npm run vercel-login   (from repo root)
#   - Linked:     npx vercel link       (from repo root, same Vercel project)
#   - .vercel/ must live at the REPO ROOT (not inside frontend/), or Vercel will
#     look for frontend/frontend when the dashboard Root Directory is "frontend".
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FRONTEND_DIR="$REPO_ROOT/frontend"

BRANCH_NAME="${DEPLOY_BRANCH_NAME:-temp_deploy_branch}"

# Override per project — or: export AUTHOR_NAME / AUTHOR_EMAIL before running
AUTHOR_NAME="${AUTHOR_NAME:-CreativeCrossbreed}"
AUTHOR_EMAIL="${AUTHOR_EMAIL:-creativecrossbreed@gmail.com}"

STASHED=0
cleanup() {
  if [[ "$STASHED" -eq 1 ]]; then
    echo ""
    echo "📦 Restoring stashed changes..."
    git -C "$REPO_ROOT" stash pop -q || true
  fi
}
trap cleanup EXIT

check_working_tree() {
  if git -C "$REPO_ROOT" diff-index --quiet HEAD -- 2>/dev/null; then
    echo "✅ Working tree is clean"
    return
  fi
  echo "❌ Working tree is not clean. You have uncommitted changes."
  echo ""
  echo "Please choose an option:"
  echo "1) Commit changes, then run this script again"
  echo "2) Stash changes for this run (restored automatically at the end)"
  echo "3) Exit"
  read -r -p "Enter your choice (1-3): " choice

  case $choice in
    1)
      echo "Commit your changes first, then run this script again."
      exit 1
      ;;
    2)
      echo "Stashing changes..."
      git -C "$REPO_ROOT" stash push -m "Stashed by scripts/vercel-deploy.sh"
      STASHED=1
      echo "✅ Changes stashed; they will be restored when the script exits."
      ;;
    3)
      echo "Exiting..."
      exit 0
      ;;
    *)
      echo "Invalid choice. Exiting..."
      exit 1
      ;;
  esac
}

if [[ ! -d "$FRONTEND_DIR" ]]; then
  echo "❌ Expected frontend at: $FRONTEND_DIR"
  exit 1
fi

ORIGINAL_BRANCH="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)"
echo "📍 Current branch: $ORIGINAL_BRANCH"

check_working_tree

if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
  echo "⚠️  Branch $BRANCH_NAME already exists. Deleting it first..."
  git -C "$REPO_ROOT" branch -D "$BRANCH_NAME" 2>/dev/null || true
fi

echo "🌿 Creating branch: $BRANCH_NAME"
git -C "$REPO_ROOT" checkout -b "$BRANCH_NAME"

# Optional: image optimization (only if the script exists in frontend/package.json)
if grep -q '"optimize-images"' "$FRONTEND_DIR/package.json" 2>/dev/null; then
  echo "🖼️  Running image optimization..."
  (cd "$FRONTEND_DIR" && npm run optimize-images)
  if ! git -C "$REPO_ROOT" diff-index --quiet HEAD --; then
    echo "📝 Staging optimized assets..."
    git -C "$REPO_ROOT" add .
  fi
else
  echo "ℹ️  No optimize-images script in frontend/package.json — skipping."
fi

echo "📝 Creating commit (author + committer for this commit only)..."
export GIT_AUTHOR_NAME="$AUTHOR_NAME"
export GIT_AUTHOR_EMAIL="$AUTHOR_EMAIL"
export GIT_COMMITTER_NAME="$AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$AUTHOR_EMAIL"
git -C "$REPO_ROOT" commit --allow-empty -m "chore: deploy (Vercel CLI)" \
  --author="$AUTHOR_NAME <$AUTHOR_EMAIL>"

echo ""
echo "🚀 Deploying to Vercel (production) from repo root (matches dashboard Root Directory → frontend) ..."
echo ""

(cd "$REPO_ROOT" && npm run deploy-prod)

DEPLOY_EXIT_CODE=$?

echo ""
echo "🔄 Switching back to: $ORIGINAL_BRANCH"
git -C "$REPO_ROOT" checkout "$ORIGINAL_BRANCH"

echo "🗑️  Deleting local branch: $BRANCH_NAME"
git -C "$REPO_ROOT" branch -D "$BRANCH_NAME" 2>/dev/null || echo "⚠️  Could not delete branch $BRANCH_NAME"

echo ""
if [[ "$DEPLOY_EXIT_CODE" -eq 0 ]]; then
  echo "✅ Done. Deploy used Vercel CLI — no GitHub push required for the build."
else
  echo "⚠️  Vercel deploy exited with code: $DEPLOY_EXIT_CODE"
fi

exit "$DEPLOY_EXIT_CODE"
