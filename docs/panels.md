# Shared panels

`PerHour.Components:CreatePanel(parent, settings)` shares the tracking panels'
border, background, typography and gold controls. Settings include `name`,
`title`, `width`, optional `height`, `footerSize` (default 28),
`closeAlwaysVisible` (default false), `onClose` and `draggable` (default false).
The X calls `onClose(panel)` when supplied, then hides the panel.
Set `form = true` for a large white panel title and spacing between form groups.

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
group:AddField({
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
`SettingsPanel.lua` opens **Per Hour Settings** on minimap right-click, with
only **Per Hour** in DS gold and **Settings** in white. The
**Panels** group has one row per module, sorted by name. Each row shares
the module's label between a visibility checkbox and a native dropdown for
**Per hour** or **Per minute**, defaulting to hourly display. Each selection immediately changes
that panel's numeric rate and unit, for example `XP/h` or `XP/min`; Honor and
Reputation use the same independent preference. Changes persist through the
[settings store](stores.md) across reloads and logins. Rate selection preserves
tracking totals, duration and pause state; large numbers keep their abbreviation.
The session tooltip still lists both rates.

Hiding a panel keeps its session running. The form follows visibility changes
from the minimap menu and panel X and reads saved preferences silently when
reopened. Reposition the minimap button by dragging it; settings have no angle
control.

The panel has one centered footer action, **Close**, at 30% of the
available footer width, and an always-visible
X. Drag its background, including
the title area, to move it; fields and buttons handle their own mouse input.
The panel retains its position while the addon remains loaded.

Validate appearance, checkbox interaction, each rate dropdown, dragging and
both close controls in WoW Forever. After `/reload` and a normal logout/login,
confirm that panel visibility, selected rates and minimap position match saved preferences.
Lua simulation checks do not validate rendering or native mouse routing.
