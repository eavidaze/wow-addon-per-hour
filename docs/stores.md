# Persistent stores

Only `src/stores/SettingsStore.lua` and `src/stores/SessionStore.lua` access
SavedVariables directly. Both retain the existing names and layout declared in
`per-hour.toc`: account preferences in `PerHourAccount_Settings`, character
sessions in `PerHourCharacter_Values`.

`core/Bootstrap.lua` handles the addon's `ADDON_LOADED` once. It initializes both
stores, binds module access, creates tracking panels, restores positions and
initializes the module menu and minimap position. Creating panels resets runtime
state while preserving saved sessions. Session restoration still waits for
`PLAYER_ENTERING_WORLD`.

## Settings

`PerHour.Stores.Settings` provides `GetMinimapAngle()` and
`SetMinimapAngle(angle)`. Each module receives its own `module.Settings` handle
with `Get(key)` and `Set(key, value)` for `isShown` and `position`. Positions are
plain tables with `point`, `relativePoint`, `x` and `y`; setting a position to
`nil` removes it.

Initialization preserves valid values, including `false` and zero, and repairs
malformed data using defaults. Invalid positions are discarded so panels use
their default layout. Setters reject invalid values. Position reads and writes
copy tables, so callers cannot mutate stored positions indirectly.

Forms keep their generic `value` and `onChanged` interface. The settings panel
connects module visibility and minimap position to the stores and applies each
change immediately. It refreshes silently when opened and when the corresponding
UI changes elsewhere. The minimap slider displays degrees while the store keeps
the existing angle in radians; displaying a rounded value never rewrites it.

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
