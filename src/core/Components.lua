local Theme = PerHour.Theme
local Components = {}
PerHour.Components = Components
Components.RenameButtonSize = {width=72,height=24}

local CIRCULAR_ICON = {
    size = 24, iconSize = 18, backgroundSize = 20,
    maskTexture = "Interface\\CharacterFrame\\TempPortraitAlphaMask",
    borderTexture = "Interface\\Minimap\\MiniMap-TrackingBorder",
    borderSize = 46, borderOffset = 9,
}
local DIALOG_BORDER_INSET = 7
local CONTENT_PADDING, FIELD_GAP = 16, 8
local HEADER_SPACING = 12
local FOOTER_PADDING, ACTION_GAP = 8, 3
local TITLE_BOX_MIN_WIDTH = 64 -- Two native 32 px corner textures.
local NORMAL_BUTTON = { minWidth=96, height=28, textPadding=32 }
local TITLE_STYLES = {
    small = { font = "GameFontHighlightSmall", fontSize = 10, headerHeight = 36 },
    default = { font = "GameFontNormalLarge", headerHeight = 56 },
}

local function CreatePanelTitle(frame, settings, style)
    local small = settings.titleSize == "small"
    if small then
        frame.TitleText = frame:CreateFontString(nil, "OVERLAY", style.font)
        local font,_,flags = frame.TitleText:GetFont()
        frame.TitleText:SetFont(font,style.fontSize,flags)
        frame.TitleText:SetText(settings.title)
        frame.TitleText:SetPoint("TOP",frame.Border.Bg,"TOP",0,-6)
        frame.TitleText:SetJustifyH("CENTER")
        frame.TitleText:SetWordWrap(false)
        frame.TitleText:SetTextColor(unpack(Theme.gold.subtleText))
        return
    end
    do
        frame.BrandText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        frame.BrandText:SetText("powered by Per Hour")
        frame.BrandText:SetTextColor(0.6, 0.6, 0.6)
        frame.BrandText:SetPoint("BOTTOMRIGHT", frame.Border.Bg, "TOPRIGHT", -FOOTER_PADDING - 12, -21)
        frame.BrandText:SetJustifyH("RIGHT")
        frame.BrandText:SetWordWrap(false)
        local brandFont, brandSize, brandFlags = frame.BrandText:GetFont()
        if brandFont then frame.BrandText:SetFont(brandFont, math.min(brandSize, 9), brandFlags) end
    end
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

-- Install after the panel's controls and tooltip scripts have been created.
function Components:SetupCloseButtonHover(frame)
    local close = frame.CloseButton
    local function Refresh()
        close:SetShown(frame:IsVisible() and (frame:IsMouseOver() or (close:IsShown() and close:IsMouseOver())))
    end
    local function Enter()
        if frame:IsVisible() then close:Show() end
    end
    local function HookRegion(region)
        -- Binding mouse scripts can enable input. Leave decorative children passive
        -- so the panel still receives hover, clicks and drag gestures through them.
        if region:IsMouseMotionEnabled() then
            local clicks = region:IsMouseClickEnabled()
            region:HookScript("OnEnter", Enter)
            region:HookScript("OnLeave", Refresh)
            region:SetMouseClickEnabled(clicks)
        end
        for _, child in ipairs({ region:GetChildren() }) do HookRegion(child) end
    end
    -- Child buttons consume mouse motion; their events must also keep the X visible.
    HookRegion(frame)
    frame:HookScript("OnHide", function() close:Hide() end)
    frame:HookScript("OnShow", Refresh)
    Refresh()
end

-- Both panels and form groups grow when fields are added or resized.
function Components:SetupFieldStack(frame, content, baseHeight, gap)
    frame.Fields, frame.ContentHeight, frame.LayingOutFields = {}, 0, false
    function frame:LayoutFields()
        if self.LayingOutFields then return end
        self.LayingOutFields = true
        local height = 0
        for _, field in ipairs(self.Fields) do
            if field:IsShown() then
                if height > 0 then height = height + gap end
                field:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -height)
                field:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -height)
                height = height + field:GetHeight()
            end
        end
        self.ContentHeight = height
        self:SetHeight(baseHeight + height)
        self.LayingOutFields = false
    end
    function frame:AddField(field)
        table.insert(self.Fields, field)
        field:HookScript("OnSizeChanged", function() self:LayoutFields() end)
        field:HookScript("OnShow", function() self:LayoutFields() end)
        field:HookScript("OnHide", function() self:LayoutFields() end)
        self:LayoutFields()
        return field
    end
end

function Components:CreatePanel(parent, settings)
    local titleStyle = assert(TITLE_STYLES[settings.titleSize or "default"], "unsupported panel title size")
    local frame = CreateFrame("Frame", settings.name, parent)
    -- Composite each window as a unit so unrelated child controls cannot render
    -- between its background and content. Let the client raise clicked windows.
    frame:SetToplevel(true)
    frame:SetFlattensRenderLayers(true)
    local footerSize = settings.footerSize or 28
    -- The native box extends 28 px below the panel top; leave 12 px before content.
    local headerHeight = settings.titleSize == "small" and titleStyle.headerHeight
        or settings.titleBox and 40 or math.max(settings.form and 56 or 0, titleStyle.headerHeight)
    local footerSpacing = CONTENT_PADDING
    if settings.contentSpacing ~= nil then
        local spacing = settings.contentSpacing
        assert(type(spacing) == "number" and spacing >= 0 and spacing < math.huge,
            "Panel content spacing must be finite and nonnegative")
        headerHeight = headerHeight - HEADER_SPACING + spacing
        footerSpacing = spacing + 2
    end
    local baseHeight = headerHeight + footerSpacing + footerSize
    frame:SetSize(settings.width, settings.height or baseHeight)
    frame.FooterSize = footerSize
    frame.FooterMinWidth = settings.titleSize == "small" and 130 or false
    -- Retain the border geometry; use Options' native opaque gray background.
    frame.Border = CreateFrame("Frame", nil, frame, "DialogBorderTranslucentTemplate")
    frame.Border:SetPoint("TOPLEFT", frame, "TOPLEFT")
    -- Keep half of the footer below the visible border, within the panel bounds.
    frame.Border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, footerSize / 2 - DIALOG_BORDER_INSET)
    frame.Border.Bg:Hide()
    frame.Background = CreateFrame("Frame", nil, frame, "FlatPanelBackgroundTemplate")
    frame.Background:SetFrameLevel(frame:GetFrameLevel())
    frame.Background:SetAllPoints(frame.Border.Bg)

    frame.TitleBox = false
    CreatePanelTitle(frame, settings, titleStyle)

    frame.CloseButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.CloseButton:SetSize(24, 24)
    frame.CloseButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 2, 2)
    frame.CloseButton:SetScript("OnClick", function()
        if settings.onClose then settings.onClose(frame) end
        frame:Hide()
    end)
    frame.CloseButton:EnableMouse(true)

    frame.Content = CreateFrame("Frame", nil, frame)
    frame.ContentInsets = {left=settings.form and 32 or DIALOG_BORDER_INSET+FOOTER_PADDING,
        right=DIALOG_BORDER_INSET+FOOTER_PADDING,top=headerHeight,bottom=footerSize+footerSpacing}
    frame.Content:SetPoint("TOPLEFT", frame, "TOPLEFT", frame.ContentInsets.left, -frame.ContentInsets.top)
    frame.Content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -frame.ContentInsets.right, frame.ContentInsets.bottom)
    frame.ContentComponent = false
    self:SetupFieldStack(frame, frame.Content, baseHeight,
        settings.form and 20 or FIELD_GAP)

    -- A custom component uses the panel's content region; forms keep AddField's layout.
    function frame:SetContent(component)
        if self.ContentComponent and self.ContentComponent ~= component then self.ContentComponent:Hide() end
        self.ContentComponent = component
        self.Content:ClearAllPoints()
        if self.TitleBox then
            self.Content:SetPoint("TOP", self.TitleBox, "BOTTOM", 0, 0)
        else
            self.Content:SetPoint("TOP", self, "TOP", 0, -headerHeight)
        end
        if self.ActionBar then
            self.Content:SetPoint("BOTTOM", self.ActionBar, "TOP", 0, 0)
        else
            self.Content:SetPoint("BOTTOM", self, "BOTTOM", 0, footerSize + footerSpacing)
        end
        self.Content:SetPoint("LEFT", self, "LEFT", 15, 0)
        self.Content:SetPoint("RIGHT", self, "RIGHT", -15, 0)
        component:SetParent(self.Content)
        component:ClearAllPoints()
        component:SetPoint("CENTER", self.Content, "CENTER", 0, self.TitleBox and 1 or 0)
        component:Show()
    end

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
    if settings.titleSize ~= "small" then self:SetupPanelWindow(frame) end
    return frame
end

function Components:CreateButton(parent, text, height, frameType)
    local button = CreateFrame(frameType or "Button", nil, parent, "SharedGoldRedButtonSmallTemplate")
    for _, section in ipairs({ button.Left, button.Center, button.Right }) do
        section:SetVertexColor(unpack(Theme.gold.buttonTint))
    end
    button:SetHeight(height or NORMAL_BUTTON.height)
    -- The gold template creates its font string on the first SetText call.
    button:SetText(text)
    local label=button:GetFontString()
    button:SetWidth(math.max(NORMAL_BUTTON.minWidth,(label and label:GetStringWidth() or 0)+NORMAL_BUTTON.textPadding))
    return button
end

function Components:CreateRenameButton(parent)
    local size=self.RenameButtonSize
    local button=self:CreateButton(parent,"Rename",size.height)
    button:SetWidth(size.width)
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

-- Footer text actions use normal button sizes; icons keep their circular dimensions.
-- A menu is optional, and toggle state belongs to the caller (isOn/onToggle).
function Components:CreatePanelActions(frame, actions)
    frame.Actions = {}
    local buttons,requiredWidth = {},0
    for index, action in ipairs(actions) do
        local button
        local circular = action.menu ~= nil or action.type == "icon" or action.type == "toggle"
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
        local width=action.width or (circular and CIRCULAR_ICON.size) or button:GetWidth()
        button:SetWidth(width)
        requiredWidth=requiredWidth+width
        buttons[index]={button=button,width=width}
        frame.Actions[action.key or index] = button
    end
    requiredWidth=requiredWidth+ACTION_GAP*math.max(0,#buttons-1)
    -- Anchor to the visible background, whose insets are owned by the template.
    local footer = CreateFrame("Frame", nil, frame)
    frame.ActionBar = footer
    footer:SetSize(frame.FooterMinWidth and math.max(frame.FooterMinWidth,requiredWidth)
        or frame:GetWidth()-FOOTER_PADDING*2,frame.FooterSize)
    if frame.FooterMinWidth then
        footer:SetPoint("CENTER", frame.Border.Bg, "BOTTOM", 0, 0)
    else
        footer:SetPoint("LEFT", frame.Border.Bg, "BOTTOMLEFT", FOOTER_PADDING, 0)
        footer:SetPoint("RIGHT", frame.Border.Bg, "BOTTOMRIGHT", -FOOTER_PADDING, 0)
    end
    local function Layout(_,width)
        local visibleWidth,count=0,0
        for _,item in ipairs(buttons) do
            if item.button:IsShown() then visibleWidth=visibleWidth+item.width; count=count+1 end
        end
        visibleWidth=visibleWidth+ACTION_GAP*math.max(0,count-1)
        local offset=(width-visibleWidth)/2
        for _,item in ipairs(buttons) do
            if item.button:IsShown() then
                item.button:ClearAllPoints()
                item.button:SetPoint("LEFT",footer,"LEFT",offset,0)
                offset=offset+item.width+ACTION_GAP
            end
        end
    end
    function frame:LayoutActions() Layout(footer,footer:GetWidth()) end
    footer:SetScript("OnSizeChanged",Layout)
    Layout(footer,footer:GetWidth())
    if frame.ContentComponent then frame:SetContent(frame.ContentComponent) end
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
    function frame:SetRate(value, unit, decimals)
        local rounded = Utils:RoundValue(value, decimals or 0)
        local width = self:GetParent():GetWidth()
        if self.DisplayValue == rounded and self.DisplayUnit == unit and self.AvailableWidth == width then return end
        self.DisplayValue, self.DisplayUnit, self.AvailableWidth = rounded, unit, width
        if self.Unit:GetText() ~= unit then self.Unit:SetText(unit) end
        self.Value:SetText(Utils:DisplayNumber(rounded))
        if self.Value:GetStringWidth() + self.Unit:GetStringWidth() + 4 > width then
            self.Value:SetText(AbbreviateLargeNumbers(rounded))
        end
        self:SetWidth(self.Value:GetStringWidth() + self.Unit:GetStringWidth() + 4)
    end
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
    local texture=settings.menu and Theme.icons.menu or settings.texture
    if texture then
        frame.Icon:SetTexture(texture)
        frame.Icon:SetTexCoord(0, 1, 0, 1)
    end
    if settings.atlas and not settings.menu then frame.Icon:SetAtlas(settings.atlas) end
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
