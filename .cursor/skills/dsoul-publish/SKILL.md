---
name: DSOUL SKILL dsoul-publish
description: Bundle and publish skills with the dsoul CLI. Validates skills against the Agent Skills spec, ensures author/version/readme/license, then generates dsoul_publish_{version}.sh for review. Use when the user wants to prepare or publish skills to DSOUL, run pre-publish checks, or generate the publish script.
compatibility: Requires dsoul CLI (from cid-skills), project with package.json and .cursor/skills (or configured skills root). Use skills-ref to validate against Agent Skills spec if available.
license: MIT
metadata:
  author: DSoul.org
  version: "0.0.7"
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

- Keep a **`.publish-history`** folder at the **project root**. It is the **authority** on what has been sent to the server. **Retain all published versions over time**—do not overwrite or delete old entries.
- **Structure:** one subfolder per skill name (the `name` field from SKILL.md frontmatter), e.g. `.publish-history/dsoul-agent/`, `.publish-history/dsoul-cli/`. In each subfolder, each published version is recorded as:
  - **`<version>.zip`** — the frozen bundle.
  - **`<version>.cid.txt`** — the CID returned by the server after a successful freeze. Example: `.publish-history/dsoul-agent/0.0.1.zip` and `.publish-history/dsoul-agent/0.0.1.cid.txt`.
- **When generating the script:** for each skill, check if **`<version>.cid.txt`** exists under `.publish-history/<skill-name>/` (skill name from SKILL.md). If it exists, the version has already been published → skip. The presence of this file is the **sole** criterion; no CID comparison or re-packaging is needed.
- **After a successful freeze:** the script must copy the zip into `.publish-history/<skill-name>/<version>.zip` and write the CID to `.publish-history/<skill-name>/<version>.cid.txt` so the next run will correctly skip that version.

---

## Pre-publish workflow (run in order)

Execute these steps when the user asks to bundle, publish, or prepare skills. Stop on any failure; do not generate the script until all checks pass.

### 1. Resolve app version

- Read **version** from **`package.json`** at the **project root**. This is used only as the **publish script filename** (e.g. `dsoul_publish_{version}.sh`).
- Each skill manages its **own version** via `metadata.version` in its SKILL.md frontmatter. Do **not** overwrite individual skill versions from package.json.

### 2. Collect skill folders

- List direct child directories of the skills root (e.g. `.cursor/skills/`).
- Treat each child directory as a skill folder **only if** it contains **SKILL.md** (case-sensitive per spec: `SKILL.md`). If a folder has no SKILL.md, list it as invalid and do not include it in publish.
- For each valid skill folder, read the **`name`** field from SKILL.md frontmatter. Use this as the canonical skill name for packaging, freezing, and history lookups—**not** the folder name. (The spec requires them to match, but always use the SKILL.md `name` as the source of truth.)

### 2b. Skip installed (downloaded) skills

Skills installed via `dsoul install` are placed in a **`skills/`** subdirectory inside the configured skills folder, alongside a **`dsoul.json`** that tracks what was installed. These skills belong to their original authors and must **never** be included in a user's publish script.

**`dsoul.json` structure** (as written by `dsoul install`):

```json
{
  "skills": [
    {
      "cid": "QmRKnu75q...",
      "shortname": null,
      "num": 294,
      "src": "https://dsoul.org/diamond_file/.../",
      "hostname": "dsoul.org"
    }
  ]
}
```

Note: `shortname` may be `null`. There is no `name` field matching SKILL.md frontmatter. The key signal is the **presence of `dsoul.json` alongside skill folders**.

**Detection rule:** Any skill folder that is a **sibling of a `dsoul.json`** file was installed by `dsoul install` — not authored in this project.

- When collecting skill folders in step 2, also scan for **`dsoul.json`** files anywhere within the skills root and its subdirectories.
- For each `dsoul.json` found: all skill folders in the **same directory** as that `dsoul.json` are installed skills.
- **Exclude those folders entirely**—do not validate, package, or freeze them. Report each as "Skipped (installed/downloaded — not yours to publish)".
- If no `dsoul.json` is found anywhere in the skills root tree, proceed normally.

**Common paths to check:**

- `<skills-root>/skills/dsoul.json` (default: `Skills/skills/dsoul.json`)
- `<skills-root>/dsoul.json`
- `.cursor/skills/skills/dsoul.json` (if skills root is `.cursor/skills/`)

> **Why:** Users should only publish skills they authored. Installed skills were frozen by someone else; re-publishing them would create duplicate registry entries under the wrong author.

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

### 9. Version-based publish check

Each skill carries its own `metadata.version` in its SKILL.md frontmatter. The user is responsible for bumping a skill's version when they want it published. The **`.publish-history/<shortcode>/`** directory is the **authority** on what has been sent to the server.

For each skill (in the list that passed all prior checks):

1. **Read the skill's version** from its SKILL.md frontmatter (`metadata.version`, e.g. `”0.2.0”`).
2. **Check `.publish-history/<skill-name>/`** (using the `name` from SKILL.md, not the folder name): look for a file named **`<version>.cid.txt`** (e.g. `.publish-history/dsoul-cli/0.2.0.cid.txt`).
   - If that file **exists** → this exact version has already been published → mark skill as **skip**.
   - If that file **does not exist** (or no history folder exists for the skill name) → this version is new → mark skill as **publish**.
3. Never compare CIDs or re-package just to check; the presence of `<version>.cid.txt` is the sole criterion.

- Skills marked **skip**: omit from the publish script entirely. Do **not** modify their SKILL.md.
- Skills marked **publish**: include in the script. Their version is already correct in SKILL.md—do **not** overwrite it from package.json.

> **Summary of changed skills:** After the check, report to the user which skills are marked **publish** and which are **skip** before proceeding.

---

## Generate the publish script (only if all checks pass)

If and only if all steps above pass, and only for skills marked **publish** (not skip):

- Create a single file in the **project root**: **`dsoul_publish_{version}.sh`** (e.g. `dsoul_publish_0.0.1.sh`), where `{version}` is the version from **package.json**.
- Use Unix-style line endings and `#!/usr/bin/env bash` (or `#!/bin/bash`) so the user can run it on macOS/Linux; Windows users can run via Git Bash or WSL.

### Script contents (in order)

0. **Log file**
   - At the top of the script, set a log file path: **`.publish-history/<skill-name>/<version>.log.txt`** (one per skill being published).
   - **Every** CLI call’s full output (stdout + stderr) must be appended to this log file via `tee -a`. This captures raw server responses—including post IDs, CIDs, and error messages—for later inspection without relying on fragile grep patterns.

1. **Register once**
   Ensure CLI is registered: run **`dsoul register`** once at the start (or a conditional check if you have a way to detect “already registered”). If using env vars (**DSOUL_USER**, **DSOUL_TOKEN** / **DSOUL_APPLICATION_KEY**), the script can note that they must be set for non-interactive use. Pipe output to the log.

2. **Balance once**
   Run **`dsoul balance`** and pipe to log. If the balance is too low, print a clear message and exit non-zero.

3. **Package each skill to publish**
   For each skill **marked publish** (not skip), run:
   - **`dsoul package <path-to-skill-folder>`** and pipe to log.
   - Paths can be relative to project root (e.g. `.cursor/skills/dsoul-agent`). The zip is created in the parent of the folder.

4. **Freeze each skill and update .publish-history**
   For each packaged skill (the resulting zip) that is in the publish list:
   - **Skill name:** use the **`name` field from SKILL.md frontmatter** (e.g. `dsoul-agent`). This is used for `--filename`, `--shortname`, and history paths.
   - **Version:** use the **skill’s own `metadata.version`** from its SKILL.md frontmatter (not the package.json version).
   - **Tags:** derive from the skill’s README or metadata.
   - Run: **`dsoul freeze <path-to-zip> --filename=<skill-name> --shortname=<skill-name> --version=<version> [--tags=tag1,tag2,...]`**
   - `--filename=<skill-name>` sets the **display title** shown in the registry (no extension needed). Use the `name` field from SKILL.md frontmatter as the value.
   - Stream output in real-time with `tee -a <log-file>` **and** a temp file, then read CID from the temp file. Never capture to a variable first — `set -e` will kill the script before the variable can be echoed if freeze fails. Pattern:
     ```bash
     TMP=$(mktemp)
     dsoul freeze ... 2>&1 | tee -a "$LOG" | tee "$TMP" || true
     new_cid=$(sed ‘s/\x1b\[[0-9;]*m//g’ "$TMP" | grep ‘CID:’ | grep -v ‘supercede’ | grep -oE ‘Qm[A-Za-z0-9]{44,}’ | head -1)
     rm -f "$TMP"
     ```
   - **Critical — ANSI + supercede collision:** The CLI prints ANSI color codes and echoes the `--supercede=` CID in its output _before_ the new result CID. A bare `grep -oE ‘Qm...’ | head -1` will grab the old supercede CID instead of the new one. Always: (1) strip ANSI codes with `sed ‘s/\x1b\[[0-9;]*m//g’`, (2) filter to lines containing `CID:`, (3) exclude lines containing `supercede`.
   - Extract the CID from the captured output. Write it to **`.publish-history/<skill-name>/<version>.cid.txt`** and copy the zip to **`.publish-history/<skill-name>/<version>.zip`**.

5. **Balance again and summary**
   Run **`dsoul balance`** again (pipe to log) and print a short summary.

### Script behavior

- The script should **not** be executed by the agent after generation. The **human** will review and run it.
- The log file at `.publish-history/<skill-name>/<version>.log.txt` is the source of truth for the raw server response. If CID/post-ID extraction fails, the user can open the log to find the values manually.

---

## Summary

| Step | Action                                                                                                                                                                                                                                                                                                                       |
| ---- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | Read version from root **package.json** (script filename only; skill versions are independent)                                                                                                                                                                                                                               |
| 2    | List skill folders (direct children of skills root); require **SKILL.md**; read `name` from frontmatter as canonical skill name                                                                                                                                                                                              |
| 2b   | **Skip installed skills:** scan for any `dsoul.json` inside the skills root tree. Any skill folder that is a **sibling of a `dsoul.json`** was installed via `dsoul install` — exclude it entirely and report it as "Skipped (installed — not yours to publish)"                                                             |
| 3    | Validate each skill against Agent Skills spec (and skills-ref if available)                                                                                                                                                                                                                                                  |
| 4    | Ask for **author** if not in SKILL.md; set **metadata.author**                                                                                                                                                                                                                                                               |
| 5    | Add **readme** / **readme.txt** / **readme.md** if missing (generate one)                                                                                                                                                                                                                                                    |
| 6    | If no license: ask user (MIT / Apache-2.0 / No License) and set license or file                                                                                                                                                                                                                                              |
| 7    | **Stop** if any skill has **node_modules** or temp/artifact files                                                                                                                                                                                                                                                            |
| 8    | Ensure each skill has license (or explicit No License) and **SKILL.md** for **dsoul package**                                                                                                                                                                                                                                |
| 9    | **Version check:** read each skill’s `name` and `metadata.version` from SKILL.md; check if `.publish-history/<name>/<version>.cid.txt` exists → if yes, mark **skip**; if no, mark **publish**. Report results to user. Do **not** modify any versions.                                                                      |
| 10   | If all pass: write **dsoul*publish*{version}.sh** only for skills marked **publish** (register once, balance once, package/freeze each with `--filename=<name>` (no `.zip`) and `--shortname=<name>` from SKILL.md, update .publish-history with zip + CID after each freeze, balance + summary). Do **not** run the script. |

After generation, tell the user the script path and that they should review and run it themselves.
