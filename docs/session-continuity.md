# Session continuity

Per Hour saves each module's total, active duration, pause state and context. It
validates all restored sessions against one character-wide reference: total time
played, obtained through `RequestTimePlayed()` and `TIME_PLAYED_MSG`.

The reference is extrapolated from the latest server reply to the instant the
sessions are saved. On the next login or UI reload, time elapsed since the addon
started loading is subtracted from the new reply. Differences of up to **30
seconds**, in either direction, are accepted. This is an approximate check;
server timing and time before the addon starts loading can affect it.

## Restoring a session

- A matching reference restores the previous running or paused state.
- A mismatch pauses restored sessions and preserves their saved totals.
- A missing or failed query reports that verification is unavailable. A query
  without a valid reply times out after 10 seconds. A late reply does not silently
  resume sessions already marked for review.
- A successful time check still waits for readable module data to establish new
  gain counters. Reputation retains its faction identity and resets on a change.
- Resume accepts the saved totals; Reset clears and stops the session. Each module
  retains its own unresolved warning until the player makes that choice.

The top-left indicator is yellow while verification is pending, green after a
successful check, and red when the session needs review. Hover for details.
It appears immediately at full opacity, without fading. The success indicator
hides after 5 seconds. Unresolved errors stay visible until Resume or Reset;
after that decision, the error indicator hides after 0.5 seconds without fading.
Each dismissal uses one delayed callback, with no per-frame work during the wait.
Timers also expire while the panel is hidden, and an older timer cannot dismiss
a newer status. Pending and unresolved-error indicators have no dismissal timer.

## Limits

The check can detect unsaved playing time even without XP, honor or reputation
gains. Interruptions within the tolerance may go unnoticed. It cannot recover
lost gains or distinguish unrecorded manual tracker pauses, so it does not add
missing time to the run or adjust its hourly rate automatically.

Disk persistence still depends on the client saving addon data during normal
exit or a UI reload. Existing version 1 sessions retain their results but lack a
played-time reference and require Resume or Reset once. New saves use version 2;
modules no longer save individual progress checkpoints.

## Validation

Run `lua tests/forever.lua` with Lua 5.1 for simulated coverage. Actual Forever
validation remains pending:

1. Start a session, earn progress, then return through character selection. Check
   that results and duration continue, excluding time spent away.
2. Pause a module and repeat. It should remain paused.
3. Exit normally, reopen the client and check the restored state.
4. After a saved checkpoint, play for more than 30 seconds without earning any
   progress, then force-close the client. On return, the old session should need
   review if the server retained that additional played time.
5. Check that indicators appear immediately, success disappears after 5 seconds,
   and unresolved errors remain visible. After Resume or Reset, the error icon
   should disappear after 0.5 seconds without fading. Hiding and reopening a panel
   must not restart an expired confirmation or let an older timer hide a new warning.
