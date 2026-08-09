# Release checklist

## Complete for 0.1.0

- Discover normal and refrigerated Feed Boxes and group them by guild.
- Use the verified native container move operation on the authoritative game.
- Balance new and existing stacks while respecting capacity and category filters.
- Re-read replicated state after every request and cool down failed routes.
- Cap each request at 500 items and delay startup until the world is ready.
- Validate restart recovery, distant bases, box destruction, live consumption,
  incompatible destinations, dynamic filters, and refrigerated boxes in
  single-player.
- Produce a minimal Workshop payload with validation and deterministic contents.

## Outstanding multiplayer validation

- Modded Steam listen host with an unmodded client: replication, normal Feed Box
  UI, reconnect, and persistence.
- Multiple guilds on one server: strict ownership isolation.
- Concurrent deficits in multiple guilds: worker fairness and throughput.
- Windows dedicated server: installation, startup, transfers, restart, and
  unmodded client behavior.

## Deferred reliability work

- Add fair scheduling or aging across guilds.
- Verify successful transfers using both source and destination observations so
  immediate Pal consumption does not cause a false cooldown.
- Replace the global readiness gate with per-guild readiness or stable-box
  exclusion.

See `KNOWN-ISSUES.md` for impact and intended remediation.

These are release-candidate test gaps, not claims of completed coverage. The
runtime fails closed when authority or guild ownership cannot be established.
