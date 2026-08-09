# Guild Feed Box Sync User Guide

Guild Feed Box Sync keeps food distributed as evenly as possible between the
normal and refrigerated Feed Boxes owned by one guild. It uses the boxes and
inventory screens already provided by Palworld; it does not add a building,
recipe, technology unlock, or separate shared inventory.

## Installation

1. Subscribe to [UE4SS Experimental (Palworld)](https://steamcommunity.com/sharedfiles/filedetails/?id=3625223587).
2. Subscribe to [Guild Feed Box Sync](https://steamcommunity.com/sharedfiles/filedetails/?id=3780425019).
3. Open **Options > Mod Management** in Palworld and enable both mods.
4. Restart Palworld before loading the world.

Steam Workshop is the recommended installation method. Advanced users managing
UE4SS themselves can instead follow the
[manual installation guide](MANUAL-INSTALL.md). Do not install both the
Workshop and manual copies of Guild Feed Box Sync.

Install only one copy of UE4SS. Combining the Workshop dependency with a manual
UE4SS installation can load it twice and cause errors or crashes.

For single-player, install the mod normally on the computer running the game.
For Steam co-op, the player hosting the world should install it. Guests are
intended to see ordinary Feed Boxes without installing the mod themselves, but
an unmodded guest joining a modded host has not yet been formally tested.

Joining an unmodded host while Guild Feed Box Sync is installed on your client
has been tested: the mod remains inactive because your game does not control the
world. Windows dedicated-server support is included but remains experimental.

## What It Does

Each food item is balanced separately between eligible Feed Boxes belonging to
the same guild. For example, 1,000 baked berries across four eligible boxes will
gradually move toward 250 berries in each box. When an amount cannot be divided
evenly, some boxes will contain one extra item.

Both Feed Box types can send and receive:

- Feed Box
- Refrigerated Feed Box

Boxes at one base and boxes at different bases can participate. The mod never
intentionally moves food between different guilds. Multiple guilds on the same
server have not yet been tested, so that setup remains experimental.

## Filters and Full Boxes

The mod respects each box's **Ingredients** and **Food** filter settings.

- A box allowing only Ingredients can receive raw ingredients.
- A box allowing only Food can receive prepared meals.
- A box allowing neither category will not receive either category.
- Changing a filter takes effect during the next balancing checks.

Food already stored in a category that the box no longer accepts is left alone.
The mod also respects available inventory slots and normal stack limits. A full
or incompatible box is skipped rather than forced to accept an item.

## Timing

Balancing does not begin immediately after loading a world. The discovered Feed
Box set must remain stable for eight checks, which normally takes about 40
seconds. Building or destroying a Feed Box restarts this waiting period.

Afterward, the mod checks approximately every five seconds and submits at most
one move per check. A single move is limited to 500 items as well as the source
quantity and destination capacity. Large inventories and multiple food types
therefore take time to settle.

Pals can continue eating normally while balancing runs. Their consumption may
briefly create a new difference for the mod to correct.

## Troubleshooting

If food is not moving:

1. Confirm both Guild Feed Box Sync and UE4SS Experimental are enabled.
2. Restart Palworld after enabling or updating either mod.
3. Wait at least 40 seconds without building or destroying a Feed Box.
4. Confirm there are at least two eligible boxes owned by the same guild.
5. Check the Ingredients and Food filters on the destination box.
6. Check that the destination has a compatible slot with available capacity.
7. Remove any second manual or Workshop UE4SS installation.

For the default Workshop installation, diagnostic messages are written to:

```text
Palworld\Mods\NativeMods\UE4SS\UE4SS.log
```

Search that file for `[GuildFeedBox]`. When reporting a problem, include the
Palworld version, whether the world is single-player, co-op, or dedicated, the
steps that reproduce the issue, and the relevant GuildFeedBox log lines.

Report reproducible problems through the
[GitHub issue tracker](https://github.com/Stians92/palworld-guild-feed-box-sync/issues).
Known limitations are listed in [KNOWN-ISSUES.md](../KNOWN-ISSUES.md).

## Compatibility Status

Version 0.2.0 has been tested in single-player with normal and refrigerated Feed
Boxes, distant bases, category filters, full destinations, construction and
destruction, restarts, and active Pal consumption.

The following scenarios are not yet verified:

- An unmodded guest connected to a modded Steam co-op host
- Multiple guilds sharing one server
- Simultaneous balancing demand from multiple guilds
- Windows dedicated-server runtime
