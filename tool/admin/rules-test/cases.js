// Test cases for firestore.rules, run by rules-test/run.js.
//
// Each case is one request (who, what, where, with which data) and whether
// the rules must ALLOW or DENY it. Rules that read other documents (get,
// exists, getAfter, existsAfter) are given fixed answers ("mocks"), so each
// case states exactly what the database looks like around the request.

const T = '2026-11-06T12:00:00Z';
const D = '/databases/(default)/documents';

// --- People ---
const amani = { uid: 'u1', token: { email_verified: true, email: 'a.mugisha@alustudent.com' } };
const bea = { uid: 'u2', token: { email_verified: true, email: 'b.uwase@alustudent.com' } };
const unverified = { uid: 'u3', token: { email_verified: false, email: 'new@alustudent.com' } };
const jean = { uid: 's1', token: { email_verified: true, email: 'jean.h@alueducation.com', staff: true } };
const noClaim = { uid: 's2', token: { email_verified: true, email: 'new.staff@alueducation.com' } };

// --- Mocks ---
// `at` answers one function for one exact path; `any` answers it for every
// path (only safe when the rule calls it for a single document).
const at = (fn, path, value) => ({ function: fn, args: [{ exactValue: D + path }], result: { value } });
const any = (fn, value) => ({ function: fn, args: [{ anyValue: {} }], result: { value } });
const studentProfile = (name = 'Amani Mugisha') => ({ data: { role: 'student', name } });

// --- Data ---
const report = (anonymous, extra = {}) => ({
  ticketNumber: 1001, title: 'Leaking tap in Block C', description: 'Spraying water.',
  category: 'water', location: 'Block C, floor 2', urgency: 'high', status: 'submitted',
  reporterId: anonymous ? null : 'u1', reporterName: anonymous ? null : 'Amani Mugisha',
  anonymous, photoCount: 1, assignedTo: null, meTooCount: 0, createdAt: T, updatedAt: T, ...extra,
});
const existing = report(false, { createdAt: '2026-11-01T10:00:00Z', updatedAt: '2026-11-01T10:00:00Z' });
const open = { ...existing, meTooCount: 3 };
const resolved = { ...existing, status: 'resolved' };
const notification = (extra = {}) => ({
  type: 'status', reportId: 'r1', ticketNumber: 1042, reportTitle: 'Leaking tap',
  status: 'in_progress', note: null, read: false, createdAt: T, ...extra,
});

// --- Case builder ---
const tc = (name, expectation, method, path, data, mocks = [], { auth = amani, before } = {}) => ({
  name,
  expectation,
  request: { auth, method, path: D + path, time: T, ...(data ? { resource: { data } } : {}) },
  ...(before ? { resource: { data: before } } : {}),
  functionMocks: mocks,
});

const backing = (who, base, after) => [
  at('get', `/users/${who}`, studentProfile('Bea Uwase')),
  at('get', '/reports/r1', { data: base }),
  at('getAfter', '/reports/r1', { data: after }),
  at('exists', `/users/${who}/reports/r1`, false),
  at('existsAfter', `/users/${who}/following/r1`, true),
];
const counterAt = (last) => any('getAfter', { data: { last } });

module.exports = [
  // ---------- Accounts ----------
  tc('student signs up', 'ALLOW', 'create', '/users/u1',
    { name: 'Amani Mugisha', email: 'a.mugisha@alustudent.com', role: 'student', createdAt: T }),
  tc('student cannot sign up as staff', 'DENY', 'create', '/users/u1',
    { name: 'Amani', email: 'a.mugisha@alustudent.com', role: 'staff', staffId: 'X-1', approved: false, createdAt: T }),
  tc('staff cannot approve themselves at sign up', 'DENY', 'create', '/users/s2',
    { name: 'New Staff', email: 'new.staff@alueducation.com', role: 'staff', staffId: 'FAC-1', approved: true, createdAt: T },
    [], { auth: noClaim }),
  tc('nobody can change their own role', 'DENY', 'update', '/users/u1',
    { name: 'Amani Mugisha', email: 'a.mugisha@alustudent.com', role: 'staff', createdAt: T }, [],
    { before: { name: 'Amani Mugisha', email: 'a.mugisha@alustudent.com', role: 'student', createdAt: T } }),
  tc('a name can be changed', 'ALLOW', 'update', '/users/u1',
    { name: 'Amani M. Mugisha', email: 'a.mugisha@alustudent.com', role: 'student', createdAt: T }, [],
    { before: { name: 'Amani Mugisha', email: 'a.mugisha@alustudent.com', role: 'student', createdAt: T } }),
  tc("students can't read each other's profiles", 'DENY', 'get', '/users/u1', null, [],
    { auth: bea, before: { name: 'Amani Mugisha', role: 'student' } }),
  tc('anyone verified can read a staff profile', 'ALLOW', 'get', '/users/s1', null, [],
    { auth: bea, before: { name: 'Jean Habimana', role: 'staff' } }),

  // ---------- Creating reports ----------
  tc('named report', 'ALLOW', 'create', '/reports/r1', report(false),
    [any('get', studentProfile()), counterAt(1001)]),
  tc('anonymous report', 'ALLOW', 'create', '/reports/r1', report(true),
    [any('get', studentProfile()), counterAt(1001), any('existsAfter', true)]),
  tc('anonymous report carrying an id', 'DENY', 'create', '/reports/r1', report(true, { reporterId: 'u1' }),
    [any('get', studentProfile()), counterAt(1001), any('existsAfter', true)]),
  tc('report under someone else\'s name', 'DENY', 'create', '/reports/r1', report(false, { reporterName: 'Someone Else' }),
    [any('get', studentProfile()), counterAt(1001)]),
  tc('report that starts resolved', 'DENY', 'create', '/reports/r1', report(false, { status: 'resolved' }),
    [any('get', studentProfile()), counterAt(1001)]),
  tc('ticket number not from the counter', 'DENY', 'create', '/reports/r1', report(false, { ticketNumber: 5 }),
    [any('get', studentProfile()), counterAt(1001)]),
  tc('unverified account cannot report', 'DENY', 'create', '/reports/r1', report(false),
    [any('get', studentProfile()), counterAt(1001)], { auth: unverified }),
  tc('counter starts at 1001', 'ALLOW', 'create', '/counters/reports', { last: 1001 }, [any('get', studentProfile())]),
  tc('counter goes up by one', 'ALLOW', 'update', '/counters/reports', { last: 1043 },
    [any('get', studentProfile())], { before: { last: 1042 } }),
  tc('counter cannot skip', 'DENY', 'update', '/counters/reports', { last: 1050 },
    [any('get', studentProfile())], { before: { last: 1042 } }),

  // ---------- Photos and the anonymous link ----------
  tc('photo on own named report', 'ALLOW', 'create', '/reports/r1/photos/0', { index: 0, data: 'AAAA' },
    [any('getAfter', { data: { reporterId: 'u1', photoCount: 1 } }), any('exists', false), any('existsAfter', false)]),
  tc('photo on own anonymous report', 'ALLOW', 'create', '/reports/r1/photos/0', { index: 0, data: 'AAAA' },
    [any('getAfter', { data: { reporterId: null, photoCount: 1 } }), any('exists', false), any('existsAfter', true)]),
  tc('photo beyond photoCount', 'DENY', 'create', '/reports/r1/photos/1', { index: 1, data: 'AAAA' },
    [any('getAfter', { data: { reporterId: 'u1', photoCount: 1 } }), any('exists', false), any('existsAfter', false)]),
  tc("photo on someone else's report", 'DENY', 'create', '/reports/r1/photos/0', { index: 0, data: 'AAAA' },
    [any('getAfter', { data: { reporterId: 'u2', photoCount: 1 } }), any('exists', false), any('existsAfter', false)]),
  tc('photo added after the report was saved', 'DENY', 'create', '/reports/r1/photos/0', { index: 0, data: 'AAAA' },
    [any('getAfter', { data: { reporterId: 'u1', photoCount: 1 } }), any('exists', true), any('existsAfter', false)]),
  tc('private link to an anonymous report', 'ALLOW', 'create', '/users/u1/reports/r1', { createdAt: T },
    [any('exists', false), any('getAfter', { data: { anonymous: true } })]),
  tc('private link readable by its owner only', 'DENY', 'get', '/users/u1/reports/r1', null, [], { auth: bea }),
  tc('mark anonymous updates seen', 'ALLOW', 'update', '/users/u1/reports/r1',
    { createdAt: '2026-11-01T10:00:00Z', seenAt: T }, [], { before: { createdAt: '2026-11-01T10:00:00Z' } }),

  // ---------- Staff updates ----------
  tc('staff: status and assignee', 'ALLOW', 'update', '/reports/r1',
    { ...existing, status: 'in_progress', assignedTo: { uid: 's1', name: 'Jean Habimana', team: 'Plumbing' }, updatedAt: T },
    [], { auth: jean, before: existing }),
  tc('staff: resolve with after photo and duplicate link', 'ALLOW', 'update', '/reports/r1',
    { ...existing, status: 'resolved', hasAfterPhoto: true, duplicateOf: { id: 'r0', ticketNumber: 1000 }, updatedAt: T },
    [], { auth: jean, before: existing }),
  tc('staff: cannot edit what the student wrote', 'DENY', 'update', '/reports/r1',
    { ...existing, title: 'Changed by staff', updatedAt: T }, [], { auth: jean, before: existing }),
  tc('staff: cannot change the Me too count', 'DENY', 'update', '/reports/r1',
    { ...existing, meTooCount: 50, updatedAt: T }, [], { auth: jean, before: existing }),
  tc('approved profile but no staff flag: cannot update', 'DENY', 'update', '/reports/r1',
    { ...existing, status: 'in_progress', updatedAt: T }, [], { auth: noClaim, before: existing }),
  tc('student: cannot change the status', 'DENY', 'update', '/reports/r1',
    { ...existing, status: 'resolved', updatedAt: T },
    [any('exists', false), any('existsAfter', false)], { before: existing }),
  tc('staff: timeline entry', 'ALLOW', 'create', '/reports/r1/updates/x',
    { status: 'in_progress', previousStatus: 'submitted', note: 'Plumber on the way.', byUid: 's1', byName: 'Jean Habimana', byTeam: 'Plumbing', createdAt: T },
    [], { auth: jean }),
  tc('staff: timeline entry in someone else\'s name', 'DENY', 'create', '/reports/r1/updates/x',
    { status: 'in_progress', note: null, byUid: 's9', byName: 'X', createdAt: T }, [], { auth: jean }),
  tc('staff: after photo', 'ALLOW', 'create', '/reports/r1/photos/after', { data: 'AAAA' }, [], { auth: jean }),
  tc('student: cannot add an after photo', 'DENY', 'create', '/reports/r1/photos/after', { data: 'AAAA' },
    [any('getAfter', { data: { reporterId: 'u1', photoCount: 1 } }), any('exists', true), any('existsAfter', false)]),

  // ---------- Notifications ----------
  tc('staff: notification for a student', 'ALLOW', 'create', '/users/u1/notifications/n1', notification(), [], { auth: jean }),
  tc('student: cannot notify others', 'DENY', 'create', '/users/u2/notifications/n1', notification()),
  tc('owner: mark read', 'ALLOW', 'update', '/users/u1/notifications/n1', notification({ read: true }), [],
    { before: notification() }),
  tc('owner: cannot rewrite the text', 'DENY', 'update', '/users/u1/notifications/n1',
    notification({ read: true, reportTitle: 'Changed' }), [], { before: notification() }),
  tc("cannot read someone else's notifications", 'DENY', 'get', '/users/u2/notifications/n1', null, [],
    { before: notification() }),

  // ---------- Me too ----------
  tc('me too: supporter record', 'ALLOW', 'create', '/reports/r1/supporters/u2', { createdAt: T },
    backing('u2', open, { ...open, meTooCount: 4 }), { auth: bea }),
  tc('me too: count jumping by two', 'DENY', 'create', '/reports/r1/supporters/u2', { createdAt: T },
    backing('u2', open, { ...open, meTooCount: 5 }), { auth: bea }),
  tc('me too: on your own report', 'DENY', 'create', '/reports/r1/supporters/u1', { createdAt: T },
    backing('u1', open, { ...open, meTooCount: 4 })),
  tc('me too: on a resolved report', 'DENY', 'create', '/reports/r1/supporters/u2', { createdAt: T },
    backing('u2', resolved, { ...resolved, meTooCount: 1 }), { auth: bea }),
  tc('me too: for someone else', 'DENY', 'create', '/reports/r1/supporters/u3', { createdAt: T }, [], { auth: bea }),
  tc('me too: staff cannot back reports', 'DENY', 'create', '/reports/r1/supporters/s1', { createdAt: T },
    [at('get', '/users/s1', { data: { role: 'staff', name: 'Jean' } }), at('get', '/reports/r1', { data: open }),
      at('getAfter', '/reports/r1', { data: { ...open, meTooCount: 4 } }), at('exists', '/users/s1/reports/r1', false),
      at('existsAfter', '/users/s1/following/r1', true)], { auth: jean }),
  tc('me too: count +1 with the supporter record', 'ALLOW', 'update', '/reports/r1', { ...open, meTooCount: 4 },
    [at('exists', '/reports/r1/supporters/u2', false), at('existsAfter', '/reports/r1/supporters/u2', true)],
    { auth: bea, before: open }),
  tc('me too: count -1 when taking it back', 'ALLOW', 'update', '/reports/r1', { ...open, meTooCount: 2 },
    [at('exists', '/reports/r1/supporters/u2', true), at('existsAfter', '/reports/r1/supporters/u2', false)],
    { auth: bea, before: open }),
  tc('me too: count without a supporter record', 'DENY', 'update', '/reports/r1', { ...open, meTooCount: 4 },
    [at('exists', '/reports/r1/supporters/u2', false), at('existsAfter', '/reports/r1/supporters/u2', false),
      at('exists', '/users/u2/reports/r1', false)], { auth: bea, before: open }),
  tc('following record with the supporter record', 'ALLOW', 'create', '/users/u2/following/r1', { createdAt: T },
    [at('existsAfter', '/reports/r1/supporters/u2', true)], { auth: bea }),
  tc('supporters are private to staff and the student', 'DENY', 'get', '/reports/r1/supporters/u3', null, [], { auth: bea }),
  tc('staff can read supporters', 'ALLOW', 'get', '/reports/r1/supporters/u3', null, [], { auth: jean }),

  // ---------- Confirm or reopen ----------
  tc('reporter confirms the fix', 'ALLOW', 'update', '/reports/r1', { ...resolved, confirmed: true },
    [at('exists', '/reports/r1/supporters/u1', false), at('existsAfter', '/reports/r1/supporters/u1', false)],
    { before: resolved }),
  tc('another student cannot confirm', 'DENY', 'update', '/reports/r1', { ...resolved, confirmed: true },
    [at('exists', '/reports/r1/supporters/u2', false), at('existsAfter', '/reports/r1/supporters/u2', false),
      at('exists', '/users/u2/reports/r1', false)], { auth: bea, before: resolved }),
  tc('anonymous reporter reopens', 'ALLOW', 'update', '/reports/r1',
    { ...report(true), status: 'submitted', updatedAt: T },
    [at('exists', '/reports/r1/supporters/u1', false), at('existsAfter', '/reports/r1/supporters/u1', false),
      at('exists', '/users/u1/reports/r1', true)], { before: { ...report(true), status: 'resolved' } }),
  tc('a confirmed report cannot be reopened', 'DENY', 'update', '/reports/r1',
    { ...resolved, confirmed: true, status: 'submitted', updatedAt: T },
    [at('exists', '/reports/r1/supporters/u1', false), at('existsAfter', '/reports/r1/supporters/u1', false)],
    { before: { ...resolved, confirmed: true } }),
  tc('reopen reason on the timeline', 'ALLOW', 'create', '/reports/r1/updates/x',
    { status: 'submitted', previousStatus: 'resolved', note: 'Reopened: still dripping', byUid: '', byName: 'Reporter', createdAt: T },
    [at('get', '/reports/r1', { data: resolved }), at('getAfter', '/reports/r1', { data: { ...resolved, status: 'submitted' } })]),
  tc('reopen entry naming the student', 'DENY', 'create', '/reports/r1/updates/x',
    { status: 'submitted', previousStatus: 'resolved', note: 'Reopened: still dripping', byUid: 'u1', byName: 'Amani', createdAt: T },
    [at('get', '/reports/r1', { data: resolved }), at('getAfter', '/reports/r1', { data: { ...resolved, status: 'submitted' } })]),

  // ---------- Announcements and everything else ----------
  tc('staff post an announcement', 'ALLOW', 'create', '/announcements/a1',
    { title: 'Water cut on Saturday', body: '9 to 12', byName: 'Jean', createdAt: T }, [], { auth: jean }),
  tc('students cannot post announcements', 'DENY', 'create', '/announcements/a1',
    { title: 'Free pizza today', body: '', byName: 'Amani', createdAt: T }),
  tc('signed-out visitors read nothing', 'DENY', 'get', '/reports/r1', null, [], { auth: null, before: existing }),
  tc('unlisted collections are closed', 'DENY', 'create', '/anything/x', { a: 1 }),
];
