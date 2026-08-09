# Manual Installation

Steam Workshop installation is recommended for most users because Steam and
Palworld handle dependency installation and updates automatically. Use the
manual archive when managing UE4SS mods yourself or when preparing an advanced
server installation.

Guild Feed Box Sync is a UE4SS Lua mod. It does not use or require a `.pak`
file.

## Requirements

- A compatible Palworld installation on Windows
- Exactly one Palworld-compatible UE4SS installation
- The `GuildFeedBox-<Version>-manual.zip` archive from the matching
  [GitHub Release](https://github.com/Stians92/palworld-guild-feed-box-sync/releases)

Do not install both Workshop UE4SS and a separate manual UE4SS distribution.
Loading UE4SS twice can cause collisions or crashes.

## Install

1. Close Palworld and any dedicated-server process.
2. Locate the active UE4SS `Mods` directory.
3. Extract the archive into that directory, keeping its outer `GuildFeedBox`
   folder.
4. Confirm the resulting path ends with
   `Mods\GuildFeedBox\Scripts\main.lua`.
5. Start Palworld, load the world, and wait about 40 seconds for balancing to
   become ready.

The default UE4SS `Mods` locations are:

Workshop UE4SS:

```text
C:\Program Files (x86)\Steam\steamapps\common\Palworld\Mods\NativeMods\UE4SS\Mods
```

Manual UE4SS:

```text
C:\Program Files (x86)\Steam\steamapps\common\Palworld\Pal\Binaries\Win64\ue4ss\Mods
```

For a non-default Steam library, start from that library's Palworld directory
and use the same relative path. The archive already contains `enabled.txt`; do
not rename the `GuildFeedBox` directory.

## Verify

The installed structure should be:

```text
Mods\
  GuildFeedBox\
    enabled.txt
    INSTALL.md
    Scripts\
      balance.lua
      config.lua
      gamedefs.lua
      identity.lua
      main.lua
```

Diagnostic messages are written to `UE4SS.log`. Search the log for
`[GuildFeedBox]`. A normal startup discovers Feed Boxes, waits for eight stable
checks, and then reports balancing activity or that the balance is complete.

## Update

Close Palworld, remove the existing `GuildFeedBox` directory, and extract the
new manual archive into the same UE4SS `Mods` directory. Do not merge files from
different versions.

Manual installations are not updated by Steam. Check the
[GitHub Releases](https://github.com/Stians92/palworld-guild-feed-box-sync/releases)
page after Palworld updates.

## Uninstall

Close Palworld and delete only the `GuildFeedBox` directory from the active
UE4SS `Mods` directory. The mod does not add custom buildings or save-game
assets, so no in-game cleanup is required.
