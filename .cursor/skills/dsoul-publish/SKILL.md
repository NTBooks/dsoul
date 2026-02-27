---
name: dsoul-publish
description: Bundle and publish skills with the dsoul CLI. Validates skills against the Agent Skills spec, ensures author/version/readme/license, then generates dsoul_publish_{version}.sh for review. Use when the user wants to prepare or publish skills to DSOUL, run pre-publish checks, or generate the publish script.
compatibility: Requires dsoul CLI (from cid-skills), project with package.json and .cursor/skills (or configured skills root). Use skills-ref to validate against Agent Skills spec if available.
license: MIT
metadata:
  author: DSoul.org
  version: "0.0.1"
---

# dsoul Publish (Bundle & Publish Skills)

This skill uses the **dsoul CLI** to validate, prepare, and generate a publish script for all skills in the project. It does **not** run the generated script—the human reviews and runs it.

**Spec:** Validate against [Agent Skills specification](https://agentskills.io/specification). Optionally validate with `skills-ref validate ./skill-dir` from [agentskills/agentskills](https://github.com/agentskills/agentskills/tree/main/skills-ref).

---

## Skills root

- Default skills root: **`.cursor/skills/`** (project root relative).
- Each **skill** is a direct child directory (e.g. `.cursor/skills/dsoul-agent/`, `.cursor/skills/dsoul-cli/`) that must contain **SKILL.md**.

---

## Publish history (`.publish-history`)

- Keep a **`.publish-history`** folder at the **project root**. It stores a copy of **every** published bundle and its CID so future runs can skip unchanged skills. **Retain all published versions over time**—do not overwrite or delete old entries.
- **Structure:** one subfolder per shortcode (folder name), e.g. `.publish-history/dsoul-agent/`, `.publish-history/dsoul-cli/`. In each subfolder, **accumulate** entries so all versions are kept:
  - **Option A (versioned files):** save each publish as `<shortcode>/<version>.zip` and `<shortcode>/<version>.cid.txt` (or `<version>.json` with `cid`, `frozenAt`). Example: `.publish-history/dsoul-agent/0.0.1.zip`, `.publish-history/dsoul-agent/0.0.1.cid.txt`.
  - **Option B (manifest):** keep a single `manifest.json` per shortcode that **appends** each publish, e.g. `{ "entries": [ { "version": "0.0.1", "cid": "Qm...", "frozenAt": "..." }, ... ] }`, and store each zip as `<shortcode>/<version>.zip` (or by CID) so you have a full history.
- **When generating the script:** consult `.publish-history/<shortcode>/` and read **all** recorded CIDs for that shortcode (from all versions). Only include a skill in the script if its **new** bundle CID is not already in that history (i.e. content has changed).
- **After a successful freeze:** the script (or the user) must **add** (not overwrite) the new version: copy the frozen zip into `.publish-history/<shortcode>/` with a versioned or unique name (e.g. `<version>.zip`) and record the CID (e.g. `<version>.cid.txt` or append to `manifest.json`) so the next run can detect duplicates and history remains complete.

---

## Pre-publish workflow (run in order)

Execute these steps when the user asks to bundle, publish, or prepare skills. Stop on any failure; do not generate the script until all checks pass.

### 1. Resolve app version

- Read **version** from **`package.json`** at the **project root**.
- Use this version for all skills (update `metadata.version` or equivalent in each SKILL.md frontmatter when syncing).

### 2. Collect skill folders

- List direct child directories of the skills root (e.g. `.cursor/skills/`).
- Treat each child directory as a skill folder **only if** it contains **SKILL.md** (case-sensitive per spec: `SKILL.md`). If a folder has no SKILL.md, list it as invalid and do not include it in publish.

### 3. Validate against Agent Skills spec

For each skill folder:

- **SKILL.md** must exist and contain valid YAML frontmatter followed by Markdown.
- **Frontmatter:**
  - **name** (required): 1–64 chars; lowercase letters, numbers, hyphens only; no leading/trailing hyphen; no consecutive hyphens; must match the **folder name**.
  - **description** (required): 1–1024 chars; describes what the skill does and when to use it.
  - **license** (optional): short license name or reference to a file.
  - **compatibility** (optional): max 500 chars if present.
  - **metadata** (optional): e.g. `author`, `version`.
- Reject if frontmatter is invalid or name does not match folder name.

If `skills-ref` is available: run `skills-ref validate <path-to-skill>` for each skill and surface errors.

### 4. Author

- For each skill, check **SKILL.md** frontmatter for **metadata.author** (or equivalent author field).
- If **author is missing**: ask the user for the author (e.g. "Author for skill X?") and then update that skill’s SKILL.md frontmatter with `metadata.author: <value>`.

### 5. README per skill

- Set each skill’s version to the **project root package.json** version.
- Update **metadata.version** (or the spec’s version field) in each skill’s **SKILL.md** frontmatter to that version (e.g. `"0.0.1"`).

- In each skill folder, look for **readme**, **readme.txt**, or **readme.md** (any casing acceptable for detection).
- If **none** of these exist: **generate** a README for that skill (e.g. **readme.md**). Base it on the skill’s **name** and **description** from SKILL.md, and optionally a short “How to use” or “When to use” line. Keep it concise.
- If at least one exists, leave it as is (do not overwrite).

### 6. License per skill

- In each skill folder, check for a **license** in SKILL.md frontmatter (**license** field) or for a license file (e.g. **license.txt**, **LICENSE**).
- If **no license** is specified and no license file is present: **ask** the user whether to add a license and suggest:
  - **MIT**
  - **Apache-2.0**
  - **No License**
- If the user chooses MIT or Apache-2.0: add the **license** field to SKILL.md frontmatter and add **license.txt** in the skill folder with the standard text. If the user chooses “No License”, record that and set frontmatter **license** to something like "Unlicensed" or "No license" and add a minimal **license.txt** (e.g. "Unlicensed. No license granted.") so **dsoul package** still succeeds (it requires license.txt).

### 7. Block temp files and node_modules

- For each skill folder, check for:
  - **node_modules** (directory)
  - Common temp/editor artifacts (e.g. `*.tmp`, `*.temp`, `*.swp`, `*~`, `.DS_Store`, `Thumbs.db`, or a **.tmp** / **temp** directory inside the skill).
- If **any** skill folder contains **node_modules** or such temp/artifact files or directories: **stop**. Do not proceed with publish. Report which skill(s) and which paths are invalid and ask the user to remove them before generating the script.

### 8. dsoul package requirements

- **dsoul package** expects **license.txt** and **skill.md** (or **SKILL.md**; use the filename your CLI accepts) in each skill folder. Ensure every skill has **license.txt** and **SKILL.md** before generating the script. If the CLI only accepts lowercase **skill.md**, add a comment in the script or a prep step to copy/link SKILL.md to skill.md.

### 9. Duplicate check (CID before version)

- **Do not** update any skill version yet. For each skill (in the list that passed all prior checks):
  1. **Package** the skill (build the bundle with current contents; e.g. run **`dsoul package <path-to-skill-folder>`** or equivalent so the zip exists).
  2. **Compute the CID** of that new bundle (e.g. run **`ipfs add --only-hash <path-to-zip>`** on the zip, or use a content hash of the zip as the identifier; store the same format as in `.publish-history`).
  3. **Consult `.publish-history/<shortcode>/`** (shortcode = folder name): read the recorded CID(s) for that shortcode. If the **new bundle CID equals** an already published CID for that shortcode, the skill is **unchanged** → mark as **skip**.
  4. If the CID is **new** (or there is no history for that shortcode), mark the skill as **publish**.
- For skills marked **skip**: do **not** update their **metadata.version** to the package version; **omit** them from the publish script.
- For skills marked **publish**: include them in the script and update their version in the next step.

### 10. Sync version from package.json (publish-only)

- For each skill marked **publish** (not skip), set that skill version to the **project root package.json** version.
- Update **metadata.version** in each such skill's **SKILL.md** frontmatter (e.g. `"0.0.1"`). Do **not** change version for skills marked **skip**. (Original: Ensure every skill has a license (or explicit “No License” and user acceptance) and **SKILL.md** before generating the script.

---

## Generate the publish scripts (only if all checks pass)

If and only if all steps above pass, and only for skills marked **publish** (not skip):

- Create a Bash script in the **project root**: **`dsoul_publish_{version}.sh`** (e.g. `dsoul_publish_0.0.1.sh`), where `{version}` is the version from **package.json**.
  - Use Unix-style line endings and `#!/usr/bin/env bash` (or `#!/bin/bash`) so the user can run it on macOS/Linux; Windows users can run via Git Bash or WSL.
- Create a Windows batch script in the **project root**: **`dsoul_publish_{version}.bat`** (e.g. `dsoul_publish_0.0.1.bat`), with the **same logical steps** (register, balance, package, freeze, update `.publish-history`, balance again), but implemented with standard `cmd.exe` batch syntax.

### Script contents (in order)

1. **Register once**  
   Ensure CLI is registered: run **`dsoul register`** once at the start (or a conditional check if you have a way to detect “already registered”). If using env vars (**DSOUL_USER**, **DSOUL_TOKEN** / **DSOUL_APPLICATION_KEY**), the script can note that they must be set for non-interactive use.

2. **Balance once**  
   Run **`dsoul balance`**. If the balance is too low for the **number of skills to freeze** (only those marked publish), **print a clear message** (e.g. “Low credits; need more stamps/credits before freezing”) and exit with a non-zero code. Otherwise continue.

3. **Package each skill to publish**  
   For each skill **marked publish** (not skip), run:
   - **`dsoul package <path-to-skill-folder>`**
   - Paths can be relative to project root (e.g. `.cursor/skills/dsoul-agent`). The zip is created in the parent of the folder.

4. **Freeze each skill and update .publish-history**  
   For each packaged skill (the resulting zip) that is in the publish list:
   - **Shortcode:** use the **folder name** (e.g. `dsoul-agent`, `dsoul-cli`).
   - **Version:** use the **version from package.json** (same as in the script filename).
   - **Tags:** derive from the skill’s README or metadata. The script **may call `agent`** (or an equivalent) to compute tags from the readme or other data if needed; document this in comments in the script.
   - Run: **`dsoul freeze <path-to-zip> --shortname=<folder-name> --version=<version> [--tags=tag1,tag2,...]`**
   - Add **updated shortcode/version** when freezing (i.e. always pass `--shortname=<folder-name>` and `--version=<version>`).
   - **After a successful freeze:** **add** (do not overwrite) the new version to history: copy the zip into **`.publish-history/<shortcode>/`** with a versioned name (e.g. `<version>.zip`) and record the **CID** (e.g. `<version>.cid.txt` or append to `manifest.json`) so the next run can detect duplicates and all published versions are retained.

5. **Balance again and summary**  
   Run **`dsoul balance`** again and **print a short summary** of actions (e.g. “Registered, checked balance, packaged N skills, froze N zips, final balance: …”).

### Script behavior

- The script should **not** be executed by the agent after generation. The **human** will review and run it.
- If tags or other values need to be computed (e.g. from readme), the script may invoke **`agent`** (or a helper) and use the result in **`dsoul freeze --tags=...`**; document how and when in comments.

---

## Summary

| Step | Action |
|------|--------|
| 1 | Read version from root **package.json** |
| 2 | List skill folders (direct children of skills root); require **SKILL.md** |
| 3 | Validate each skill against Agent Skills spec (and skills-ref if available) |
| 4 | Ask for **author** if not in SKILL.md; set **metadata.author** |
| 5 | Add **readme**’s / **readme.txt** / **readme.md** if missing (generate one) |
| 6 | If no license: ask user (MIT / Apache-2.0 / No License) and set license or file |
| 7 | **Stop** if any skill has **node_modules** or temp/artifact files |
| 8 | Ensure each skill has license (or explicit No License) and **SKILL.md** for **dsoul package** |
| 9 | **Duplicate check:** package each skill, compute CID **before** version bump; consult **.publish-history**; if CID already published → mark **skip** (omit from script, do not update version); else mark **publish** |
| 10 | **Sync version** from package.json only for skills marked **publish**; do not change version for **skip** |
| 11 | If all pass: write **dsoul_publish_{version}.sh** and **dsoul_publish_{version}.bat** only for skills marked **publish** (register once, balance once, package/freeze each, update .publish-history with zip + CID after each freeze, balance + summary). Do **not** run the scripts. |

After generation, tell the user the script path and that they should review and run it themselves.
