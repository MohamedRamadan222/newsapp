# NewsApp Static Design → Flutter Map

Pure **HTML + CSS, no JS**. Open `design/index.html` in a browser.
Phone frame = `max-width: 430px`, mimics `Scaffold`.

## Pages
- `index.html` — Home (hero + trending + latest)
- `search.html` — Search + trending tags + recent + results
- `article.html` — Details (hero, author, body, related)
- `bookmarks.html` — Saved list
- `categories.html` — Topics grid

## System (fixed in this revision)
- **Colors: neutral zinc only.** `bg #131315`, `surface #1B1C1F`,
  `card #222326`, `border #343639`, `text #F4F4F5`, `muted #A1A1AA`.
  Primary action = white (`#FAFAFA` bg + `#131315` text). No blue /
  orange / gradients. Badge, chips-active, buttons all share it.
- **Type: one scale.** `.t-hero 20/bold`, `.t-title 15/semi (2-line clamp)`,
  `.t-body 14/relaxed`, `.t-meta 12/medium`, `.t-section 17/bold`.
  No inline `style="font:..."`.
- **Icons: one SVG set, one size system.** `--icon-sm 16`, `--icon-md 20`,
  `--icon-lg 22`, box `--icon-btn-box 42`. All icons are inline SVG
  with `stroke="currentColor"`, maps to Flutter `Icons.*`.
- **Badges: one style.** `.badge` = 24px pill, white bg, uppercase 11px.
- **Buttons: one system.** `.btn` + `.btn--secondary` (both 48px, pill,
  14px bold), `.searchbar__btn` (small 38px variant), `.follow-btn`
  (36px neutral). Same radius, same font.

## Tokens → Flutter
| CSS | Flutter |
|---|---|
| `--color-bg / --color-surface / --color-card` | `ColorScheme.surface / surfaceContainer` |
| `--color-primary (#FAFAFA)` | `ColorScheme.primary` (neutral) |
| `.t-hero / .t-title / .t-body / .t-meta` | `TextTheme.headlineSmall / titleMedium / bodyMedium / labelMedium` |
| `--icon-sm/md/lg` | `IconTheme(size: 16/20/22)` |
| `--space-* (8pt)` | `SizedBox / Padding` |
| `.appbar` | `AppBar` |
| `.chip-row .chip` | `TabBar` / `ChoiceChip` (36px) |
| `.hero-card / .trend-card / .news-card` | `Card + InkWell` → `DetailScreen` |
| `.h-scroll` | `ListView(horizontal)` |
| `.news-list` | `ListView.builder` |
| `.cat-grid` | `GridView.count(crossAxisCount: 2)` |
| `.bottom-nav` | `NavigationBar` (4 destinations) |
| `.btn / .btn--secondary` | `FilledButton / OutlinedButton` |

## Static data
Hardcoded text + `picsum.photos/seed/*` images. Replace with
`Image.network(article.imageUrl)` later.
