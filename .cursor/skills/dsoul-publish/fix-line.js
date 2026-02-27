const fs = require('fs');
const path = require('path');
const p = path.join(__dirname, 'SKILL.md');
let s = fs.readFileSync(p, 'utf8');
const idx = s.indexOf(' (Original:');
if (idx !== -1) {
  const end = s.indexOf(' script.', idx);
  if (end !== -1) s = s.slice(0, idx) + s.slice(end + ' script.'.length);
}
s = s.replace(/in each skill folder \. Ensure/, 'in each skill folder. Ensure');
fs.writeFileSync(p, s);
