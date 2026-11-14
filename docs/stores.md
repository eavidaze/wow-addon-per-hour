# Persistent stores

Only `src/stores/SettingsStore.lua` and `src/stores/SessionStore.lua` access
SavedVariables directly. Both retain the existing names and layout declared in
`per-hour.toc`: account preferences in `PerHourAccount_Settings`, character
sessions in `PerHourCharacter_Values`.

`core/Bootstrap.lua` handles the addon's `ADDON_LOADED` once. It initializes both
stores, binds module access, creates tracking panels and initializes the module
menu and minimap position. Creating panels resets runtime state while preserving
saved sessions. Panel positions and sessions restore on the first
`PLAYER_ENTERING_WORLD`. Until then, showing panels does not adjust or save their
positions using temporary loading-screen dimensions. All saved anchors are
applied before collision resolution begins.

## Module runtime

Each module keeps its identity (`Name`, `TagName`, `ShortName`), registered events
and custom hooks at the root. Bootstrap creates separate `State` and `View`
tables for each module before building panels:

| Member | Responsibility |
| --- | --- |
| `module.State` | Runtime totals, duration, rates, running/paused flags, restore status and module-specific progression baselines or faction context. |
| `module.View` | Panel, rate text, buttons, indicators and the independent hidden tracker frame. |
| `module.Settings` | Scoped access to the module's account preferences. |
| `module.Store` | Scoped access to the module's saved character session. |

Tracking and session code read and update `State`; rendering reads it and updates
controls in `View`. The tracker frame stays independent of panel visibility, so
hiding a panel does not stop progress. No frames or controls belong in `State`.

`BaseModule:ResetModule` updates the existing state table and calls the module's
custom reset for its progression baselines. It preserves the view and both table
identities, so callbacks keep valid references. A user reset clears that module's
saved session; the initial panel reset preserves sessions awaiting restoration.

Session saving explicitly selects totals, duration, pause/review flags and custom
context from runtime state. Neither container is persisted directly, and the
existing version 2 save layout is unchanged. Runtime values and controls are
accessed through their respective containers; there are no root-level aliases.

## Settings

`PerHour.Stores.Settings` provides `GetMinimapAngle()` and
`SetMinimapAngle(angle)`. Each module receives its own `module.Settings` handle
with `Get(key)` and `Set(key, value)` for `isShown`, `position` and `rate`. Positions are
plain tables with `point`, `relativePoint`, `x` and `y`; setting a position to
`nil` removes it. The display rate is `hour` (default) or `minute`, independently
for Experience, Honor and Reputation. Invalid saved rates recover the default.

Initialization preserves valid values, including `false` and zero, and repairs
malformed data using defaults. Invalid positions are discarded so panels use
their default layout. Setters reject invalid values. Position reads and writes
copy tables, so callers cannot mutate stored positions indirectly.

Forms keep their generic `value` and `onChanged` interface. The settings panel
connects module visibility and display rates to the stores and applies each
change immediately. It refreshes silently when opened and when visibility changes
elsewhere. Rate selection changes the panel's numeric value and unit without
altering session totals, duration, running state or the calculated rates. The
minimap remains draggable and its position is saved, with no angle form control.

## Sessions

Each module receives `module.Store:ReadSession()` and `ClearSession()`.
`ReadSession()` returns a detached snapshot, or `nil, true` for malformed data
so the session coordinator can report an error. The common store validates
totals, duration and flags; the module validates its own context, such as a
reputation faction. A module's handle only accesses that module's saved entry.

`PerHour.Session` captures progress and owns continuity checks, pause/resume and
restoration. It calls `PerHour.Stores.Sessions:SaveAll(snapshots, playedAtSave)`
to commit all module snapshots with one shared played-time reference. Module
handles have no independent save operation. Saving copies snapshots and context;
clearing a session preserves other sessions and account preferences.

Version 1 sessions remain readable; the next batch save uses version 2. Unknown
versions start empty, matching the existing compatibility policy. Stores update
SavedVariables in memory; the client writes them to disk during normal exit or
UI reload.

Run `lua tests/forever.lua` with Lua 5.1 for store contracts and integration
coverage. Simulations do not replace validation of reload, normal logout and
panel behavior in WoW Forever.
