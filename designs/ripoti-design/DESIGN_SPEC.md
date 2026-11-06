# Ripoti design spec

Ripoti (Swahili for "report") is a campus issue reporting app. Students report broken facilities, water and power problems, damaged furniture, sanitation and safety issues, and follow each report until it is resolved. Campus staff review reports and update their status.

"Ripoti" is a working name. Keep it in one constant so it is easy to rename.

The look is **dark neumorphism**: one deep plum-grey base colour, with every surface shaped by two shadows instead of borders. The design is deliberately clean. It has very few icons and no floating decorations.

The screen images in `screens/` are the source of truth for layout. This document explains the rules behind them.

---

## 1. Design tokens

### Colours

| Token | Hex | Used for |
|---|---|---|
| `base` | `#2B2230` | Page background and every neumorphic surface (cards, chips, inputs, nav bar) |
| `shadowDark` | `#1A1420` | Dark shadow, bottom-right of raised shapes and top-left inside pressed shapes |
| `shadowLight` | `#3C3042` | Light edge, top-left of raised shapes and bottom-right inside pressed shapes |
| `textPrimary` | `#F3ECF1` | Headings, titles, body text |
| `textSecondary` | `#B9A9B6` | Labels, meta text (place, time), helper text |
| `textTertiary` | `#9C8C99` | Placeholders, inactive nav icons |
| `textBody` | `#D5C7D2` | Long body text and unselected chip text |
| `amber` | `#DB9734` | Primary buttons, the + action, selected urgency level |
| `onAmber` | `#2A1424` | Text and icons on amber |
| `amberLight` | `#F0B45E` | Selected chips and tabs, links, the active nav icon, "Submitted" status |
| `plum` | `#680D4E` | Brand fills: logo square, "New today" staff tile, success check badge, switch ON track |
| `pinkLight` | `#F4A9D8` | "In progress" status, High urgency pill |
| `pinkMark` | `#D77BB5` | Completed steps on the progress timeline |
| `teal` | `#74D6CD` | "Resolved" status, resolved counts |
| `divider` | `#3A2F40` | Thin dividers in lists |
| `track` | `#4A3D50` | Empty dots, empty timeline steps, unfilled bars |
| `error` | `#FF8A80` | Validation errors, "Sign out" |

Illustrations keep their own colours (skin tones, teal, navy, washroom greys). See `illustrations/`.

### Status colours (text colour on a pressed pill)

| Status | Colour |
|---|---|
| Submitted | `amberLight` `#F0B45E` |
| Under review | `textBody` `#D5C7D2` |
| In progress | `pinkLight` `#F4A9D8` |
| Resolved | `teal` `#74D6CD` |

A status is always shown as a written word, never as colour alone.

### Urgency pills (staff side)

| Urgency | Style |
|---|---|
| High | filled `pinkLight`, text `onAmber` |
| Medium | filled `amber`, text `onAmber` |
| Low | pressed pill, text `textBody` |

### Shadows (the neumorphic recipe)

Raised (cards, buttons, chips you can tap):

```
BoxShadow(color: shadowDark,  offset: Offset(7, 7),   blurRadius: 16)
BoxShadow(color: shadowLight, offset: Offset(-7, -7), blurRadius: 16)
```

Sizes used: small 4/10 (chips, small buttons), medium 5/12 (round icon buttons), large 7/16 (cards), extra large 12/24 (illustration panels). Format is offset/blur.

Pressed (inputs, the selected chip or tab, status pills, the current nav icon): the same two shadows drawn **inside** the shape. Flutter's `BoxShadow` has no inset option. Use an inset shadow package (for example `flutter_inset_shadow`; check pub.dev for the current, maintained one) or draw it with a `CustomPainter`. Wrap both in one reusable widget so screens never build shadows by hand.

Coloured buttons (amber, plum) use the raised recipe with the same dark and light shadow colours.

### Corner radii

- Illustration panels: 36
- Cards: 24
- Inputs, primary buttons: 18 to 20
- Chips: fully rounded (height / 2)
- Round icon buttons: 16 (46 × 46)
- Floating bottom nav: 26

### Spacing

- Screen side padding: 22 to 24
- Gap between sections: 22 to 26
- Gap inside cards: 10
- Card padding: 18
- Leave about 130 px of space at the bottom of scrolling screens so content clears the floating nav bar.

### Typography

Font: **Plus Jakarta Sans** (use the `google_fonts` package, or bundle the font files).

| Role | Size / weight |
|---|---|
| Onboarding headline | 30 / 800, line height 1.15, letter spacing -0.6 |
| Screen title | 26 / 800 |
| Greeting name | 24 / 800 |
| Section heading | 17 to 18 / 800 |
| Card title | 15.5 / 700 |
| Body | 14.5 to 15 / 400 to 500, line height 1.5 |
| Meta text | 12.5 / 500 |
| Category label | 11.5 / 800, uppercase, letter spacing 0.6 |
| Button | 16 / 700 (primary), 13 to 14 / 700 (small) |
| Nav | icons only (with semantic labels) |

---

## 2. Reusable components

Build these once and reuse them everywhere.

| Component | Notes |
|---|---|
| `NeuSurface` | Container that is raised or pressed (`depth` parameter). Every other component uses it. |
| `NeuCard` | Raised `NeuSurface`, radius 24, padding 18. Tappable variant has a pressed state while touched. |
| `PrimaryButton` | Amber, 56 to 58 tall, radius 20, text `onAmber`. Has loading and disabled states. |
| `SecondaryButton` | Raised `base` surface, text `textPrimary`. |
| `NeuIconButton` | 46 × 46, radius 16, raised. Used for back and close. |
| `NeuTextField` | Pressed surface, 52 to 56 tall, radius 18, label above it, error text below it. No leading icons except search. |
| `SegmentedToggle` | Pressed track holding 2 or 3 options. The selected option is a raised `base` pill with `amberLight` text. Used for Student / Campus staff, All / My reports, New / Mine / All, Low / Medium / High (the urgency selection is filled amber). |
| `FilterChipRow` | Horizontally scrolling chips. Unselected = raised. Selected = pressed with `amberLight` bold text. |
| `StatusPill` | Pressed pill, text in the status colour. |
| `ReportCard` | Category label (uppercase), title, then "place · time" on the left and a `StatusPill` on the right. Browse and staff variants also show "N me too". |
| `StatTile` | Big number (30 / 800) plus a label. Neutral raised, or filled plum / amber for the two highlighted staff tiles. |
| `ProgressTimeline` | Vertical steps: done = filled `pinkMark` dot plus line, current = amber dot with a ring, upcoming = hollow `track` dot. A staff note can sit under the current step as a small raised card. |
| `FloatingNavBar` | Floats 16 from the sides and 18 from the bottom, height 72, radius 26, raised. Student: Home, Reports, + (amber, 54 × 54), Notifications (amber dot when unread), Profile. Staff: Dashboard, All reports, Profile. The current tab's icon sits in a pressed square and turns `amberLight`. |
| `NeuSwitch` | Pressed track. Knob is a raised `base` circle. ON = plum track. |

---

## 3. Screens

PNG file names in `screens/` are in brackets. The matching template source is in `source/`.

### Onboarding carousel (`01a`, `01b`, `01c`)
- Top: plum logo square plus the "Ripoti" wordmark on the left, a raised "Skip" pill on the right (goes to Sign in).
- One horizontal carousel (`PageView`) with 3 slides. Each slide: an illustration in a raised panel (radius 36), a two-line headline (second line `amberLight`) and a short paragraph.
  1. "Spot something / broken on campus?"
  2. "Snap it. / Report it."
  3. "Watch it / get fixed."
- **Auto-advances every 4 seconds** and loops. Swiping or tapping a dot changes the slide and restarts the timer. Slide transition: about 0.6 s, ease-out curve.
- Dots: inside a pressed pill. The current dot stretches to a 24 px amber pill.
- Bottom (always visible): "Get started" (amber, goes to Create account) and "I already have an account" (secondary, goes to Sign in).

### Sign in (`02a`, `02b`)
- Back button, then a raised logo tile, "Welcome back", subtitle.
- `SegmentedToggle`: Student / Campus staff.
- Campus email, Password (with a "Show" text button), "Forgot password?" link.
- Primary button label changes with the role: "Sign in" or "Sign in to staff dashboard".
- "New to Ripoti? Create an account" link.

### Create account (`03a`, `03b`)
- Role toggle, Full name, Campus email, Password with a 3-bar strength meter, Confirm password.
- Picking Campus staff adds a **Staff ID** field and the note "Staff accounts are approved by the facilities office."
- Shows the inline error style: red outline plus "Passwords do not match".

### Home (student) (`04`)
- "Good morning," plus first name. Round avatar with initials on the right (goes to Profile).
- Pressed search field.
- "Spotted a problem?" card: background image `assets/paint-bg.png` with a dark overlay (rgba(24,12,30,0.5)), white text, amber "Report an issue" button (goes to New report). It is the only image on the screen.
- Two stat tiles: Open reports (amber number), Resolved (teal number). These count the signed-in student's own reports.
- "Recent reports" with "View all", filter chips (All, Submitted, In progress, Resolved), then `ReportCard`s.
- `FloatingNavBar` with Home active.

### New report (`05`, full scroll)
A scrolling form with the "Submit report" button pinned at the bottom. Leave enough bottom padding that the last row ("Report anonymously") is not hidden behind the button. In the image it is partly covered, which is a known mockup issue.
- Close button plus "New report".
- Photos (optional, up to 3): an attached photo tile with a remove button, and a pressed "+ Add photo" tile that opens camera or gallery.
- Category (required): a 3-column grid of text buttons: Water, Power, Furniture, Sanitation, Safety, Other. The selected one is pressed with `amberLight` text.
- Title (required), Description (required, 300 character counter), Location (required, plus a "Use my current location" text button).
- "How urgent is it?": Low / Medium / High with a hint line that changes with the choice:
  - Low: "it can wait a few days."
  - Medium: "it affects people today."
  - High: "it is unsafe or blocks a whole building."
- "Report anonymously" switch: staff will not see the reporter's name.

### Report submitted (`06`)
- Illustration (`illustrations/report_submitted.svg`) in a raised panel with a plum check badge overlapping the top-right corner.
- "Report submitted" plus a thank-you line.
- Ticket card: ticket number, status pill, title, and a 4-step strip (Submitted, Review, In progress, Resolved) with the current step filled amber.
- "Track this report" (goes to details) and "Back to home".

### Browse reports (`07`)
- "Campus reports", toggle All reports / My reports, search, chips (All, Submitted, Under review, In progress, Resolved), a count line ("5 reports") with a "Newest first" sort control, then report cards showing "N me too".

### Report details (`08`, full scroll)
- Back button, "TICKET #1042".
- Photo in a raised frame (swipe if there are several).
- Category label, status pill, title, "place · date · urgency", description.
- "Me too" card: "12 students also see this issue" plus an amber "Me too" button. After tapping, it becomes pressed and reads "Added", and the count goes up.
- "Progress" timeline inside a pressed panel, with the staff note under the current step.
- On a resolved report, the reporter should be asked "Is it fixed?" with Yes / Reopen (see Notifications).

### Notifications (`09`)
- "Mark all read".
- Campus announcement card (filled amber).
- Grouped as Today / Earlier. Unread rows are bold with an amber dot.
- A resolved report row asks "Is it fixed?" with "Yes, fixed" (amber) and "Reopen" buttons.

### Profile (`10`)
- Avatar (amber circle, initials), name, email, role label.
- Stat tiles: Reported, Open, Resolved.
- List: My reports, Followed reports, Notification settings, Dark mode switch, Help and FAQ.
- "Sign out" in the error colour.

### Staff dashboard (`11`)
- "Facilities desk" / "Hello, {first name}", avatar.
- 2 × 2 stat tiles: New today (plum fill), In progress (amber fill), Under review, Resolved this week.
- "Report queue" with a toggle: New / Mine / All. Cards show category, time, urgency pill, title, "place · status · N me too". Tapping a card opens the update screen.
- Staff `FloatingNavBar` (no + button).

### Staff: update status (`12a`, `12b`, full scroll)
- Ticket summary card: photo thumbnail, category plus urgency, title, place, "N me too", the reporter's description and name (hidden if anonymous).
- "Update status": a 2 × 2 radio group (Submitted, Under review, In progress, Resolved). The selected one is pressed with its status colour.
- "Assigned to" (pressed field plus "Change").
- "Note to the reporter" (multi-line) plus "Everyone who backed this report gets notified."
- Choosing Resolved reveals "After photo" upload (`12b`).
- Pinned bottom: "Duplicate" (secondary) and "Save update" (primary).

---

## 4. Assets

- `assets/paint-bg.png`: background for the "Spotted a problem?" card.
- `illustrations/*.svg`: onboarding slides 1 to 3, the success screen, and a sample report photo (for empty states or seed data). Render them with `flutter_svg`. They are vector, so they stay sharp on every screen size.

## 5. Sample content

The mockups use sample data: student "Amani Mugisha", staff "Jean Habimana (Plumbing)", ticket "#1042 Leaking tap in the Block C washroom", and a few other reports. Use them only as seed data for development. Never hard-code them into screens.
