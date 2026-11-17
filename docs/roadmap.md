# Keyrate roadmap

Steps, not semver. vN is the Nth small shippable step and v100 is the finish. Each step ends with its check green. Keyrate stays one number with nothing attached: no accounts, themes or multiplayer.

## Gap matrix vs Monkeytype, 10fastfingers, Speed Typer, Keybr (2026-11-02)
Own design wins, borrow ideas only. Each row is one minor on web plus all native ports, vectors updated first. Out of scope stays: accounts, themes, multiplayer, leaderboards, badges.
- [ ] G3 (M, Speed Typer, Monkeytype): Last 20 tests on device, personal best per mode, no sync
- [ ] G4 (S, 10fastfingers, Speed Typer): Word list sizes: top 200, 1000, 5000
- [ ] G6 (M, Speed Typer): Custom text mode (pasted text, never sets a best, ties to v14)
- [ ] G7 (L, all): v81 languages
- [ ] G8: side by side screenshots vs Monkeytype in light and dark, fix whatever looks worse

## 4.3(a) rejection (2026-11-03, iOS and Mac 2.0.0)
Reply sent on Mac 11-04, nothing back. What changed for the resubmit: own word list from public domain novels (the old one matched Monkeytype and 10fastfingers), G1 and G5 on every port, listing rewritten around the keys you miss. Next if it comes back again: G3, the missed keys across your last 20 tests, which is the real answer to "what is different".

## To v100

### Rules and scoring

### Android
(blocked 11-01: no Android SDK on this Mac, so the APK and emulator steps cannot run here. A JDK is now installed: `:shared:jvmTest` runs and all 18 shared tests pass, after fixing a missing paren in SessionTest.kt)
- [ ] v20: Run the debug APK on an emulator and walk 15, 60, words and quote
- [ ] v21: Fix whatever the soft keyboard does to the hidden input (autocorrect, spaces)
- [ ] v22: Adaptive launcher icon with the glyph on the accent tile
- [ ] v24: Dark theme walk on a device, both orientations
- [ ] v25: Tablet and foldable layout: the words column stays 832dp wide and centred
- [ ] v26: TalkBack pass: words, timer, result
- [ ] v27: Release build: R8 on, signing from a gitignored file, versionCode from the git count
- [ ] (11-01: text done in metadata/android, fastlane supply layout; screenshots wait on the device walk, v20) v28: Play listing text and screenshots in a metadata folder, ready to paste
- [ ] v29: keyrate-kmp.yml runs shared tests and assembleDebug, added only after a clean run on a fresh clone
- [ ] v30: Keep the APK under 10 MB
- [ ] v33: Play pre-launch report read and fixed
- [ ] v34: First Play internal-testing build uploaded (Joshua signs in)
- [ ] v35: Android 2.0.1 from what the report and testers show

### Desktop (Windows, Mac, Linux)
- [ ] v37: Build the Msi and the Deb on CI runners, not here
- [ ] v40: Windows font check: system sans, never a serif fallback
- [ ] v41: Linux check on Wayland and X11
- [ ] v43: Notarize the Mac Dmg (Joshua's account)
- [ ] v45: Desktop 2.0.1 from what the three platforms show

### iPhone, iPad, Mac (SwiftUI)
- [ ] (11-01: builds and launches on the iPhone 17 Pro simulator, focus lands; the typing walk needs Simulator.app or a UI test target, this Mac has neither, so it moves to the real phone walk in v59) v46: Run on an iPhone simulator and walk every mode with the keyboard up
- [ ] v50: VoiceOver pass on iPhone and Mac
- [ ] v58: TestFlight build 1 to Joshua's phone
- [ ] v59: Real iPhone walk: keyboard, autocorrect off, copy and paste, rotation
- [ ] v60: Fix what the real phone shows, TestFlight build 2

### Terminal

### Quality, docs, CI
- [ ] v73: Landing: swap each Coming soon for a real link as it ships
- [ ] v74: Landing: a dark screenshot in each platform card
- [ ] (11-01: grep half done, no fetch, XMLHttpRequest, WebSocket, beacon, URLSession, HttpURLConnection or ktor in web, Swift or Kotlin, no INTERNET permission, no network entitlement; the firewall run is still to do) v78: Security pass: no network calls in any build, checked by grep and by a firewall run
- [ ] v81: Languages: Spanish, French, German and Portuguese word lists as opt-in modes, UI strings translated
- [ ] (11-01: waits on v81; with only English words there is no right-to-left text to check yet) v82: Right-to-left check for the UI
- [ ] v85: A crash-free week on TestFlight and Play internal before any public submit
- [ ] v86: Reply to the first ten real reviews, plain words
- [ ] v87: Delete dead code: legacy notes, unused chips, stale files
- [ ] v88: Docs 100: every markdown file current, links valid, CI green, no stale branches
- [ ] v89: Quality pass on all four apps against the web, side by side, same words same score

### Release
- [ ] v90: Bump README, whitepaper and badges to v2.0.0 once iOS and Mac are in review
- [ ] v91: Tag keyrate-native-v2.0.0 and push the tag by name
- [ ] v92: Retake every screenshot after the last UI change
- [ ] v93: Product Hunt kit in launch/ (Joshua posts)
- [ ] v94: GitHub description, homepage and topics set
- [ ] v95: 2.0.1: the first round of fixes from real users, nothing new
- [ ] v96: Drop Coming soon from the landing entirely
- [ ] v97: Journal entry for the release, plain words
- [ ] v98: Move keyrate to its own repo only if the fleet rule says so, history kept
- [ ] v99: Review the out-of-scope list once: still no accounts, themes or multiplayer
- [ ] v100: v100: Keyrate on five platforms, one number, the same on all of them

## Joshua's steps
Apple login and 2FA, Play sign-in, signing and notarizing, store submits, posting the launch.

## TUI pilot (2026-09-05)
`keyrate-tui` is a SwiftPM target (SwiftTUI). `tui/Sources/Score.swift` is a line-for-line port of score.js and the apps reuse it. It renders one score card; v63 makes it live.

## Ingested 2026-11-03
- [x] Build issues email (Nov 2): orientations already in project.yml (b3ee817), build bumped to 5 for the next upload; 2.0.0 iOS+Mac stay WAITING_FOR_REVIEW on build 4

## Ingested 2026-11-13
- [ ] Note was the title only ("Keyrate"), written in a run of App Review status checks. Report its review status. Last known (root roadmap, 2026-11-08): waiting on Apple. Could not re-pull today: the asc API is blocked by an unaccepted Apple agreement (see vault blocked-on-joshua.md).

## Next (2026-11-17)
- [ ] Languages: Spanish, French, German, Portuguese word lists counted from public domain novels (scripts/wordlist.mjs per language), a Language picker in Settings and on the web, UI strings translated.
- [ ] Accounts on jaybulb-api: sign in, sign up, forgot password, profile with avatar (upload or a generated keycap), bests synced. Privacy policy refreshed alongside.
- [ ] Leaderboards tab (daily and weekly per mode), then matchmaking and live races (Durable Objects).
- [ ] Drill mode in the Apple and Kotlin apps (web has it).
- [ ] iPhone QA on Joshua's Mac (the iOS simulator is unusable on Dad's 2017 Intel Mac).
- [ ] CLOUDFLARE_API_TOKEN repo secret, then commit .github/workflows/deploy.yml.
- [ ] Docs refresh: CLAUDE.md (ask first), docs/ARCHITECTURE.md, docs/LOOP-HANDOFF.md, docs/images/architecture.svg.

## Launch (Joshua, upstairs)
- [ ] App Store submit for iOS and Mac 2.3.0 (asc login from Joshua's Mac).
- [ ] Product Hunt (Tuesday), Show HN, Reddit (r/typing, r/MechanicalKeyboards, r/macapps), Twitter/X.

## Gaps vs all-the-right-type, Monkeytype, 10fastfingers (2026-11-17)
One row per minor, web first, then Apple and Kotlin.
- [ ] Lessons: home row first, one row at a time, with a finger guide on the keyboard
- [ ] Test options: stop on error, blind (no red), zen (no timer), smooth caret, key sounds (off by default)
- [ ] Text: custom pasted text (never sets a best), word list sizes 200 / 1k / 5k, languages
- [ ] History: a graph of every run, a per-key heatmap, best per mode with dates
- [ ] Accounts, leaderboards (daily, weekly), live races, a shareable result card and certificate
- [ ] Themes beyond light and dark, kept to the brand palette
- [ ] Settings, Account tab: sign in and register with Apple, Google, GitHub and email (jaybulb-api already does email, Apple and Google id tokens; GitHub OAuth needs adding there), forgot password, profile and avatar
