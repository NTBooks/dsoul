#!/usr/bin/env bash
set -euo pipefail

# =============================================================
# dsoul Publish Script — dsoul_publish_0.0.3.sh
# Skills to publish:
#   dsoul-cli     v0.2.2
#   dsoul-publish v0.0.3
# Skipped (already published):
#   dsoul-agent   v0.0.1
#   dsoul-analyze v0.0.1
# =============================================================

# Log files (one per skill being published)
LOG_CLI=".publish-history/dsoul-cli/0.2.2.log.txt"
LOG_PUBLISH=".publish-history/dsoul-publish/0.0.3.log.txt"

mkdir -p ".publish-history/dsoul-cli"
mkdir -p ".publish-history/dsoul-publish"

echo "=== dsoul Publish Script ===" | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
echo "Date: $(date)"                | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
echo ""                             | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"

# Non-interactive use: set DSOUL_USER and DSOUL_TOKEN (or DSOUL_APPLICATION_KEY)
if [[ -z "${DSOUL_USER:-}" || ( -z "${DSOUL_TOKEN:-}" && -z "${DSOUL_APPLICATION_KEY:-}" ) ]]; then
  echo "NOTE: DSOUL_USER and DSOUL_TOKEN (or DSOUL_APPLICATION_KEY) are not set."
  echo "      dsoul register will run interactively."
fi

# 1. Register
echo "--- Register ---" | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
dsoul register -i 2>&1 | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"

# 2. Balance (before)
echo ""                         | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
echo "--- Balance (before) ---" | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
TMP_BAL=$(mktemp)
dsoul balance 2>&1 | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH" | tee "$TMP_BAL" || true
if grep -qiE 'insufficient|0 stamp|no stamp' "$TMP_BAL"; then
  echo "WARNING: Balance may be too low to freeze. Review and exit if needed."
fi
rm -f "$TMP_BAL"

# =============================================================
# Skill: dsoul-cli (v0.2.2)
# =============================================================
echo ""                           | tee -a "$LOG_CLI"
echo "--- Package: dsoul-cli ---" | tee -a "$LOG_CLI"
dsoul package .cursor/skills/dsoul-cli 2>&1 | tee -a "$LOG_CLI"

echo "--- Freeze: dsoul-cli v0.2.2 ---" | tee -a "$LOG_CLI"
TMP_CLI=$(mktemp)
dsoul freeze .cursor/skills/dsoul-cli.zip \
  --filename=dsoul-cli \
  --shortname=dsoul-cli \
  --version=0.2.2 \
  --tags=skill,dsoul,cli \
  --supercede=QmPmWA5NjYMwwB9Km67xCmnDrJHYaFqh45LKSYYRFjPnsL \
  2>&1 | tee -a "$LOG_CLI" | tee "$TMP_CLI" || true

new_cid_cli=$(grep -oE 'Qm[A-Za-z0-9]{44,}' "$TMP_CLI" | head -1)
rm -f "$TMP_CLI"

if [[ -n "$new_cid_cli" ]]; then
  echo "CID: $new_cid_cli" | tee -a "$LOG_CLI"
  cp .cursor/skills/dsoul-cli.zip ".publish-history/dsoul-cli/0.2.2.zip"
  echo "$new_cid_cli" > ".publish-history/dsoul-cli/0.2.2.cid.txt"
  echo "dsoul-cli 0.2.2 published successfully." | tee -a "$LOG_CLI"
else
  echo "ERROR: Could not extract CID for dsoul-cli. Check $LOG_CLI for raw output." | tee -a "$LOG_CLI"
  exit 1
fi

# =============================================================
# Skill: dsoul-publish (v0.0.3)
# =============================================================
echo ""                                | tee -a "$LOG_PUBLISH"
echo "--- Package: dsoul-publish ---"  | tee -a "$LOG_PUBLISH"
dsoul package .cursor/skills/dsoul-publish 2>&1 | tee -a "$LOG_PUBLISH"

echo "--- Freeze: dsoul-publish v0.0.3 ---" | tee -a "$LOG_PUBLISH"
TMP_PUB=$(mktemp)
dsoul freeze .cursor/skills/dsoul-publish.zip \
  --filename=dsoul-publish \
  --shortname=dsoul-publish \
  --version=0.0.3 \
  --tags=skill,dsoul,publish \
  --supercede=QmWwAeoVHJWdZdfP8pvgzLng5pNQfcqQFcFjBUCzgBr2SL \
  2>&1 | tee -a "$LOG_PUBLISH" | tee "$TMP_PUB" || true

new_cid_pub=$(grep -oE 'Qm[A-Za-z0-9]{44,}' "$TMP_PUB" | head -1)
rm -f "$TMP_PUB"

if [[ -n "$new_cid_pub" ]]; then
  echo "CID: $new_cid_pub" | tee -a "$LOG_PUBLISH"
  cp .cursor/skills/dsoul-publish.zip ".publish-history/dsoul-publish/0.0.3.zip"
  echo "$new_cid_pub" > ".publish-history/dsoul-publish/0.0.3.cid.txt"
  echo "dsoul-publish 0.0.3 published successfully." | tee -a "$LOG_PUBLISH"
else
  echo "ERROR: Could not extract CID for dsoul-publish. Check $LOG_PUBLISH for raw output." | tee -a "$LOG_PUBLISH"
  exit 1
fi

# 5. Final balance + summary
echo ""                        | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
echo "--- Balance (after) ---" | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
dsoul balance 2>&1 | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"

echo ""                        | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
echo "=== Publish Summary ===" | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
echo "  dsoul-cli     0.2.2  => CID: $new_cid_cli"                                 | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
echo "  dsoul-publish 0.0.3  => CID: $new_cid_pub"                                 | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
echo "  Skipped: dsoul-agent (0.0.1), dsoul-analyze (0.0.1) -- already published." | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
echo "=== Done ==="            | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
