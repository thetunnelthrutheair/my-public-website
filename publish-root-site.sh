
#!/usr/bin/env bash
set -Eeuo pipefail

USER="thetunnelthrutheair"
REPO="$USER.github.io"
SOURCE="$HOME/projects/website/my-public-website"
TARGET="$HOME/$REPO"

command -v gh >/dev/null || {
  echo "Install GitHub CLI first: https://cli.github.com/"
  exit 1
}

command -v git >/dev/null || {
  echo "Install Git first: sudo apt install git"
  exit 1
}

gh auth status >/dev/null 2>&1 || gh auth login

if [[ ! -f "$SOURCE/index.html" ]]; then
  echo "Missing $SOURCE/index.html"
  exit 1
fi

if gh repo view "$USER/$REPO" >/dev/null 2>&1; then
  echo "Repository already exists: $USER/$REPO"
  if [[ ! -d "$TARGET/.git" ]]; then
    echo "Clone it first or choose a different local folder: $TARGET"
    exit 1
  fi
else
  if [[ -e "$TARGET" ]]; then
    echo "Local target exists but repository does not."
    echo "Move $TARGET aside before continuing."
    exit 1
  fi
  gh repo create "$REPO" --public
  gh repo clone "$USER/$REPO" "$TARGET"
fi

cd "$TARGET"

# Copy the current site without copying the old repository's Git history.
cp -a "$SOURCE/." .
git add .

if ! git diff --cached --quiet; then
  git -c user.name="$USER" \
      -c user.email="$USER@users.noreply.github.com" \
      commit -m "Publish root website"
fi

git push -u origin HEAD:main

# Configure GitHub Pages to publish from main/root.
gh api --method POST "repos/$USER/$REPO/pages" \
  -f 'source[branch]=main' -f 'source[path]=/' >/dev/null 2>&1 ||
gh api --method PUT "repos/$USER/$REPO/pages" \
  -f 'source[branch]=main' -f 'source[path]=/' >/dev/null

echo
echo "Published source: https://github.com/$USER/$REPO"
echo "Your website: https://$USER.github.io/"
echo "Initial deployment may take several minutes."

