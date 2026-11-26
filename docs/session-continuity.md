# Shared session continuity

Per Hour has one session per character. Start, Pause, Resume and Finish control
all metrics and the same measured period. Travel and waiting while running count;
pauses, offline time, loading and verification do not.

## Reload, logout and interruption

- A UI reload restores the prior running/paused state only after continuity checks.
- A normal logout/login returns the current session paused, without archiving it.
  Resume continues it; Finish and Reset archives it.
- Disconnects or abrupt exits restore the checkpoint available from the last
  client save. Uncertain continuity remains paused for review with partial flags.
- A session already paused stays paused.
- Finish is allowed during verification: it archives preserved data as partial
  without waiting for a reply. A late reply cannot revive that session.
- A late played-time response updates future reference availability but never
  silently resumes a session whose verification already timed out.

The first PLAYER_ENTERING_WORLD flags distinguish a reload from a normal login.
Session.lua requests total time played and compares its login-adjusted reference
with the saved value, accepting a difference of up to 30 seconds in either direction.
Verification times out after 10 seconds. Totals and the clock stay suspended
while a current session awaits verification.

Before resuming, XP and reputation establish fresh progress baselines; Gold
refreshes inventory/money baselines and pending accepted entries. Paused/offline
progress is not added retrospectively. Watched-faction changes create reputation
segments without resetting other metrics.

## Limits and recovery

SavedVariables reach disk when the client saves them, such as normal logout or
reload. The addon cannot force a disk write or recover gains lost in a crash.
The played-time check is approximate: gaps within its tolerance can be missed.
Resume accepts the preserved totals and retains the partial warning.

A failed metric read does not stop the others. Invalid saved data is preserved
for recovery; an unreadable module context is isolated instead of pretending its
data is complete. A new-format save is restored normally on later logins.

## Validation in Forever

1. Start, earn XP/Gold, reload: verify the same session resumes after verification.
2. Pause and reload: it remains paused and retains its totals.
3. Log out normally while running: login shows Resume, with the same totals.
4. Wait outside the game and before Resume: neither interval increases duration.
5. Change faction while paused or during loading: prior faction results remain.
6. Test delayed price data during verification, pause and world entry.
7. After a checkpoint, play for more than 30 seconds and force-close only if you
   want to exercise crash recovery. Verify preserved totals and partial/review state.
8. Confirm a late reply never resumes a timed-out or finalized session.

The Lua 5.1 suite simulates these transitions. Native saving and event order
still require the in-game checks above.
