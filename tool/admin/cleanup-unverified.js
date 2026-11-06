// Deletes accounts that have not verified their email within 24 hours,
// together with their users/{uid} profile.
//
// The app already removes an expired account when its owner signs in again.
// This script catches the accounts nobody comes back to. Scheduled Cloud
// Functions need the paid Blaze plan, so on the free plan run this by hand
// or on a schedule (see README).
//
//   npm run cleanup:dry   # list what would be deleted
//   npm run cleanup       # delete
const { auth, db } = require('./admin-app');

const WINDOW_MS = 24 * 60 * 60 * 1000;
const dryRun = process.argv.includes('--dry-run');

async function findExpired() {
  const expired = [];
  let pageToken;
  do {
    const page = await auth.listUsers(1000, pageToken);
    for (const user of page.users) {
      const created = Date.parse(user.metadata.creationTime);
      if (!user.emailVerified && Date.now() - created > WINDOW_MS) {
        expired.push(user);
      }
    }
    pageToken = page.pageToken;
  } while (pageToken);
  return expired;
}

async function main() {
  const expired = await findExpired();
  if (expired.length === 0) {
    console.log('No unverified accounts older than 24 hours.');
    return;
  }
  for (const u of expired) {
    console.log(`${dryRun ? 'Would delete' : 'Deleting'} ${u.email} (created ${u.metadata.creationTime})`);
  }
  if (dryRun) return;

  // Profiles first, in batches of up to 500 writes.
  for (let i = 0; i < expired.length; i += 500) {
    const batch = db.batch();
    for (const u of expired.slice(i, i + 500)) batch.delete(db.doc(`users/${u.uid}`));
    await batch.commit();
  }
  const result = await auth.deleteUsers(expired.map((u) => u.uid));
  console.log(`Deleted ${result.successCount} account(s), ${result.failureCount} failed.`);
  for (const e of result.errors) console.error(e.error.message);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
