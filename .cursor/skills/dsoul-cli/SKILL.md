---
name: dsoul-cli
description: How to install and use the dsoul CLI (Diamond Soul Downloader from cid-skills). Use when the user wants to install the dsoul CLI, or run any dsoul command (install, config, uninstall, update, upgrade, package, freeze, balance, files, register, unregister, help). Not for wallet/agent flow (use dsoul-create-wallet, dsoul-faucet, etc. for that).
license: MIT
metadata:
  author: DSoul.org
  version: "0.2.0"
---

# dsoul CLI (Diamond Soul Downloader)

The **dsoul** CLI comes from [NTBooks/cid-skills](https://github.com/NTBooks/cid-skills). It installs, updates, packages, and freezes skills by CID or shortname. **CLI credentials** (dsoul register/balance/files/freeze) are separate from **wallet/agent** credentials (dsoul-register, pnpm balance, etc.).

---

## Installing the CLI

Use when the user asks how to install dsoul or set up the `dsoul` command.

### Option 1: Development (npm link)

```bash
git clone https://github.com/NTBooks/cid-skills.git
cd cid-skills
npm install
npm link
```

Then `dsoul help` from any directory. Remove: `npm unlink -g diamond-soul-downloader`.

### Option 2: Global install from path

```bash
npm install -g /path/to/cid-skills
```

### Option 3: npx (no install)

```bash
npx diamond-soul-downloader install <cid-or-shortname>
npx diamond-soul-downloader help
```

### Option 4: Built app

- **Windows:** Add folder with **DSoul.exe** to PATH; run `DSoul.exe install ...` or `DSoul.exe help`.
- **macOS:** CLI at `Diamond Soul Downloader.app/Contents/MacOS/Diamond Soul Downloader`; symlink to PATH if desired.

After install: set skills folder for **-g** via app Options or `dsoul config skills-folder <path>` or `DSOUL_SKILLS_FOLDER`. Provider: `dsoul config dsoul-provider https://dsoul.org`.

---

## Commands (reference)

Pick the command that matches what the user asked; run it or tell the user to run it locally if the agent has no shell access.

### dsoul webstart

Start the web UI (default port 8148).

```bash
dsoul webstart [port]
```

Running `dsoul` with no arguments also starts the web UI. Port can also be set via `PORT` env var or `.env`.

### dsoul status

Show current config and credential status.

```bash
dsoul status
```

### dsoul search

Search the registry. Omit the query to browse the homepage.

```bash
dsoul search [query] [-n N] [--page=N]
```

- **-n N** — Number of results to return.
- **--page=N** — Page number for paginated results.

### dsoul install

Install a skill by CID or shortname. Blocked CIDs cannot be installed.

```bash
dsoul install [-g] [-y] <cid-or-shortname>
```

- **-g** — Install into configured global skills folder. Without **-g**, uses `./Skills` in cwd.
- **-y** — Non-interactive when multiple entries exist (pick oldest).

Examples: `dsoul install QmXoypiz...`, `dsoul install -g user@project:v1`.

### dsoul config

Set or view settings.

```bash
dsoul config <key> [value]
```

Keys: **dsoul-provider** (host, e.g. `https://dsoul.org`), **skills-folder** (path for `install -g`), **skills-folder-name** (display name for the skills folder). Omit value to print current value.

### dsoul uninstall

Remove a skill by CID or shortname.

```bash
dsoul uninstall <cid-or-shortname>
```

### dsoul update

Refresh blocklist and check for upgrades (does not install).

```bash
dsoul update [-g] [--local] [--delete-blocked | --no-delete-blocked]
```

### dsoul upgrade

Upgrade installed skills to latest versions.

```bash
dsoul upgrade [-g] [--local] [--delete-blocked | --no-delete-blocked]
```

### dsoul init

Create a new folder with a `skill.md` template inside a given directory.

```bash
dsoul init <directory>
```

### dsoul package

Create a zip bundle of a skill folder (must contain **license.txt** and **skill.md**).

```bash
dsoul package <folder>
```

Creates `<foldername>.zip` in the parent of the folder. The published name is set when you run `dsoul freeze`, not here.

### dsoul hash

Print the CIDv0 (IPFS) hash of a local file without uploading it.

```bash
dsoul hash cidv0 <file>
```

### dsoul freeze

Stamp a file on DSOUL to get an IPFS CID. Uses credentials from **dsoul register**.

```bash
dsoul freeze <file> [--filename=NAME] [--shortname=NAME] [--tags=tag1,tag2] [--version=X.Y.Z] [--license_url=URL] [--supercede=CID]
```

Requires **dsoul register** first. Shortname is optional; server infers `username@NAME:version`.

- **--filename=NAME** — Override the name the file is stored under on the server. If omitted, the local file's basename is used. The extension check for zip validation and upload mode is always based on the actual file on disk, so renaming via `--filename` won't break zip handling.

Examples:
```bash
# Store as a different name regardless of local filename
dsoul freeze ./output.md --filename=my-agent-soul.md --shortname=my-agent-soul --tags=soul,agent

# Name a zip bundle on upload
dsoul freeze ./build.zip --filename=my-skill-v2.zip --version=2.0.0
```

### dsoul supercede

Supersede stamps a **forward pointer on the old file** saying "I have been replaced by this new CID." Anyone holding the old CID can discover the newer version through it.

There are two ways to do this:

**1. At freeze time** — pass the old CID and the server resolves the chain:

```bash
dsoul freeze ./v2.zip --supercede=QmOldCid123... --version=2.0.0
```

**2. After upload** — apply retroactively using the old file's WordPress post ID and the new file's CID:

```bash
dsoul supercede <old-post-id> <new-cid>
```

- `<old-post-id>` is the WordPress post ID of the **old** file being superseded.
- `<new-cid>` is the IPFS CID of the **new** version that replaces it.

Returns 403 if you don't own the post. Requires **dsoul register** first.

### dsoul balance (CLI)

Check stamp/credit balance on DSOUL. Uses **CLI** credentials (from dsoul register), not wallet.json.

```bash
dsoul balance
```

Requires **dsoul register** first.

### dsoul files

List the user's frozen files (CID, title, date, shortnames, tags).

```bash
dsoul files [--page=N] [--per_page=N]
```

Requires **dsoul register** first.

### dsoul register (CLI)

Store WordPress username and application key for the CLI (balance, files, freeze).

```bash
dsoul register
```

Interactive: prompts for username and key. Non-interactive: set **DSOUL_USER** and **DSOUL_TOKEN** (or **DSOUL_APPLICATION_KEY**), then run `dsoul register`.

### dsoul unregister

Remove stored CLI credentials.

```bash
dsoul unregister
```

### dsoul plugin

Manage CLI plugins.

```bash
dsoul plugin list
dsoul plugin install <name> [-y]
```

- **list** — Show installed plugins.
- **install \<name\>** — Install a plugin by name. Use **-y** to skip confirmation.

### dsoul help

List all commands and options.

```bash
dsoul help
```

Also `dsoul -h` or `dsoul --help`. If the agent can run shell commands, run this and relay the output.

---

## Disambiguation

- **dsoul balance** (this skill) = CLI balance using credentials from `dsoul register`. Use when the user is talking about the dsoul CLI.
- **pnpm balance** / dsoul-balance skill = wallet/agent balance using wallet.json and the diamond-soul API. Use when the user is in the wallet/agent flow (create wallet → faucet → register → balance).
