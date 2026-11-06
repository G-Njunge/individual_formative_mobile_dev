# Prompt for Claude Code

Copy everything below the line into Claude Code, from the root of your Flutter project, after unzipping this package into a folder called `design/` in that project.

---

I'm building **Ripoti**, a Flutter mobile app for a university assignment. Students report campus issues (broken facilities, water shortages, power outages, damaged furniture, sanitation problems, safety concerns) and campus staff review the reports and update their status. Please implement the full app from the design in `design/`, using **Firebase** as the backend.

## Start by reading the design

Read these before writing any code:

1. `design/DESIGN_SPEC.md`: colours, shadows, typography, reusable components, and the behaviour of every screen. This is the source of truth for design rules.
2. `design/screens/*.png`: an image of every screen and state. Match these layouts closely. Look at every image.
3. `design/source/*.dc.html`: the HTML templates the images were rendered from. Use them to read exact sizes, spacing and copy. They use a small template syntax (`{{value}}`, `<sc-for>` loops, `<sc-if>` conditions, with the sample data in the `<script>` at the bottom of each file). Do not try to run them.
4. `design/illustrations/*.svg` and `design/assets/paint-bg.png`: copy these into the Flutter project's `assets/` and render the SVGs with `flutter_svg`.

Then give me a short plan (folder structure, packages, data model, milestones) and wait for my OK before building.

## Assignment requirements (must all be met)

- Students can submit reports with a description and category, and optionally attach photos.
- Users can browse submitted reports, search and filter them, open report details, and track status from submission to resolution.
- Two roles: **students**, who submit reports, and **authorised campus staff**, who review reports and update their status.
- State management with a modern approach. Use **Riverpod** (`flutter_riverpod`). Keep business logic in providers and repositories, not in widgets.
- **Firebase Authentication** (email and password), **Cloud Firestore** for data, **Firebase Storage** for photos.
- It must show clear use of: basic widgets and layouts, navigation, forms with input validation, reusable components, asynchronous programming (loading, error and empty states everywhere data loads), state management, and Firebase integration.
- Thoughtful extra features that improve reporting are encouraged. The design already includes "Me too", anonymous reports, urgency levels, staff notes, notifications and confirm-or-reopen. Build those.

## Tech choices

- Flutter (latest stable) and Dart with null safety. Target Android and iOS.
- Packages: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `flutter_riverpod`, `go_router`, `google_fonts` (Plus Jakarta Sans), `flutter_svg`, `image_picker`, `intl`, and an inset shadow package for the pressed neumorphic look (check pub.dev for a maintained one, or write a `CustomPainter`). Ask me before adding anything else that is not small and well maintained.
- Folder structure: feature-first, for example `lib/core/` (theme, tokens, router, shared widgets), `lib/features/auth`, `onboarding`, `reports`, `staff`, `notifications`, `profile`, each with `data/` (repositories, models), `application/` (providers) and `presentation/` (screens, widgets).
- Put every colour, shadow, radius and text style from the spec into one theme and tokens file. Screens must never hard-code colours or shadows.
- Firebase setup: **do not invent Firebase config values.** Tell me when to run `flutterfire configure` and use the generated `firebase_options.dart`.

## Data model (Firestore)

Use this as a starting point and tell me if you think something should change:

- `users/{uid}`: `name`, `email`, `role` (`student` | `staff`), `staffId` (staff only), `approved` (bool, staff only; a staff account cannot use staff features until an admin sets this to true in the console), `createdAt`.
- `reports/{reportId}`:
  - `ticketNumber` (int, from a `counters/reports` doc incremented in a transaction)
  - `title`, `description`, `category` (`water` | `power` | `furniture` | `sanitation` | `safety` | `other`)
  - `location`, `urgency` (`low` | `medium` | `high`)
  - `status` (`submitted` | `under_review` | `in_progress` | `resolved`)
  - `photoUrls` (list), `afterPhotoUrl`
  - `reporterId`, `reporterName` (null when `anonymous` is true), `anonymous`
  - `assignedTo` (`{uid, name, team}`)
  - `meTooCount`
  - `createdAt`, `updatedAt`
- `reports/{reportId}/updates/{updateId}`: `status`, `note`, `byUid`, `byName`, `createdAt`. This collection is the progress timeline.
- `reports/{reportId}/supporters/{uid}`: `createdAt`. One per "Me too", so a student can only back a report once.
- `users/{uid}/notifications/{id}`: `type`, `reportId`, `title`, `body`, `read`, `createdAt`.
- `announcements/{id}`: `title`, `body`, `createdAt`. Created by staff.

Photos go in Storage at `reports/{reportId}/{fileName}.jpg`. Compress before uploading (for example `imageQuality: 70`, `maxWidth: 1600`) and limit files to 5 MB and `image/*` in the Storage rules.

When staff save an update, write the report change, the `updates` entry, and a notification for the reporter and every supporter in one batch. No Cloud Functions are needed for the assignment. If a function would clearly be better, tell me and keep it optional.

## Security (write and explain real rules)

Create `firestore.rules`, `storage.rules` and `firestore.indexes.json`. At minimum:

- Every read and write requires sign-in.
- Users can create their own `users` doc, but cannot set `approved` to true or change their own `role` afterwards.
- Students can create reports only as themselves, with `status: submitted`.
- Only approved staff can change `status`, `assignedTo` and `afterPhotoUrl`, add `updates`, and create announcements and notifications for other users.
- The reporter may only reopen a resolved report (resolved to submitted) or confirm the fix.
- "Me too": a user can create or delete only their own supporter doc, and `meTooCount` may only change by exactly 1 alongside it (use `existsAfter` / `getAfter`).
- Users can read and mark as read only their own notifications.

Add the composite indexes the queries need (for example `status` + `createdAt`, `reporterId` + `createdAt`).

## Screens and flows

Build every screen in the spec and the images:

- Onboarding carousel (auto-advancing)
- Sign in and Create account (with the role toggle)
- Student: Home, New report, Report submitted, Browse reports (All / My reports, search, filters), Report details (timeline, Me too, confirm or reopen), Notifications, Profile
- Staff: Dashboard (counts plus a New / Mine / All queue), Update status

Routing: send signed-in users to the student or staff home based on their role. Unapproved staff see a simple "waiting for approval" screen. Show onboarding only on first launch.

Notes:
- Search: Firestore has no full-text search, so filter the loaded list on the device by title and location (case-insensitive). Say so in the README.
- Use real-time streams (`snapshots()`) for lists, details and notifications so status changes appear live.
- "Use my current location" can be a stretch goal: ask me first before adding location packages.
- Form validation: required fields, campus email format, password at least 8 characters with a strength meter, matching confirm password, description up to 300 characters, at most 3 photos.

## Quality bar

- Every screen that loads data has loading, empty and error states in the same visual style.
- Accessibility: semantic labels on icon-only buttons (the nav bar is icons only), touch targets at least 44 px, readable text contrast on the dark base.
- Tests: unit tests for validators, model `fromJson`/`toJson` and repository logic (use `fake_cloud_firestore` and `firebase_auth_mocks`), plus widget tests for the main reusable components and the New report form.
- A seed script or a debug-only button that creates sample users and reports (the sample content is in the spec). Never ship the sample data in the UI.
- A `README.md` covering: setup (`flutterfire configure`, deploying rules and indexes with the Firebase CLI), how to make a staff account approved, architecture overview, and a feature checklist mapped to the assignment requirements.

## How to work

- Build in milestones and show me each one before moving on:
  1. Theme, tokens and shared components, with a debug "component gallery" screen I can compare against the images.
  2. Firebase setup, auth, onboarding and role-based routing.
  3. Student reporting: New report with photo upload, Home, Browse, Details.
  4. Staff dashboard and status updates, including the notification fan-out.
  5. Me too, notifications, profile, confirm or reopen.
  6. Security rules, indexes, seed data, tests, README.
- Run `flutter analyze` and the tests at the end of each milestone, and fix what they report.
- Ask me before making a decision that changes the design, the data model or the folder structure. For small choices, pick a sensible default and mention it.
- Explain why you chose an approach, not just what you did, so I can explain it in my presentation.
