local PerHour = PerHour
local button = CreateFrame("DropdownButton", "PerHourMinimapButton", Minimap)
PerHour.MinimapButton = button

button:SetSize(31, 31)
button:SetFrameStrata("MEDIUM")
button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
button:RegisterForDrag("LeftButton")

local icon = button:CreateTexture(nil, "BACKGROUND")
icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
icon:SetSize(20, 20)
icon:SetPoint("CENTER")

local border = button:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
border:SetSize(54, 54)
border:SetPoint("TOPLEFT")

local function UpdatePosition()
    local angle = PerHourAccount_Settings.minimap.angle
    button:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * (Minimap:GetWidth() / 2 + 5),
        math.sin(angle) * (Minimap:GetHeight() / 2 + 5))
end

local function UpdateDragPosition()
    local x, y = GetCursorPosition()
    local centerX, centerY = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    PerHourAccount_Settings.minimap.angle = math.atan2(y / scale - centerY, x / scale - centerX)
    UpdatePosition()
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
    GameTooltip:AddLine("Click to toggle the menu.", 1, 1, 1)
    GameTooltip:AddLine("Drag to move around the minimap.", 1, 1, 1)
    GameTooltip:Show()
end)
button:SetScript("OnLeave", function() GameTooltip:Hide() end)

button:RegisterEvent("ADDON_LOADED")
button:SetScript("OnEvent", function(self, event, name)
    if name ~= PerHour.AddonName then return end
    self:UnregisterEvent("ADDON_LOADED")
    PerHour.Settings:Init()
    PerHour.Displayer:RestorePositions()
    PerHour.ToggleMenu:Init(self)
    UpdatePosition()
end)
