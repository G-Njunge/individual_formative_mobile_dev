// Approves a staff account and sets their team, so they can use staff
// features.
//
//   npm run approve -- jean.h@alueducation.com "Plumbing"
//
// Two things happen, in this order:
// 1. The login gets a `staff: true` custom claim. The security rules check
//    this flag instead of reading the profile, because one status update can
//    write hundreds of notifications and Firestore only allows 20 document
//    lookups per write. Only the Admin SDK (this script) can set claims, so
//    nobody can give themselves staff access.
// 2. The profile gets `approved: true` and the team, which lets the app past
//    the "Waiting for approval" screen.
//
// Setting `approved` by hand in the console is not enough any more: without
// the claim, the staff member can see the dashboard but can't save updates.
const { auth, db } = require('./admin-app');

async function main() {
  const [email, team] = process.argv.slice(2);
  if (!email || !team) {
    console.error('Usage: npm run approve -- <staff email> "<team>"');
    process.exit(1);
  }
  const user = await auth.getUserByEmail(email);
  const ref = db.doc(`users/${user.uid}`);
  const snap = await ref.get();
  if (!snap.exists || snap.get('role') !== 'staff') {
    console.error(`${email} is not a staff account.`);
    process.exit(1);
  }
  await auth.setCustomUserClaims(user.uid, {
    ...(user.customClaims || {}),
    staff: true,
  });
  await ref.update({ approved: true, team });
  console.log(`Approved ${snap.get('name')} (${email}), team: ${team}.`);
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
