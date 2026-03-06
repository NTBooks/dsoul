#!/usr/bin/env bash
# dsoul publish script v0.2.0 — review and run manually.
# Requires: dsoul CLI (diamond-soul-downloader) v0.2.0+.
# For non-interactive use set DSOUL_USER and DSOUL_TOKEN (or DSOUL_APPLICATION_KEY).
# Skills to publish: dsoul-cli (only skill updated in this release)

set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
VERSION="0.2.0"
PREV_VERSION="0.0.1"
SKILLS=(dsoul-cli)
N=${#SKILLS[@]}

echo "=== Register (once) ==="
dsoul register -i

echo "=== Balance (before) ==="
dsoul balance
echo "If balance is too low for $N freezes, exit and add credits then re-run."
read -p "Continue? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] || exit 1

echo "=== Package each skill ==="
for shortcode in "${SKILLS[@]}"; do
  dsoul package "$ROOT/.cursor/skills/$shortcode"
done

for shortcode in "${SKILLS[@]}"; do
  mkdir -p ".publish-history/$shortcode"
done

echo "=== Freeze and record CIDs ==="
for shortcode in "${SKILLS[@]}"; do
  zip_path="$ROOT/.cursor/skills/$shortcode.zip"
  if [ ! -f "$zip_path" ]; then
    echo "  Skip $shortcode: zip not found at $zip_path"
    continue
  fi

  echo "Freezing $shortcode..."
  out=$(dsoul freeze "$zip_path" \
    --filename="$shortcode.zip" \
    --shortname="$shortcode" \
    --version="$VERSION" \
    --tags=skill,dsoul)

  new_cid=$(echo "$out" | grep -oE 'Qm[A-Za-z0-9]{44,}' | head -1)
  new_post_id=$(echo "$out" | grep -oE 'post[_ -]?id[^0-9]*([0-9]+)' | grep -oE '[0-9]+' | head -1)

  if [ -n "$new_cid" ]; then
    cp "$zip_path" ".publish-history/$shortcode/$VERSION.zip"
    echo "$new_cid" > ".publish-history/$shortcode/$VERSION.cid.txt"
    echo "  CID: $new_cid"
  else
    echo "  Warning: could not extract CID from freeze output for $shortcode"
    echo "  Output was: $out"
    continue
  fi

  if [ -n "$new_post_id" ]; then
    echo "$new_post_id" > ".publish-history/$shortcode/$VERSION.postid.txt"
    echo "  Post ID: $new_post_id"
  else
    echo "  Warning: could not extract post ID — record it manually in .publish-history/$shortcode/$VERSION.postid.txt"
  fi

  # Apply supercede: stamp the old file with the new CID as its successor
  prev_postid_file="$ROOT/.publish-history/$shortcode/$PREV_VERSION.postid.txt"
  if [ -f "$prev_postid_file" ] && [ -n "$new_cid" ]; then
    prev_post_id=$(cat "$prev_postid_file" | tr -d '[:space:]')
    echo "  Superseding old post $prev_post_id with new CID $new_cid..."
    dsoul supercede "$prev_post_id" "$new_cid"
  else
    echo "  No previous post ID found at $prev_postid_file"
    echo "  To link version history manually, run:"
    echo "    dsoul supercede <old-post-id> $new_cid"
  fi
done

echo "=== Balance (after) ==="
dsoul balance
echo "Done. Packaged and froze dsoul-cli. CID recorded in .publish-history/dsoul-cli/."
