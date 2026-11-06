// Shared set-up for the admin scripts.
//
// Uses the service-account key at tool/admin/service-account.json, or the
// file named by the GOOGLE_APPLICATION_CREDENTIALS environment variable.
// The key gives full access to the project: never commit it (it is in
// .gitignore) and never ship it in the app.
const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const localKey = path.join(__dirname, 'service-account.json');
const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || localKey;

if (!fs.existsSync(keyPath)) {
  console.error(
    `No service-account key found at ${keyPath}.\n` +
      'Download one from Firebase console > Project settings > Service accounts ' +
      '> Generate new private key, and save it as tool/admin/service-account.json.',
  );
  process.exit(1);
}

admin.initializeApp({ credential: admin.credential.cert(require(keyPath)) });

module.exports = { admin, auth: admin.auth(), db: admin.firestore() };
