#!/usr/bin/env bash
# dsoul publish script v0.0.1 — review and run manually.
# Requires: dsoul CLI (diamond-soul-downloader). For non-interactive use set DSOUL_USER and DSOUL_TOKEN (or DSOUL_APPLICATION_KEY).
# Skills to publish: dsoul-agent, dsoul-analyze, dsoul-cli, dsoul-publish

set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
VERSION="0.0.1"
SKILLS=(dsoul-agent dsoul-analyze dsoul-cli dsoul-publish)
N=${#SKILLS[@]}

echo "=== Register (once) ==="
dsoul register -i

echo "=== Balance (before) ==="
dsoul balance
echo "If balance is too low for $N freezes, exit and add credits (e.g. pnpm buy-credits) then re-run."
read -p "Continue? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] || exit 1

echo "=== Package each skill ==="
for shortcode in "${SKILLS[@]}"; do
  dsoul package "$ROOT/.cursor/skills/$shortcode"
done

mkdir -p .publish-history/dsoul-agent .publish-history/dsoul-analyze .publish-history/dsoul-cli .publish-history/dsoul-publish

echo "=== Freeze and record CIDs ==="
for shortcode in "${SKILLS[@]}"; do
  zip_path="$ROOT/.cursor/skills/$shortcode.zip"
  if [ -f "$zip_path" ]; then
    echo "Freezing $shortcode..."
    out=$(dsoul freeze "$zip_path" --shortname="$shortcode" --version="$VERSION" --tags=skill,dsoul)
    cid=$(echo "$out" | grep -oE 'Qm[A-Za-z0-9]{44,}' | head -1)
    if [ -n "$cid" ]; then
      cp "$zip_path" ".publish-history/$shortcode/$VERSION.zip"
      echo "$cid" > ".publish-history/$shortcode/$VERSION.cid.txt"
      echo "  CID: $cid"
    fi
  else
    echo "  Skip $shortcode: zip not found at $zip_path"
  fi
done

echo "=== Balance (after) ==="
dsoul balance
echo "Done. Packaged $N skills, froze zips. CIDs recorded in .publish-history/<shortcode>/."
