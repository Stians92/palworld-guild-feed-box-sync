# Steam Workshop release notes

## Suggested listing

**Title:** Guild Feed Box Sync

**Short description:** Keeps food evenly distributed across your guild's
existing Feed Boxes. No new building, recipe, or technology unlock required.

**Description:**

Guild Feed Box Sync keeps the food at your guild's bases evenly distributed.
Instead of adding a special shared container, it works with the normal Feed
Boxes you already use.

If your guild has 1,000 baked berries across four eligible Feed Boxes, the mod
will gradually move them toward 250 berries in each box. Every food item is
balanced separately. When an amount cannot be divided evenly, some boxes will
simply contain one extra item.

FEATURES

- Works with both normal and refrigerated Feed Boxes.
- Syncs food between boxes at the same base and at different bases owned by the
  same guild.
- Respects each box's Ingredients and Food filter settings.
- Respects full boxes, available slots, and normal stack limits.
- Uses the existing Feed Box inventory and interface.
- Adds no building, recipe, technology unlock, or separate shared inventory.

Food is moved in steps rather than all at once. The mod checks every five
seconds and moves up to 500 items at a time, so a large collection can take a
little while to settle. Syncing normally begins about 40 seconds after loading a
world. Building or destroying a Feed Box starts that short waiting period again.

INSTALLATION

1. Subscribe to UE4SS Experimental (Palworld), Workshop item 3625223587.
2. Subscribe to Guild Feed Box Sync.
3. Enable both under Options > Mod Management, then restart Palworld.

For co-op, install Guild Feed Box Sync on the player hosting the world. Other
players are intended to join without installing it and should continue to see
ordinary Feed Boxes. This has not yet been confirmed with an unmodded guest, so
multiplayer support should be considered experimental in version 0.1.0.

Windows dedicated-server files are included, but dedicated-server use and
servers containing multiple guilds have not yet been tested.

TESTED IN SINGLE-PLAYER

- Normal and refrigerated Feed Boxes
- Distant bases
- Ingredient-only and prepared-food-only filters
- Full boxes and unavailable slots
- Building and destroying boxes
- Restarting with an existing imbalance
- Pals eating while food is being balanced

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

**Initial change note:** Initial 0.1.0 release: guild-scoped balancing
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
