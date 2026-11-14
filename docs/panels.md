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
the group and enclosing panel resize and reposition subsequent groups.

| Field `type` | Settings and behavior |
| --- | --- |
| `checkbox` | Boolean `value`; `SettingsCheckboxTemplate`, including its native checkmark and hover state. Clicking the checkbox or label toggles it. |
| `select` | `options = { { value = "hour", label = "Per hour" }, ... }`; `SettingsDropdownWithButtonsTemplate`, with its native dropdown, radio menu and previous/next buttons. |
| `text` | String `value`, optional `maxLength` (default 64); Enter or losing focus commits the text, Escape restores the last committed value. |
| `slider` | `MinimalSliderWithSteppersTemplate`; numeric `value`, **required finite `min` and `max` with `min < max`**, optional positive `step` (default 1), `format` (default `%g`) and `suffix`. |
| `group` | One shared `label` and a `fields` array of controls placed side by side; optional `spacing` (default 8). Access children through `field.Fields[index]`. |

Individual controls accept `label`, optional `controlWidth` (the space reserved for the control column, default 300) and
`onChanged(value)`. Use `field:GetValue()` and `field:SetValue(value)` to read
or update a field. Sliders round to the configured step and clamp to their
bounds. Form controls keep values in memory; callers decide whether to persist
them or apply them to the addon.

Fields accept a `subfields` array, or `field:AddSubfield(settings)` after
creation. Subfields use the same field settings and appear below their parent,
with 16 px of additional left indentation and an 8 px gap. Controls keep their
right alignment. Access them through `field.Subfields[index]`; composite rows
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

The minimap left-click menu is titled **Panels**.
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
**Panels** group has one row per module, sorted by name. Each row shares
the module's label between a visibility checkbox and a native dropdown for
**Per hour** or **Per minute**, defaulting to hourly display. Each selection immediately changes
that panel's numeric rate and unit, for example `XP/h` or `XP/min`; Honor and
Reputation use the same independent preference. Changes persist through the
[settings store](stores.md) across reloads and logins. Rate selection preserves
tracking totals, duration and pause state; large numbers keep their abbreviation.
The session tooltip still lists both rates.

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

The panel has one centered footer action, **Close**, at 30% of the
available footer width, and an always-visible
X. Drag its background, including
the title area, to move it; fields and buttons handle their own mouse input.
The panel retains its position while the addon remains loaded.
Its `contentSpacing = 12` keeps 12 px below the boxed header and 14 px between
the form content and **Close**, independently of the compact tracker layout.

Validate appearance, checkbox interaction, each rate dropdown, dragging and
both close controls in WoW Forever. After `/reload` and a normal logout/login,
confirm that panel visibility, selected rates and minimap position match saved preferences.
Validate the reputation subfield's indentation and scrolling, switching factions
through both interfaces, **None**, and session reset after switching factions.
Lua simulation checks do not validate rendering or native mouse routing.
