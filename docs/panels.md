# Revamp interface and in-game test checklist

The interface uses Forever's DialogBorderTranslucentTemplate border geometry,
DialogHeaderTemplate and SharedGoldRedButtonSmallTemplate, with Settings native
checkboxes, selectors and slider. The translucent border background is hidden;
all panels use Options' FlatPanelBackgroundTemplate, which supplies the native
PANEL_BACKGROUND_COLOR without extra tint or alpha. Details tabs reuse Options'
MinimalTabTemplate and CreateRadioButtonGroup, including native selection artwork.
Sources: [Options frame](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_Settings_Shared/Mainline/Blizzard_SettingsPanelTemplates.xml),
[Options tabs](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_SettingsPanel.xml).

The addon uses one shared dashboard and independent movable consultation windows.
Panels have two title styles: normal retains the native ornamental header for
Settings and consultation windows; small uses a centered 10 px muted gold caption
inside the tracker border, with no ornamental plate and a shorter header area.
The tracker's X appears only while hovering the panel or its controls.
Normal footer buttons have a 96 px minimum width and 28 px height, with 32 px
horizontal text padding. Footer groups are centered; Compare does not
stretch to the panel width. Longer labels grow to fit. History and Details share
Components:CreateRenameButton, using the same 72 x 24 px size. Details reserves
the button's measured width before wrapping its session name. Icon actions with dropdown menus share INV_Scroll_03
through Theme.icons.menu, including tracker Sessions and Details Announce. The
direct session-view action retains INV_Misc_Note_06.

Panels use native toplevel behavior and render-layer flattening so the background,
text and controls of different windows are not interleaved. Clicking a window
brings it forward. Standard windows initially open in a 32 px cascade within their
own strata, constrained to the screen; a hidden window does not determine placement.
First-open placement runs once, preserving subsequent manual moves during the
session. Windows fit both screen dimensions. The tracker keeps its separate
position; Rename/Delete retain FULLSCREEN_DIALOG above the DIALOG consultation windows.
PanelWindows.lua owns placement and fitting, without per-frame polling or new settings.

## Controls

| Input | Result |
| --- | --- |
| Minimap / broker left click | Show/hide dashboard; leave capture unchanged. |
| Minimap / broker right click | Open Settings. |
| Dashboard X | Hide only the dashboard. |
| Start / Pause / Resume | Control the shared session. |
| Sessions > Finish Session, or current Details footer | Confirm, freeze and save result, then wait for Start. |
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
duration show zero without an Unavailable warning. Metric tooltips show only the
metric name, total and the opposite rate: per minute when the display uses per
hour, or per hour when it uses per minute. Capture warnings and metric context
remain in Details. Tracked rates share Format:RateReading/RateText across the
dashboard, tooltips and consultation views: a numeric value plus xp/h, g/m, etc.
Gold rates convert copper to gold; absolute amounts use Format:Amount and native
coin icons, preserving copper precision and negative signs.
Value and unit sit together as a centered group without a
background, with no status labels below the displays. When enabled,
the Experience estimate appears above the primary display, between it and the
speedometer; the Reputation estimate appears below primary. Both can be visible
together, using the same XS component and 10 px font as Duration, with areas
matching the primary width.
Both estimate texts follow the same session-status colors as Duration and the
action indicator: gray before Start/after Finish, green while running and yellow
while paused (including continuity verification).
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
value font and the same width as its column, without a background.
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
The gauge always reads XP, regardless of primary metric. Experience and Reputation
each end with an independent Show estimates checkbox in Settings. Both default off;
the previous shared estimate preference is not migrated. At max level, the XP
estimate and gauge are hidden while the Reputation estimate remains available.
The gauge occupies the primary display's width. Its labels stay at 10 px while
only the arc, tick marks and needle geometry resize. Compact artwork uses
analytic edge coverage baked directly at the final texture resolution, linear
sampling and native rotation. Label boxes anchor outside the arc, with a 6 px
gap; radius and frame height account for their measured widths and heights;
label text keeps automatic width so native FontStrings do not add ellipsis.
the frame and its text are not scaled. Side stacks use a 10 px vertical gap
while retaining their centered alignment.

Metric selectors and their arrows swap positions. Metric rows have no drag handles.
The watched-faction selector changes
the native watched faction. None affects only reputation capture.

The interface and number formatting use English. Rates use /h and /m. Fixed fonts
use compact k/M readouts; display text can overflow its slot without ellipsis.
All four counters display at most one decimal place, without rounding stored
totals, rates or estimate calculations. Identical readings are not redrawn.
Tooltips give full values.
Details uses compact XP/Honor readings with complete values in tooltips;
Gold rates use numeric gold with g/h or g/m, while totals retain native coin icons
and copper precision.
Estimates use unrounded session means, at least one measured minute and rounding
up to whole minutes. Paused shows Paused; absent progress gives No estimate available.

## History, Details and comparison

History starts with the current character and can select other known characters
or all characters. Each record has its own name, timestamp, starting map, measured
duration and result. Duplicate names remain independent. Select exactly two to
Compare. Rename affects one record; Delete requires its own confirmation.
Compare uses a fixed, single-line gold grid header with 16 px session titles;
the metric and separator headings are blank. Titles truncate with
ellipsis; their tooltips show the complete name, character, start and duration.
The panel is 700 px wide, with a 648 px table. Height fits the rows between a
320 px minimum and a 520 px maximum; additional factions scroll within that limit.
Each metric occupies one 32 px row with 14 px readings. Labels follow the session card's small,
muted-gold style. The greater reading in each row is gold; the other remains white,
and ties leave both white. Winners use unrounded hourly rates, treating absent
readings as zero. The first reading aligns right and the second
aligns left, facing a fixed 24 px `vs.` column with 6 px of padding on either side.
The `vs.` column marks the exact horizontal center of the panel, including the
space reserved for its scrollbar; metric labels occupy a narrower left column.
The winner also shows a green upward triangle and its percentage advantage, before
the first reading or after the second. The percentage uses the full rate difference
divided by the absolute opposing rate, with up to one decimal place below 100%
and no decimal places from 100% onward; positive differences
below 0.1% show `<0.1%`. For negative Gold this measures reduced loss. Ties, missing
or unavailable readings and a zero opposing baseline have no percentage.
Readings and percentage captions use their full natural text
width, without ellipsis. The metric label yields space when a left-side winning
group needs it. Only column titles and metric labels may truncate; `vs.` stays 24 px.
Rows show compact rates per hour only, with a space before `xp/h`, `g/h`, `hon/h`
or `rep/h` (numeric gold in `g/h`), independent of the
dashboard's selected period. Zero, unavailable, untracked and zero-duration
readings display zero with the metric's spaced hourly unit. Value tooltips contain only the metric/faction title,
`Rate per min.:` with the inverse minute rate and `Total:` with the full amount.
Unavailable minute rates display `0/m`; absent totals are zero. Session names,
measured time, capture warnings and calculation explanations are omitted from
these value tooltips.
Experience, Gold and Honor come first, followed by the union of tracked factions
sorted alphabetically and matched by faction ID. Each faction rate uses its own
tracked time. Duration is not included in the comparison rows. The header remains
fixed while only metric rows scroll.
New sessions default to `<starting area> - <local date and time>`, for example
`Mount Hyjal - Nov 27, 2026 14:54`. Only Start assigns this title; existing names
and restored sessions are preserved without migration.
History rows are 28 px with a white session name on a single line, without
a subtitle. Duration and estimated Gold occupy aligned columns; selection stays on the
left. The first Session column combines the 18.5 px INV_Misc_Note_06 icon and title
in one transparent button, with identical click/hover behavior across both.
Click opens that row's Details; hover retains the icon highlight without a session
tooltip. The row background also has no session tooltip. Only Rename
and the 24 px UIPanelCloseButton X for Delete remain in the right action column. The X opens
the existing deletion confirmation and has its own action tooltip. Gold est.
shows only the largest nonzero denomination (gold, otherwise silver, otherwise
copper), without rounding into a larger unit; zero is 0 copper. Full precision
and metadata remain available in Details. The title uses the standard white value style
and truncates with ellipsis when necessary; its icon and text share one hit area.
Checkbox, Details icon, Rename and Delete share a 24 px band anchored to the top
of the row, with the same vertical center and whole-pixel control edges. The smaller
Details texture is centered inside its 24 px slot, matching the half-scale item
icons (the native ItemButton is 37 px). The 3 px divider
and remaining 1 px sit below that band, avoiding a half-pixel center in 25 px content.

Session Details pins one grouped card at the top. Its heading shows only the name
beside Session and Rename. The name is green while running and gold when paused
or finished; verification/review states also use gold rather than implying active
capture. Refreshes reset the color when status or the displayed record changes.
Character shows
the character's first name and surname, with a realm suffix only when nonempty;
Level occupies the second column as 56 (62% xp), using the
starting level and initial XP.
Started shows the local start date and time, such as Nov 26, 2026 14:54,
with Duration in the second column as 3h 43m 35s. Measured time
excludes pauses and offline time. Experience, Honor and Gold each occupy a row
with rate in column one and total in column two. Rate labels follow the shared
Hour/Minute preference. XP/Honor rates truncate to one compact decimal (61.7k,
53.1); totals truncate to whole compact units (230k, 198). Only display values
are shortened. Tooltips retain exact rates/totals, measured time, quality flags
and issue causes, plus Gold's Coins, Items (est.), Expenses and pending/excluded
price count. Absolute Gold shares Format:Amount/Format:Money with event rows for
native coin icons; Gold rates share Format:RateText with dashboard tooltips.
Total Gold shows the net value followed by (inc - exp), left-aligned in the standard
white value color; its numeric composition remains available in the tooltip.
Visited areas is the last card row, after all metrics. It always shows the route,
including a single starting area, with bullets separating visited areas.
Below the card, Income, Expenses and Reputation share one native virtualized ScrollBox.
The former Gold tab is split into Income and Expenses at the same navigation level;
Income is the default for each session. Only the selected tab's content scrolls.
The tab content and scrollbar sit inside the border of Options_InnerFrame,
joined to the tab strip, with 8 px of breathing room. Tabs.lua draws only the
eight outer slices at native thickness; the atlas center is omitted. A fixed
black fill at 45% opacity covers only the interior, matching the darker inner
border band while leaving the surrounding panel background unchanged. The box
uses its parent's frame level, below the sibling ScrollBox, so its translucent
fill cannot darken the text or pooled rows.
The Experience row is omitted for sessions started at level 60; recorded starting context
controls visibility, so later character progression cannot hide archived XP.
Live updates retain selection and scroll position. Changing tabs starts at the top. It can stay open alongside History
or Settings. Finish turns open current Details into the archived record.
The current Details footer shows Finish Session while running or paused, including
recovery/verification states. Archived Details hides it and recenters the remaining
action. The Sessions dropdown lists History, Current Session, a divider and
Finish Session rendered with Components:CreateButton, the same normal red-and-gold
component used by panel actions, with the footer's tint and 28 px height. The menu
pools only an empty Frame container; the actual button and its label are owned by
the dashboard and reused. Opening attaches and centers the button in the container;
closing hides it and returns it to the dashboard. Its native menu responder closes
the dropdown and opens the same confirmation as the Details footer. The implementation
uses the native menu's [custom frame elements](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_Menu/11_0_0_MenuImplementationGuide.lua).
Register initialization with `root:CreateFrame():AddInitializer(...)` and data with
`SetData`: [MenuUtil's wrapper](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_Menu/MenuUtil.lua)
does not forward initializer/data arguments to MenuTemplates.CreateFrame.
Without a current session, only History is listed. Both Finish controls call
Session:Finish(). Every public
Session:Finish() request opens the shared Finish dialog, with Finish Session and
Cancel, in FULLSCREEN_DIALOG like Delete. Only confirmation for that exact current
session ID performs the archive. Cancel, X and Escape preserve the session's state;
capture continues while a running session awaits confirmation. Finishing closes any
pending confirmation for that record; a stale confirmation cannot finish a new one.
Finish, Rename and Delete use centered 14 px body text. Finish and Rename share a
centered title field, prefilled and selected with the current session title (the
starting area/date/time suggestion unless already renamed). Finish saves the edited
title only on confirmation; Cancel, X and Escape discard the draft. Both title
dialogs accept Enter, trim outer whitespace and require 1–80 characters, with an
inline error for invalid input. Delete explicitly warns that removal is permanent.
Income and Expenses contain their Last / Description / Count / Total table, with an
empty/expired-details notice when needed. Sum sits above the Total header, aligned
with its values. It sums known retained rows for that tab, never the global net
metric. An asterisk flags pending/excluded prices or the latest-1,000-events limit;
the Sum tooltip explains these limits. Expired details show a dash instead of zero.
All table headers remain fixed, including History and Compare. Only body rows enter
the ScrollBox; Income/Expenses also pin Sum above their headers. GoldGroups.lua groups retained events only for display:
item variants use the complete item-link payload, merging loot/rewards on Income
and consumption/delivery on Expenses. Incoming and outgoing quantities never net
against each other. Count is item units, or the number of non-item occurrences.
Dropped coins and Reward coins are separate groups; repeated repairs/flights
group by source. Last is the latest occurrence, independent of price resolution.
Income sorts by accumulated known value descending; Expenses by largest cost.
Ties use Last descending and stable group identity. Group IDs survive updates so
the viewport can retain a consulted group as rankings change.
Card fields span the width and wrap; the heading reserves space for Rename so
long names cannot overlap the action. Fields start at 24 px, table rows at 28 px
and the heading uses 32 px. Native font metrics determine taller
rows for wrapped text. The card stays outside the ScrollBox; its frame pool grows with wrapped
fields. The window grows when necessary to retain at least 240 px of tab content,
then follows the standard screen fitting. Key/value fields
have no separators; only grids and lists use the copper row divider.
Frozen unresolved quotes are labeled Excluded prices, not Pending prices.
Reputation is a single Faction / Duration / Rate / Total grid, sorted by faction
name. Repeated tracking intervals contribute to the same faction row; its rate
uses that faction's tracked duration. The watched faction is green while running
and gold while paused or awaiting verification; other and archived factions are
white. Partial capture and the rate time basis remain in its tooltip. Untracked
time appears as a No faction row with Duration and dashes for Rate/Total.
The list uses distinct renderers and native variable extents: 52 px Compare summaries,
24 px headers, 28 px sessions and 26 px grouped Gold rows. Gold content stays
centered above the 3 px copper divider, with Last / Description / Count / Total columns,
half-scale item/source icon, reserved quest-marker
slot and rarity-colored item name without a quantity suffix. Count aligns right
in its own column. Values align right
using native money strings; outgoing values are red, without a redundant sign.
Price provenance stays in the icon tooltip instead of another text line/column.
Only item and quest icons show their native tooltips; item names remain passive.

Grouped items retain native item tooltips, counts, recorded quotes and source
provenance. A single quest retains its native tooltip; groups spanning several
quests report their count without pretending to represent one quest. Mixed prices
are summed exactly as recorded, never repriced or replaced with an average. The
tooltip shows up to six consolidated quote parts, with an additional-parts count.
Pending/excluded members do not enter known value: entirely unresolved groups
show Pending or Not included · frozen; mixed groups show their known subtotal
with an asterisk and explain the missing members in the icon tooltip. Renderers
query cached item metadata, never market prices. Capture, persistence and metric
summaries are unchanged; no migration or saved-data rewrite is involved.
Viewport refreshes retain the first surviving visible record and its partial
pixel offset across mixed row heights. Changing the record or character filter
or selected metric tab resets the viewport. Pooled frames create only the controls needed by each row
type and hide the previous type when reused.
Unresolved values excluded at Finish show Not included · frozen. Announce in live
Details sends the chosen metric only to the explicitly selected chat channel.

Compare derives its hourly rates from the same preserved summaries as Details.
Value tooltips show the inverse minute rate and full total; absent faction
readings display `0 rep/h` in the table and zero in their tooltip readings.

History retains 100 summaries per character, details of the latest 20 and up to
1,000 retained Gold events per session, grouped for consultation. Limited lists
explicitly say they group only the latest 1,000 events; summaries still cover all.
Expired/truncated details have their
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
   Request Finish from both Sessions and the Details footer while running and paused.
   Cancel or close with X/Escape and verify capture state/totals are preserved.
   Confirm once, verify one history entry, archived Details without Finish, and
   correct footer centering. Finish during continuity verification and repeat
   requests; no old dialog may finalize a later session.
4. **Layouts:** Full, Extended and Focused; Show duration on/off; gauge on/off;
   each estimate on/off separately and together. Check all ten gauge maxima and /h versus /m.
5. **Metric order:** swap by selectors and their arrows. Reach/use max level,
   confirm XP leaves positions and others move up without clearing saved order.
6. **Reputation:** A -> B -> A, changes in the native reputation UI, and None.
   Details must combine repeated intervals into one row per faction with correct
   Duration/Rate/Total, current-faction colors and a No faction row for untracked time.
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
    Verify 26 px event rows and 28 px single-line session rows, icon/title click and hover, rarity colors,
    native source icons without direction arrows, and the INV_Misc_Note_06 Details action.
    In Details, switch Income/Expenses/Reputation and scroll long content: the grouped card,
    metric results, tab strip, column headers and Gold Sum must stay fixed. Check
    History/Compare headers too. Check inline Rename for current
    and archived sessions, including an open session that is finished and renamed.
    Check leveling sessions,
    repeat item gains/spends and coin drops/rewards, verify Last and Count, and
    check value-descending income / cost-descending expenses. Resolve quotes and
    verify rows merge/update without changing totals; inspect pending/frozen and
    mixed-price tooltips, single/multiple quest markers and retained-event limits.
    sessions that reach 60 and sessions started at 60, including archived records.
    Check that key/value cards have no dividers and tables retain theirs. Compare
    the native gray background with Options across tracker, Settings and Details.
    Scroll to a partially visible row, receive more loot/archive another session
    and confirm the viewport stays anchored. Reused rows must not retain an old
    quest marker, item rarity, tooltip, checkbox selection or action target.
11. **Simultaneous windows:** keep History/Details/Settings open, change rate,
    rename, finalize and delete; inspect refresh, focus and Escape behavior.
    Open Compare too. Verify a cascade with exposed headers, click both panel
    backgrounds and child controls to switch the front window, and confirm no
    texts, checkboxes, footer actions or close buttons interleave. Move a window,
    close/reopen it and verify the position stays put. Check Rename/Delete above
    the consultation windows and repeat at reduced resolution/UI scale.
12. **Persistence:** reload running and paused, normal logout/login, loading screens,
    another character and another realm. Review uncertain recovery before Resume.
13. **Screen fit:** UI scales/resolutions, long names, large/negative rates, fixed
    typography, display overflow, tooltips and draggable/clamped windows.
14. **Retention:** Lua tests cover 101 summaries and 1,002 events; inspect notices
    when enough records are available. Summaries must remain unchanged.

For failures, record the triggering action, Lua error/stack trace and expected/
actual result. Native-client validation remains pending until these checks pass.
