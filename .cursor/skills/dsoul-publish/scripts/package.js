const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const skillsRoot = path.join(process.cwd(), ".cursor", "skills");

if (!fs.existsSync(skillsRoot)) {
  console.error("Skills root not found:", skillsRoot);
  process.exit(1);
}

const dirs = fs.readdirSync(skillsRoot, { withFileTypes: true });
const skillFolders = dirs
  .filter((d) => d.isDirectory())
  .map((d) => path.join(skillsRoot, d.name))
  .filter((dir) => fs.existsSync(path.join(dir, "SKILL.md")));

if (skillFolders.length === 0) {
  console.log("No skill folders (with SKILL.md) found in", skillsRoot);
  process.exit(0);
}

for (const folder of skillFolders) {
  const rel = path.relative(process.cwd(), folder);
  console.log("Packaging", rel, "...");
  execFileSync("npx", ["diamond-soul-downloader", "package", folder], {
    stdio: "inherit",
    cwd: process.cwd(),
  });
}

console.log("Done. Zips created in .cursor/skills/ (parent of each skill folder).");
