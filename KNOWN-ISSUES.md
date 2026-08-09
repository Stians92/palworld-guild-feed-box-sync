# Known issues

These limitations are recorded for follow-up after the initial 0.1.0 release.
They are not known to duplicate or lose items.

## Cross-guild scheduling fairness

The single global worker currently selects the largest compatible transfer from
all loaded guilds. A guild that continuously produces large deficits can delay a
smaller deficit in another guild indefinitely. Multi-guild scheduling has not
yet been tested. A future version should schedule guilds using round-robin or
aging while retaining largest-first selection within each guild.

## Verification after Pal consumption

A submitted move is verified by observing an increase in its destination slot
on the next scan. A Pal can consume the transferred food before that scan,
making a successful move appear unverified. The route then pauses for one minute
before retrying. A future version should also use a matching source decrease as
evidence that the move applied.

## Global readiness gate

Automatic balancing starts only after every discovered Feed Box has a stable,
valid runtime view. One permanently unresolved box can therefore keep balancing
paused for all guilds. A future version should track readiness per guild or omit
an unstable box until it becomes valid.
