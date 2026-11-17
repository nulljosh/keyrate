# Keyrate brand kit and design system

**Brand kit** is who Keyrate is: the icon, the colours, the voice. **Design system** is how screens get built: tokens, type, spacing and the few components every port shares. Both live here; `tokens.css` is the design system in code.

## The idea
Keycaps. Cream keys on charcoal, and one red key: the one you keep missing. Everything Keyrate shows is built from that picture, from the icon to the landing hero to the result screen.

## Icon
- `../icon.svg`: the app icon, rounded tile, for READMEs (80 px) and the web.
- `icon-1024.png`: App Store icon, square, no alpha.
- `../../apple/Keyrate.icon`: Icon Composer source for iOS and macOS 26 (charcoal fill, `glyph.png` keys).
- `mark.svg`: the keys alone in `currentColor`, the missed key as an outline. For your own background.
- Clear space: one key width. Smallest size: 16 px (the favicon drops the key lips).

## Colour
| Role | Light | Dark |
|---|---|---|
| Background | `#ffffff` | `#1c1a17` |
| Surface (keys, cards, chips) | `#f5f5f7` | `#26231f` |
| Ink | `#1f1b16` | `#f3ede0` |
| Keycap (icon) | `#f3ede0` on `#b9b0a0` lip | same |
| Tile (icon) | `#2b2825` to `#141210` | same |
| Miss | `#d70015` | `#ff453a` |

Red means a miss and nothing else: a lit key, a wrong letter, the icon's one key. Actions use ink, not red. No beige, purple or teal.

## Type
System sans only (`-apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", Arial, sans-serif`). No serif, no mono outside code.

| Use | Size / line | Weight | Tracking |
|---|---|---|---|
| Hero | 84 / 87 (clamp from 44) | 700 | -0.028em |
| Big number (wpm) | 72 / 72 | 700 | -0.04em |
| Title | 34 / 41 | 700 | -0.02em |
| Body | 17 / 26 | 400 | 0 |
| Small | 15 / 22 | 400 | 0 |
| Footnote | 13 / 18 | 400 | 0 |

## Space and shape
- 8 point grid: 4, 8, 12, 16, 24, 32, 48, 64, 96.
- Radii: keycap 16 percent of its width, cards 28, buttons fully round, icon 22 percent.
- Keycaps have a lip: a 5 percent drop shadow in the border colour, gone when pressed.

## Components
- **Keycap**: surface face, 1 px border, lip. States: idle, down (ink face, no lip), miss (red face), worst (red ring).
- **Mode bar**: the only glass. Liquid Glass on iOS and macOS 26, regular material before, solid under Reduce Transparency.
- **Result**: the big number, accuracy beside it, the speed line, the keyboard with five keys lit.
- **Buttons**: capsules, 48 pt tall. Solid ink for the main action, outline for the rest.

## Motion
- Keys press in 40 ms and release in 90 ms. Slips flash red for 240 ms.
- Loose keycaps drift and follow the scroll at three depths; the scene eases toward the scroll position.
- The footer band: ordered dither, a sweeping beam, crawling scanlines.
- Reduce Motion: everything still, the five worst keys shown.

## Voice
Short sentences, plain words, talk to one person. Say what the test shows, not what it is not.
