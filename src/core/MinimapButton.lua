local PerHour = PerHour
local Theme = PerHour.Theme
local button = CreateFrame("DropdownButton", "PerHourMinimapButton", Minimap)
PerHour.MinimapButton = button
-- This native tooltip uses the body font on every line, including the first.
local tooltip = GameNoHeaderTooltip
button.Tooltip = tooltip

button:SetSize(31, 31)
button:SetFrameStrata("MEDIUM")
button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
button:RegisterForDrag("LeftButton")
-- DropdownButton only accepts left mouse events by default. Enable both buttons
-- and hook the native handler so left-click still toggles its menu exactly once.
button:RegisterForMouse("LeftButtonDown", "LeftButtonUp", "RightButtonDown", "RightButtonUp")
button:HookScript("OnMouseDown", function(self, mouseButton)
    if mouseButton == "RightButton" then
        self:CloseMenu()
        GameTooltip:Hide()
        tooltip:Hide()
        PerHour.SettingsPanel:Show()
    end
end)

local icon = button:CreateTexture(nil, "BACKGROUND")
icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
icon:SetSize(20, 20)
-- Align the watch with the visible ring rather than its padded texture bounds.
icon:SetPoint("CENTER", button, "CENTER", 2, -1)

local border = button:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
border:SetSize(54, 54)
border:SetPoint("TOPLEFT")

local function UpdatePosition(angle)
    angle = angle or PerHour.Stores.Settings:GetMinimapAngle()
    button:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * (Minimap:GetWidth() / 2 + 5),
        math.sin(angle) * (Minimap:GetHeight() / 2 + 5))
end

function button:SetAngle(angle)
    PerHour.Stores.Settings:SetMinimapAngle(angle)
    UpdatePosition()
end

local function UpdateDragPosition()
    local x, y = GetCursorPosition()
    if x == button.DragCursorX and y == button.DragCursorY then return end
    button.DragCursorX, button.DragCursorY = x, y
    local centerX, centerY = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    button.DragAngle = math.atan2(y / scale - centerY, x / scale - centerX)
    UpdatePosition(button.DragAngle)
end

function button:SaveDragPosition()
    if button.DragAngle and button.DragAngle ~= PerHour.Stores.Settings:GetMinimapAngle() then
        PerHour.Stores.Settings:SetMinimapAngle(button.DragAngle)
    end
    button.DragAngle = false
end
button.DragAngle = false

button:SetScript("OnDragStart", function(self)
    self:CloseMenu()
    GameTooltip:Hide()
    tooltip:Hide()
    self.DragCursorX, self.DragCursorY = nil, nil
    self:SetScript("OnUpdate", UpdateDragPosition)
end)
button:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    UpdateDragPosition()
    self:SaveDragPosition()
end)
button:HookScript("OnHide", function(self)
    self:SetScript("OnUpdate", nil)
    self:SaveDragPosition()
    tooltip:Hide()
end)

button:HookScript("OnEnter", function(self)
    tooltip:SetOwner(self, "ANCHOR_LEFT")
    tooltip:ClearLines()
    tooltip:AddLine(Theme:GoldText("Left-click:") .. " Menu", 1, 1, 1)
    tooltip:AddLine(Theme:GoldText("Right-click:") .. " Settings", 1, 1, 1)
    tooltip:AddLine(Theme:GoldText("Drag:") .. " Move", 1, 1, 1)
    tooltip:Show()
end)
button:SetScript("OnLeave", function() tooltip:Hide() end)

function button:Init()
    UpdatePosition()
end
