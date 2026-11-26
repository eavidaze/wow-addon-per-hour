# Revamp interface and in-game test checklist

The interface uses Forever's DialogBorderTranslucentTemplate, DialogHeaderTemplate
and SharedGoldRedButtonSmallTemplate, with Settings native checkboxes, selectors
and slider. It uses one shared dashboard and independent movable consultation windows.
Panels have two title styles: normal retains the native ornamental header for
Settings and consultation windows; small uses a centered 10 px muted gold caption
inside the tracker border, with no ornamental plate and a shorter header area.
The tracker's X appears only while hovering the panel or its controls.

## Controls

| Input | Result |
| --- | --- |
| Minimap / broker left click | Show/hide dashboard; leave capture unchanged. |
| Minimap / broker right click | Open Settings. |
| Dashboard X | Hide only the dashboard. |
| Start / Pause / Resume | Control the shared session. |
| Sessions > Finish and Reset | Freeze and save result, then wait for Start. |
| Sessions > History | Browse saved summaries. |
| Sessions > Details, or click a readout | Open current Session Details. |
| /perhour | Open Settings, including with an organizer-hidden minimap icon. |
| /perhour xp, gold, honor, rep | Show the same dashboard without changing its order or session. |
| /perhour help | Explain supported commands. |

The minimap is the standard embedded LibDBIcon launcher and shares callbacks
with broker displays. Dragging uses LibDBIcon's own positioning code.

## Dashboard and settings

Full shows primary, secondary and two tertiary readouts. Extended shows primary
and secondary. Focused shows only primary. Counters have no name labels above them;
their units identify the metric, with lowercase xp. Before Start, counters and
duration show zero without an Unavailable warning. Metric context remains in tooltips.
Value and unit sit together as a centered group. Capture warnings appear in
tooltips and Details, with no status labels below the displays. When enabled,
the estimate appears above the primary display, using the same XS component and
10 px font as Duration, with an area matching the primary width.
Preferred order starts with Experience,
Gold, Honor and Reputation; max level hides XP and promotes the others without
overwriting the preference. Reputation is hidden whenever no faction is watched,
including before Start; an unavailable reputation reading is never shown as zero.
If only one tertiary remains, it is centered vertically beside the primary.
The primary width scales from the secondary by their height ratio (60:42).
Secondary and tertiary displays share the same width. The panel fits the visible
columns and their contents, including duration, estimates and the gauge.
Focused, Extended and Full reserve the same height for the current composition;
switching type changes width and visibility without a vertical resize.
Each column is centered vertically as a whole, including the XS + MD block on
the left. Displays use explicit whole-pixel sizes: LG / MD / SM / XS fonts are
28 / 18 / 14 / 10 px, with heights of 29 / 19 / 15 / 11 px and units of 12 / 10 / 10 / 9 px.
The primary retains its established width when the speedometer is visible, keeping
its geometry; otherwise it uses 85% of that width to bring the side columns closer.
Secondary and tertiary widths shrink to 75% of their previous reference, following
the MD font ratio of 18/24. Widths use 84.7% of the reference measured for four
digits or a compact reading alongside each metric's /h and /m unit; longer readings
extend beyond the slot instead of being cut with ellipsis.
Value and unit stay centered together at their natural text width. Native
FontStrings use automatic width/height, avoiding tight bounds that can trigger
ellipsis at fractional UI scales.
Secondary and tertiary widths remain equal;
changing values or units does not resize them. Native controls retain their scale;
the session action has a fixed 96 px width across Start, Pause and Resume.
The footer shares the display area's horizontal padding, leaving 8 px inside
each border even when the action row determines the panel's minimum width.
This remains wider than the 3 px gaps between the central and circular actions.
Its diamond indicates current state: gray before Start, green while running
(Pause action), and yellow while paused (Resume action). The native atlas stays
desaturated so its original colors do not mix with the state tint.
Header and footer content gaps are reduced. A readable metric without gains shows zero and its rate unit,
including immediately after selecting a faction during a running session.
Settings retains the preferred metric positions
even while a metric is hidden.

Show duration applies to Extended and Full; Focused does not show it. There is
no short-session override. Details and Compare always retain duration.
Duration uses the shared XS display above the secondary: 11 px high, a 10 px
value font and the same background and width as its column.
Its text shows whole seconds below one minute (0s through 59s), whole minutes
below one hour (1m through 59m), then hours and minutes (1h 0m, 1h 2m).
Stored duration retains full precision for calculations. Duration is the only
display that uses the session status color: idle gray, running green, paused yellow.
It has no leading icon. The action button's status diamond retains those colors.
The optional active/pause indicator remains available through
Components:CreateSessionIndicator(parent), but the dashboard does not instantiate it.
It follows MUI CircularProgress motion with a native 84-frame FlipBook over 1.4
seconds and two bars when inactive. See the Design System component catalog and
src/licenses/MaterialUI.txt for attribution.
The gauge always reads XP, regardless of primary metric, and the estimate source
can be Experience or Reputation. Both remain separate display preferences.
The gauge occupies the primary display's width. Its labels stay at 10 px while
only the arc, tick marks and needle geometry resize. Compact artwork uses
analytic edge coverage baked directly at the final texture resolution, linear
sampling and native rotation. Label boxes anchor outside the arc, with a 6 px
gap; radius and frame height account for their measured widths and heights;
label text keeps automatic width so native FontStrings do not add ellipsis.
the frame and its text are not scaled. Side stacks use a 10 px vertical gap
while retaining their centered alignment.

Metric selectors swap positions. Grips support drag/drop onto another row.
Use selectors as an alternative to dragging. The watched-faction selector changes
the native watched faction. None affects only reputation capture.

The interface and number formatting use English. Rates use /h and /m. Fixed fonts
use compact k/M readouts; display text can overflow its slot without ellipsis.
All four counters display at most one decimal place, without rounding stored
totals, rates or estimate calculations. Identical readings are not redrawn.
Tooltips give full values.
Details retains copper precision and complete values with wrapping.
Estimates use unrounded session means, at least one measured minute and rounding
up to whole minutes. Paused shows Paused; absent progress gives No estimate available.

## History, Details and comparison

History starts with the current character and can select other known characters
or all characters. Each record has its own name, timestamp, starting map, measured
duration and result. Duplicate names remain independent. Select exactly two to
Compare. Rename affects one record; Delete requires its own confirmation.

Session Details covers XP, honor, reputation by faction, Gold composition and Gold
events in one native virtualized scroll list. It can stay open alongside History
or Settings. Finish turns open current Details into the archived record.
Per-faction totals/rates use the sum of that faction's tracked intervals; segment
rows show their sequence on the measured session clock.

Item events retain native item and quest tooltips, source, quantity and recorded
valuation parts. Renderers query cached item metadata, never market prices.
Unresolved values excluded at Finish show Not included · frozen. Announce in live
Details sends the chosen metric only to the explicitly selected chat channel.

Compare uses the same summary values and rates as Details, including each
reputation faction, measured durations and Partial/Pending/Incomplete flags.
Absent faction data stays unavailable rather than becoming zero.

History retains 100 summaries per character, details of the latest 20 and up to
1,000 consultable Gold events per session. Expired/truncated details have their
own notice and do not change capture quality or totals.

## Test in WoW Forever

Simulation does not confirm rendering, clipping, mouse routing, actual signals
or SavedVariables writes. Test these on the game client:

1. **First revamp load:** enable Lua errors; confirm one dashboard, defaults and
   empty revamp history. Old tracker preferences and sessions are not imported.
2. **Visibility:** left/right minimap clicks, broker clicks with hidden minimap,
   X, /perhour and every legacy metric command. Hiding must keep capture running.
3. **Session boundaries:** Start, earn XP/Gold/honor, Pause, gain while paused,
   Resume and Finish. Verify no paused gain, duplicate event or extra history entry.
4. **Layouts:** Full, Extended and Focused; Show duration on/off; gauge on/off;
   estimate on/off and both sources. Check all ten gauge maxima and /h versus /m.
5. **Metric order:** swap by selectors and drag/drop. Reach/use max level,
   confirm XP leaves positions and others move up without clearing saved order.
6. **Reputation:** A -> B -> A, changes in the native reputation UI, and None.
   Details must show separate factions, repeated intervals and proper rates.
7. **Estimates:** wait one active minute; pause/resume; no gains; level/standing
   change; maximum level/Exalted. Archived sessions must not predict from live progress.
8. **Gold:** looted/shared coins, quest money/items, consumables, delivered quest
   items, personal and guild repairs, paid flight, old-stock consumption and FIFO.
   Verify sales, purchases, mail, trade and bank transfers are not farming income.
9. **Prices:** vendor only; optional TSM/Auctionator; fixed quotes; pending data
   during pause/reload; Finish unresolved values; response after another Start.
   Frozen history must not change or leak income into the next session.
10. **History:** current and archived Details, long event scrolling, Rename,
    duplicate names, cancel/confirm Delete and Compare. Check native item/quest
    tooltips and complete copper values, including negative totals.
11. **Simultaneous windows:** keep History/Details/Settings open, change rate,
    rename, finalize and delete; inspect refresh, focus and Escape behavior.
12. **Persistence:** reload running and paused, normal logout/login, loading screens,
    another character and another realm. Review uncertain recovery before Resume.
13. **Screen fit:** UI scales/resolutions, long names, large/negative rates, fixed
    typography, display overflow, tooltips and draggable/clamped windows.
14. **Retention:** Lua tests cover 101 summaries and 1,002 events; inspect notices
    when enough records are available. Summaries must remain unchanged.

For failures, record the triggering action, Lua error/stack trace and expected/
actual result. Native-client validation remains pending until these checks pass.
