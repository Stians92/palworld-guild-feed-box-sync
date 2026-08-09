# Contributing

Bug reports, focused fixes, compatibility findings, and documentation
improvements are welcome.

## Reporting Problems

Search the existing issues before opening a new one. Use the bug-report form and
include:

- The Palworld and Guild Feed Box Sync versions
- Whether the world is single-player, Steam co-op, or dedicated
- Whether the mod is installed through Workshop or deployed for development
- Clear reproduction steps
- Relevant lines containing `[GuildFeedBox]` from `UE4SS.log`

Do not upload an entire log or save file unless a maintainer asks for it. Remove
personal paths, server addresses, player identifiers, and unrelated mod data.

Potential cross-guild transfers, item duplication or loss, remotely triggered
crashes, and other exploitable behavior must be reported privately according to
[SECURITY.md](SECURITY.md), not through a public issue.

## Development

Development setup, deployment assumptions, tests, and packaging commands are
documented in [README.md](README.md#development).

Keep changes narrowly scoped and consistent with the existing Lua runtime. Pull
requests should:

- Explain the behavior being changed and why
- Include focused tests where the logic can be tested outside the game
- Describe in-game validation for runtime changes
- Update user or developer documentation when behavior changes
- Avoid committing logs, dumps, saves, generated `dist/` packages, or local
  `.workshop.json` files

Run the available regression tests and package validation before submitting:

```powershell
lua .\tests\balance_spec.lua
lua .\tests\identity_spec.lua
.\tools\package.ps1
```

If a Lua interpreter is unavailable, state that clearly in the pull request.

By contributing, you agree that your contribution is licensed under the
repository's [MIT License](LICENSE).
