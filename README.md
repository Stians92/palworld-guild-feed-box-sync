# Guild Feed Box Sync

[Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3780425019)
| [User guide](docs/USER-GUIDE.md)
| [Known issues](KNOWN-ISSUES.md)
| [Report a problem](https://github.com/Stians92/palworld-guild-feed-box-sync/issues)

Guild Feed Box Sync is a server-oriented Palworld UE4SS Lua mod. It redistributes
food between the existing vanilla Feed Boxes owned by the same guild. It adds no
building, recipe, or technology unlock, and both Feed Box variants retain their
normal interface and behavior. For each food item, quantities are made equal
across eligible boxes where container capacity permits; unavoidable remainders
are assigned in a stable order.

Using only existing vanilla containers also keeps the mod server-oriented. An
unmodded client joining a modded host is expected to see ordinary Feed Boxes and
their normally replicated inventories, without needing custom building assets or
UI. Joining a vanilla host with the mod installed client-side has been tested and
is inert; the reverse arrangement, an unmodded client joining a modded host,
still awaits multiplayer validation.

## Current status

Version 0.1.0 is the initial public release. Automatic transfers are enabled
after a delayed readiness gate and use only the native item operation verified
against vanilla Feed Box UI behavior. See the [user guide](docs/USER-GUIDE.md)
for installation, expected behavior, and troubleshooting.

## Requirements

- Steam Palworld revision `82182`, from the 2026-07-30 build. Later game updates
  may require a compatible mod release.
- Windows for dedicated-server use (the current official server-mod limitation)
- [UE4SS Experimental (Palworld), Workshop item `3625223587`](https://steamcommunity.com/sharedfiles/filedetails/?id=3625223587)
- Exactly one UE4SS installation

Do not combine the Workshop UE4SS installation with a manual `dwmapi.dll`; that
loads UE4SS twice and can cause collisions.

## Installation

For a Steam listen host or single-player game:

1. Subscribe to **UE4SS Experimental (Palworld)**, Workshop item `3625223587`.
2. Subscribe to Guild Feed Box Sync.
3. In Palworld, open **Options > Mod Management**, enable both mods, and restart
   the game.

Only the host is intended to need Guild Feed Box Sync. Other players should see
ordinary vanilla Feed Boxes and receive the resulting inventory changes through
normal game replication. This client behavior is the design target but has not
yet been validated with an unmodded client on a modded host.

For a Windows dedicated server, enable global mod loading and list
`UE4SSExperimentalPW` before `GuildFeedBox` in `Mods/PalModSettings.ini`. The
package contains the official Windows server installation rule, but dedicated-
server runtime remains untested and should be treated as experimental in 0.1.0.

## How synchronization works

This is periodic redistribution, not a virtual shared inventory. The host reads
the existing stacks in every loaded normal and refrigerated Feed Box, groups
boxes by their validated guild ID, and plans each food item independently.
Eligible boxes are assigned equal quantities where possible; stable ordering
decides which boxes receive unavoidable remainders.

The runtime submits at most one native move request every five seconds, capped
at 500 items and the source and destination stack limits. It then reads the
containers again before choosing another move. Large inventories or many item
types therefore equalize gradually rather than changing all at once.

Balancing begins after the discovered box set remains stable for eight scans,
normally about 40 seconds. Building or destroying a box restarts that readiness
period. The runtime respects the UI's **Ingredients** and **Food** filters.
Internally, Palworld reports disabled raw ingredients as `Food` and disabled
prepared meals as `Meal`; these are deny-list identifiers, not the UI labels.

Known operational limitations are tracked in [KNOWN-ISSUES.md](KNOWN-ISSUES.md).

## Support and contributions

Use the [issue tracker](https://github.com/Stians92/palworld-guild-feed-box-sync/issues)
for reproducible bugs and focused feature requests. See
[CONTRIBUTING.md](CONTRIBUTING.md) before submitting code or detailed test
results.

Potential cross-guild transfers, item duplication or loss, remotely triggered
crashes, and other exploitable behavior should be reported privately according
to [SECURITY.md](SECURITY.md).

## Development

`tools/deploy.ps1` assumes:

- Windows PowerShell with `robocopy` available.
- This repository has been checked out locally; the command below is run from
  its root directory.
- Steam Palworld is installed at
  `C:\Program Files (x86)\Steam\steamapps\common\Palworld`, unless
  `-PalworldPath` is supplied.
- Exactly one Palworld-compatible UE4SS distribution is installed. The script
  prefers the Workshop layout at `Mods\NativeMods\UE4SS\Mods` and otherwise
  uses the manual layout at `Pal\Binaries\Win64\ue4ss\Mods`.
- The current user can write to the selected Palworld directory. An elevated
  PowerShell session may be required for a protected Steam installation.
- Palworld will be restarted after deployment; the script does not reload a
  running Lua mod.

From the repository root, deploy to the default Steam location with:

```powershell
.\tools\deploy.ps1
```

For another Steam library or installation directory, use:

```powershell
.\tools\deploy.ps1 -PalworldPath "D:\SteamLibrary\steamapps\common\Palworld"
```

The script mirrors `mod/` into the selected UE4SS
`Mods\GuildFeedBox` directory. Mirroring removes files in that destination that
do not exist under `mod/`; do not keep manual changes or unrelated files there.
It does not modify other UE4SS mods.

After restarting Palworld, load a save containing at least two Feed Boxes and
search `UE4SS.log` for `[GuildFeedBox]`. The Workshop UE4SS log is at
`Mods\NativeMods\UE4SS\UE4SS.log`; the manual-install log is normally at
`Pal\Binaries\Win64\ue4ss\UE4SS.log`.

The release runtime does not register diagnostic keybinds. Add temporary local
instrumentation when investigating a new game build rather than shipping debug
input handlers to Workshop subscribers.

Development note: use UE4SS's built-in C++ Header Generator (`Ctrl+H`) when a
nested reflected type is needed. Do not traverse `FProperty` instances as
UObjects from Lua; this can crash UE4SS before `pcall` can recover.

Run the pure Lua regression tests with a standalone Lua interpreter:

```powershell
lua .\tests\balance_spec.lua
lua .\tests\identity_spec.lua
```

Build and validate the allowlisted Workshop folder, ZIP, and SHA-256 file with:

```powershell
.\tools\package.ps1
```

Generated release artifacts are written under `dist/` and are not committed.

The automatic executor submits at most one move per interval and reads containers
again before selecting the next move. It fails closed unless a Feed Box actor
reports server authority, and any change to the loaded box set restarts its
readiness delay. Each pass selects the largest capacity-compatible deficit so
small corrections caused by live food consumption cannot starve larger moves.

The production build respects each Feed Box's category filters. Raw ingredients
and prepared food are handled independently. Existing contents in filtered-out
boxes are left alone.

`mod/Info.json` includes both local/host and dedicated-server Lua installation
rules. Clients joining a modded server are not intended to install Guild Feed
Box; they only receive vanilla container replication. The UE4SS dependency is
required on the machine running the mod.

## Validation status

Single-player validation covers normal and refrigerated Feed Boxes, new and
existing stacks, live category-filter changes, 500-item batches, distant bases,
restart recovery, box construction and destruction, full or incompatible
destinations, Pal consumption, and an extended soak test.

The following multiplayer coverage remains outstanding for this initial
release:

- A modded Steam listen host with an unmodded client, including UI visibility,
  replication, reconnect, and persistence.
- Two or more guilds on one server, proving that inventory never crosses guild
  ownership boundaries.
- Simultaneous deficits in multiple guilds, checking fairness and throughput of
  the single global worker.
- Runtime validation on a Windows dedicated server.

## Safety model

- All UObject work executes on the game thread.
- Expensive `FindAllOf` scans never run per frame.
- Unresolved guild ownership creates an isolated one-box group, so food can
  never cross guild boundaries due to a failed lookup.
- The planner conserves every item and creates moves rather than copied stacks.
- Every mutation uses a native move operation with a fresh request GUID and is
  capped by source quantity and destination stack capacity.
- Existing destination stacks must also pass the native `IsMaxStack()` check;
  an unknown capacity is not treated as available space.
- Only one request is sent per pass; replicated container state is read again
  before another move is selected.
- Every request must produce an observed destination-slot increase on the next
  scan. A route that does not apply cools down for one minute instead of being
  retried continuously.

## License

The source code and scripts are available under the [MIT License](LICENSE).
Palworld imagery, screenshots, names, trademarks, and other third-party visual
material in this repository are not covered by that license; see
[ASSETS.md](ASSETS.md) for details.

Guild Feed Box Sync is an unofficial fan-made mod and is not affiliated with or
endorsed by Pocketpair.
