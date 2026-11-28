# Per Hour - WoW Forever

Measure XP, estimated net Gold, honor and reputation in one shared activity session.
Targets **WoW Forever (Interface 16001)**. Native rendering and event ordering
still require in-game validation.

## Install

Extract into `_forever_\Interface\AddOns\per-hour`, with `per-hour.toc` directly
inside that folder, then restart WoW and enable the addon.
For a linked development checkout on Windows, run `.\scripts\install.ps1` once.

**Updating to the revamp:** previous tracker sessions and preferences are not
imported. The revamp starts with its own defaults and empty history.

## Use

- Left-click the minimap clock to show/hide Per Hour; right-click opens Settings.
- Start / Pause / Resume controls every metric together. Hidden panels keep capturing.
- Finish Session in Sessions or the current Session window lets you edit the title, confirms saving to History and waits for another Start.
- Sessions > Current Session opens metrics, reputation by faction and grouped Gold Income/Expenses.
- History opens saved sessions, supports Rename and confirmed Delete, and compares two
  selected sessions with all metrics. Its character selector can show other characters.
- Settings controls Focused / Extended / Full, metric order, /h or /m, duration,
  separate XP/reputation estimates, XP speedometer and watched faction. Use metric selectors or arrows to reorder.
- Changing faction preserves earlier results. None stops only reputation capture.
- Reload restores the verified state; normal logout returns to a paused session.
- /perhour opens Settings; /perhour xp|gold|honor|rep shows the shared panel.
- Session > Announce shares a live metric only after selecting a chat channel.

History keeps 100 summaries per character and details of the latest 20 sessions,
up to 1,000 consultable events each. Finish freezes unresolved Gold as incomplete.
See [usage and in-game test checklist](docs/panels.md),
[Gold accounting](docs/gold-tracking.md) and [session continuity](docs/session-continuity.md).

## Development

Run from the repository root:

    lua tests/forever.lua          # Lua 5.1
    .\scripts\package.ps1          # Local ZIP in dist\

If Lua is unavailable, install the optional development runtime with
python -m pip install --target dist/runtime lupa, then run
python scripts/lua51.py tests/forever.lua. This executes actual Lua 5.1;
the runtime is excluded from the addon package.
See [architecture](docs/stores.md) and [releasing](docs/releasing.md).

Original author: José Júnior. Thanks to Zwietabak and AssisrMatheus. [MIT license](LICENSE).
