local Components = PerHour.Components
local Theme = PerHour.Theme
local ROW_HEIGHT, GROUP_HEADER, SUBFIELD_INDENT = 32, 40, 24
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
    local function FormatValue(value)
        local text = type(settings.format) == "function" and settings.format(value)
            or string.format(settings.format or "%g", value)
        return text .. (settings.suffix or "")
    end
    local right = MinimalSliderWithSteppersMixin.Label.Right
    slider:Init(settings.value or settings.min, settings.min, settings.max,
        (settings.max - settings.min) / (settings.step or 1), {
            [right] = FormatValue,
        })
    field.ValueText = slider.RightText
    field.ValueText:ClearAllPoints()
    field.ValueText:SetPoint("RIGHT", field.ControlArea, "RIGHT", 0, 0)
    field.ValueText:SetJustifyH("LEFT")
    field.ValueText:SetWordWrap(false)
    function field:RefreshValueText()
        -- Reformat even when only the display unit changes, keeping long intermediate values inside the field.
        local valueWidth = 0
        for _, value in ipairs({ settings.min, settings.max, self.Value }) do
            self.ValueText:SetText(FormatValue(value))
            valueWidth = math.max(valueWidth, self.ValueText:GetStringWidth())
        end
        slider:SetWidth(self.ControlArea:GetWidth() - valueWidth - 4)
        self.ValueText:SetWidth(valueWidth)
    end
    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        if not field.Updating then field:SetValue(value) end
    end)
    return slider
end

local function SetupSubfields(field, settings)
    field.SubfieldStack = false
    function field:AddSubfield(childSettings)
        if not self.SubfieldStack then
            local stack = CreateFrame("Frame", nil, self)
            stack:SetPoint("TOPLEFT", self, "TOPLEFT", SUBFIELD_INDENT, -ROW_HEIGHT - 8)
            stack:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, -ROW_HEIGHT - 8)
            Components:SetupFieldStack(stack, stack, 0, 8)
            stack:HookScript("OnSizeChanged", function()
                local height = stack:GetHeight()
                self:SetHeight(ROW_HEIGHT + (height > 0 and 8 + height or 0))
            end)
            self.SubfieldStack, self.Subfields = stack, stack.Fields
        end
        local nested = {}
        for key, value in pairs(childSettings) do nested[key] = value end
        nested.controlWidth = nested.controlWidth or (self.ControlArea:GetWidth() - SUBFIELD_INDENT)
        return self.SubfieldStack:AddField(Components:CreateFormField(self.SubfieldStack, nested))
    end
    for _, childSettings in ipairs(settings.subfields or {}) do field:AddSubfield(childSettings) end
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
    field.ControlArea:SetPoint("TOPRIGHT", field, "TOPRIGHT", 0, 0)
    if not inline then
        field.Label = field:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        field.Label:SetText(settings.label)
        field.Label:SetTextColor(unpack(Theme.gold.text))
        field.Label:SetPoint("LEFT", field, "TOPLEFT", 0, -ROW_HEIGHT / 2)
        field.Label:SetPoint("RIGHT", field.ControlArea, "LEFT", -12, 0)
        field.Label:SetJustifyH("LEFT")
        field.Label:SetWordWrap(false)
    end

    if settings.type == "group" then
        field.Fields = {}
        local width = 0
        for index, childSettings in ipairs(settings.fields or {}) do
            if index > 1 then width = width + (settings.spacing or 8) end
            if childSettings.fill then
                local nested = {}
                for key, value in pairs(childSettings) do nested[key] = value end
                nested.controlWidth = field.ControlArea:GetWidth() - width
                childSettings = nested
            end
            local child = self:CreateFormField(field.ControlArea, childSettings, true)
            child:SetWidth(child.ControlArea:GetWidth())
            child:SetPoint("LEFT", field.ControlArea, "LEFT", width, 0)
            width = width + child:GetWidth()
            table.insert(field.Fields, child)
        end
        field.ControlArea:SetWidth(width)
        SetupSubfields(field, settings)
        return field
    end

    function field:GetValue() return self.Value end
    if settings.type == "select" then
        function field:SetOptions(options, value)
            settings.options = options
            self:SetValue(value, true)
        end
    end
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
            self:RefreshValueText()
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
        local control = field.Selector.Dropdown
        field.Control = control
        local stepperWidth = field.Selector.DecrementButton:GetWidth()
            + field.Selector.IncrementButton:GetWidth() + 10
        control:SetWidth(math.min(220, field.ControlArea:GetWidth() - stepperWidth))
        -- Align the outer left stepper with other controls, including nested rows.
        local inset = field.Selector.DecrementButton:GetWidth() + 5
            - (field.Selector:GetWidth() - control:GetWidth()) / 2
        field.Selector:SetPoint("LEFT", field.ControlArea, "LEFT", inset, 0)
        control:SetupMenu(function(_, root)
            if settings.maxMenuHeight then root:SetScrollMode(settings.maxMenuHeight) end
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
    SetupSubfields(field, settings)
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
