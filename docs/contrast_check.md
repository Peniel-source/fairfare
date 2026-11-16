# Contrast check (D1)

The rubric asks for text contrast of at least **4.5 to 1** (WCAG 2.1 AA, normal text). This file records every text and background pair in the FairFare palette, the pairs that failed, and the colors that replaced them. The colors live in `app/lib/core/theme/app_colors.dart`.

Method: the ratios below were computed with the WCAG 2.1 relative luminance formula, `(L1 + 0.05) / (L2 + 0.05)`. To confirm them, enter each pair in the WebAIM Contrast Checker (https://webaim.org/resources/contrastchecker/) and save the screenshots in `docs/report/contrast/` (see section 5).

## 1. Roadmap palette as designed

| Text color | Background | Ratio | AA (4.5) |
|---|---|---|---|
| Ink `#2A2118` | Cream `#F7F1E6` | 14.05 | Pass |
| Ink `#2A2118` | Tan `#EEE1CD` | 12.25 | Pass |
| Muted `#8B7A67` | Cream `#F7F1E6` | 3.68 | **Fail** |
| Muted `#8B7A67` | Tan `#EEE1CD` | 3.21 | **Fail** |
| Orange `#D97706` | Cream `#F7F1E6` | 2.83 | **Fail** |
| Orange `#D97706` | Tan `#EEE1CD` | 2.47 | **Fail** |
| White `#FFFFFF` | Terracotta `#C1622C` (button) | 4.16 | **Fail** |
| Terracotta `#C1622C` (links, active icons) | Cream `#F7F1E6` | 3.70 | **Fail** |

Three roles failed: muted caption text, orange price text, and the terracotta button and link color.

## 2. Corrections

Each fix keeps the same hue and only lowers the lightness until the pair passes on both cream and tan, so the warm look of the mockups stays.

| Role | Was | Now | On cream | On tan | On white |
|---|---|---|---|---|---|
| Captions, secondary text (`mutedText`) | `#8B7A67` | `#6E6051` | 5.41 | 4.71 | |
| Prices, tags (`orangeText`) | `#D97706` | `#965204` | 5.33 | 4.65 | |
| Primary: buttons, links, active nav (`primary`) | `#C1622C` | `#9A4E23` | 5.36 | 4.67 | 6.02 (white label) |
| Error text (`error`) | | `#B3261E` | 5.81 | 5.07 | |

The original colors stay in the palette for things that are not text:

* `terracotta #C1622C` is the seed of the Material 3 color scheme.
* `orange #D97706` is used for decorative fills only: gradient bars, badge fills, icon circles.
* `muted #8B7A67` is used for outlines and dividers only.

## 3. Dark scheme

The mockups are light only. The dark scheme comes from the same seed, with these text colors:

| Text color | Background | Ratio | AA (4.5) |
|---|---|---|---|
| Text `#F3EADC` | Background `#1C1712` | 14.92 | Pass |
| Text `#F3EADC` | Card `#2A231C` | 12.99 | Pass |
| Muted text `#C9B9A5` | Background `#1C1712` | 9.29 | Pass |
| Muted text `#C9B9A5` | Card `#2A231C` | 8.09 | Pass |
| Primary and prices `#F2A65A` | Background `#1C1712` | 8.79 | Pass |
| Primary and prices `#F2A65A` | Card `#2A231C` | 7.66 | Pass |
| Button label `#1C1712` | Primary `#F2A65A` | 8.79 | Pass |

## 4. Tap targets

Every button, icon button, chip and segmented control has a minimum size of 48 by 48 dp, set once in `app_theme.dart` (`AppSpacing.minTapTarget`). `IconLabelRow` rows are also at least 48 dp tall.

## 5. Screenshots to add

- [ ] WebAIM result for each row of the table in section 2
- [ ] Settings screen and Wallet screen in light and dark mode
