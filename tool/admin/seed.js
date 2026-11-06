// Fills the project with the sample content from the design, for demos and
// testing. Never shipped in the app.
//
//   npm run seed -- --password "Demo-pass-2026"
//   npm run seed:clear
//
// Creates verified demo logins (staff approved, with the staff flag), their
// profiles, a handful of reports at every status, timeline entries, Me toos,
// notifications, an anonymous report and a campus announcement. Everything
// it creates has an id starting with "seed-", which is how seed:clear finds
// it again. Ticket numbers come from the real counter, like the app's.
const { auth, db, admin } = require('./admin-app');

const { Timestamp } = admin.firestore;
const ago = (hours) => Timestamp.fromDate(new Date(Date.now() - hours * 3600e3));

const people = {
  amani: { name: 'Amani Mugisha', email: 'demo.amani@alustudent.com', role: 'student' },
  bea: { name: 'Bea Uwase', email: 'demo.bea@alustudent.com', role: 'student' },
  chris: { name: 'Chris Nkurunziza', email: 'demo.chris@alustudent.com', role: 'student' },
  diane: { name: 'Diane Ishimwe', email: 'demo.diane@alustudent.com', role: 'student' },
  jean: {
    name: 'Jean Habimana',
    email: 'demo.jean@alueducation.com',
    role: 'staff',
    staffId: 'FAC-0231',
    team: 'Plumbing',
  },
};
const uid = (key) => `seed-${key}`;
const jean = { uid: uid('jean'), name: people.jean.name, team: people.jean.team };

// The reports in the design, oldest first. `steps` are staff updates after
// "Submitted", each [status, hours ago, note].
const reports = [
  {
    key: 'chair',
    title: 'Broken chair in Room 204',
    description: 'The back leg of the chair by the window has snapped. Someone could fall.',
    category: 'furniture', location: 'Room 204', urgency: 'low',
    by: 'amani', hoursAgo: 52, backers: ['chris'],
    steps: [
      ['under_review', 50, null],
      ['in_progress', 40, 'Replacement chair ordered.'],
      ['resolved', 26, 'New chair in place.'],
    ],
  },
  {
    key: 'drain',
    title: 'Blocked drain near the cafeteria',
    description: 'Water is pooling by the back door of the cafeteria and it smells.',
    category: 'sanitation', location: 'Cafeteria', urgency: 'medium',
    by: 'chris', hoursAgo: 48, backers: ['amani', 'diane'],
    steps: [['under_review', 30, 'Grounds team will check it tomorrow morning.']],
  },
  {
    key: 'tap',
    title: 'Leaking tap in the Block C washroom',
    description: 'The tap by the second sink is spraying water from the pipe. The floor is wet and slippery.',
    category: 'water', location: 'Block C, ground floor', urgency: 'medium',
    by: 'amani', hoursAgo: 8, backers: ['bea', 'chris', 'diane'],
    steps: [
      ['under_review', 7.5, null],
      ['in_progress', 6, 'Plumber on the way. Water to the washroom will be off for about 30 minutes.'],
    ],
  },
  {
    key: 'power',
    title: 'Power out in the library study room',
    description: 'None of the sockets or lights work in study room 2.',
    category: 'power', location: 'Library L2', urgency: 'high',
    by: 'diane', hoursAgo: 5, backers: ['amani', 'bea'],
    steps: [],
  },
  {
    key: 'light',
    title: 'Streetlight out on the main path',
    description: 'The light halfway along the main path is off. It is very dark there at night.',
    category: 'safety', location: 'Main path', urgency: 'high',
    by: 'bea', anonymous: true, hoursAgo: 3, backers: ['amani', 'chris', 'diane'],
    steps: [],
  },
];

async function ensureUser(key, password) {
  const p = people[key];
  const id = uid(key);
  try {
    await auth.updateUser(id, { email: p.email, password, displayName: p.name, emailVerified: true });
  } catch (e) {
    if (e.code !== 'auth/user-not-found') throw e;
    await auth.createUser({ uid: id, email: p.email, password, displayName: p.name, emailVerified: true });
  }
  if (p.role === 'staff') await auth.setCustomUserClaims(id, { staff: true });
  await db.doc(`users/${id}`).set({
    name: p.name,
    email: p.email,
    role: p.role,
    ...(p.role === 'staff' ? { staffId: p.staffId, approved: true, team: p.team } : {}),
    createdAt: ago(24 * 7),
  });
}

async function seed(password) {
  if (!password || password.length < 8) {
    console.error('Usage: npm run seed -- --password "<at least 8 characters>"');
    process.exit(1);
  }
  if ((await db.doc(`reports/seed-${reports[0].key}`).get()).exists) {
    console.error('Sample data is already there. Run `npm run seed:clear` first.');
    process.exit(1);
  }

  for (const key of Object.keys(people)) await ensureUser(key, password);

  // Hand out real ticket numbers, as the app would.
  const first = await db.runTransaction(async (tx) => {
    const ref = db.doc('counters/reports');
    const last = (await tx.get(ref)).get('last');
    const start = typeof last === 'number' ? last + 1 : 1001;
    tx.set(ref, { last: start + reports.length - 1 });
    return start;
  });

  for (const [i, r] of reports.entries()) {
    const id = `seed-${r.key}`;
    const ticket = first + i;
    const ref = db.doc(`reports/${id}`);
    const last = r.steps.at(-1);
    const status = last ? last[0] : 'submitted';
    const batch = db.batch();

    batch.set(ref, {
      ticketNumber: ticket,
      title: r.title,
      description: r.description,
      category: r.category,
      location: r.location,
      urgency: r.urgency,
      status,
      reporterId: r.anonymous ? null : uid(r.by),
      reporterName: r.anonymous ? null : people[r.by].name,
      anonymous: !!r.anonymous,
      photoCount: 0,
      assignedTo: r.steps.length ? jean : null,
      meTooCount: r.backers.length,
      createdAt: ago(r.hoursAgo),
      updatedAt: ago(last ? last[1] : r.hoursAgo),
    });
    if (r.anonymous) {
      batch.set(db.doc(`users/${uid(r.by)}/reports/${id}`), { createdAt: ago(r.hoursAgo) });
    }
    for (const b of r.backers) {
      batch.set(ref.collection('supporters').doc(uid(b)), { createdAt: ago(r.hoursAgo - 0.5) });
      batch.set(db.doc(`users/${uid(b)}/following/${id}`), { createdAt: ago(r.hoursAgo - 0.5) });
    }

    let previous = 'submitted';
    for (const [n, [next, hours, note]] of r.steps.entries()) {
      batch.set(ref.collection('updates').doc(`seed-${n}`), {
        status: next,
        previousStatus: previous,
        note,
        byUid: jean.uid,
        byName: jean.name,
        byTeam: jean.team,
        createdAt: ago(hours),
      });
      // What "Save update" would write: one notification per named
      // reporter and supporter. Anonymous reporters get theirs on the phone.
      const recipients = [...(r.anonymous ? [] : [r.by]), ...r.backers];
      for (const who of recipients) {
        batch.set(db.doc(`users/${uid(who)}/notifications/seed-${r.key}-${n}`), {
          type: next === previous ? 'note' : 'status',
          reportId: id,
          ticketNumber: ticket,
          reportTitle: r.title,
          status: next,
          note,
          read: hours > 24,
          createdAt: ago(hours),
        });
      }
      previous = next;
    }
    await batch.commit();
    console.log(`#${ticket}  ${status.padEnd(12)} ${r.title}`);
  }

  await db.doc('announcements/seed-water-cut').set({
    title: 'Planned water cut in Hostel A on Saturday, 9:00 to 12:00',
    body: 'Store some water the night before. Washrooms in Block C are not affected.',
    byName: jean.name,
    createdAt: ago(2),
  });

  console.log('\nSign in with any of these (password as given):');
  for (const p of Object.values(people)) console.log(`  ${p.email.padEnd(30)} ${p.role}`);
}

async function clear() {
  const reportsSnap = await db.collection('reports').get();
  for (const d of reportsSnap.docs) {
    if (d.id.startsWith('seed-')) await db.recursiveDelete(d.ref);
  }
  await db.doc('announcements/seed-water-cut').delete();
  for (const key of Object.keys(people)) {
    await db.recursiveDelete(db.doc(`users/${uid(key)}`));
    try {
      await auth.deleteUser(uid(key));
    } catch (e) {
      if (e.code !== 'auth/user-not-found') throw e;
    }
  }
  // Notifications about sample reports in real users' inboxes, and their
  // "following" records, if they backed a sample report.
  const real = await db.collection('users').get();
  for (const u of real.docs) {
    for (const sub of ['notifications', 'following']) {
      const docs = await u.ref.collection(sub).get();
      for (const d of docs.docs) {
        if (d.id.startsWith('seed-') || String(d.get('reportId') || '').startsWith('seed-')) {
          await d.ref.delete();
        }
      }
    }
  }
  console.log('Removed the sample data. The ticket counter is left as it is, so numbers are never reused.');
}

const args = process.argv.slice(2);
const run = args.includes('--clear')
  ? clear()
  : seed(args[args.indexOf('--password') + 1] && args.includes('--password')
      ? args[args.indexOf('--password') + 1]
      : undefined);
run.then(() => process.exit(0)).catch((e) => {
  console.error(e.message);
  process.exit(1);
});
