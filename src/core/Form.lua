local Components = PerHour.Components
local Theme = PerHour.Theme
local ROW_HEIGHT, GROUP_HEADER = 32, 40
local CONTROL_WIDTH = 300

local function IsFinite(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function FindOption(options, value)
    for _, option in ipairs(options) do
        if option.value == value then return option end
    end
end

local function CreateSlider(field, settings)
    local slider = CreateFrame("Frame", nil, field.ControlArea, "MinimalSliderWithSteppersTemplate")
    slider:SetPoint("LEFT", field.ControlArea, "LEFT", 0, 0)
    local right = MinimalSliderWithSteppersMixin.Label.Right
    slider:Init(settings.value or settings.min, settings.min, settings.max,
        (settings.max - settings.min) / (settings.step or 1), {
            [right] = function(value)
                return string.format(settings.format or "%g", value) .. (settings.suffix or "")
            end,
        })
    field.ValueText = slider.RightText
    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        if not field.Updating then field:SetValue(value) end
    end)
    return slider
end

function Components:CreateFormField(parent, settings, inline)
    assert(settings.type == "checkbox" or settings.type == "select" or settings.type == "slider"
        or settings.type == "text" or settings.type == "group", "Unsupported form field type")
    if settings.type == "slider" then
        assert(IsFinite(settings.min) and IsFinite(settings.max) and settings.min < settings.max,
            "Numeric fields require explicit finite min and max, with min < max")
        assert(IsFinite(settings.step or 1) and (settings.step or 1) > 0, "Slider step must be positive")
    end
    local field = CreateFrame("Frame", nil, parent)
    field:SetHeight(ROW_HEIGHT)
    field:EnableMouse(true)
    field.Updating = false
    field.ControlArea = CreateFrame("Frame", nil, field)
    local controlWidth = settings.controlWidth
        or (inline and settings.type == "checkbox" and 32) or CONTROL_WIDTH
    field.ControlArea:SetSize(controlWidth, ROW_HEIGHT)
    field.ControlArea:SetPoint("RIGHT", field, "RIGHT", 0, 0)
    if not inline then
        field.Label = field:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        field.Label:SetText(settings.label)
        field.Label:SetTextColor(unpack(Theme.formLabel))
        field.Label:SetPoint("LEFT", field, "LEFT", 0, 0)
        field.Label:SetPoint("RIGHT", field.ControlArea, "LEFT", -12, 0)
        field.Label:SetJustifyH("LEFT")
        field.Label:SetWordWrap(false)
    end

    if settings.type == "group" then
        field.Fields = {}
        local width = 0
        for index, childSettings in ipairs(settings.fields or {}) do
            local child = self:CreateFormField(field.ControlArea, childSettings, true)
            if index > 1 then width = width + (settings.spacing or 8) end
            child:SetWidth(child.ControlArea:GetWidth())
            child:SetPoint("LEFT", field.ControlArea, "LEFT", width, 0)
            width = width + child:GetWidth()
            table.insert(field.Fields, child)
        end
        field.ControlArea:SetWidth(width)
        return field
    end

    function field:GetValue() return self.Value end
    function field:SetValue(value, silent)
        local option
        if settings.type == "select" then
            option = FindOption(settings.options, value)
            if not option then return end
        elseif settings.type == "slider" then
            local step = settings.step or 1
            value = tonumber(value)
            if not value or value ~= value then return end
            value = settings.min + math.floor((value - settings.min) / step + 0.5) * step
            value = math.max(settings.min, math.min(settings.max, value))
        elseif settings.type == "checkbox" then
            value = value == true
        else
            value = tostring(value or "")
        end
        local previous = self.Value
        self.Value, self.Updating = value, true
        if settings.type == "checkbox" then
            self.Control:SetChecked(value)
        elseif settings.type == "slider" then
            self.Control:SetValue(value)
        elseif settings.type == "select" then
            self.Control:GenerateMenu()
        else
            self.Control:SetText(value)
        end
        self.Updating = false
        if not silent and previous ~= value and settings.onChanged then settings.onChanged(value) end
    end

    if settings.type == "checkbox" then
        field.Control = CreateFrame("CheckButton", nil, field.ControlArea, "SettingsCheckboxTemplate")
        field.Control:SetPoint("LEFT", field.ControlArea, "LEFT", 0, 0)
        field.Control:Init(settings.value == true, function() SettingsTooltip:SetText(settings.label) end)
        field.Control:RegisterCallback(SettingsCheckboxMixin.Event.OnValueChanged, function(_, value)
            field:SetValue(value)
        end)
        field:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" then field.Control:Click() end
        end)
    elseif settings.type == "select" then
        field.Value = settings.value or settings.options[1].value
        field.Selector = CreateFrame("Frame", nil, field.ControlArea, "SettingsDropdownWithButtonsTemplate")
        -- Native steppers extend beyond the selector frame on both sides.
        field.Selector:SetPoint("CENTER", field.ControlArea, "CENTER", 0, 0)
        local control = field.Selector.Dropdown
        field.Control = control
        control:SetWidth(220)
        control:SetupMenu(function(_, root)
            for _, option in ipairs(settings.options) do
                root:CreateRadio(option.label, function(value) return field:GetValue() == value end,
                    function(value) field:SetValue(value) end, option.value)
            end
        end)
        field.Selector:SetSteppersShown(true)
        control:HookScript("OnHide", function(self) self:CloseMenu() end)
    elseif settings.type == "slider" then
        field.Control = CreateSlider(field, settings)
    else
        field.Control = CreateFrame("EditBox", nil, field.ControlArea, "InputBoxTemplate")
        field.Control:SetSize(220, 20)
        field.Control:SetPoint("LEFT", field.ControlArea, "LEFT", 6, 0)
        field.Control:SetAutoFocus(false)
        field.Control:SetMaxLetters(settings.maxLength or 64)
        field.Control:SetScript("OnEnterPressed", function(self)
            field:SetValue(self:GetText())
            self:ClearFocus()
        end)
        field.Control:SetScript("OnEditFocusLost", function(self) field:SetValue(self:GetText()) end)
        field.Control:SetScript("OnEscapePressed", function(self)
            self:SetText(field:GetValue())
            self:ClearFocus()
        end)
        field.Control:SetScript("OnHide", function(self) self:ClearFocus() end)
    end
    local value = settings.value
    if value == nil then
        if settings.type == "select" then value = settings.options[1].value
        elseif settings.type == "slider" then value = settings.min end
    end
    field:SetValue(value, true)
    return field
end

function Components:CreateFormGroup(parent, settings)
    local group = CreateFrame("Frame", nil, parent)
    group:SetHeight(GROUP_HEADER)
    group.TitleText = group:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    group.TitleText:SetText(settings.title)
    group.TitleText:SetTextColor(unpack(Theme.text))
    group.TitleText:SetPoint("TOPLEFT", group, "TOPLEFT", 0, 0)
    group.TitleText:SetPoint("TOPRIGHT", group, "TOPRIGHT", 0, 0)
    group.TitleText:SetJustifyH("LEFT")
    group.TitleText:SetWordWrap(false)
    group.Content = CreateFrame("Frame", nil, group)
    group.Content:SetPoint("TOPLEFT", group, "TOPLEFT", 16, -GROUP_HEADER)
    group.Content:SetPoint("BOTTOMRIGHT", group, "BOTTOMRIGHT", 0, 0)
    self:SetupFieldStack(group, group.Content, GROUP_HEADER, 8)
    local addField = group.AddField
    function group:AddField(fieldSettings)
        return addField(self, Components:CreateFormField(self.Content, fieldSettings))
    end
    for _, fieldSettings in ipairs(settings.fields or {}) do group:AddField(fieldSettings) end
    return group
end
