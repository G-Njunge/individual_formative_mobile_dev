// Checks firestore.rules against the cases in cases.js.
//
//   npm run test:rules
//
// Uses Firebase's rules test API (firebaserules.projects.test): Google's
// servers evaluate the local rules file against each request. Nothing is
// deployed or written to the project, and no emulator (or Java) is needed.
//
// Signs in with your Firebase CLI login (`firebase login`), which may use
// this API. The Admin SDK service account usually may not, so it is only
// the fallback (grant it the "Firebase Rules Viewer" role to use it).
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const cases = require('./cases');

const rulesPath = path.join(__dirname, '..', '..', '..', 'firestore.rules');
const projectId = JSON.parse(
  fs.readFileSync(path.join(__dirname, '..', '..', '..', '.firebaserc'), 'utf8'),
).projects.default;

async function accessToken() {
  try {
    const lib = path.join(execSync('npm root -g').toString().trim(), 'firebase-tools', 'lib');
    const account = require(path.join(lib, 'auth.js')).getGlobalDefaultAccount();
    if (account) {
      const { requireAuth } = require(path.join(lib, 'requireAuth.js'));
      const apiv2 = require(path.join(lib, 'apiv2.js'));
      await requireAuth({ user: account.user, tokens: account.tokens, project: projectId });
      const token = await apiv2.getAccessToken();
      if (token) return token;
    }
  } catch (_) {
    // Fall through to the service account.
  }
  const { admin } = require('../admin-app');
  return (await admin.app().options.credential.getAccessToken()).access_token;
}

async function main() {
  // JSON can't carry raw bytes, so photo cases send a string. The copy of
  // the rules sent for testing accepts a string where the real ones need
  // bytes; every other line is checked as written.
  const source = fs
    .readFileSync(rulesPath, 'utf8')
    .replaceAll('.data is bytes', '.data is string');

  const token = await accessToken();

  const res = await fetch(`https://firebaserules.googleapis.com/v1/projects/${projectId}:test`, {
    method: 'POST',
    headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
    body: JSON.stringify({
      source: { files: [{ name: 'firestore.rules', content: source }] },
      testSuite: { testCases: cases.map(({ name, ...c }) => c) },
    }),
  });
  const body = await res.json();
  if (!res.ok) throw new Error(`${res.status}: ${JSON.stringify(body.error || body).slice(0, 500)}`);
  if (body.issues?.length) {
    for (const i of body.issues) console.error(`Rules issue: ${i.description} (line ${i.sourcePosition?.line})`);
  }

  let failed = 0;
  body.testResults.forEach((r, i) => {
    const ok = r.state === 'SUCCESS';
    if (!ok) failed++;
    console.log(`${ok ? 'PASS' : 'FAIL'}  ${cases[i].expectation.padEnd(5)} ${cases[i].name}`);
    if (!ok) {
      for (const m of r.debugMessages || []) console.log(`        ${m}`);
    }
  });
  console.log(`\n${cases.length - failed} of ${cases.length} passed.`);
  process.exit(failed ? 1 : 0);
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
