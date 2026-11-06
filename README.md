# Ripoti

Ripoti (Swahili for "report") is a Flutter app for reporting campus issues: broken facilities, water shortages, power outages, damaged furniture, sanitation problems and safety concerns. Students submit reports and follow them until they are fixed. Campus staff review the reports and update their status.

Built with Flutter, Riverpod and Firebase (Authentication and Cloud Firestore), from the design in [designs/ripoti-design/](designs/ripoti-design/).

## Progress

| Milestone | Scope | Status |
|---|---|---|
| 1 | Theme, design tokens, shared components, component gallery | Done |
| 2 | Firebase set-up, sign in and sign up, email verification, forgot password, onboarding, role-based routing | Done (needs `flutterfire configure`, see below) |
| 3 | Student reporting: New report with photos, Report submitted, Home, Browse, Report details | Done (redeploy rules and indexes, see below) |
| 4 | Staff dashboard and status updates, notification fan-out | Not started |
| 5 | Me too, notifications, profile, confirm or reopen | Not started |
| 6 | Full security rules, indexes, seed data, remaining tests, final README | Not started |

Screens that belong to later milestones (Notifications, Profile, the staff side) are temporary placeholders, so routing and sign-in can already be tried end to end.

## Setup

### 1. Prerequisites

- Flutter (stable) and Dart. Check with `flutter doctor`.
- Node.js, for the Firebase CLI and the admin scripts.
- Firebase CLI: `npm install -g firebase-tools`, then `firebase login`.
- FlutterFire CLI: `dart pub global activate flutterfire_cli`.

### 2. Firebase project

The project is `formative2-b25e3` on the free **Spark** plan. If you set up your own project:

1. Create a project in the [Firebase console](https://console.firebase.google.com) (Analytics not needed).
2. **Authentication → Sign-in method:** enable **Email/Password**.
3. **Firestore Database:** create a database in production mode. Pick a location near your users; it cannot be changed later.
4. Do **not** create Storage. See [Photos without Firebase Storage](#photos-without-firebase-storage).
5. Change the project ID in [.firebaserc](.firebaserc).

### 3. Connect the app

From the project folder:

```
flutterfire configure --project=formative2-b25e3 --platforms=android,ios
```

This registers the Android and iOS apps (`com.ripoti.app`) and generates `lib/firebase_options.dart` and `android/app/google-services.json`. Config values are never written by hand. iOS can be configured on Windows but needs a Mac to build.

### 4. Deploy the security rules and indexes

```
firebase deploy --only firestore
```

Until the rules are deployed, a database created in production mode refuses every read and write, and sign up will fail. Run it again whenever `firestore.rules` or `firestore.indexes.json` changes. A new index takes a few minutes to build; until then "My reports" and Home show an error.

### 5. Run

Firebase is configured for **Android** (and iOS, which needs a Mac), not for web or Windows. Start an Android emulator or plug in a phone first:

```
flutter pub get
flutter emulators --launch Pixel_7
flutter run
```

In Chrome the app shows a "not set up for this platform" message. To support web, run `flutterfire configure --project=formative2-b25e3 --platforms=android,ios,web`.

### Making a staff account usable

Staff sign up with an `@alueducation.com` email and a Staff ID. After verifying their email they see "Waiting for approval" until an admin approves them. Either:

- **Console:** Firestore → `users` → the staff member's document. Set `approved` to `true` and add a string field `team` (for example `Plumbing`). The app moves on by itself.
- **Script:** `cd tool/admin && npm install && npm run approve -- jean.h@alueducation.com "Plumbing"` (needs the service-account key described below).

Users cannot approve themselves or change their own role. The security rules block it.

### Admin scripts and the service-account key

[tool/admin/](tool/admin/) holds Node scripts that use `firebase-admin`:

| Command | What it does |
|---|---|
| `npm run cleanup:dry` | Lists accounts unverified for more than 24 hours |
| `npm run cleanup` | Deletes those accounts and their profiles |
| `npm run approve -- <email> "<team>"` | Approves a staff account |

They need a key: Firebase console → Project settings → Service accounts → **Generate new private key**, saved as `tool/admin/service-account.json`. The key gives full access to the project. It is in `.gitignore`. Never commit it or put it in the app.

## Accounts and verification

- **Campus emails only.** Students sign up with `@alustudent.com`, staff with `@alueducation.com`. This is checked in the form ([app_config.dart](lib/core/config/app_config.dart)) and again in [firestore.rules](firestore.rules), so it can't be bypassed.
- **Email verification, once.** After "Create account" Firebase sends a verification link and the app shows "Check your email". It checks every 5 seconds and moves on when the link is clicked. Resend is limited to once a minute. Once verified, the account is never asked again.
- **Unverified accounts are removed after 24 hours.** Firebase creates the account before the email can be verified, because the link belongs to an account. An unverified account can't use the app. If its owner comes back after 24 hours, the app deletes it and asks them to register again. Accounts nobody comes back to are removed by `npm run cleanup`. A scheduled Cloud Function would do this automatically, but scheduled functions need the paid Blaze plan, so the free plan uses the script. Run it by hand or on a schedule (for example Windows Task Scheduler running `npm run cleanup` daily in `tool/admin`).
- **Password rules, shown while you type.** A new password needs at least 8 characters, an uppercase and a lowercase letter, a number and a symbol. Create account shows these as a checklist that ticks off as you type, and the error under the field names exactly what is still missing (for example "Add a number and a symbol"), so nobody has to guess. If the password policy in the Firebase console (Authentication → Settings → Password policy) is stricter, Firebase's own list of what is missing is shown instead of a generic error. Sign in doesn't apply these rules, so older accounts still work.
- **"Use a different email"** on "Check your email" deletes the unverified account and opens Create account, so the student can sign up again straight away.
- **Forgot password** sends Firebase's reset email. The app shows the same message whether or not the email has an account, so nobody can use it to find out who is registered.
- **Role check on sign in.** The Student / Campus staff toggle must match the account, so a student cannot land in the staff flow by mistake.

Reset and verification emails often land in spam, especially on school email.

## Architecture

Feature-first folders, each split into three layers:

```
lib/
  main.dart                   Firebase + SharedPreferences start-up
  app.dart                    MaterialApp.router with light and dark themes
  core/
    config/                   AppConfig: app name, email domains, limits
    theme/                    tokens (colours, shadows, radii), text styles, ThemeData
    widgets/                  shared components (NeuSurface, buttons, fields, cards...)
    router/                   routes, session-based redirects, nav-bar shells
    models/                   report status, urgency and category enums
    utils/                    validators, time formatting
    errors/ storage/ firebase/  small shared providers and types
    debug/                    component gallery and placeholders (debug only)
  features/
    auth/          data/ (AppUser, AuthRepository)  application/ (providers, controllers)  presentation/ (screens)
    onboarding/    application/ (seen flag)  presentation/ (carousel)
    reports/       data/ (Report, ReportRepository, PhotoPicker)  application/ (providers, filters, New report controller)  presentation/ (Home, Browse, New report, Submitted, Details)
```

- **data/**: repositories are the only code that talks to Firebase. They return app models and throw readable errors (`UserFacingException`) instead of Firebase error codes.
- **application/**: Riverpod providers hold state and logic. `sessionProvider` combines the login and the profile into one status (signed out, needs verification, awaiting approval, student, staff). Form controllers expose an `AsyncValue` so screens can show loading and errors.
- **presentation/**: widgets only read providers and render. They never call Firebase.

**Routing.** [go_router](lib/core/router/app_router.dart) re-runs one rule, [sessionRedirect](lib/core/router/session_redirect.dart), whenever the session changes. Screens never navigate after sign in, verification or approval; the redirect does it. The rule is a plain function, so every case is unit tested.

**Design system.** Every colour, shadow, radius and text style lives in [tokens.dart](lib/core/theme/tokens.dart) and [text_styles.dart](lib/core/theme/text_styles.dart). Screens never hard-code them. The neumorphic look comes from one widget, [NeuSurface](lib/core/widgets/neu_surface.dart): raised surfaces use two `BoxShadow`s, and pressed surfaces use a small custom painter, because Flutter has no inset shadow. Dark is the original design and the default. A matching light theme keeps the same roles, with accent text colours darkened to stay readable.

## Decisions and trade-offs

### Photos without Firebase Storage

New Firebase projects need the paid Blaze plan to use Storage, so this project stays on the free Spark plan and stores photos in Firestore instead (Milestone 3). Each photo is compressed on the phone (about 1024 px wide, JPEG quality 60, usually 100 to 250 KB) and saved as a `Blob` in its own document under `reports/{id}/photos/`. That keeps every document well under Firestore's 1 MiB limit, and report lists never download photos. On Blaze, only the photo repository would change.

### Search, filters and sort

Firestore has no full-text search, so Browse loads the 200 most recent reports (live) and filters them on the device: search matches the title or location, ignoring case, and every word typed must match. The status chips and the sort control ("Newest first", "Oldest first", "Most me too") work on the same list, so they need no extra indexes and respond instantly. A campus with many more reports would need a search service such as Algolia or Typesense.

### Ticket numbers

Each report gets a readable number (#1001, #1002...) from a counter document, `counters/reports`. The counter and the report are written in one **transaction**, so two students submitting at the same moment can never get the same number: Firestore retries one of them. The security rules check that the counter only goes up by one and that the report's number is the counter's new value.

### Creating a report in one step

The counter, the report and its photos are saved in the same transaction, so a report is either saved completely or not at all. There is never a report with missing photos, or photos without a report. Photos can only be written in that same write; afterwards they can't be added or changed.

### Location is typed, not GPS

An earlier version had "Use my current location" (GPS). It was removed: GPS can't tell floors or rooms apart, it is often tens of metres off inside buildings, and it needed a location permission the app otherwise doesn't need. Students type the building, floor and room, which is what staff actually need to find the problem.

### Staying under Firestore's lookup limit

Security rules can read other documents (`get()`, `exists()`, `getAfter()`) to check a write, but Firestore allows at most 20 such lookups in one transaction. Creating an anonymous report with three photos is six writes (counter, report, private link, three photos), so the rules are written to read as little as possible: the report rule reads the profile once and checks everything about the report, and the photo and private-link rules only check that they belong to that report. An earlier version re-checked the student on every write, which could go over the limit with three photos and get the report refused.

### Live updates

Lists, details and the timeline use Firestore `snapshots()` streams, so a status change made by staff appears on the student's screen without refreshing. Photos are read once, because they never change after submission, and Firestore's offline cache means opening the same report again doesn't download them again.

### Anonymous reports

Any signed-in user can read any report, so whatever a report stores is effectively public. If anonymous reports kept the reporter's user id, anyone could match an anonymous report to the same person's named reports (same id) and work out who sent it. So:

- **Named reports** store `reporterId` and `reporterName` as usual.
- **Anonymous reports** store neither. The rules reject an anonymous report that carries an id or a name.
- The only link is a private record, `users/{uid}/reports/{reportId}`, written in the same transaction. Only the reporter can read it, and it can't be created for someone else's report or changed later.
- "My reports" and Home join two live sources: named reports (`where reporterId == uid`) and the anonymous ones listed in the private records (`whereIn` on the document id, in groups of 30, Firestore's limit).

What this doesn't hide: the Firebase project owner can still see the private records in the console, which is normal for campus systems (abuse can be followed up). Staff updates in Milestone 4 will reach anonymous reporters without staff learning who they are.

### Fonts

Plus Jakarta Sans is bundled in `assets/fonts` rather than downloaded at runtime, so it works offline and in tests.

## Testing

```
flutter analyze
flutter test
```

So far: validators, time formatting, the `AppUser` and `Report` models, `AuthRepository` and `ReportRepository` (with `firebase_auth_mocks` and `fake_cloud_firestore`), search, filters, sort and the progress timeline, every routing rule, widget tests for the shared components, and a widget test of the New report form (validation, photo, submit).

The security rules are not unit tested yet. That needs the Firestore emulator, which needs Java, and is planned for Milestone 6.

## Assignment checklist

| Requirement | Where | Status |
|---|---|---|
| Submit reports with description, category, optional photos | [new_report_screen.dart](lib/features/reports/presentation/new_report_screen.dart), `ReportRepository.createReport` | Done |
| Browse, search, filter, details, track status | Browse, Home, Report details with the live progress timeline | Done |
| Two roles: students and authorised staff | `AppUser.role`, staff approval, role-based routing | Done |
| Modern state management (Riverpod), logic outside widgets | `application/` providers and controllers | Done for auth and reports; continues |
| Firebase Authentication (email and password) | `AuthRepository`, verification, password reset | Done |
| Cloud Firestore | `users`, `reports`, `reports/{id}/photos`, `reports/{id}/updates`, `counters` | Done for students; staff writes in Milestone 4 |
| Basic widgets and layouts | all screens | Done so far |
| Navigation | go_router, nav-bar shells, redirects | Done |
| Forms with validation | sign in, sign up (email domain, live password checklist, confirm), New report (required fields, category, 300-character description, up to 3 photos) | Done |
| Reusable components | `core/widgets`, component gallery | Done |
| Asynchronous programming: loading, empty, error states | `AsyncValueView`, `LoadingState`, `EmptyState`, `ErrorState` | Components done; used on every data screen |
| Security rules | [firestore.rules](firestore.rules) (accounts, report creation, photos, counter) | In progress, finished in Milestone 6 |
| Extra features: anonymous reports (no id or name stored), urgency levels, readable ticket numbers, sort | New report, Browse | Done |
| Extra features: Me too, staff notes, notifications, confirm or reopen | Me too count and staff notes already show on Report details | Milestones 4 and 5 |
| Extra: one-time email verification with 24-hour expiry | auth feature, admin script | Done |
