local PerHour = PerHour
local Theme = PerHour.Theme
local icons = LibStub("LibDBIcon-1.0")
local tooltip = GameNoHeaderTooltip
-- LibDBIcon uses degrees. Keep this runtime table separate from saved settings,
-- whose existing per-character angle remains in radians.
local position = { minimapPos = 225 }
local initialized = false

local function HideTooltips()
    GameTooltip:Hide()
    tooltip:Hide()
end

local broker = LibStub("LibDataBroker-1.1"):NewDataObject("PerHour", {
    type = "launcher",
    tocname = PerHour.AddonName,
    text = "Per Hour",
    label = "Per Hour",
    icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",
    OnClick = function(owner, mouseButton)
        if mouseButton == "LeftButton" then
            HideTooltips()
            PerHour.ToggleMenu:Toggle(owner)
        elseif mouseButton == "RightButton" then
            PerHour.ToggleMenu:Close()
            HideTooltips()
            PerHour.SettingsPanel:Show()
        end
    end,
    OnEnter = function(owner)
        tooltip:SetOwner(owner, "ANCHOR_LEFT")
        tooltip:ClearLines()
        tooltip:AddLine(Theme:GoldText("Left-click:") .. " Menu", 1, 1, 1)
        tooltip:AddLine(Theme:GoldText("Right-click:") .. " Settings", 1, 1, 1)
        tooltip:AddLine(Theme:GoldText("Drag:") .. " Move", 1, 1, 1)
        tooltip:Show()
    end,
    OnLeave = function() tooltip:Hide() end,
})
icons:Register("PerHour", broker, position)
local button = icons:GetMinimapButton("PerHour")
PerHour.MinimapButton = button
button.Tooltip = tooltip

function button:SetAngle(angle)
    PerHour.Stores.Settings:SetMinimapAngle(angle)
    position.minimapPos = math.deg(angle)
    icons:SetButtonToPosition(self, position.minimapPos)
end

function button:SaveDragPosition()
    if not initialized then return end
    local angle = math.rad(position.minimapPos)
    if angle ~= PerHour.Stores.Settings:GetMinimapAngle() then
        PerHour.Stores.Settings:SetMinimapAngle(angle)
    end
end
button.Dragging = false

-- LibDBIcon owns cursor sampling, positioning and the drag update callback.
-- Only dismiss our UI and save its resulting angle at lifecycle boundaries.
button:HookScript("OnDragStart", function(self)
    PerHour.ToggleMenu:Close()
    HideTooltips()
    self.Dragging = true
end)
button:HookScript("OnDragStop", function(self)
    self.Dragging = false
    self:SaveDragPosition()
end)
button:HookScript("OnHide", function(self)
    if self.Dragging then
        self.Dragging = false
        -- Cancel an interrupted drag through its normal stop handler.
        local stopDrag = self:GetScript("OnDragStop")
        if stopDrag then stopDrag(self) end
    end
    self:SaveDragPosition()
    tooltip:Hide()
end)

function button:Init()
    position.minimapPos = math.deg(PerHour.Stores.Settings:GetMinimapAngle())
    icons:SetButtonToPosition(self, position.minimapPos)
    initialized = true
end
