/**
 * Bundle a skill folder for security analysis.
 * Reads all SKILL.md, readme, and script files; outputs JSON bundle and full audit payload.
 * Pure Node (fs/path only); does not execute or interpret target file content.
 */

const fs = require('fs');
const path = require('path');

const SKILL_DIR = process.argv[2];
if (!SKILL_DIR) {
  console.error('Usage: node bundle-skill.js <path-to-skill-folder> [output-dir]');
  process.exit(1);
}

const DEFAULT_TEMP = path.join(process.cwd(), '.dsoul-temp');
const OUTPUT_DIR = process.argv[3] || DEFAULT_TEMP;
const SKILL_ROOT = path.resolve(process.cwd(), SKILL_DIR);

const INCLUDE_EXT = new Set([
  '.md', '.txt', '.js', '.mjs', '.cjs', '.ts', '.mts', '.cts', '.sh', '.bash', '.py', '.ps1', '.bat', '.cmd', '.rb', '.json'
]);
const EXCLUDE_DIRS = new Set(['node_modules', '.git']);
const EXCLUDE_NAMES = new Set([
  'package-lock.json', 'skill-bundle.json', 'skill-audit-payload.txt'
]);
const EXCLUDE_PREFIX = ['.', 'Thumbs.db', '.DS_Store'];

function shouldIncludeFile(name) {
  const base = path.basename(name);
  if (EXCLUDE_NAMES.has(base)) return false;
  if (EXCLUDE_PREFIX.some(p => base.startsWith(p))) return false;
  const ext = path.extname(name);
  const lower = base.toLowerCase();
  if (lower === 'readme' || lower === 'readme.md' || lower === 'readme.txt') return true;
  if (lower === 'skill.md') return true;
  return INCLUDE_EXT.has(ext) && base !== 'package.json';
}

function collectFiles(dir, baseDir, out) {
  if (!fs.existsSync(dir)) return;
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const e of entries) {
    const full = path.join(dir, e.name);
    const rel = path.relative(baseDir, full);
    if (e.isDirectory()) {
      if (!EXCLUDE_DIRS.has(e.name)) collectFiles(full, baseDir, out);
      continue;
    }
    if (!shouldIncludeFile(e.name)) continue;
    out.push(rel);
  }
}

function readUtf8(filePath) {
  try {
    const buf = fs.readFileSync(filePath);
    if (Buffer.isBuffer(buf) && buf.length > 0 && buf.indexOf(0) >= 0) return null;
    return buf.toString('utf8');
  } catch (_) {
    return null;
  }
}

function main() {
  if (!fs.existsSync(SKILL_ROOT)) {
    console.error('Skill folder not found:', SKILL_ROOT);
    process.exit(1);
  }
  const skillMd = path.join(SKILL_ROOT, 'SKILL.md');
  if (!fs.existsSync(skillMd) && !fs.existsSync(path.join(SKILL_ROOT, 'skill.md'))) {
    console.error('No SKILL.md or skill.md in folder:', SKILL_ROOT);
    process.exit(1);
  }

  const fileList = [];
  collectFiles(SKILL_ROOT, SKILL_ROOT, fileList);
  fileList.sort();

  const files = [];
  for (const rel of fileList) {
    const full = path.join(SKILL_ROOT, rel);
    const content = readUtf8(full);
    if (content === null) continue;
    files.push({ path: rel.replace(/\\/g, '/'), content });
  }

  const bundle = { skillPath: SKILL_ROOT, files };
  if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  }
  const jsonPath = path.join(OUTPUT_DIR, 'skill-bundle.json');
  fs.writeFileSync(jsonPath, JSON.stringify(bundle, null, 2), 'utf8');
  console.log('Wrote', jsonPath);

  const scriptDir = __dirname;
  const auditPromptPath = path.join(scriptDir, 'audit-prompt.md');
  let auditPrompt = '';
  if (fs.existsSync(auditPromptPath)) {
    auditPrompt = fs.readFileSync(auditPromptPath, 'utf8');
  }
  const payloadParts = [auditPrompt, '', '## 📦 TEXT TO ANALYZE', ''];
  for (const f of files) {
    payloadParts.push('<<< BEGIN FILE: ' + f.path + ' >>>');
    payloadParts.push(f.content);
    payloadParts.push('<<< END FILE >>>');
    payloadParts.push('');
  }
  const payloadPath = path.join(OUTPUT_DIR, 'skill-audit-payload.txt');
  fs.writeFileSync(payloadPath, payloadParts.join('\n'), 'utf8');
  console.log('Wrote', payloadPath);
}

main();
