#!/usr/bin/env bash
# dsoul publish script v0.0.2 — review and run manually.
# Requires: dsoul CLI (diamond-soul-downloader).
# For non-interactive use set DSOUL_USER and DSOUL_TOKEN (or DSOUL_APPLICATION_KEY).
# Skills to publish: dsoul-publish @ 0.0.2 (only skill with a new version)
# Skipped (already published): dsoul-agent @ 0.0.1, dsoul-analyze @ 0.0.1, dsoul-cli @ 0.2.0

set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

SKILL_NAME="dsoul-publish"
SKILL_VERSION="0.0.2"
PREV_VERSION="0.0.1"

echo "=== Register (once) ==="
dsoul register -i

echo "=== Balance (before) ==="
dsoul balance
echo "If balance is too low for 1 freeze, exit and add credits then re-run."
read -p "Continue? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] || exit 1

echo "=== Package ==="
dsoul package "$ROOT/.cursor/skills/$SKILL_NAME"

echo "=== Freeze and record CID ==="
zip_path="$ROOT/.cursor/skills/$SKILL_NAME.zip"
if [ ! -f "$zip_path" ]; then
  echo "ERROR: zip not found at $zip_path"
  exit 1
fi

mkdir -p ".publish-history/$SKILL_NAME"

echo "Freezing $SKILL_NAME..."
out=$(dsoul freeze "$zip_path" \
  --filename="$SKILL_NAME" \
  --shortname="$SKILL_NAME" \
  --version="$SKILL_VERSION" \
  --tags=skill,dsoul,publish)

new_cid=$(echo "$out" | grep -oE 'Qm[A-Za-z0-9]{44,}' | head -1)
new_post_id=$(echo "$out" | grep -oiE 'post[_ -]?id[^0-9]*([0-9]+)' | grep -oE '[0-9]+' | head -1)

if [ -n "$new_cid" ]; then
  cp "$zip_path" ".publish-history/$SKILL_NAME/$SKILL_VERSION.zip"
  echo "$new_cid" > ".publish-history/$SKILL_NAME/$SKILL_VERSION.cid.txt"
  echo "  CID: $new_cid"
else
  echo "  Warning: could not extract CID from freeze output"
  echo "  Output was: $out"
  exit 1
fi

if [ -n "$new_post_id" ]; then
  echo "$new_post_id" > ".publish-history/$SKILL_NAME/$SKILL_VERSION.postid.txt"
  echo "  Post ID: $new_post_id"
else
  echo "  Warning: could not extract post ID — record it manually in .publish-history/$SKILL_NAME/$SKILL_VERSION.postid.txt"
fi

# Supersede previous version
# No postid file found for $PREV_VERSION — run this manually if you have the old post ID:
#   dsoul supercede <old-post-id> $new_cid
echo "  To link version history, run:"
echo "    dsoul supercede <old-post-id-for-$PREV_VERSION> $new_cid"

echo "=== Balance (after) ==="
dsoul balance
echo "Done. Packaged and froze $SKILL_NAME @ $SKILL_VERSION. CID recorded in .publish-history/$SKILL_NAME/."
