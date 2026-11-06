# Ripoti

Ripoti (Swahili for "report") is a Flutter app for reporting campus issues: broken facilities, water shortages, power outages, damaged furniture, sanitation problems and safety concerns. Students submit reports and follow them until they are fixed. Campus staff review the reports and update their status.

Built with Flutter, Riverpod and Firebase (Authentication and Cloud Firestore), from the design in [designs/ripoti-design/](designs/ripoti-design/).

## Progress

| Milestone | Scope | Status |
|---|---|---|
| 1 | Theme, design tokens, shared components, component gallery | Done |
| 2 | Firebase set-up, sign in and sign up, email verification, forgot password, onboarding, role-based routing | Done (needs `flutterfire configure`, see below) |
| 3 | Student reporting: New report with photos, Home, Browse, Report details | Not started |
| 4 | Staff dashboard and status updates, notification fan-out | Not started |
| 5 | Me too, notifications, profile, confirm or reopen | Not started |
| 6 | Full security rules, indexes, seed data, remaining tests, final README | Not started |

Screens that belong to later milestones are temporary placeholders, so routing and sign-in can already be tried end to end.

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

Until the rules are deployed, a database created in production mode refuses every read and write, and sign up will fail.

### 5. Run

```
flutter pub get
flutter run
```

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
```

- **data/**: repositories are the only code that talks to Firebase. They return app models and throw readable errors (`UserFacingException`) instead of Firebase error codes.
- **application/**: Riverpod providers hold state and logic. `sessionProvider` combines the login and the profile into one status (signed out, needs verification, awaiting approval, student, staff). Form controllers expose an `AsyncValue` so screens can show loading and errors.
- **presentation/**: widgets only read providers and render. They never call Firebase.

**Routing.** [go_router](lib/core/router/app_router.dart) re-runs one rule, [sessionRedirect](lib/core/router/session_redirect.dart), whenever the session changes. Screens never navigate after sign in, verification or approval; the redirect does it. The rule is a plain function, so every case is unit tested.

**Design system.** Every colour, shadow, radius and text style lives in [tokens.dart](lib/core/theme/tokens.dart) and [text_styles.dart](lib/core/theme/text_styles.dart). Screens never hard-code them. The neumorphic look comes from one widget, [NeuSurface](lib/core/widgets/neu_surface.dart): raised surfaces use two `BoxShadow`s, and pressed surfaces use a small custom painter, because Flutter has no inset shadow. Dark is the original design and the default. A matching light theme keeps the same roles, with accent text colours darkened to stay readable.

## Decisions and trade-offs

### Photos without Firebase Storage

New Firebase projects need the paid Blaze plan to use Storage, so this project stays on the free Spark plan and stores photos in Firestore instead (Milestone 3). Each photo is compressed on the phone (about 1024 px wide, JPEG quality 60, usually 100 to 250 KB) and saved as a `Blob` in its own document under `reports/{id}/photos/`. That keeps every document well under Firestore's 1 MiB limit, and report lists never download photos. On Blaze, only the photo repository would change.

### Search

Firestore has no full-text search, so search filters the loaded list on the device by title and location, ignoring case (Milestone 3).

### Fonts

Plus Jakarta Sans is bundled in `assets/fonts` rather than downloaded at runtime, so it works offline and in tests.

## Testing

```
flutter analyze
flutter test
```

So far: validators, time formatting, the `AppUser` model, `AuthRepository` (with `firebase_auth_mocks` and `fake_cloud_firestore`), every routing rule, and widget tests for the shared components.

## Assignment checklist

| Requirement | Where | Status |
|---|---|---|
| Submit reports with description, category, optional photos | `features/reports` | Milestone 3 |
| Browse, search, filter, details, track status | `features/reports` | Milestone 3 |
| Two roles: students and authorised staff | `AppUser.role`, staff approval, role-based routing | Done |
| Modern state management (Riverpod), logic outside widgets | `application/` providers and controllers | Done for auth; continues |
| Firebase Authentication (email and password) | `AuthRepository`, verification, password reset | Done |
| Cloud Firestore | `users` profiles; reports from Milestone 3 | In progress |
| Basic widgets and layouts | all screens | Done so far |
| Navigation | go_router, nav-bar shells, redirects | Done |
| Forms with validation | sign in, sign up (email domain, password strength, confirm) | Done; New report in Milestone 3 |
| Reusable components | `core/widgets`, component gallery | Done |
| Asynchronous programming: loading, empty, error states | `AsyncValueView`, `LoadingState`, `EmptyState`, `ErrorState` | Components done; used on every data screen |
| Security rules | [firestore.rules](firestore.rules) (accounts so far) | In progress, finished in Milestone 6 |
| Extra features: Me too, anonymous reports, urgency, staff notes, notifications, confirm or reopen | | Milestones 3 to 5 |
| Extra: one-time email verification with 24-hour expiry | auth feature, admin script | Done |
