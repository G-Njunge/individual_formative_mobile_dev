// Marks an account's email as verified without the email link. For test
// accounts whose inbox you can't open (for example a made-up
// @alueducation.com address). Real users should always click the link.
//
//   npm run verify -- jean.h@alueducation.com
//
// The app's "Check your email" screen checks every 5 seconds, so it moves on
// by itself (or press "I've verified").
const { auth } = require('./admin-app');

async function main() {
  const [email] = process.argv.slice(2);
  if (!email) {
    console.error('Usage: npm run verify -- <email>');
    process.exit(1);
  }
  const user = await auth.getUserByEmail(email);
  if (user.emailVerified) {
    console.log(`${email} is already verified.`);
    return;
  }
  await auth.updateUser(user.uid, { emailVerified: true });
  console.log(`Marked ${email} as verified.`);
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
