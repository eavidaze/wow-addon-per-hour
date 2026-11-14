local PerHour = PerHour
local button = CreateFrame("DropdownButton", "PerHourMinimapButton", Minimap)
PerHour.MinimapButton = button

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

local function UpdatePosition()
    local angle = PerHour.Stores.Settings:GetMinimapAngle()
    button:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * (Minimap:GetWidth() / 2 + 5),
        math.sin(angle) * (Minimap:GetHeight() / 2 + 5))
end

function button:SetAngle(angle)
    PerHour.Stores.Settings:SetMinimapAngle(angle)
    UpdatePosition()
    PerHour.SettingsPanel:Refresh()
end

local function UpdateDragPosition()
    local x, y = GetCursorPosition()
    local centerX, centerY = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    button:SetAngle(math.atan2(y / scale - centerY, x / scale - centerX))
end

button:SetScript("OnDragStart", function(self)
    self:CloseMenu()
    GameTooltip:Hide()
    self:SetScript("OnUpdate", UpdateDragPosition)
end)
button:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    UpdateDragPosition()
end)
button:HookScript("OnHide", function(self)
    self:SetScript("OnUpdate", nil)
end)

button:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Per Hour")
    GameTooltip:AddLine("Left-click to toggle the menu.", 1, 1, 1)
    GameTooltip:AddLine("Right-click to open settings.", 1, 1, 1)
    GameTooltip:AddLine("Drag to move around the minimap.", 1, 1, 1)
    GameTooltip:Show()
end)
button:SetScript("OnLeave", function() GameTooltip:Hide() end)

function button:Init()
    UpdatePosition()
end
