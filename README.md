# Per Hour - WoW Forever

Track experience, honor and watched reputation earned per minute and per hour.
Targets **WoW Forever 1.60.1 (Interface 16001)**. In-game validation is pending.

## Install

1. Extract the addon into `_forever_\Interface\AddOns\per-hour`.
   The folder must contain `per-hour.toc` directly.
2. Restart WoW and enable **Per Hour - Forever** in the AddOns list.

For local development on Windows, run `.\scripts\install.ps1` once to link this
checkout to the game's AddOns folder. Keep the checkout in place; subsequent
code changes only need `/reload`.

## Use

- Click the minimap clock or use `/perhour` to toggle the module menu.
- Check a module to show its window. Drag the minimap button to reposition it.
- **Start / Pause / Resume** controls tracking; paused gains and time are excluded.
- Drag anywhere on a window's background to move it; its close button hides it without stopping tracking.
- Windows automatically stay apart when moved or reopened.
- The gear menu offers **Reset** (clear and stop) and **Announce** (share results to chat).
- Hover over a window to see session duration, total gained, hourly and per-minute rates, and the tracked faction.
- **Reputation** requires a watched faction; switching factions resets it.

Window visibility, window positions and minimap button position are saved.
Sessions survive reloads and logins per character. Offline time and gains are excluded;
running sessions resume automatically, and manually paused sessions stay paused.
The icon at the top-left corner of the panel reports the restore check: green means matching played time;
red means the session needs review. Hover for details. Divergent sessions stay paused.
Continuity uses one played-time reference per character, with a 30-second tolerance.
Success fades after 5 seconds. Errors fade 0.5 seconds after Reset or Resume.

See [Session continuity](docs/session-continuity.md) for limitations and validation steps.

## Development

Run commands from the repository root:

```powershell
lua tests/forever.lua      # Lua 5.1 simulation checks
.\scripts\package.ps1     # Generate the release ZIP in dist\
```

See [Publishing a release](docs/releasing.md) for CurseForge setup.

## Credits

Original author: José Júnior. Thanks to Zwietabak and AssisrMatheus.
[MIT license](LICENSE).
