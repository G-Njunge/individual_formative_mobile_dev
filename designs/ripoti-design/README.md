# Ripoti design package

Everything Claude Code needs to build the Ripoti campus reporting app in Flutter with Firebase.

## How to use it

1. Unzip this into your Flutter project as a folder called `design/` (so you have `design/DESIGN_SPEC.md`, `design/screens/` and so on).
2. Open Claude Code in the project root.
3. Paste the prompt from `CLAUDE_CODE_PROMPT.md` (everything below the line).

## What's inside

| Path | What it is |
|---|---|
| `CLAUDE_CODE_PROMPT.md` | The prompt to paste into Claude Code |
| `DESIGN_SPEC.md` | Colours, shadows, type, components and screen-by-screen behaviour |
| `screens/` | 17 PNG images: all 12 screens, plus extra states (each onboarding slide, staff versions of sign in and sign up, the "Resolved" choice on the staff update screen) |
| `source/` | The template files the images were rendered from, for exact sizes and copy |
| `illustrations/` | The onboarding and success illustrations as SVG files, ready for `flutter_svg` |
| `assets/paint-bg.png` | Background image for the "Spotted a problem?" card on Home |

## Screen list

| Image | Screen |
|---|---|
| 01a, 01b, 01c | Onboarding carousel (auto-advancing, 3 slides) |
| 02a, 02b | Sign in (student, staff) |
| 03a, 03b | Create account (student, staff) |
| 04 | Home |
| 05 | New report (full scroll) |
| 06 | Report submitted |
| 07 | Browse reports |
| 08 | Report details (full scroll) |
| 09 | Notifications |
| 10 | Profile |
| 11 | Staff dashboard |
| 12a, 12b | Staff: update status (full scroll; 12b shows the after-photo upload when Resolved is chosen) |
