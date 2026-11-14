local PerHour = PerHour
local Utils = Utils
local BaseModule = BaseModule
local Components = PerHour.Components
local Theme = PerHour.Theme
local goldR, goldG, goldB = unpack(Theme.gold.text)
local Displayer = {}
PerHour.Displayer = Displayer

local WIDTH, HEIGHT = 180, 94
local CONTROL_SIZE = 28
local UPDATE_INTERVAL = 1
local CHANNELS = { "Say", "Yell", "Party", "Guild", "Raid" }
local PANEL_GAP = 4
local RESTORE_SUCCESS_SECONDS = 5
local RESTORE_ERROR_DELAY_SECONDS = 0.5
local modules = {}
local positionsReady = false
local RESTORE_STATUS = {
    pending = { atlas = READY_CHECK_WAITING_TEXTURE_RAID, title = "Checking saved session...", r = 1, g = 0.8, b = 0 },
    success = { atlas = READY_CHECK_READY_TEXTURE_RAID, title = "Session restored successfully.", r = 0.2, g = 1, b = 0.2 },
    error = { atlas = READY_CHECK_NOT_READY_TEXTURE_RAID, title = "Session integrity check failed.", r = 1, g = 0.2, b = 0.2 },
}

local function AnimateRestoreIndicator(module, delay)
    local indicator = module.View.RestoreIndicator
    local startedAt = GetTime()
    local startAlpha = indicator:GetAlpha()
    local fadeOutAt = delay and (startedAt + delay)
    indicator.Fading = fadeOutAt ~= nil
    indicator:SetScript("OnUpdate", function(self)
        local now = GetTime()
        local fadingOut = fadeOutAt and now >= fadeOutAt
        local alpha
        if fadingOut then
            alpha = 1 - (now - fadeOutAt) / Theme.motion.fadeOut
        else
            alpha = startAlpha + (1 - startAlpha) * math.min(1, (now - startedAt) / Theme.motion.fadeIn)
        end
        alpha = math.max(0, math.min(1, alpha))
        self:SetAlpha(alpha)
        if fadingOut and alpha == 0 then
            self.Fading = false
            self:SetScript("OnUpdate", nil)
            self:Hide()
            self:SetAlpha(1)
            module.State.RestoreStatus = nil
            Displayer:RefreshRestoreStatus(module)
        elseif not fadeOutAt and alpha == 1 then
            self:SetScript("OnUpdate", nil)
        end
    end)
end

local function ShowRestoreTooltip(module)
    local status = RESTORE_STATUS[module.State.RestoreStatus]
    if not status then return end
    GameTooltip:SetText(status.title, status.r, status.g, status.b)
    if module.State.RestoreStatus == "success" then
        GameTooltip:AddLine("Played time matches the saved session (30-second tolerance).", 1, 1, 1, true)
    elseif module.State.RestoreStatus == "pending" then
        GameTooltip:AddLine("Waiting for played time or character data.", 1, 1, 1, true)
    else
        GameTooltip:AddLine(module.State.RestoreIssue, 1, 1, 1, true)
        GameTooltip:AddLine("Reset for accurate results, or Resume to keep saved totals.", goldR, goldG, goldB, true)
        GameTooltip:AddLine("Exit the game normally to save your session.", 0.8, 0.8, 0.8, true)
    end
    GameTooltip:Show()
end

local function FindFreePosition(module, x, y)
    local frame = module.View.Frame
    local width, height = frame:GetWidth(), frame:GetHeight()
    local maxX, maxY = UIParent:GetWidth() - width, UIParent:GetHeight()
    local function ClampX(value) return math.max(0, math.min(maxX, value)) end
    local function ClampY(value) return math.max(height, math.min(maxY, value)) end
    x, y = ClampX(x), ClampY(y)
    local xs, ys = { x, 0, maxX }, { y, height, maxY }
    local obstacles = {}
    if frame:IsShown() then
        for _, other in ipairs(modules) do
            if other ~= module and other.View.Frame:IsShown() and other.Settings:Get("isShown") then
                local obstacle = {
                    x = other.View.Frame:GetLeft(), y = other.View.Frame:GetTop(),
                    width = other.View.Frame:GetWidth(), height = other.View.Frame:GetHeight(),
                }
                table.insert(obstacles, obstacle)
                table.insert(xs, ClampX(obstacle.x - width - PANEL_GAP))
                table.insert(xs, ClampX(obstacle.x + obstacle.width + PANEL_GAP))
                table.insert(ys, ClampY(obstacle.y + height + PANEL_GAP))
                table.insert(ys, ClampY(obstacle.y - obstacle.height - PANEL_GAP))
            end
        end
    end
    -- A nearest free rectangle touches either the requested position, a panel, or the screen.
    local bestX, bestY, bestDistance
    for _, left in ipairs(xs) do
        for _, top in ipairs(ys) do
            local free = left >= 0 and left + width <= UIParent:GetWidth()
                and top <= maxY and top - height >= 0
            for _, obstacle in ipairs(obstacles) do
                if left < obstacle.x + obstacle.width + PANEL_GAP and left + width + PANEL_GAP > obstacle.x
                    and top > obstacle.y - obstacle.height - PANEL_GAP and top - height - PANEL_GAP < obstacle.y then
                    free = false
                    break
                end
            end
            local distance = (left - x) ^ 2 + (top - y) ^ 2
            if free and (not bestDistance or distance < bestDistance) then
                bestX, bestY, bestDistance = left, top, distance
            end
        end
    end
    return bestX, bestY
end

local function PlaceShownPanel(module)
    if not positionsReady then return end
    if not Displayer:SavePosition(module) then
        module.Settings:Set("isShown", false)
        module.View.Frame:Hide()
        Utils:AddonMessage("No room to show " .. module.Name .. ".")
    end
end

local function ToggleTracking(module)
    if module.State.PendingRestore then return end
    if module.State.HasStarted then
        -- Sample before changing state so pause/resume excludes the right gains.
        if module.CustomOnUpdate then module.CustomOnUpdate(nil, 0) end
        if not module.State.HasStarted then return end
        BaseModule:UpdateRates(module)

        if module.State.HasPaused then
            module.State.HasPaused = false
            if module.State.RestoreStatus == "error" then
                module.State.RestoreStatus = nil
                module.State.RestoreIssue = nil
            end
            Utils:AddonMessage(module.Name .. " resumed.")
        else
            module.State.HasPaused = true
            Utils:AddonMessage(module.Name .. " paused.")
        end
        BaseModule:RefreshDisplayedValues(module)
    else
        if module.CustomStart and module.CustomStart() == false then return end
        module.State.RestoreStatus = nil
        module.State.RestoreIssue = nil
        module.State.HasStarted = true
        module.State.UpdatedAt = GetTime()
        local message = module.CustomStartedMessage and module.CustomStartedMessage() or " started."
        Utils:AddonMessage(module.Name .. message)
        BaseModule:RefreshDisplayedValues(module)
    end
end

local function CreatePanel(module, index, count)
    local frame = Components:CreatePanel(UIParent, {
        name = PerHour.AddonName .. "-" .. module.TagName .. "-frame",
        title = module.Name,
        titleSize = "small",
        titleBox = true,
        width = WIDTH, height = HEIGHT, footerSize = CONTROL_SIZE,
        onClose = function() module.Settings:Set("isShown", false) end,
    })
    module.View.Frame = frame
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetPoint("CENTER", UIParent, "CENTER", (index - (count + 1) / 2) * (WIDTH + 16), 0)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        local cursorX, cursorY = GetCursorPosition()
        local left, top, scale = frame:GetLeft(), frame:GetTop(), frame:GetEffectiveScale()
        self:SetScript("OnUpdate", function()
            local x, y = GetCursorPosition()
            Displayer:SavePosition(module, left + (x - cursorX) / scale, top + (y - cursorY) / scale)
        end)
    end)
    frame:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        Displayer:SavePosition(module)
    end)
    frame:HookScript("OnHide", function()
        frame:SetScript("OnUpdate", nil)
        if GameTooltip:IsOwned(frame) or GameTooltip:IsOwned(module.View.RestoreIndicator) then GameTooltip:Hide() end
    end)
    frame:HookScript("OnShow", function()
        PlaceShownPanel(module)
    end)
end

local function GetTrackingState(module)
    if not module.State.HasStarted then return "Start", "Not started", 0.5, 0.5, 0.5 end
    if module.State.HasPaused then return "Resume", "Paused", 1, 0.8, 0 end
    return "Pause", "Running", 0.2, 1, 0.2
end

local function ShowRunTooltip(module)
    local _, status, r, g, b = GetTrackingState(module)
    local totalUnit = module.Name == "Experience" and "XP" or module.Name
    GameTooltip:SetText(module.Name, goldR, goldG, goldB)
    GameTooltip:AddLine(status, r, g, b)
    if module.CustomGetContext then GameTooltip:AddLine(module.CustomGetContext(), 0.8, 0.8, 0.8, true) end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Session", goldR, goldG, goldB)
    GameTooltip:AddDoubleLine("Duration", Utils:DisplayTimer(module.State.Time), 0.7, 0.7, 0.7, 1, 1, 1)
    GameTooltip:AddDoubleLine("Total " .. totalUnit, Utils:DisplayNumber(module.State.Element), 0.7, 0.7, 0.7, goldR, goldG, goldB)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Rates", goldR, goldG, goldB)
    GameTooltip:AddDoubleLine(module.ShortName .. "/h", Utils:DisplayRoundedNumber(module.State.ElementPerHour, 0), 0.7, 0.7, 0.7, goldR, goldG, goldB)
    GameTooltip:AddDoubleLine(module.ShortName .. "/min", Utils:DisplayRoundedNumber(module.State.ElementPerMinute, 0), 0.7, 0.7, 0.7, 1, 1, 1)
    GameTooltip:Show()
end

local function CreateValues(module)
    local frame = module.View.Frame
    local content = CreateFrame("Frame", nil, frame)
    -- Center the rate in the space between the full header box and footer controls.
    content:SetPoint("TOP", frame.TitleBox, "BOTTOM", 0, 0)
    content:SetPoint("BOTTOM", frame.ActionBar, "TOP", 0, 0)
    content:SetPoint("LEFT", frame, "LEFT", 15, 0)
    content:SetPoint("RIGHT", frame, "RIGHT", -15, 0)
    local rateFrame = Components:CreateRateDisplay(frame, module.ShortName .. "/h")
    rateFrame:SetPoint("CENTER", content, "CENTER", 0, frame.TitleBox and 1 or 0)
    module.View.RateFrame = rateFrame

    module.View.RateValue = rateFrame.Value
    module.View.RateUnit = rateFrame.Unit

    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        ShowRunTooltip(module)
    end)
    frame:SetScript("OnLeave", function()
        if GameTooltip:IsOwned(frame) then GameTooltip:Hide() end
    end)
end

local function CreateRestoreIndicator(module)
    local frame = module.View.Frame
    local restore = CreateFrame("Frame", nil, frame)
    module.View.RestoreIndicator = restore
    Components:CreateCircularIcon(restore, { iconSize = 16, background = true })
    restore:SetPoint("TOPLEFT", frame, "TOPLEFT", -5, 3)
    restore:SetIgnoreParentAlpha(true)
    restore:EnableMouse(true)
    restore:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        ShowRestoreTooltip(module)
    end)
    local function HideRestoreTooltip()
        if GameTooltip:IsOwned(restore) then GameTooltip:Hide() end
    end
    restore:SetScript("OnLeave", HideRestoreTooltip)
    restore:SetScript("OnHide", HideRestoreTooltip)
    restore:Hide()
end

local function CreateControls(module)
    local frame = module.View.Frame
    Components:CreatePanelActions(frame, {
        { key = "start", type = "status", text = "Start", onClick = function() ToggleTracking(module) end },
        {
            key = "options", type = "icon", texture = "Interface\\Icons\\Trade_Engineering",
            menu = function(_, rootDescription)
                rootDescription:CreateTitle("Options")
                rootDescription:CreateButton("Reset", function()
                    BaseModule:ResetModule(module)
                    Utils:AddonMessage(module.Name .. " reset.")
                end)
                rootDescription:CreateButton("Settings", function() PerHour.SettingsPanel:Show() end)
                local announce = rootDescription:CreateButton("Announce")
                for _, channel in ipairs(CHANNELS) do
                    announce:CreateButton(channel, function(chatType) BaseModule:SendTo(module, chatType) end, channel)
                end
            end,
        },
    })
    module.View.ToggleStartButton = frame.Actions.start
    module.View.ActiveIndicator = frame.Actions.start.Indicator
    module.View.OptionsButton = frame.Actions.options
end

local function CreateTracker(module)
    -- Tracking continues when the panel is hidden.
    local tracker = CreateFrame("Frame", nil, UIParent)
    module.View.TrackerFrame = tracker
    tracker:SetScript("OnEvent", function(self, event, ...)
        if module.State.HasStarted and module.CustomOnEvent then module.CustomOnEvent(self, event, ...) end
    end)
    tracker:SetScript("OnUpdate", function(self, elapsed)
        if not module.State.HasStarted then return end
        if not PerHour.Session.InWorld then return end
        module.State.TimeSinceLastUpdate = module.State.TimeSinceLastUpdate + elapsed
        if module.State.TimeSinceLastUpdate > UPDATE_INTERVAL then
            local updateElapsed = module.State.TimeSinceLastUpdate
            module.State.TimeSinceLastUpdate = 0
            if module.State.PendingRestore then
                PerHour.Session:ValidateRestore(module)
                return
            end
            if module.CustomOnUpdate then module.CustomOnUpdate(self, updateElapsed) end
            if module.State.HasStarted and not module.State.HasPaused then BaseModule:UpdateRates(module) end
        end
    end)
    for _, event in ipairs(module.RegisteredEvents) do tracker:RegisterEvent(event) end
end

function Displayer:SavePosition(module, x, y)
    local frame = module.View.Frame
    x, y = FindFreePosition(module, x or frame:GetLeft(), y or frame:GetTop())
    if not x then return false end
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
    module.Settings:Set("position", { point = "TOPLEFT", relativePoint = "BOTTOMLEFT", x = x, y = y })
    return true
end

function Displayer:RefreshTrackingState(module)
    local text, _, r, g, b = GetTrackingState(module)
    module.View.ToggleStartButton:SetText(text)
    module.View.ToggleStartButton:SetEnabled(module.State.PendingRestore == nil)
    module.View.ActiveIndicator:SetVertexColor(r, g, b)
end

function Displayer:RefreshRestoreStatus(module)
    local status = RESTORE_STATUS[module.State.RestoreStatus]
    local indicator = module.View.RestoreIndicator
    local currentStatus = module.State.RestoreStatus or "none"
    if indicator.Status ~= currentStatus then
        local dismissError = indicator.Status == "error" and currentStatus == "none"
        indicator.Status = currentStatus
        indicator.Fading = false
        indicator:SetScript("OnUpdate", nil)
        indicator:EnableMouse(true)
        if dismissError then
            indicator:EnableMouse(false)
            if GameTooltip:IsOwned(indicator) then GameTooltip:Hide() end
            AnimateRestoreIndicator(module, RESTORE_ERROR_DELAY_SECONDS)
        elseif status then
            if not indicator:IsShown() then indicator:SetAlpha(0) end
            AnimateRestoreIndicator(module, currentStatus == "success" and RESTORE_SUCCESS_SECONDS or nil)
        else
            indicator:SetAlpha(1)
        end
    end
    if not status then
        if not indicator.Fading then indicator:Hide() end
        return
    end
    indicator.Icon:SetAtlas(status.atlas)
    indicator:Show()
    if GameTooltip:IsShown() and GameTooltip:IsOwned(indicator) then ShowRestoreTooltip(module) end
end

function Displayer:RefreshTooltip(module)
    if GameTooltip:IsShown() and GameTooltip:IsOwned(module.View.Frame) then ShowRunTooltip(module) end
end

function Displayer:RefreshRate(module)
    local rate, unit = module.View.RateValue, module.View.RateUnit
    local perMinute = module.Settings:Get("rate") == "minute"
    local value = perMinute and module.State.ElementPerMinute or module.State.ElementPerHour
    unit:SetText(module.ShortName .. (perMinute and "/min" or "/h"))
    rate:SetText(Utils:DisplayRoundedNumber(value, 0))
    if rate:GetStringWidth() + unit:GetStringWidth() + 4 > module.View.Frame:GetWidth() - 30 then
        rate:SetText(AbbreviateLargeNumbers(Utils:RoundValue(value, 0)))
    end
    module.View.RateFrame:SetWidth(rate:GetStringWidth() + unit:GetStringWidth() + 4)
end

function Displayer:RestorePositions()
    positionsReady = false
    for _, module in ipairs(modules) do
        local position = module.Settings:Get("position")
        if position then
            module.View.Frame:ClearAllPoints()
            module.View.Frame:SetPoint(position.point, UIParent, position.relativePoint, position.x, position.y)
        end
    end
    positionsReady = true
    for _, module in ipairs(modules) do
        if module.View.Frame:IsShown() and module.Settings:Get("isShown") then PlaceShownPanel(module) end
    end
end

function Displayer:Init()
    for _, module in pairs(PerHour.Modules) do table.insert(modules, module) end
    table.sort(modules, function(a, b) return a.Name < b.Name end)
    for index, module in ipairs(modules) do
        CreatePanel(module, index, #modules)
        CreateRestoreIndicator(module)
        CreateControls(module)
        CreateValues(module)
        CreateTracker(module)
        BaseModule:ResetModule(module, true)
    end
end
