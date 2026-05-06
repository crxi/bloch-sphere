#!/usr/bin/env bash
# Push this repo to GitHub and enable GitHub Pages from main / root.
#
# Prereqs (one-time):
#   1. brew install gh        (already done if you ran setup_web_test.sh)
#   2. gh auth login          (interactive — pick GitHub.com, HTTPS, browser auth)
#
# Usage:
#   ./deploy_gh_pages.sh [repo-name] [public|private]
#
# Defaults to "bloch-sphere" + public. The repo is created under your
# logged-in user. Re-running is safe: if the repo already exists the
# script just pushes and re-enables Pages.

set -euo pipefail

REPO_NAME="${1:-bloch-sphere}"
VISIBILITY="${2:-public}"

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh not installed. brew install gh" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "ERROR: not logged in. Run: gh auth login" >&2
  exit 1
fi

OWNER="$(gh api user -q .login)"
FULL="$OWNER/$REPO_NAME"
echo "Target: github.com/$FULL  ($VISIBILITY)"

# Create the repo if it doesn't exist; otherwise just keep going.
if ! gh repo view "$FULL" >/dev/null 2>&1; then
  echo "Creating repo $FULL..."
  gh repo create "$REPO_NAME" --"$VISIBILITY" --source=. --remote=origin --push
else
  echo "Repo exists; making sure remote 'origin' points to it..."
  if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "https://github.com/$FULL.git"
  else
    git remote add origin "https://github.com/$FULL.git"
  fi
  git push -u origin main
fi

# Enable Pages from main / root.
echo "Enabling GitHub Pages..."
gh api -X POST "repos/$FULL/pages" \
  -f "source[branch]=main" -f "source[path]=/" \
  >/dev/null 2>&1 \
  || gh api -X PUT "repos/$FULL/pages" \
       -f "source[branch]=main" -f "source[path]=/" \
       >/dev/null 2>&1 \
  || true

# Wait for Pages to come up; the first build can take ~30s.
PAGES_URL=""
for _ in $(seq 1 30); do
  PAGES_URL="$(gh api "repos/$FULL/pages" -q .html_url 2>/dev/null || true)"
  [[ -n "$PAGES_URL" ]] && break
  sleep 2
done

cat <<EOF

================================================================
  Pushed to:   https://github.com/$FULL
  Pages URL:   ${PAGES_URL:-https://$OWNER.github.io/$REPO_NAME/}

  First build can take a minute. Hit refresh if 404s.
  After every edit:
      git push       # then wait ~30s for Pages to rebuild
================================================================

EOF
