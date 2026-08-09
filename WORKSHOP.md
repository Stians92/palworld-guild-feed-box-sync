# Steam Workshop release notes

## Suggested listing

**Title:** Guild Feed Box Sync

**Short description:** Automatically balances food across your guild's existing
vanilla Feed Boxes. No custom building or technology unlock. Designed for host-
side use with vanilla clients; multiplayer validation pending.

**Description:**

Guild Feed Box Sync periodically moves existing food stacks between your guild's
vanilla Feed Boxes. For each item, it aims to give every eligible box the same
quantity while respecting filters, slot capacity, and unavoidable remainders.
It does not create a shared inventory or add a building, recipe, or technology
unlock. Players keep using the normal Feed Box interface and inventory behavior.

The host submits at most one native move every five seconds. Each move is capped
at 500 items and the source and destination stack limits, then all containers
are read again before another move is selected. Large or varied inventories
therefore equalize gradually. Synchronization starts after the Feed Box set
remains stable for eight scans, normally about 40 seconds; building or destroying
a box restarts that readiness period.

Because the mod operates on existing server-authoritative vanilla containers,
other players are intended to join without installing it. They should see normal
Feed Boxes while their contents update through the game's ordinary replication.
This avoids the client-side assets and classes a custom shared building would
typically require. Unmodded-client compatibility with a modded host is currently
an architectural expectation and remains listed as an outstanding multiplayer
test, not a verified claim.

Both normal and refrigerated Feed Boxes are supported. Their ingredient and
prepared-food filters are respected.

**Installation**

1. Subscribe to **UE4SS Experimental (Palworld)**, Workshop item `3625223587`.
2. Subscribe to **Guild Feed Box Sync**.
3. Enable both under **Options > Mod Management**, then restart Palworld.

Install Guild Feed Box Sync on the host. Vanilla-client compatibility is
intended but has not yet been tested with an unmodded client on a modded host.
The package includes a Windows dedicated-server installation rule, but dedicated-
server runtime is untested and should be treated as experimental in 0.1.0.

This is an initial release candidate. Single-player behavior has been exercised
extensively, including restart, distant bases, changing filters, full boxes,
building and destroying boxes, refrigerated storage, Pal consumption, and a
long-running soak test. Listen-host client replication, multi-guild isolation,
multi-guild load, and Windows dedicated-server runtime still require multiplayer
validation.

## Uploader handoff

1. Run `.\tools\package.ps1` and confirm it completes successfully.
2. Install and start the official Pocketpair Palworld Mod Uploader while Steam
   is running and logged into an account that owns Palworld.
3. Set its Workshop content directory to
   `steamapps/workshop/content/1623730`.
4. Choose **Create New Mod**, select **Lua**, and allow the uploader to create a
   numeric Workshop item directory and its `.workshop.json` file.
5. Copy the contents of `dist/GuildFeedBox-<Version>/` into that numeric
   directory. Preserve the uploader-created `.workshop.json` file.
6. In Palworld, enable the dependency and local Guild Feed Box Sync item under
   **Options > Mod Management**, restart, and perform a final smoke test.
7. Choose **Upload To Steam**, enter the change note below, then initially set
   the item visibility to **Hidden**.
8. On the Workshop page, set UE4SS item `3625223587` as a required item and
   verify the `UE4SS`, `Gameplay`, and `Utilities` tags.
9. Add screenshots showing ordinary Feed Boxes, normal inventory interaction,
   and ingredient/prepared-food filter behavior.
10. Subscribe to the hidden item, remove or disable the local development copy,
    and smoke-test the actual subscribed installation before making it public.

**Initial change note:** Initial 0.1.0 release candidate: guild-scoped balancing
for normal and refrigerated Feed Boxes, filter-aware placement, 500-item transfer
batches, and conservative authority and capacity checks.

Every future upload must change the `Version` string in `mod/Info.json` before
building the package.

Official references:

- [Palworld server mod setup](https://docs.palworldgame.com/settings-and-operation/mod/)
- [Palworld Mod Uploader package format](https://github.com/pocketpairjp/PalworldModUploader/blob/main/PalworldModUploader/docs/en/02-Package.md)
- [Palworld Mod Uploader workflow](https://github.com/pocketpairjp/PalworldModUploader/blob/main/PalworldModUploader/docs/en/03-ModUploader.md)

## Test status

Verified in single-player:

- Normal and refrigerated boxes can both send and receive.
- New stacks and existing stacks balance without duplicating items.
- Large deficits move in batches of 500.
- Ingredient and prepared-food filters are respected and update live.
- Full and incompatible destinations are skipped.
- Distant bases balance while unloaded from the player's immediate area.
- Restart recovery, construction, destruction, Pal consumption, and extended
  runtime completed without observed transfer errors.

Not yet verified:

- Unmodded client connected to a modded Steam listen host.
- Multiple guilds sharing one server.
- Fairness under simultaneous demand from multiple guilds.
- Windows dedicated-server runtime.
