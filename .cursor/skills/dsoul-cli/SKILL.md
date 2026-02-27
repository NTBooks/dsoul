---
name: dsoul-cli
description: How to install and use the dsoul CLI (Diamond Soul Downloader from cid-skills). Use when the user wants to install the dsoul CLI, or run any dsoul command (install, config, uninstall, update, upgrade, package, freeze, balance, files, register, unregister, help). Not for wallet/agent flow (use dsoul-create-wallet, dsoul-faucet, etc. for that).
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

Keys: **dsoul-provider** (host, e.g. `https://dsoul.org`), **skills-folder** (path for `install -g`). Omit value to print current value.

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
dsoul upgrade [-g] [--local] [-y]
```

### dsoul package

Create a zip of a skill folder (must contain **license.txt** and **skill.md**).

```bash
dsoul package <folder>
```

Creates `<foldername>.zip` in the parent of the folder.

### dsoul freeze

Stamp a file on DSOUL to get an IPFS CID. Uses credentials from **dsoul register**.

```bash
dsoul freeze <file> [--shortname=NAME] [--tags=tag1,tag2] [--version=X.Y.Z] [--license_url=URL]
```

Requires **dsoul register** first. Shortname is optional; server infers `username@NAME:version`.

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
