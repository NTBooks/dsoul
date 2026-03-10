#!/usr/bin/env bash
set -euo pipefail

# =============================================================
# dsoul Publish Script — dsoul_publish_0.0.5.sh
# Skills to publish:
#   dsoul-cli     v0.2.3  supercedes QmZ5yJkyQ9dDvmEfu3faKi1cgSKSTfFEnXbf2dzs7GyLsr (v0.2.2)
#   dsoul-publish v0.0.5  supercedes QmRKnu75qTocbsdtVbw5Jeh5CoLd6gZP5F6sZ1kej4nYTi (v0.0.4)
# Skipped (already published):
#   dsoul-agent   v0.0.1
#   dsoul-analyze v0.0.1
# =============================================================

LOG_CLI=".publish-history/dsoul-cli/0.2.3.log.txt"
LOG_PUBLISH=".publish-history/dsoul-publish/0.0.5.log.txt"

mkdir -p ".publish-history/dsoul-cli"
mkdir -p ".publish-history/dsoul-publish"

echo "=== dsoul Publish Script ===" | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
echo "Date: $(date)"                | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
echo ""                             | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"

# 1. Register (already registered)
echo "--- Register ---" | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
dsoul register -i 2>&1 | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"

# 2. Balance (before)
echo ""                         | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
echo "--- Balance (before) ---" | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
dsoul balance 2>&1 | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"

# =============================================================
# Skill: dsoul-cli (v0.2.3)
# =============================================================
echo ""                           | tee -a "$LOG_CLI"
echo "--- Package: dsoul-cli ---" | tee -a "$LOG_CLI"
dsoul package .cursor/skills/dsoul-cli 2>&1 | tee -a "$LOG_CLI"

echo "--- Freeze: dsoul-cli v0.2.3 ---" | tee -a "$LOG_CLI"
TMP_CLI=$(mktemp)
dsoul freeze .cursor/skills/dsoul-cli.zip \
  --filename=dsoul-cli \
  --shortname=dsoul-cli \
  --version=0.2.3 \
  --tags=skill,dsoul,cli \
  --supercede=QmZ5yJkyQ9dDvmEfu3faKi1cgSKSTfFEnXbf2dzs7GyLsr \
  2>&1 | tee -a "$LOG_CLI" | tee "$TMP_CLI" || true

new_cid_cli=$(grep -oE 'Qm[A-Za-z0-9]{44,}' "$TMP_CLI" | head -1)
rm -f "$TMP_CLI"

if [[ -n "$new_cid_cli" ]]; then
  echo "CID: $new_cid_cli" | tee -a "$LOG_CLI"
  cp .cursor/skills/dsoul-cli.zip ".publish-history/dsoul-cli/0.2.3.zip"
  echo "$new_cid_cli" > ".publish-history/dsoul-cli/0.2.3.cid.txt"
  echo "dsoul-cli 0.2.3 published successfully." | tee -a "$LOG_CLI"
else
  echo "ERROR: Could not extract CID for dsoul-cli. Check $LOG_CLI for raw output." | tee -a "$LOG_CLI"
  exit 1
fi

# =============================================================
# Skill: dsoul-publish (v0.0.5)
# =============================================================
echo ""                                | tee -a "$LOG_PUBLISH"
echo "--- Package: dsoul-publish ---"  | tee -a "$LOG_PUBLISH"
dsoul package .cursor/skills/dsoul-publish 2>&1 | tee -a "$LOG_PUBLISH"

echo "--- Freeze: dsoul-publish v0.0.5 ---" | tee -a "$LOG_PUBLISH"
TMP_PUB=$(mktemp)
dsoul freeze .cursor/skills/dsoul-publish.zip \
  --filename="DSOUL SKILL dsoul-publish" \
  --shortname=dsoul-publish \
  --version=0.0.5 \
  --tags=skill,dsoul,publish \
  --supercede=QmRKnu75qTocbsdtVbw5Jeh5CoLd6gZP5F6sZ1kej4nYTi \
  2>&1 | tee -a "$LOG_PUBLISH" | tee "$TMP_PUB" || true

new_cid_pub=$(grep -oE 'Qm[A-Za-z0-9]{44,}' "$TMP_PUB" | head -1)
rm -f "$TMP_PUB"

if [[ -n "$new_cid_pub" ]]; then
  echo "CID: $new_cid_pub" | tee -a "$LOG_PUBLISH"
  cp .cursor/skills/dsoul-publish.zip ".publish-history/dsoul-publish/0.0.5.zip"
  echo "$new_cid_pub" > ".publish-history/dsoul-publish/0.0.5.cid.txt"
  echo "dsoul-publish 0.0.5 published successfully." | tee -a "$LOG_PUBLISH"
else
  echo "ERROR: Could not extract CID for dsoul-publish. Check $LOG_PUBLISH for raw output." | tee -a "$LOG_PUBLISH"
  exit 1
fi

# 3. Balance (after) + summary
echo ""                        | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
echo "--- Balance (after) ---" | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
dsoul balance 2>&1 | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"

echo ""                        | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
echo "=== Publish Summary ===" | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
echo "  dsoul-cli     0.2.3  => CID: $new_cid_cli"                                  | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
echo "  dsoul-publish 0.0.5  => CID: $new_cid_pub"                                  | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
echo "  Skipped: dsoul-agent (0.0.1), dsoul-analyze (0.0.1) -- already published."  | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
echo "=== Done ==="            | tee -a "$LOG_CLI" | tee -a "$LOG_PUBLISH"
