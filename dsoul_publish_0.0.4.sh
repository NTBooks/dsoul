#!/usr/bin/env bash
set -euo pipefail

# =============================================================
# dsoul Publish Script — dsoul_publish_0.0.4.sh
# Skills to publish:
#   dsoul-publish v0.0.4  (display: "DSOUL SKILL dsoul-publish")
#     supercedes: QmS77qf555oLanzRsVy76DnUvUiMmJuzHGTTWfQWRKhBfK (v0.0.3)
# Skipped (already published):
#   dsoul-agent   v0.0.1
#   dsoul-analyze v0.0.1
#   dsoul-cli     v0.2.2
# =============================================================

LOG=".publish-history/dsoul-publish/0.0.4.log.txt"
mkdir -p ".publish-history/dsoul-publish"

echo "=== dsoul Publish Script ===" | tee -a "$LOG"
echo "Date: $(date)"                | tee -a "$LOG"
echo ""                             | tee -a "$LOG"

# 1. Register (already registered; -i keeps it non-destructive)
echo "--- Register ---" | tee -a "$LOG"
dsoul register -i 2>&1 | tee -a "$LOG"

# 2. Balance (before)
echo ""                         | tee -a "$LOG"
echo "--- Balance (before) ---" | tee -a "$LOG"
dsoul balance 2>&1 | tee -a "$LOG"

# =============================================================
# Skill: dsoul-publish (v0.0.4)
# =============================================================
echo ""                                | tee -a "$LOG"
echo "--- Package: dsoul-publish ---"  | tee -a "$LOG"
dsoul package .cursor/skills/dsoul-publish 2>&1 | tee -a "$LOG"

echo ""                                     | tee -a "$LOG"
echo "--- Freeze: dsoul-publish v0.0.4 ---" | tee -a "$LOG"
TMP=$(mktemp)
dsoul freeze .cursor/skills/dsoul-publish.zip \
  --filename="DSOUL SKILL dsoul-publish" \
  --shortname=dsoul-publish \
  --version=0.0.4 \
  --tags=skill,dsoul,publish \
  --supercede=QmS77qf555oLanzRsVy76DnUvUiMmJuzHGTTWfQWRKhBfK \
  2>&1 | tee -a "$LOG" | tee "$TMP" || true

new_cid=$(grep -oE 'Qm[A-Za-z0-9]{44,}' "$TMP" | head -1)
rm -f "$TMP"

if [[ -n "$new_cid" ]]; then
  echo "CID: $new_cid" | tee -a "$LOG"
  cp .cursor/skills/dsoul-publish.zip ".publish-history/dsoul-publish/0.0.4.zip"
  echo "$new_cid" > ".publish-history/dsoul-publish/0.0.4.cid.txt"
  echo "dsoul-publish 0.0.4 published successfully." | tee -a "$LOG"
else
  echo "ERROR: Could not extract CID. Check $LOG for raw output." | tee -a "$LOG"
  exit 1
fi

# 3. Balance (after) + summary
echo ""                        | tee -a "$LOG"
echo "--- Balance (after) ---" | tee -a "$LOG"
dsoul balance 2>&1 | tee -a "$LOG"

echo ""                        | tee -a "$LOG"
echo "=== Publish Summary ===" | tee -a "$LOG"
echo "  dsoul-publish 0.0.4  => CID: $new_cid"                                      | tee -a "$LOG"
echo "  Skipped: dsoul-agent (0.0.1), dsoul-analyze (0.0.1), dsoul-cli (0.2.2)."    | tee -a "$LOG"
echo "=== Done ==="            | tee -a "$LOG"
