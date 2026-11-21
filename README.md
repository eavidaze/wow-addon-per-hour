# Per Hour - WoW Forever

Track experience, honor, watched reputation and estimated net gold per minute and per hour.
Targets **WoW Forever 1.60.1 (Interface 16001)**. In-game validation is pending.

## Install

1. Extract the addon into `_forever_\Interface\AddOns\per-hour`.
   The folder must contain `per-hour.toc` directly.
2. Restart WoW and enable **Per Hour** in the AddOns list.

For local development on Windows, run `.\scripts\install.ps1` once to link this
checkout to the game's AddOns folder. Keep the checkout in place; subsequent
code changes only need `/reload`.

## Use

- Left-click the minimap clock to toggle the module menu.
- Use `/perhour`, or right-click the minimap clock, to open **Settings**
  for panel visibility, a shared hourly/per-minute display unit and the watched reputation.
- Use `/perhour help` to list the available text commands.
- Use `/perhour xp`, `gold`, `honor` or `rep` to show the corresponding tracker.
- Check a module to show its window. Drag the minimap button to reposition it.
- The standard minimap icon supports Leatrix and other LibDBIcon organizers; its libraries are included.
- **Start / Pause / Resume** controls tracking; paused gains and time are excluded.
- Drag a window's background to move it; its close button appears on hover and hides it without stopping tracking.
- Enable **Show speedometer** under Experience in **Settings** for an XP gauge with ten scale levels.
- Windows automatically stay apart when moved or reopened.
- The **Options** gear menu offers **Reset** (clear and stop), **Settings** and **Announce** (share results to chat).
- Hover over a window for session details and estimates to the next XP level or reputation standing.
- Enable **Show estimates** in **Settings → General** to also display predictions below the rates.
- Choose a watched faction in **Settings** or the game's reputation panel;
  switching factions resets the reputation tracker.
- **Gold** values eligible items with optional TSM → Auctionator → vendor pricing and a vendor minimum;
  poor (gray) items always use vendor value. It tracks loot and rewards,
  and subtracts consumed/delivered items, personal repairs and paid flights. Trades, mail, item purchases
  and vendor-sale receipts are excluded. See [Gold tracking](docs/gold-tracking.md).
- Left-click **Gold** or choose **Gold → Options → Details** to view income, expenses and event history.

Window visibility, window positions and minimap button position are saved per character.
One hourly/per-minute display preference applies to all windows and is saved per character.
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
