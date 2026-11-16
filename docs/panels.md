# Shared panels

`PerHour.Components:CreatePanel(parent, settings)` shares the tracking panels'
border, background, typography and gold controls. Settings include `name`,
`title`, `width`, optional `height`, `footerSize` (default 28),
`closeAlwaysVisible` (optional override), `onClose` and `draggable` (default false).
The X calls `onClose(panel)` when supplied, then hides the panel.
`titleSize` accepts `"small"` (`GameFontHighlight`, used by trackers) or
`"default"` (`GameFontNormalLarge`, the default). Titles are centered. Small
headers span the row using the footer's side insets. Text is gold inside boxes
and white when unboxed.
The X follows `titleSize`: always visible for `"default"`, fading in on hover
and out when leaving for `"small"`. Set `closeAlwaysVisible = true` or `false`
to override that behavior for an individual panel. The settings panel inherits
the always-visible X from its default size; trackers inherit the small-size fade.
Set `titleBox = true` to surround either size with Forever's native
[`DialogHeaderTemplate`](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Shared/Dialog/DialogTemplates.xml),
as used by the Game Menu. The box sits over the top border. Small boxes fill
the row between the footer's side insets; default boxes fit the text and
shrink to leave room for the panel corners and close button. Branding does
not reduce the title box width. `panel.TitleText`
remains available; boxed titles also expose `panel.TitleBox`.
Small boxes use 24 px of text padding on each side; default boxes retain the
native 32 px per side. Both preserve the native corner textures.
Boxed panels leave 12 px between the bottom of the title box and the content.
Set `contentSpacing` to a nonnegative number of pixels to configure this gap
on the panel; it also sets the gap between content and footer buttons to that
value + 2 px. Panel height follows both gaps when fields grow or shrink.
Omitting it preserves the compact layout's existing spacing.
The settings panel uses a boxed default title; trackers use boxed small titles.
Tracker titles contain only the module name (Experience, Honor or Reputation).
Their rate display is centered between the title box and footer controls.
Small panels have no branding. Default panels show gray `powered by Per Hour`
on the right of the header, using a small font at 9 px and an extra 12 px of
horizontal inset to keep it clear of the X. Branding does not affect title
or content positioning.
Set `form = true` for form content padding and spacing between groups,
independently of the title size and box.

```lua
local panel = Components:CreatePanel(UIParent, {
    title = "Example", width = 360,
    titleSize = "small", -- or "default"
    titleBox = true, -- omit for an unboxed title
    contentSpacing = 12, -- 12 px after header, 14 px before footer
})
```

For custom content, use `panel:SetContent(component)`. It reparents the component
into `panel.Content` and centers it between the title and footer, preserving the
panel's configured size. Replacing the component hides the previous one. A composite
component can contain multiple displays. Adding footer actions later updates the
content boundary. Use custom content or form fields for a given panel.

`TrackerPanels.lua` creates and coordinates the three monitors, including session
controls, positioning and refreshes. Each monitor mounts a composite through
`SetContent`. It always contains a `CreateRateDisplay` component, whose
`SetRate(value, unit)` method formats the number, unit and overflow abbreviation
using its parent's width. When enabled, a `CreateSpeedometerDisplay` component
sits above that numeric display. Its `SetRate(value, maximum)` method updates only
the dial labels and animated needle. The coordinator supplies the existing
session rate to both displays, without changing the tracking calculation.

Use `panel:AddField(field)` for forms. Fields belong to `panel.Content` and
provide their own height; the panel stacks them with spacing and adjusts its
height automatically. `Components:CreateCheckbox(panel.Content, settings)`
accepts `label`, optional `checked` and optional `onChanged(checked)`. Clicking
the label also toggles the checkbox. No value is persisted automatically.

Forms use `Components:CreateFormGroup(panel.Content, settings)` with a `title`
and a `fields` array. Add the group with `panel:AddField(group)`. Each group has
a white title using `GameFontNormalHuge`, the same font as the hourly rate, and
indented rows with gold labels on the left and aligned controls on the right.
Groups have no separator lines. `group:AddField(settings)` can add rows later;
the group and enclosing panel resize and reposition subsequent groups. Hidden
fields take no space; showing them restores their row and spacing automatically.

| Field `type` | Settings and behavior |
| --- | --- |
| `checkbox` | Boolean `value`; `SettingsCheckboxTemplate`, including its native checkmark and hover state. Clicking the checkbox or label toggles it. |
| `select` | `options = { { value = "hour", label = "Per hour" }, ... }`; `SettingsDropdownWithButtonsTemplate`, with its native dropdown, radio menu and previous/next buttons. |
| `text` | String `value`, optional `maxLength` (default 64); Enter or losing focus commits the text, Escape restores the last committed value. |
| `slider` | `MinimalSliderWithSteppersTemplate`; numeric `value`, **required finite `min` and `max` with `min < max`**, optional positive `step` (default 1), `format` (a string, default `%g`, or a function receiving the value) and `suffix`. |
| `group` | One shared `label` and a `fields` array of controls placed side by side; optional `spacing` (default 8). Access children through `field.Fields[index]`. |

Individual controls accept `label`, optional `controlWidth` (the space reserved for the control column, default 300) and
`onChanged(value)`. Use `field:GetValue()` and `field:SetValue(value)` to read
or update a field. Sliders round to the configured step and clamp to their
bounds. Form controls keep values in memory; callers decide whether to persist
them or apply them to the addon.

Fields accept a `subfields` array, or `field:AddSubfield(settings)` after
creation. Subfields use the same field settings and appear below their parent,
with 24 px of additional indentation for labels and controls and an 8 px gap.
The control column narrows to keep the right boundary inside the form. Select
fields align their outer left stepper with checkboxes at the same nesting level.
Sliders shorten to fit the indented control column and reserve space for their
formatted minimum and maximum values, with the readout inside the right boundary
and a 4 px gap after the slider. Readouts align left so shorter values stay close.
Access subfields through `field.Subfields[index]`; composite rows
keep their inline controls in `field.Fields`. Nested subfields and later rows
resize and reposition the enclosing group and panel automatically.

Select fields also provide `field:SetOptions(options, value)` to replace their
choices and refresh the selected value silently, without calling `onChanged`.
An optional `maxMenuHeight` enables native menu scrolling at that height.

In a `group` row, child labels are omitted from the layout; a checkbox's label
still supplies its tooltip. Each child keeps its own value and callback.
Checkboxes reserve 32 pixels by default in these rows; other controls reserve
300. Set a child's `controlWidth` to reserve a different width without resizing
its native control. The shared control column fits the sum of the child widths
and spacing. The shared label does not toggle any child.
The last child may use `fill = true` to occupy the remaining control column;
this keeps a checkbox and slider inside an indented row without fixed child widths.
Dropdowns are centered inside their reserved column so both native stepper
buttons fit without overlapping adjacent controls. Their frame and stepper
anchors come from Forever's [shared panel templates](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.lua).

Form controls use the same complete templates as Forever's Options menu. Leave
their textures, fonts, colors, checkmarks, arrows and native sizes unchanged.
Text inputs use `InputBoxTemplate` with its default font and artwork and an
explicit 220 × 20 layout size. Per Hour supplies the surrounding groups, labels,
placement and value callbacks. The outer panel and footer retain Per Hour's
shared design.

`Theme.gold.text` is the shared gold text color for rate values and units,
form labels and tooltip labels. The minimap uses the native `GameNoHeaderTooltip`
with three compact lines aligned to the left and no title, so the first action
uses the same body font as the others. `Theme:GoldText(text)` applies the shared
gold color inline to each label, followed immediately by the white action.
See Forever's [tooltip definitions](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GameTooltip/Mainline/GameTooltip.xml).

```lua
local group = Components:CreateFormGroup(panel.Content, {
    title = "Appearance",
    fields = {
        { type = "checkbox", label = "Show icon", value = true },
        { type = "slider", label = "Opacity", value = 80,
            min = 25, max = 100, step = 5, suffix = "%" },
    },
})
panel:AddField(group)
```

To share a label between controls, add a composite row:

```lua
local row = group:AddField({
    type = "group", label = "Experience",
    fields = {
        { type = "checkbox", label = "Show Experience", value = true },
        { type = "select", value = "hour", options = {
            { value = "hour", label = "Per hour" },
            { value = "minute", label = "Per minute" },
        } },
    },
})
```

To place a related setting below a row:

```lua
row:AddSubfield({
    type = "select", label = "Tracked faction", value = 72,
    options = { { value = 72, label = "Stormwind" } },
    onChanged = function(factionID) C_Reputation.SetWatchedFactionByID(factionID) end,
})
```

Pass `actions` to `CreatePanel`, or call
`Components:CreatePanelActions(panel, actions)` once after creating it. Each
action can have a `key`, and its control is available at `panel.Actions[key]`.

| `type` | Appearance and behavior |
| --- | --- |
| `button` (default) | Gold text button with `text` and `onClick(panel, button)`. |
| `status` | Gold text button with an additional `Indicator` texture for tracking state. |
| `icon` | Circular icon and ring; `menu(button, rootDescription)` creates a dropdown, otherwise `onClick` runs directly. |
| `toggle` | Circular icon and ring; `isOn()` reads state and `onToggle(value, panel)` changes it. Color reflects state; optional `onTexture` and `offTexture` change the artwork. |

Circular actions accept `texture` or `atlas`. Actions accept an optional
`tooltip()` returning text and a fixed `width`. Text actions default to
`fullWidth = true` and share the remaining footer width; set `fullWidth = false`
to size an action to its label, or supply `width` or `widthFraction` explicitly.
Toggle state refreshes after clicks and when the
panel opens; call `button:Refresh()` after changing state elsewhere while open.
Use `widthFraction = 0.3` for 30% of the available footer width. A single action
can use `align = "CENTER"` to stay centered within that footer.

The minimap left-click menu is titled **Show trackers**.
Each tracker's gear menu is titled **Options**, with **Reset**, **Settings**
and **Announce**, in that order. **Settings** opens the same shared settings panel as minimap
right-click, regardless of which tracker opens it.
**Announce** sends one message to the chosen chat channel, leading with the
hourly average, followed by active session duration and total gains in
parentheses, with a discreet `[Per Hour]` prefix. Reputation appends the
session's faction when available. For example:
`[Per Hour] 240,000 XP/h - 30m (120,000 XP total)`
`SettingsPanel.lua` opens **Per Hour Settings** on minimap right-click, with
the entire boxed title in DS gold. The
**General** group starts with one **Rate** dropdown for
**Per hour** or **Per minute**, defaulting to hourly display. It immediately changes
all three panels' numeric rates and units, for example `XP/h` or `XP/min`.
The **Show trackers** group contains each module's visibility checkbox, sorted by name.
The shared unit is saved per character. Changes persist through the
[settings store](stores.md) across reloads and logins. Rate selection preserves
tracking totals, duration and pause state; large numbers keep their abbreviation.
The session tooltip still lists both rates.

**Experience** has an indented **Show speedometer** row with a checkbox and
the maximum slider immediately to its right, without a separate maximum label.
The checkbox defaults to disabled and applies only to Experience, for the current character.
Honor and Reputation keep their numeric displays. The XP numeric rate stays
visible in either mode. Enabling the gauge expands the Experience monitor
from 180 x 94 to 240 x 204; disabling it restores the
compact layout. The existing placement rules keep visible panels on screen and
avoid overlaps. Tracking and pause state are preserved.

The inline maximum slider has 10 levels (default 5) and appears while
**Show speedometer** is enabled. Its compact readout and the XP dial use
the current **Rate** unit. The maximum readout includes `/h` or `/min`, such as
`20k/h` or `320/min`. Only the level is saved per character; switching
units keeps that level and resolves the corresponding maximum from
`src/model/SpeedometerScales.lua`. Disabling the gauge hides the slider;
the checkbox row stays visible and the panel height remains unchanged.

| Level | XP/min | XP/h (rounded) |
| --- | --- | --- |
| 1 | 160 | 10k |
| 2 | 320 | 20k |
| 3 | 480 | 30k |
| 4 | 640 | 40k |
| 5 | 800 | 50k |
| 6 | 960 | 60k |
| 7 | 1.1k | 70k |
| 8 | 1.3k | 80k |
| 9 | 1.4k | 90k |
| 10 | 1.6k | 100k |

The hourly maxima are approximate counterparts rather than exact conversions;
minute levels 7–9 are also rounded to the nearest hundred.
Above the maximum, the needle stays near the end stop while the numeric
display keeps the actual rate. The gauge uses two transparent, antialiased TGA
textures with linear filtering: `src/textures/SpeedometerDial.tga` for the arc,
ticks and center cap, and `SpeedometerNeedle.tga` for the rotating pointer.
Both are white artwork tinted in Lua; the five scale labels remain dynamic text.
The pointer uses the darker red in `Theme.speedometer.needle`. Both artworks have
black shadow copies at 45% opacity, offset one UI pixel right and down. The needle's
shadow shares its rotation while keeping that screen-relative offset.
It animates the needle over 0.2 seconds and does not include another numeric readout.
When the rate is strictly greater than the maximum, an overload effect adds two
short yellow-white flashes and an inward tremor, followed by a pause. Most beats
reach 1.5 degrees; three beats per burst reach 3 degrees. The cadence remains
32 beats per second during a 0.36-second burst, with a 1.44-second pause.
The 1.8-second cycle uses native Alpha animations on an additive copy of
the existing needle texture; its color comes from `Theme.speedometer.overload`.
The needle, glow and shadow share the same rotation. Repeated rate updates do
not restart the cycle. Returning to or below the maximum stops the effect
immediately; hiding the gauge stops both the glow and tremor, and showing it again
resumes overload only if its latest rate still exceeds the maximum. Session
calculations and the numeric readout are unaffected.
Regenerate the textures with `python scripts/generate-speedometer-assets.py`
(development dependencies: Pillow and Lupa with Lua 5.1). The generator executes
`Theme.lua` to read the dial, needle, shadow and text colors for its preview;
the TGA assets remain white with transparency. It also writes a magnified illustration to
`dist/SpeedometerPreview.png`; that preview is not an in-game screenshot.

The Reputation row has an indented **Tracked faction** dropdown. It displays
the game's watched faction and changes it directly through
[`C_Reputation`](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ReputationInfoDocumentation.lua).
`UPDATE_FACTION` keeps the open form synchronized with changes made in the
game's reputation panel. The alphabetized list includes known reputations in
collapsed and inactive groups, plus headers that have their own reputation.
Reading the list restores the original collapsed states. **None** clears the
watched faction, and long lists use native scrolling. Reopening settings reads
the current game state; no separate addon preference is saved. The selector
works while the tracker is hidden or stopped and does not start a session.
Changing factions preserves the tracker's existing automatic session reset;
gains from different factions are never combined.

Hiding a panel keeps its session running. The form follows visibility changes
from the minimap menu and panel X and reads saved preferences silently when
reopened. Reposition the minimap button by dragging it; settings have no angle
control.

Tracker visibility, tracker positions and the minimap button position are saved
per character, along with the hourly/per-minute preference shared by all three panels.
Matching valid legacy account rates are imported once per character; mixed,
missing or invalid legacy rates default to hourly.
Previous account layouts are not imported; characters start with hidden trackers
and the default layout until they save their own preferences.

The panel has one centered footer action, **Close**, at 30% of the
available footer width, and an always-visible
X. Drag its background, including
the title area, to move it; fields and buttons handle their own mouse input.
The panel retains its position while the addon remains loaded.
Its `contentSpacing = 12` keeps 12 px below the boxed header and 14 px between
the form content and **Close**, independently of the compact tracker layout.

Validate appearance, checkbox interaction, the shared rate dropdown, dragging and
both close controls in WoW Forever. After `/reload` and a normal logout/login,
confirm that panel visibility, selected unit and minimap position match saved preferences.
Switch between two characters and confirm their layouts and display units remain independent.
Changing the unit must update all three panels' numeric readouts and the XP gauge scale.
Verify that the speedometer checkbox applies only to XP, keeps the
numeric rate below the dial and restores after reload. Check that the single
maximum slider appears while enabled, including after reopening and reload;
check all ten levels, switching units without changing the level,
pause/resume, overflow and switching characters with different gauge preferences.
Validate the reputation subfield's indentation and scrolling, switching factions
through both interfaces, **None**, and session reset after switching factions.
Lua simulation checks do not validate rendering or native mouse routing.
