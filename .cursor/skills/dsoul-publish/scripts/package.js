const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const cwd = process.cwd();

// Candidate skills roots for each AI IDE / agent runtime.
// Add new roots here as the ecosystem evolves.
const CANDIDATE_ROOTS = [
  path.join(cwd, ".claude", "skills"),
  path.join(cwd, ".cursor", "skills"),
  path.join(cwd, ".codex", "skills"),
  path.join(cwd, ".gemini", "skills"),
];

/**
 * Return true if the given directory was installed via `dsoul install`.
 * Detection rule: any skill folder that is a sibling of a dsoul.json file
 * was installed — not authored — and must not be published.
 */
function isInstalledSkillsDir(dir) {
  return fs.existsSync(path.join(dir, "dsoul.json"));
}

// Collect skill folders from all roots that exist, skipping installed-skill dirs.
const skillFolders = [];
const searched = [];
const skippedInstalled = [];

for (const root of CANDIDATE_ROOTS) {
  if (!fs.existsSync(root)) continue;
  searched.push(root);

  const entries = fs.readdirSync(root, { withFileTypes: true });
  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    const skillDir = path.join(root, entry.name);

    // Skip if this subdirectory is an install target (has its own dsoul.json).
    if (isInstalledSkillsDir(skillDir)) {
      skippedInstalled.push(path.relative(cwd, skillDir));
      continue;
    }

    // Skip if the root itself is an install target.
    if (isInstalledSkillsDir(root)) {
      skippedInstalled.push(path.relative(cwd, skillDir));
      continue;
    }

    if (fs.existsSync(path.join(skillDir, "SKILL.md"))) {
      skillFolders.push(skillDir);
    }
  }
}

if (searched.length === 0) {
  console.error(
    "No skills root found. Expected one of:\n" +
      CANDIDATE_ROOTS.map((r) => "  " + path.relative(cwd, r)).join("\n")
  );
  process.exit(1);
}

if (skippedInstalled.length > 0) {
  console.log(
    "Skipped (installed — not yours to publish):\n" +
      skippedInstalled.map((r) => "  " + r).join("\n")
  );
}

if (skillFolders.length === 0) {
  console.log(
    "No authored skill folders (with SKILL.md) found in:\n" +
      searched.map((r) => "  " + path.relative(cwd, r)).join("\n")
  );
  process.exit(0);
}

for (const folder of skillFolders) {
  const rel = path.relative(cwd, folder);
  console.log("Packaging", rel, "...");
  execFileSync("npx", ["diamond-soul-downloader", "package", folder], {
    stdio: "inherit",
    cwd,
  });
}

console.log(
  "Done. Zips created alongside each skill folder in:\n" +
    searched.map((r) => "  " + path.relative(cwd, r)).join("\n")
);
