# Keyrate roadmap

Semver. Each minor ships on the web first, then Apple, Kotlin and the terminal. A release is done when `scripts/check.sh` is green, it is deployed, and it has QA screenshots. The history of finished steps lives in `git log`.

Now: **2.4.0** (2026-11-19, web). Grade 2026-11-19: C+ overall. Web B+, landing B, Mac B, iOS C+, Android D, desktop D, joshuatree/Pi D, docs C.

## 2.4.0: Landing and web accounts (shipped 2026-11-19)
- [x] Top bar: logo left, Log in and Sign up right (Account when signed in)
- [x] /account: email sign up, log in, forgot and reset password, sign out, delete account (jaybulb-api)
- [x] Hero demo cycles 50, 90, 120 and 200 wpm; the typed line shows under the buttons and the result card shows each run
- [x] Brand kit: Mark on white and Mark on charcoal render (mark.svg had no #m), cool greys
- [x] SEO: canonical, Open Graph image, Twitter card, JSON-LD, robots.txt, sitemap.xml
- [x] Privacy: info@jaybulb.com, accounts section
- [x] Cool grey palette (web/palette.css) on every page, 8 px rhythm, AA contrast, 40 px tap targets
- [x] Test: a key in flight when the run ends no longer restarts it (the result holds 800 ms)
- [ ] Docs: architecture.svg redraw, ARCHITECTURE.md and LOOP-HANDOFF.md refresh, a user help page

## 2.5.0: Mac and iPhone
- [ ] Mac UI pass to A+ with QA screenshots (macOS 13 here, 26 upstairs)
- [ ] Settings, Account tab: Sign in with Apple, Google and GitHub (ASWebAuthenticationSession + PKCE), email; tokens in Keychain only
- [ ] jaybulb-api: GitHub OAuth
- [ ] Drill mode in the Apple app
- [ ] History: last 20 runs and the keys you miss across them (also the answer to 4.3(a))
- [ ] GitHub releases: a notarized Mac .dmg each tag; iOS links to the App Store or TestFlight
- [ ] App Store: resubmit iOS and Mac with the changes above and a reply to 4.3(a). Expedited review is for urgent bug fixes, not rejections, so it doesn't apply
- [ ] Real iPhone walk upstairs: keyboard, autocorrect off, rotation, VoiceOver

## 2.6.0: Terminal
- [ ] `keyrate` TUI made live (tui/, SwiftPM): the test, the result card, the five keys
- [ ] `brew install nulljosh/tap/keyrate` from homebrew-tap, built on release
- [ ] Linux build of the TUI (Swift on Linux) for the Pi and servers

## 2.7.0: Everywhere
- [ ] joshuatree / Raspberry Pi: fix the Makefile path (now `web/app/index.html`), regenerate app_keyrate.h, check it on the Pi
- [ ] Android: emulator walk, soft keyboard, release build under 10 MB, Play internal test (Joshua signs in)
- [ ] Desktop: Linux .deb and Windows .msi built on CI; Wayland, X11 and Windows font checks

## 2.8.0: Fast and solid
- [ ] Landing and test at Lighthouse 100 across the board, no layout shift
- [ ] Shared jaybulb.com CSS and JS vendored, so the site needs one origin
- [ ] CSP and security headers in web/_headers
- [ ] Works offline as an installable web app
- [ ] CLOUDFLARE_API_TOKEN secret, then deploy on push

## 3.0.0: Online
- [ ] Bests synced to your account (opt-in; storage format v2, hence the major)
- [ ] Leaderboards, daily and weekly per mode
- [ ] Profile and avatar (upload or a generated keycap)
- [ ] Shareable result card

## 3.1.0: Languages
- [ ] Spanish, French, German and Portuguese word lists from public domain novels, a language picker, translated UI, right-to-left check

## 3.2.0: Practice
- [ ] Lessons: home row first, a finger guide on the keyboard
- [ ] Test options: stop on error, blind, zen, key sounds (off by default)
- [ ] Custom text (never sets a best), word list sizes 200, 1k and 5k

## 4.0.0: Races
- [ ] Live races and matchmaking on Durable Objects

## Launch (Joshua)
Apple login and 2FA, Play sign-in, signing and notarizing, store submits. Product Hunt (a Tuesday), Show HN, r/typing, r/MechanicalKeyboards, r/macapps.

## Out of scope
Themes beyond light and dark in the brand palette. Ads. Tracking.

## Inbox
New Apple Notes land here; sort them into a release.
