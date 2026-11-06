// Approves a staff account and sets their team, so they can use staff
// features. Same effect as editing users/{uid} in the Firebase console.
//
//   npm run approve -- jean.h@alueducation.com "Plumbing"
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
  await ref.update({ approved: true, team });
  console.log(`Approved ${snap.get('name')} (${email}), team: ${team}.`);
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
