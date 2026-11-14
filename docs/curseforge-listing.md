# CurseForge listing

## Project name

Per Hour - XP, Honor & Reputation Farming Tracker

## Summary

Track XP for leveling, honor for PvP and reputation gains per hour in WoW Forever, with sessions preserved between logins.

## Description

### Per Hour - WoW Forever

Track your progress in WoW Forever with experience, honor and reputation earned
per hour and per minute.

#### Features

- Compact tracker windows with native WoW controls.
- Independent **Start**, **Pause** and **Resume** controls for each tracker.
- Live session tooltips showing duration, totals, hourly and per-minute rates, and the watched faction.
- Tracker windows stay apart when moved or reopened, preventing overlapping panels.
- A draggable minimap clock with a menu to show or hide each tracker.
- Saved window visibility, window positions and minimap button position.
- Per-character sessions preserved between logins, including totals, active duration and manual pause state.
- A shared continuity check flags restored sessions that may have missed progress.
- An **Announce** option to share your results in chat.

#### Getting started

Click the minimap clock or type `/perhour`, select a tracker, and click **Start**.

Hover over a tracker: **Session** shows duration and total gained, while **Rates**
shows gains per hour and per minute. Open the **Options** gear menu for **Reset**,
**Settings** and **Announce**.
**Announce** shares one chat message with your hourly average first, followed
by active session time and total gains in parentheses; reputation also names
the tracked faction.
The close button appears while hovering over the panel.

Paused time and gains are excluded. Closing a tracker window keeps an active
session running; **Reset** clears and stops it. Sessions are saved per character
when you log out normally. Offline time and gains are excluded; running sessions
resume after verification, and manually paused sessions stay paused.

The restore icon at the top-left of each panel is **yellow** while checking,
**green** after a successful check, or **red** when the session needs review.
Hover for details. The green confirmation disappears automatically. If a session
needs review, it stays paused until **Resume** accepts its saved totals or
**Reset** clears and stops it.

The check compares total played time with the saved session, allowing a
30-second tolerance for timing differences. It can flag unsaved playing time
even without XP, honor or reputation gains. Short interruptions may go unnoticed,
and lost progress cannot be recovered. Exit the game normally to save your sessions.

Using a hearthstone or changing zones keeps the current XP session running.

#### Reputation tracking

Select a faction to display on your reputation bar before starting the tracker.
Changing the watched faction resets the reputation tracker. Gains and losses
contribute to the session total.

#### Feedback

Feedback and bug reports are welcome!

[Source code and issue tracker](https://github.com/eavidaze/wow-addon-per-hour)
