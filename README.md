<img src="web/icon.svg" width="80">

![version](https://img.shields.io/badge/version-v2.3.0-blue) [![tests](https://github.com/nulljosh/keyrate/actions/workflows/test.yml/badge.svg)](https://github.com/nulljosh/keyrate/actions/workflows/test.yml) ![license](https://img.shields.io/badge/license-Apache%202.0-blue)

A typing test that shows you which keys slow you down. Live at **[keyrate.jaybulb.com](https://keyrate.jaybulb.com)**.

<img src="docs/images/landing.png" width="720">

## Features

- **Your five worst keys, lit.** The result draws a keyboard with the keys you miss most in red. A slip you fixed still counts.
- **Speed, second by second.** A line of your words per minute across the run, with raw speed beside it.
- **Words of its own.** The thousand most common words across twenty public domain novels, plus quotes from writers long out of copyright.
- **Six modes.** 15, 30 or 60 seconds, 25 or 50 words, or a quote. Punctuation and numbers optional.
- **Light, dark or auto.** Follows your device, or pick one.

<img src="docs/images/typing.png" width="720">

## Platforms

| Where | Folder | Status |
|---|---|---|
| Web | `web/` | Live |
| iPhone, iPad, Mac | `apple/` | In App Review |
| Android, Windows, Linux | `kmp/` | Builds, not released |
| Terminal | `tui/` | Builds |

Every port checks itself against `tests/vectors.json`, so a score means the same thing everywhere.

## Run it

```sh
node --test tests/                 # scoring, rules, word list, vectors
cd web && python3 -m http.server   # the site at localhost:8000
scripts/check.sh                   # node, Kotlin, Xcode and README links
```

iPhone, iPad and Mac: `cd apple && xcodegen generate && open Keyrate.xcodeproj`. Android and desktop: `cd kmp && ./gradlew :composeApp:run`. Terminal: `swift run --package-path tui keyrate-tui`.

## Architecture

<img src="docs/images/architecture.svg" width="720">

More in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), the reasoning in [docs/WHITEPAPER.md](docs/WHITEPAPER.md), the brand in [web/brand/BRAND.md](web/brand/BRAND.md).

## License

Apache 2.0. Copyright 2026 Joshua Trommel.
