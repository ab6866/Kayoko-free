# Kayoko 4.3.4+free10

Feature-rich clipboard manager for iOS — **free build**.

Based on the archived GPLv3 Kayoko project by Alexandra Aurora Göttlicher, via the
maintained `com.82flex.kayoko` fork.

## What this build changes

### 1. Removed the "Purchase Kayoko" promo block

The preferences pane no longer shows the Havoc Marketplace purchase card or its
support footer at the bottom of the root list.

- `Preferences/Resources/Root.plist` — dropped the promo `PSGroupCell` footer and the
  `KayokoLinkCell` entry.
- `Preferences/Resources/{en,zh-Hans}.lproj/Root.strings` — removed the matching strings.

### 2. New switch: **Show Time**

Placed in the **History** group, directly below **Save Images**.

When enabled, the capture **date and time** (`MM-dd` / `HH:mm`) is drawn underneath
the app icon as two stacked lines. The relative time is then dropped from the detail
line so it is not shown twice.

Default: **off** — existing behaviour is unchanged until you turn it on.

Data flow:

| Layer | File | Change |
|---|---|---|
| Key | `Preferences/KayokoPreferenceKeys.h` | `ShowIconAndTime` + default `NO` |
| UI | `Preferences/Resources/Root.plist` | `PSSwitchCell` after Save Images |
| Runtime | `Tweak/Core/KayokoCoreRuntime.m` | default registration, read, push to view |
| Panel | `Tweak/Core/Controllers/KayokoMainViewController.{h,m}` | property + setter forwarding |
| List | `Tweak/Core/Controllers/KayokoHistoryListViewController.{h,m}` | forwarding |
| Table | `Tweak/Core/Views/KayokoHistoryListView.{h,m}` | property, reload, extra row height |
| Content | `Tweak/Core/Models/KayokoTableViewCellContentProvider.{h,m}` | build the date / time strings |
| Cell | `Tweak/Core/Views/KayokoTableViewCell.{h,m}` | two timestamp labels under the icon, reuse id |
| L10n | `Preferences/Resources/{en,zh-Hans}.lproj/Root.strings` | `Show Time` / `显示时间` |

### 5. Fixed: only the date showed, and the cell was not vertically centred

Reported after the first cut of **Show Time**: the icon column showed `09-19` but
not `19:26`, the text sat too high in the row, and the layout did not adapt when
the switch was toggled.

**a) The time line could disappear.** The date and time were emitted as a single
string with an embedded newline (`MM-dd\nHH:mm`) rendered by one label with
`numberOfLines = 0`. A wrapped label sizes its intrinsic width to the *widest*
line, and inside a row with a fixed height the second line could be laid out
outside the visible bounds and dropped. There are now two labels —
`timestampDateLabel` and `timestampTimeLabel` — stacked by constraints, each
sizing to its own content, so one line can no longer swallow the other.

**b) The two columns were not centred against each other.** The icon was pinned to
the cell's centre, but the timestamp hangs *below* the icon. With the timestamp
visible the left column is therefore taller than the icon alone, so pinning the
icon to the centre pushed the whole column upward relative to the text block —
which is why the text looked top-heavy. Turning the timestamp off then reset the
icon through a different branch, so the two states disagreed.

Both columns are now laid out as blocks and centred independently:

- left column = icon + optional timestamp, centred as a unit;
- right column = title / preview / item details, centred as a unit.

The icon's own centre pin was removed and replaced by a conditional layout guide,
so the row adapts to every combination of the switch, the preview line count and
the item-details mode.

**c) The row height is now derived, not guessed.** The extra height added for the
timestamp is computed from the real font metrics
(`icon + gap + 2 × lineHeight + insets`) instead of a hand-tuned constant, and only
the shortfall against the base row height is added. A future font or Dynamic Type
change can no longer silently clip the time again.

### 3. Fixed: dpkg could not run the post-install script

Installing produced:

```
dpkg: unable to execute installed com.82flex.kayoko package post-installation script
(/Library/dpkg/info/com.82flex.kayoko.postinst): No such file or directory
```

Two causes, both fixed:

1. `layout/DEBIAN/postinst` and `postrm` were checked in with **CRLF** line endings.
   The shebang therefore installed as `#!/bin/sh\r`, and dpkg looked for an
   interpreter named `/bin/sh\r` that does not exist.
2. The shebang was `#!/bin/bash`, which is not guaranteed to exist inside every
   jailbreak root. Both scripts now use `#!/bin/sh` and `postinst` probes a few
   candidate updater paths before running it.

`.gitattributes` now also pins `layout/DEBIAN/*` to `eol=lf` so this cannot regress.

### 3. Authorization remnants cleaned up

The 4.3.2 base already disabled purchase verification; this build removes the
leftover dead code and user-visible strings.

- `Preferences/Controllers/KayokoRootListController.m` — deleted the authorization
  overlay and the Havoc credential-sync machinery.
- `Preferences/Controllers/KayokoAdvancedOptionsListController.m` and
  `AdvancedOptions.plist` — removed the **Deactivate** entry and its handlers.
- `Updater/main.m` — removed the `sync-credential` command and credential mirroring.
- `Shared/Purchases/` — module deleted; `Makefile` references removed.
- `Tweak/Core/KayokoCoreRuntime.m`, `Tweak/Core/Controllers/KayokoMainViewController.m`
  — the panel no longer consults an authorization gate.
- Localization files — dropped the "Purchase Kayoko", "Check Product Authorization",
  "Authorization Not Found", Sileo/Zebra instruction and network-failure strings.

### 4. Build fix: CRLF line endings

The tracked `devkit/*.sh` scripts, `Makefile`s, `control`, plists, `.strings` and
the CI workflow were stored with Windows CRLF line endings. On macOS/Linux bash
sources `devkit/*.sh`, and the trailing `\r` is then parsed as a command name:

```
devkit/env.sh: line 2:
: command not found
```

which aborts every variant with exit code `127`. All text build inputs are now
normalized to LF, and a `.gitattributes` (`* text=auto eol=lf`) prevents
regression on future checkouts.

## Preview

<img src="Preview.png" alt="Preview" />

## Installation

1. Download the `deb` matching your jailbreak from the
   [releases](https://github.com/ab6866/Kayoko-free/releases).
2. Install it with your preferred package manager.

| Jailbreak | File |
|---|---|
| legacy (unc0ver, checkra1n, …) | `..._iphoneos-arm.deb` |
| rootless (Dopamine, palera1n) | `..._iphoneos-arm64.deb` |
| roothide Bootstrap | `..._iphoneos-arm64e.deb` |

Only install one variant. The package id `com.82flex.kayoko` is unchanged, so
uninstall the original Kayoko first — or simply install over it.

This package conflicts with and replaces the original `codes.aurora.kayoko` package.
During the v4 history upgrade, clipboard history from both the original
`codes.aurora.kayoko` data directory and the maintained `com.82flex.kayoko` data
directory is imported into the new store.

### Dependencies

`firmware (>= 14.0)`, `mobilesubstrate`, `preferenceloader`, `com.opa334.altlist`
(AltList repo: <https://opa334.github.io/>).

## Building

Three jailbreak variants are cross-built by GitHub Actions
(`.github/workflows/build.yml`, matrix: `legacy` / `rootless` / `roothide`).

```sh
gh workflow run "Build Package"
```

Or locally with a Theos checkout:

```sh
source devkit/rootless.sh     # or devkit/roothide.sh, devkit/env.sh
make package
```

Artifacts land in `packages/`.

| Variant | Env script | Package scheme |
|---|---|---|
| legacy | `devkit/env.sh` | *(none)* |
| rootless | `devkit/rootless.sh` | `rootless` |
| roothide | `devkit/roothide.sh` | `roothide` |

## Source Code

The archived upstream project is available at
<https://github.com/AlexandraAurora/Kayoko>.

## License

Kayoko is distributed under [GPLv3](COPYING). Paid distribution does not remove
recipients' GPLv3 rights to copy, modify, and redistribute the software.

This fork is not affiliated with or endorsed by the original author.
