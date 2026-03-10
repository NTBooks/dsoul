#!/usr/bin/env bash
set -euo pipefail

# =============================================================
# dsoul Publish Script — dsoul_publish_0.0.7.sh
# Skills to publish:
#   dsoul-publish v0.0.7  supercedes QmQQuiXfMBQ1pMUpAjy4B22M6Zt4c1CtdwFGnd9JJ9c8jo (v0.0.6)
# Skipped (already published):
#   dsoul-cli     v0.2.3
#   dsoul-agent   v0.0.1
#   dsoul-analyze v0.0.1
# =============================================================

LOG_PUBLISH=".publish-history/dsoul-publish/0.0.7.log.txt"

mkdir -p ".publish-history/dsoul-publish"

echo "=== dsoul Publish Script ===" | tee -a "$LOG_PUBLISH"
echo "Date: $(date)"                | tee -a "$LOG_PUBLISH"
echo ""                             | tee -a "$LOG_PUBLISH"

# 1. Register
echo "--- Register ---" | tee -a "$LOG_PUBLISH"
dsoul register -i 2>&1 | tee -a "$LOG_PUBLISH"

# 2. Balance (before)
echo ""                         | tee -a "$LOG_PUBLISH"
echo "--- Balance (before) ---" | tee -a "$LOG_PUBLISH"
dsoul balance 2>&1 | tee -a "$LOG_PUBLISH"

# =============================================================
# Skill: dsoul-publish (v0.0.7)
# Changes: fixed CID grep pattern (strip ANSI, exclude supercede line);
#          multi-root skill discovery; installed-skill skip logic
# =============================================================
echo ""                                | tee -a "$LOG_PUBLISH"
echo "--- Package: dsoul-publish ---"  | tee -a "$LOG_PUBLISH"
dsoul package .cursor/skills/dsoul-publish 2>&1 | tee -a "$LOG_PUBLISH"

echo "--- Freeze: dsoul-publish v0.0.7 ---" | tee -a "$LOG_PUBLISH"
TMP_PUB=$(mktemp)
dsoul freeze .cursor/skills/dsoul-publish.zip \
  --filename="DSOUL SKILL dsoul-publish" \
  --shortname=dsoul-publish \
  --version=0.0.7 \
  --tags=skill,dsoul,publish \
  --supercede=QmQQuiXfMBQ1pMUpAjy4B22M6Zt4c1CtdwFGnd9JJ9c8jo \
  2>&1 | tee -a "$LOG_PUBLISH" | tee "$TMP_PUB" || true

new_cid_pub=$(sed 's/\x1b\[[0-9;]*m//g' "$TMP_PUB" | grep 'CID:' | grep -v 'supercede' | grep -oE 'Qm[A-Za-z0-9]{44,}' | head -1)
rm -f "$TMP_PUB"

if [[ -n "$new_cid_pub" ]]; then
  echo "CID: $new_cid_pub" | tee -a "$LOG_PUBLISH"
  cp .cursor/skills/dsoul-publish.zip ".publish-history/dsoul-publish/0.0.7.zip"
  echo "$new_cid_pub" > ".publish-history/dsoul-publish/0.0.7.cid.txt"
  echo "dsoul-publish 0.0.7 published successfully." | tee -a "$LOG_PUBLISH"
else
  echo "ERROR: Could not extract CID for dsoul-publish. Check $LOG_PUBLISH for raw output." | tee -a "$LOG_PUBLISH"
  exit 1
fi

# 3. Balance (after) + summary
echo ""                        | tee -a "$LOG_PUBLISH"
echo "--- Balance (after) ---" | tee -a "$LOG_PUBLISH"
dsoul balance 2>&1 | tee -a "$LOG_PUBLISH"

echo ""                        | tee -a "$LOG_PUBLISH"
echo "=== Publish Summary ===" | tee -a "$LOG_PUBLISH"
echo "  dsoul-publish 0.0.7  => CID: $new_cid_pub"                                                    | tee -a "$LOG_PUBLISH"
echo "  Skipped: dsoul-cli (0.2.3), dsoul-agent (0.0.1), dsoul-analyze (0.0.1) -- already published." | tee -a "$LOG_PUBLISH"
echo "=== Done ==="            | tee -a "$LOG_PUBLISH"
