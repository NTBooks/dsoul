/**
 * Package each skill folder as a zip (same location as dsoul package: parent/<shortcode>.zip)
 * and compute SHA-256 of the zip for duplicate detection. No dsoul CLI required.
 * Outputs JSON array: [{ shortcode, zipPath, hash }, ...]
 */
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const archiver = require("archiver");

const skillsRoot = path.join(process.cwd(), ".cursor", "skills");

if (!fs.existsSync(skillsRoot)) {
  process.stderr.write("Skills root not found: " + skillsRoot + "\n");
  process.exit(1);
}

const dirs = fs.readdirSync(skillsRoot, { withFileTypes: true });
const skillFolders = dirs
  .filter((d) => d.isDirectory())
  .map((d) => ({ shortcode: d.name, dir: path.join(skillsRoot, d.name) }))
  .filter(({ dir }) => fs.existsSync(path.join(dir, "SKILL.md")));

function zipFolder(folderPath, outPath) {
  return new Promise((resolve, reject) => {
    const output = fs.createWriteStream(outPath);
    const archive = archiver("zip", { zlib: { level: 9 } });
    output.on("close", () => resolve());
    archive.on("error", reject);
    archive.pipe(output);
    archive.directory(folderPath, false);
    archive.finalize();
  });
}

function sha256File(filePath) {
  const buf = fs.readFileSync(filePath);
  return crypto.createHash("sha256").update(buf).digest("hex");
}

(async () => {
  const results = [];
  for (const { shortcode, dir } of skillFolders) {
    const zipPath = path.join(skillsRoot, shortcode + ".zip");
    await zipFolder(dir, zipPath);
    const hash = sha256File(zipPath);
    results.push({ shortcode, zipPath, hash });
  }
  process.stdout.write(JSON.stringify(results));
})();
