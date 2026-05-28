#!/usr/bin/env bash
#
# Heirloom one-command release.
#
#   ./release.sh            # re-release the current pubspec version
#   ./release.sh 1.0.2      # bump pubspec to 1.0.2 (build number auto-increments), then release
#
# Does: optional version bump → test → build release APK → tag → push to
# GitHub + GitLab → create/update a release with heirloom.apk on both.
#
set -euo pipefail
cd "$(dirname "$0")"

REPO="tariknaeem/heirloom"
APK_SRC="build/app/outputs/flutter-apk/app-release.apk"
APK_OUT="/tmp/heirloom.apk"
NOTES_FILE="/tmp/heirloom_notes.md"

step() { printf '\n▶ %s\n' "$1"; }

# ── version ───────────────────────────────────────────────────────────────────
NEWVER="${1:-}"
CUR=$(grep -E '^version:' pubspec.yaml | sed -E 's/version:[[:space:]]*//')
CURNAME="${CUR%%+*}"; CURBUILD="${CUR##*+}"
if [ -n "$NEWVER" ]; then
  BUILD=$((CURBUILD + 1))
  sed -i '' -E "s/^version:.*/version: ${NEWVER}+${BUILD}/" pubspec.yaml
  VERNAME="$NEWVER"
  git add pubspec.yaml
  git commit -m "chore: bump version to ${NEWVER}+${BUILD}" >/dev/null
  echo "  bumped pubspec → ${NEWVER}+${BUILD}"
else
  VERNAME="$CURNAME"
fi
TAG="v${VERNAME}"

# ── guard: clean working tree ─────────────────────────────────────────────────
if [ -n "$(git status --porcelain)" ]; then
  echo "✗ Working tree not clean — commit or stash first:"; git status -s; exit 1
fi

# ── test + build ──────────────────────────────────────────────────────────────
step "Running tests"
flutter test
step "Building release APK"
flutter build apk --release
[ -f "$APK_SRC" ] || { echo "✗ APK not found at $APK_SRC"; exit 1; }
cp "$APK_SRC" "$APK_OUT"

# ── release notes from commits since the previous tag ─────────────────────────
PREVTAG=$(git describe --tags --abbrev=0 2>/dev/null || true)
if [ -n "$PREVTAG" ] && [ "$PREVTAG" != "$TAG" ]; then
  CHANGES=$(git log "${PREVTAG}..HEAD" --pretty='- %s' | grep -v '^- chore: bump' || true)
else
  CHANGES=$(git log -8 --pretty='- %s' | grep -v '^- chore: bump' || true)
fi
[ -z "$CHANGES" ] && CHANGES="- Maintenance release"

cat > "$NOTES_FILE" <<EOF
**Heirloom ${TAG}**

### Changes
${CHANGES}

### 📲 Install
1. On your Android phone, download **\`heirloom.apk\`** below.
2. Open it; if prompted, allow **"Install unknown apps"**.
3. Launch **Heirloom**.

> Debug-signed for free distribution — Android shows an "unknown developer"
> warning, which is normal for apps installed outside the Play Store.
EOF

# ── tag + push to both remotes ────────────────────────────────────────────────
git tag -a "$TAG" -m "Heirloom $TAG" 2>/dev/null || echo "  tag $TAG already exists, reusing"
step "Pushing to GitHub + GitLab"
git push origin master --follow-tags
git push gitlab master --follow-tags

# ── GitHub release (create, or clobber asset if it already exists) ────────────
step "Publishing GitHub release"
if gh release view "$TAG" >/dev/null 2>&1; then
  gh release edit "$TAG" --notes-file "$NOTES_FILE"
  gh release upload "$TAG" "${APK_OUT}#heirloom.apk" --clobber
else
  gh release create "$TAG" "${APK_OUT}#heirloom.apk" --title "Heirloom $TAG" --notes-file "$NOTES_FILE"
fi

# ── GitLab release ────────────────────────────────────────────────────────────
step "Publishing GitLab release"
if glab release view "$TAG" -R "$REPO" >/dev/null 2>&1; then
  glab release upload "$TAG" "$APK_OUT" -R "$REPO" 2>/dev/null || true
else
  glab release create "$TAG" "$APK_OUT" --name "Heirloom $TAG" --notes-file "$NOTES_FILE" -R "$REPO"
fi

cat <<EOF

✓ Released ${TAG}
  GitHub : https://github.com/${REPO}/releases/tag/${TAG}
  GitLab : https://gitlab.com/${REPO}/-/releases/${TAG}
  Latest : https://github.com/${REPO}/releases/latest
EOF
