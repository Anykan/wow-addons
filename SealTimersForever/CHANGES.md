# Changes compared to upstream

This folder is a **personal fork/backup** of [Seal Timers Forever](https://github.com/Pirson-s-Addons/SealTimersForever)
by **Pirson** (MIT License, see `LICENSE`) for World of Warcraft: Forever.

- **Upstream base:** tag `v1.00`, commit `ea5e7692f5492d59ddcaff30a7d68a7584c17b4d`
- **Modified on:** 2026-09-20 (files backed up on 2026-09-26)
- **Install path:** `World of Warcraft/_classic_beta_/Interface/AddOns/SealTimersForever/`
- **Exact diff:** [`upstream-v1.00-to-local.patch`](upstream-v1.00-to-local.patch)
  (`git apply` it on a clean upstream v1.00 to reproduce this version)

Only two files differ from upstream v1.00: `SealTimersForever.lua` (+195 / -13 lines) and `Locales.lua` (+12 lines).
`LICENSE`, `README.md` and `SealTimersForever_Camelot.toc` are unchanged (the README therefore does **not**
describe the additions below; this file does).

## Added: timer bar

A horizontal `StatusBar` with remaining-time text, shown under the seal icon.

- Fills/empties in sync with the circular cooldown swipe. It reads start/duration from the icon's own
  `Cooldown` via `GetCooldownTimes()` (`SyncBar`), so there is one source of truth.
- Text shows whole seconds, one decimal below 5 s.
- **Only shown when the cooldown times are readable.** In WoW Forever aura data is "secret" in combat;
  if `IsSecret()` / `Readable()` fail the bar stays hidden and only the circular swipe works.
- A single `OnUpdate` (`UpdateBars`, hooked on the icon anchor) drives all bars.
- The bar has its **own anchor frame** (`SealTimersForeverBarAnchor`), so it can be dragged anywhere,
  independent of the icon block. Position is saved separately.
- Bar background is a black 60 % texture; bar color defaults to the addon's purple (`0.84, 0.59, 1`).

## Added: new settings

Saved in `SealTimersForeverDB` (new defaults in `DEFAULTS`):

| Key | Default | Meaning |
|-----|---------|---------|
| `barWidth` | icon size | Bar width in px (slider 20-400, step 10) |
| `barPoint`, `barX`, `barY` | `CENTER`, `0`, `-176` | Bar position (default = 2 px below the icon at the default icon position) |
| `barColorR/G/B` | `0.84 / 0.59 / 1` | Bar color (stored as three numbers, not a table, so profiles never share the `DEFAULTS` table) |
| `showIcon` | `true` | Show the seal icon + circular swipe |
| `showBar` | `true` | Show the timer bar |

In the **Options -> AddOns** panel: checkboxes "Show icon" and "Show bar", slider "Bar width".

## Added: `/stf color`

Opens Blizzard's color picker for the bar color. Supports both the new API
(`ColorPickerFrame:SetupColorPickerAndShow`) and the old one (`func` / `cancelFunc` / `SetColorRGB`);
cancel restores the previous color.

## Changed: unlock / scale behaviour

- Unlocking (`Lock position` off) now also shows a purple drag handle with label on the bar anchor.
- `ApplyScale` also scales the bar anchor.
- Added `ApplyBarWidth`, `ApplyBarColor`, `ApplyVisibility`; they also update the icon **pool**
  (icons are reused, so pooled icons must not keep stale width/color/visibility).
- `HideSeal` hides the bar and clears `barStart` / `barDuration`.

## Changed: `StartTimer` refactor

The early `return`s were replaced by an `if / elseif / else` chain so that `SyncBar(icon)` runs at the end
in every path (previously it would have been skipped by the early returns). Behaviour of the timer itself is unchanged.

## Changed: initialisation order

On login `CreateBarAnchor()` is called, and `ApplyLock`, `ApplyScale`, `ApplyBarWidth`, `ApplyBarColor`,
`ApplyVisibility` now run after both anchors exist (previously `ApplyLock`/`ApplyScale` ended `CreateAnchor`).

## Locales

`Locales.lua` gained six keys in English and Spanish (no other languages, upstream has more):
`BAR_WIDTH`, `BAR_WIDTH_TOOLTIP`, `SHOW_ICON`, `SHOW_ICON_TOOLTIP`, `SHOW_BAR`, `SHOW_BAR_TOOLTIP`.

## Not included (upstream v1.01 and later)

Upstream moved on after v1.00 (v1.01: swing timer with seal-twist zone laid out like Kaedin's WeakAura,
twisting on/off switch, own options panel with About page, 20 languages, split into `Core/`, `UI/`, `Locales/`).
None of that is in this fork. Updating to upstream v1.01 would overwrite the timer bar; re-apply the patch
(or port it) afterwards.

## Code comments

The added code comments are in Spanish, matching the style of the upstream source.
