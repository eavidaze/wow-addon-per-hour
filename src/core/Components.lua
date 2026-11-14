local Theme = PerHour.Theme
local Components = {}
PerHour.Components = Components

local CIRCULAR_ICON = {
    size = 24, iconSize = 18, backgroundSize = 20,
    maskTexture = "Interface\\CharacterFrame\\TempPortraitAlphaMask",
    borderTexture = "Interface\\Minimap\\MiniMap-TrackingBorder",
    borderSize = 46, borderOffset = 9,
}
local DIALOG_BORDER_INSET = 7
local CONTENT_PADDING, FIELD_GAP = 16, 8
local FOOTER_PADDING, ACTION_GAP = 8, 3
local TITLE_BOX_MIN_WIDTH = 64 -- Two native 32 px corner textures.
local TITLE_STYLES = {
    small = { font = "GameFontHighlight", headerHeight = 40, boxPadding = 48 },
    default = { font = "GameFontNormalLarge", headerHeight = 56 },
}

local function CreatePanelTitle(frame, settings, style)
    if settings.titleBox then
        -- Reuse Forever's Game Menu header, including its native corner artwork.
        local box = CreateFrame("Frame", nil, frame, "DialogHeaderTemplate")
        frame.TitleBox, frame.TitleText = box, box.Text
        box.headerTextPadding = style.boxPadding or box.headerTextPadding
        box:SetHeaderFont(style.font)
        box:Setup(settings.title)
        frame.TitleText:ClearAllPoints()
        frame.TitleText:SetPoint("CENTER", box, "CENTER", 0, 0)
        local function LayoutTitleBox()
            local padding = box.headerTextPadding
            local width = math.min(math.max(TITLE_BOX_MIN_WIDTH, frame.TitleText:GetStringWidth() + padding),
                math.max(TITLE_BOX_MIN_WIDTH, frame:GetWidth() - 48))
            box:SetWidth(width)
            frame.TitleText:SetWidth(width - padding)
        end
        frame:HookScript("OnSizeChanged", LayoutTitleBox)
        LayoutTitleBox()
    else
        frame.TitleText = frame:CreateFontString(nil, "OVERLAY", style.font)
        frame.TitleText:SetText(settings.title)
        frame.TitleText:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -15)
        frame.TitleText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -15, -15)
    end
    frame.TitleText:SetJustifyH("CENTER")
    frame.TitleText:SetWordWrap(false)
    frame.TitleText:SetTextColor(unpack(settings.titleBox and Theme.gold.text or Theme.text))
end

local function IsCursorOver(frame)
    if not frame:IsVisible() then return false end
    local left, top = frame:GetLeft(), frame:GetTop()
    if not left or not top then return false end
    local x, y = GetCursorPosition()
    local scale = frame:GetEffectiveScale()
    x, y = x / scale, y / scale
    return x >= left and x <= left + frame:GetWidth()
        and y <= top and y >= top - frame:GetHeight()
end

local function SetupCloseButtonFade(frame)
    local close = frame.CloseButton
    local function Reset()
        close:SetAlpha(0)
        close:EnableMouse(false)
    end
    Reset()
    -- Poll geometry so hovering child controls also counts as hovering the panel.
    -- Keep this on the close button; the panel's OnUpdate is used for dragging.
    close:SetScript("OnUpdate", function(self, elapsed)
        local alpha = self:GetAlpha()
        local hovered = IsCursorOver(frame) or (alpha > 0 and IsCursorOver(self))
        if hovered then
            alpha = math.min(1, alpha + elapsed / Theme.motion.fadeIn)
        else
            alpha = math.max(0, alpha - elapsed / Theme.motion.fadeOut)
        end
        self:SetAlpha(alpha)
        self:EnableMouse(alpha > 0)
    end)
    frame:HookScript("OnHide", Reset)
end

-- Both panels and form groups grow when fields are added or resized.
function Components:SetupFieldStack(frame, content, baseHeight, gap)
    frame.Fields, frame.ContentHeight, frame.LayingOutFields = {}, 0, false
    function frame:LayoutFields()
        if self.LayingOutFields then return end
        self.LayingOutFields = true
        local height = 0
        for index, field in ipairs(self.Fields) do
            if index > 1 then height = height + gap end
            field:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -height)
            field:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -height)
            height = height + field:GetHeight()
        end
        self.ContentHeight = height
        self:SetHeight(baseHeight + height)
        self.LayingOutFields = false
    end
    function frame:AddField(field)
        table.insert(self.Fields, field)
        field:HookScript("OnSizeChanged", function() self:LayoutFields() end)
        self:LayoutFields()
        return field
    end
end

function Components:CreatePanel(parent, settings)
    local titleStyle = assert(TITLE_STYLES[settings.titleSize or "default"], "unsupported panel title size")
    local frame = CreateFrame("Frame", settings.name, parent)
    local footerSize = settings.footerSize or 28
    -- The native box extends 28 px below the panel top; leave 12 px before content.
    local headerHeight = settings.titleBox and 40 or math.max(settings.form and 56 or 0, titleStyle.headerHeight)
    frame:SetSize(settings.width, settings.height or headerHeight + CONTENT_PADDING + footerSize)
    frame.FooterSize = footerSize
    -- Use the same border and translucent background as Blizzard's Edit Mode.
    frame.Border = CreateFrame("Frame", nil, frame, "DialogBorderTranslucentTemplate")
    frame.Border:SetPoint("TOPLEFT", frame, "TOPLEFT")
    -- Keep half of the footer below the visible border, within the panel bounds.
    frame.Border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, footerSize / 2 - DIALOG_BORDER_INSET)

    CreatePanelTitle(frame, settings, titleStyle)

    frame.CloseButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.CloseButton:SetSize(24, 24)
    frame.CloseButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 2, 2)
    frame.CloseButton:SetScript("OnClick", function()
        if settings.onClose then settings.onClose(frame) end
        frame:Hide()
    end)
    if not settings.closeAlwaysVisible then SetupCloseButtonFade(frame) end

    frame.Content = CreateFrame("Frame", nil, frame)
    frame.Content:SetPoint("TOPLEFT", frame, "TOPLEFT", settings.form and 32 or 15, -headerHeight)
    frame.Content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, footerSize + CONTENT_PADDING)
    self:SetupFieldStack(frame, frame.Content, headerHeight + CONTENT_PADDING + footerSize,
        settings.form and 20 or FIELD_GAP)

    if settings.draggable then
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:SetClampedToScreen(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        frame:HookScript("OnHide", function(self) self:StopMovingOrSizing() end)
    end
    if settings.actions then self:CreatePanelActions(frame, settings.actions) end
    return frame
end

function Components:CreateButton(parent, text, height, frameType)
    local button = CreateFrame(frameType or "Button", nil, parent, "SharedGoldRedButtonSmallTemplate")
    for _, section in ipairs({ button.Left, button.Center, button.Right }) do
        section:SetVertexColor(unpack(Theme.gold.buttonTint))
    end
    button:SetHeight(height)
    -- The gold template creates its font string on the first SetText call.
    button:SetText(text)
    return button
end

function Components:CreateStatusButton(parent, text, height)
    local button = self:CreateButton(parent, text, height)
    local label = button:GetFontString()
    label:ClearAllPoints()
    -- Center the label together with the 20 px notification atlas.
    label:SetPoint("CENTER", button, "CENTER", 10, 0)
    button.Indicator = button:CreateTexture(nil, "OVERLAY")
    button.Indicator:SetSize(20, 20)
    button.Indicator:SetPoint("RIGHT", label, "LEFT", 0, 0)
    button.Indicator:SetAtlas("UI-HUD-MicroMenu-Communities-Icon-Notification")
    button.Indicator:SetDesaturated(true)
    return button
end

-- Text actions share the remaining space; icons keep their circular dimensions.
-- A menu is optional, and toggle state belongs to the caller (isOn/onToggle).
function Components:CreatePanelActions(frame, actions)
    frame.Actions = {}
    local buttons, fixedWidth, relativeWidth, flexibleCount = {}, 0, 0, 0
    for index, action in ipairs(actions) do
        local button
        local circular = action.type == "icon" or action.type == "toggle"
        if circular then
            button = CreateFrame(action.menu and "DropdownButton" or "Button", nil, frame)
            self:CreateCircularIcon(button, action)
            button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
        elseif action.type == "status" then
            button = self:CreateStatusButton(frame, action.text, frame.FooterSize)
        else
            button = self:CreateButton(frame, action.text, frame.FooterSize)
        end
        if action.menu then
            button:SetupMenu(action.menu)
            frame:HookScript("OnHide", function() button:CloseMenu() end)
        elseif action.type == "toggle" then
            function button:Refresh()
                local enabled = action.isOn()
                self.Icon:SetVertexColor(unpack(enabled and Theme.toggle.on or Theme.toggle.off))
                local texture
                if enabled then texture = action.onTexture else texture = action.offTexture end
                if texture or action.texture then
                    self.Icon:SetTexture(texture or action.texture)
                elseif action.atlas then
                    self.Icon:SetAtlas(action.atlas)
                end
            end
            button:SetScript("OnClick", function(self)
                action.onToggle(not action.isOn(), frame)
                self:Refresh()
            end)
            frame:HookScript("OnShow", function() button:Refresh() end)
            button:Refresh()
        elseif action.onClick then
            button:SetScript("OnClick", function(self) action.onClick(frame, self) end)
        end
        if action.tooltip then self:SetButtonTooltip(button, action.tooltip) end
        local width = action.width or (circular and CIRCULAR_ICON.size)
        if not width and not action.widthFraction and action.fullWidth == false then
            local label = button:GetFontString()
            width = math.max(80, (label and label:GetStringWidth() or 0) + 32)
        end
        local widthFraction = not width and action.widthFraction
        if width then
            button:SetWidth(width)
            fixedWidth = fixedWidth + width
        elseif widthFraction then
            relativeWidth = relativeWidth + widthFraction
        else
            flexibleCount = flexibleCount + 1
        end
        buttons[index] = { button = button, width = width, widthFraction = widthFraction, align = action.align }
        frame.Actions[action.key or index] = button
    end
    -- Anchor to the visible background, whose insets are owned by the template.
    local footer = CreateFrame("Frame", nil, frame)
    frame.ActionBar = footer
    footer:SetSize(frame:GetWidth() - FOOTER_PADDING * 2, frame.FooterSize)
    footer:SetPoint("LEFT", frame.Border.Bg, "BOTTOMLEFT", FOOTER_PADDING, 0)
    footer:SetPoint("RIGHT", frame.Border.Bg, "BOTTOMRIGHT", -FOOTER_PADDING, 0)
    local function Layout(_, width)
        local available = width * (1 - relativeWidth) - ACTION_GAP * (#buttons - 1) - fixedWidth
        local offset = 0
        for index, item in ipairs(buttons) do
            local button = item.button
            local buttonWidth = item.width or (item.widthFraction and width * item.widthFraction)
                or math.max(0, available / flexibleCount)
            button:SetWidth(buttonWidth)
            button:ClearAllPoints()
            if #buttons == 1 and item.align == "CENTER" then
                button:SetPoint("CENTER", footer, "CENTER", 0, 0)
            else
                button:SetPoint("LEFT", footer, "LEFT", offset, 0)
            end
            if not item.width and not item.widthFraction then
                local nextButton = buttons[index + 1]
                if nextButton then
                    button:SetPoint("RIGHT", nextButton.button, "LEFT", -ACTION_GAP, 0)
                else
                    button:SetPoint("RIGHT", footer, "RIGHT", 0, 0)
                end
            end
            offset = offset + buttonWidth + ACTION_GAP
        end
    end
    footer:SetScript("OnSizeChanged", Layout)
    Layout(footer, footer:GetWidth())
end

function Components:CreateCheckbox(parent, settings)
    local field = CreateFrame("Frame", nil, parent)
    field:SetHeight(28)
    field:EnableMouse(true)
    field.Checkbox = CreateFrame("CheckButton", nil, field, "UICheckButtonTemplate")
    field.Checkbox:SetSize(24, 24)
    field.Checkbox:SetPoint("LEFT", field, "LEFT", 0, 0)
    field.Checkbox:SetChecked(settings.checked == true)
    field.Label = field:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    field.Label:SetText(settings.label)
    field.Label:SetPoint("LEFT", field.Checkbox, "RIGHT", 6, 0)
    field.Label:SetPoint("RIGHT", field, "RIGHT", 0, 0)
    field.Label:SetJustifyH("LEFT")
    field.Checkbox:SetScript("OnClick", function(self)
        if settings.onChanged then settings.onChanged(self:GetChecked()) end
    end)
    -- The label is clickable without making the field a drag handle.
    field:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then field.Checkbox:Click() end
    end)
    return field
end

function Components:CreateRateDisplay(parent, unitText)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(24)
    frame.Value = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    frame.Value:SetTextColor(unpack(Theme.gold.text))
    frame.Value:SetPoint("LEFT")
    frame.Value:SetWordWrap(false)
    frame.Unit = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.Unit:SetTextColor(unpack(Theme.gold.text))
    frame.Unit:SetPoint("BOTTOMLEFT", frame.Value, "BOTTOMRIGHT", 4, 0)
    frame.Unit:SetText(unitText)
    return frame
end

-- Add circular artwork to a caller-owned Frame or Button; interaction stays with the caller.
function Components:CreateCircularIcon(frame, settings)
    local style = CIRCULAR_ICON
    frame:SetSize(style.size, style.size)
    if settings.background then
        frame.Background = frame:CreateTexture(nil, "BACKGROUND")
        frame.Background:SetSize(style.backgroundSize, style.backgroundSize)
        frame.Background:SetPoint("CENTER")
        frame.Background:SetColorTexture(unpack(Theme.circularBackground))
    end
    frame.Icon = frame:CreateTexture(nil, "ARTWORK")
    local iconSize = settings.iconSize or style.iconSize
    frame.Icon:SetSize(iconSize, iconSize)
    frame.Icon:SetPoint("CENTER")
    if settings.texture then
        frame.Icon:SetTexture(settings.texture)
        frame.Icon:SetTexCoord(0, 1, 0, 1)
    end
    if settings.atlas then frame.Icon:SetAtlas(settings.atlas) end
    local maskedTexture = settings.background and frame.Background or frame.Icon
    local mask = frame:CreateMaskTexture()
    mask:SetTexture(style.maskTexture, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(maskedTexture)
    maskedTexture:AddMaskTexture(mask)
    frame.Border = frame:CreateTexture(nil, "OVERLAY")
    frame.Border:SetTexture(style.borderTexture)
    frame.Border:SetVertexColor(unpack(Theme.gold.ringTint))
    frame.Border:SetSize(style.borderSize, style.borderSize)
    -- TrackingBorder includes transparent padding to the right and below its ring.
    frame.Border:SetPoint("CENTER", frame, "CENTER", style.borderOffset, -style.borderOffset)
end

function Components:SetButtonTooltip(button, getText)
    button:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(getText())
        GameTooltip:Show()
    end)
    button:HookScript("OnLeave", function() GameTooltip:Hide() end)
    button:HookScript("OnHide", function(self)
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
end
