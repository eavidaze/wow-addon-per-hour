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

function Components:CreatePanel(parent, settings)
    local frame = CreateFrame("Frame", settings.name, parent)
    frame:SetSize(settings.width, settings.height)
    -- Use the same border and translucent background as Blizzard's Edit Mode.
    frame.Border = CreateFrame("Frame", nil, frame, "DialogBorderTranslucentTemplate")
    frame.Border:SetPoint("TOPLEFT", frame, "TOPLEFT")
    -- Keep half of the footer below the visible border, within the panel bounds.
    frame.Border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, settings.footerSize / 2 - DIALOG_BORDER_INSET)

    frame.TitleText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.TitleText:SetText(settings.title)
    frame.TitleText:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -15)
    frame.TitleText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -15, -15)
    frame.TitleText:SetJustifyH("CENTER")
    frame.TitleText:SetWordWrap(false)
    frame.TitleText:SetTextColor(unpack(Theme.text))

    frame.CloseButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.CloseButton:SetSize(24, 24)
    frame.CloseButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 2, 2)
    SetupCloseButtonFade(frame)
    return frame
end

function Components:CreateStatusButton(parent, text, height)
    local button = CreateFrame("Button", nil, parent, "SharedGoldRedButtonSmallTemplate")
    for _, section in ipairs({ button.Left, button.Center, button.Right }) do
        section:SetVertexColor(unpack(Theme.gold.buttonTint))
    end
    button:SetHeight(height)
    -- The gold template creates its font string on the first SetText call.
    button:SetText(text)
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

function Components:CreateRateDisplay(parent, unitText)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(24)
    frame.Value = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    frame.Value:SetPoint("LEFT")
    frame.Value:SetWordWrap(false)
    frame.Unit = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
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
end
