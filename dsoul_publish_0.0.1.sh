#!/usr/bin/env bash
# dsoul publish script v0.0.1 — review and run manually.
# Requires: dsoul CLI (diamond-soul-downloader), DSOUL_USER/DSOUL_TOKEN or DSOUL_APPLICATION_KEY for non-interactive use.
# Skills to publish: dsoul-agent, dsoul-analyze, dsoul-cli, dsoul-publish

set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "=== Register (once) ==="
dsoul register

echo "=== Balance (before) ==="
dsoul balance
# If balance too low for 4 freezes, exit here (add check if needed)

echo "=== Package each skill ==="
dsoul package "$ROOT/.cursor/skills/dsoul-agent"
dsoul package "$ROOT/.cursor/skills/dsoul-analyze"
dsoul package "$ROOT/.cursor/skills/dsoul-cli"
dsoul package "$ROOT/.cursor/skills/dsoul-publish"

VERSION="0.0.1"
mkdir -p .publish-history/dsoul-agent .publish-history/dsoul-analyze .publish-history/dsoul-cli .publish-history/dsoul-publish

echo "=== Freeze and record CIDs ==="
for shortcode in dsoul-agent dsoul-analyze dsoul-cli dsoul-publish; do
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
  fi
done

echo "=== Balance (after) ==="
dsoul balance
echo "Done. Packaged 4 skills, froze 4 zips. Update .publish-history with CIDs from freeze output if needed."
