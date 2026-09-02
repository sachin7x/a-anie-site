#!/usr/bin/env bash
# deploy.sh — Deploy the current directory to Vercel production for the
# `aanie-frontend` project. Used because the Vercel project is not GitHub-linked
# (the link requires browser OAuth that the CLI cannot automate). Without this
# script, `git push origin master` will NOT trigger a production deploy.
#
# Usage:
#   ./scripts/deploy.sh           # deploy current branch
#   ./scripts/deploy.sh --dry     # print what would happen, don't deploy
#
# After this script runs, smoke:prod and smoke:api should both stay green.

set -euo pipefail

DRY=0
if [[ "${1:-}" == "--dry" ]]; then
  DRY=1
fi

# Always run from repo root so the vercel project link resolves.
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# Guard: refuse to deploy if there are uncommitted changes, unless --force
if ! git diff --quiet || ! git diff --cached --quiet; then
  if [[ "${DEPLOY_FORCE:-0}" != "1" ]]; then
    echo "error: working tree has uncommitted changes. Commit, stash, or set DEPLOY_FORCE=1." >&2
    git status --short >&2
    exit 1
  fi
fi

# Capture current HEAD for the deploy log.
HEAD_SHA="$(git rev-parse HEAD)"
HEAD_SHORT="$(git rev-parse --short HEAD)"
BRANCH="$(git branch --show-current)"

echo "deploying branch=$BRANCH sha=$HEAD_SHORT to aanie-frontend production"

if [[ "$DRY" == "1" ]]; then
  echo "(dry-run) would run: vercel deploy --prod --yes --project aanie-frontend"
  exit 0
fi

# Deploy. The CLI may print a URL on success; we let that flow through.
vercel deploy --prod --yes --project aanie-frontend

# Post-deploy smoke check (best-effort, non-fatal).
echo "running smoke:prod..."
if npm run --silent smoke:prod 2>&1 | tail -3; then
  echo "smoke:prod OK"
else
  echo "warning: smoke:prod failed; investigate before considering this deploy successful" >&2
fi
