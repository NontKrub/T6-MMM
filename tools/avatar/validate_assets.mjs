import fs from 'node:fs/promises';
import validator from 'gltf-validator';

const files = process.argv.slice(2);
if (files.length === 0) {
  console.error('Usage: node validate_assets.mjs <model.glb> [...]');
  process.exit(2);
}

let failed = false;
for (const file of files) {
  const bytes = new Uint8Array(await fs.readFile(file));
  const report = await validator.validateBytes(bytes, {
    uri: file,
    format: 'glb',
    writeTimestamp: false,
    maxIssues: 0,
  });
  const errors = report.issues?.numErrors ?? 0;
  const warnings = report.issues?.numWarnings ?? 0;
  console.log(`${file}: errors=${errors} warnings=${warnings}`);
  if (errors > 0) {
    failed = true;
    for (const issue of report.issues.messages ?? []) {
      if (issue.severity === 0) console.error(JSON.stringify(issue));
    }
  }
}

process.exitCode = failed ? 1 : 0;
