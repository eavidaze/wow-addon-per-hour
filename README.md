# Per Hour - WoW Forever

Track experience, honor and watched reputation earned per minute and per hour.
Targets **WoW Forever 1.60.1 (Interface 16001)**. In-game validation is pending.

## Install

1. Extract the addon into `_forever_\Interface\AddOns\per-hour`.
   The folder must contain `per-hour.toc` directly.
2. Restart WoW and enable **Per Hour** in the AddOns list.

For local development on Windows, run `.\scripts\install.ps1` once to link this
checkout to the game's AddOns folder. Keep the checkout in place; subsequent
code changes only need `/reload`.

## Use

- Left-click the minimap clock or use `/perhour` to toggle the module menu.
- Right-click the minimap clock to open **Settings** for panel visibility,
  hourly/per-minute rates and the watched reputation.
- Check a module to show its window. Drag the minimap button to reposition it.
- **Start / Pause / Resume** controls tracking; paused gains and time are excluded.
- Drag anywhere on a window's background to move it; its close button hides it without stopping tracking.
- Windows automatically stay apart when moved or reopened.
- The **Options** gear menu offers **Reset** (clear and stop), **Settings** and **Announce** (share results to chat).
- Hover over a window to see session duration, total gained, hourly and per-minute rates, and the tracked faction.
- Choose a watched faction in **Settings** or the game's reputation panel;
  switching factions resets the reputation tracker.

Window visibility, window positions and minimap button position are saved.
Sessions survive reloads and logins per character. Offline time and gains are excluded;
running sessions resume automatically, and manually paused sessions stay paused.
The top-left restore icon reports the continuity check. Hover for details; sessions
that need review stay paused until you choose **Resume** or **Reset**.

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
