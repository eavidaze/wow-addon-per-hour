local PerHour = PerHour
local Utils = Utils
local BaseModule = BaseModule
local Components = PerHour.Components
local Theme = PerHour.Theme
local Displayer = {}
PerHour.Displayer = Displayer

local WIDTH, HEIGHT = 180, 94
local CONTROL_SIZE = 28
local FOOTER_PADDING = 8
local UPDATE_INTERVAL = 1
local CHANNELS = { "Say", "Yell", "Party", "Guild", "Raid" }
local PANEL_GAP = 4
local RESTORE_SUCCESS_SECONDS = 5
local RESTORE_ERROR_DELAY_SECONDS = 0.5
local modules = {}
local RESTORE_STATUS = {
    pending = { atlas = READY_CHECK_WAITING_TEXTURE_RAID, title = "Checking saved session...", r = 1, g = 0.8, b = 0 },
    success = { atlas = READY_CHECK_READY_TEXTURE_RAID, title = "Session restored successfully.", r = 0.2, g = 1, b = 0.2 },
    error = { atlas = READY_CHECK_NOT_READY_TEXTURE_RAID, title = "Session integrity check failed.", r = 1, g = 0.2, b = 0.2 },
}

local function AnimateRestoreIndicator(module, delay)
    local indicator = module.RestoreIndicator
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
            module.RestoreStatus = nil
            Displayer:RefreshRestoreStatus(module)
        elseif not fadeOutAt and alpha == 1 then
            self:SetScript("OnUpdate", nil)
        end
    end)
end

local function ShowRestoreTooltip(module)
    local status = RESTORE_STATUS[module.RestoreStatus]
    if not status then return end
    GameTooltip:SetText(status.title, status.r, status.g, status.b)
    if module.RestoreStatus == "success" then
        GameTooltip:AddLine("Played time matches the saved session (30-second tolerance).", 1, 1, 1, true)
    elseif module.RestoreStatus == "pending" then
        GameTooltip:AddLine("Waiting for played time or character data.", 1, 1, 1, true)
    else
        GameTooltip:AddLine(module.RestoreIssue, 1, 1, 1, true)
        GameTooltip:AddLine("Reset for accurate results, or Resume to keep saved totals.", 1, 0.82, 0, true)
        GameTooltip:AddLine("Exit the game normally to save your session.", 0.8, 0.8, 0.8, true)
    end
    GameTooltip:Show()
end

local function FindFreePosition(module, x, y)
    local frame = module.Frame
    local width, height = frame:GetWidth(), frame:GetHeight()
    local maxX, maxY = UIParent:GetWidth() - width, UIParent:GetHeight()
    local function ClampX(value) return math.max(0, math.min(maxX, value)) end
    local function ClampY(value) return math.max(height, math.min(maxY, value)) end
    x, y = ClampX(x), ClampY(y)
    local xs, ys = { x, 0, maxX }, { y, height, maxY }
    local obstacles = {}
    if frame:IsShown() then
        for _, other in ipairs(modules) do
            if other ~= module and other.Frame:IsShown() and other:IsShown() then
                local obstacle = {
                    x = other.Frame:GetLeft(), y = other.Frame:GetTop(),
                    width = other.Frame:GetWidth(), height = other.Frame:GetHeight(),
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
    if not Displayer:SavePosition(module) then
        module:SetIsShown(false)
        module.Frame:Hide()
        Utils:AddonMessage("No room to show " .. module.Name .. ".")
    end
end

local function ToggleTracking(module)
    if module.PendingRestore then return end
    if module.HasStarted then
        -- Sample before changing state so pause/resume excludes the right gains.
        if module.CustomOnUpdate then module.CustomOnUpdate(nil, 0) end
        if not module.HasStarted then return end
        BaseModule:UpdateRates(module)

        if module.HasPaused then
            module.HasPaused = false
            if module.RestoreStatus == "error" then
                module.RestoreStatus = nil
                module.RestoreIssue = nil
            end
            Utils:AddonMessage(module.Name .. " resumed.")
        else
            module.HasPaused = true
            Utils:AddonMessage(module.Name .. " paused.")
        end
        BaseModule:RefreshDisplayedValues(module)
    else
        if module.CustomStart and module.CustomStart() == false then return end
        module.RestoreStatus = nil
        module.RestoreIssue = nil
        module.HasStarted = true
        module.UpdatedAt = GetTime()
        local message = module.CustomStartedMessage and module.CustomStartedMessage() or " started."
        Utils:AddonMessage(module.Name .. message)
        BaseModule:RefreshDisplayedValues(module)
    end
end

local function CreatePanel(module, index, count)
    local frame = Components:CreatePanel(UIParent, {
        name = PerHour.AddonName .. "-" .. module.TagName .. "-frame",
        title = module.Name .. " Per Hour",
        width = WIDTH, height = HEIGHT, footerSize = CONTROL_SIZE,
    })
    module.Frame = frame
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetPoint("CENTER", UIParent, "CENTER", (index - (count + 1) / 2) * (WIDTH + 16), 0)
    frame.CloseButton:SetScript("OnClick", function()
        module:SetIsShown(false)
        frame:Hide()
    end)

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
        if GameTooltip:IsOwned(frame) or GameTooltip:IsOwned(module.RestoreIndicator) then GameTooltip:Hide() end
    end)
    frame:HookScript("OnShow", function()
        if PerHourAccount_Settings and PerHourAccount_Settings[module.Name] then PlaceShownPanel(module) end
    end)
end

local function GetTrackingState(module)
    if not module.HasStarted then return "Start", "Not started", 0.5, 0.5, 0.5 end
    if module.HasPaused then return "Resume", "Paused", 1, 0.8, 0 end
    return "Pause", "Running", 0.2, 1, 0.2
end

local function ShowRunTooltip(module)
    local _, status, r, g, b = GetTrackingState(module)
    local totalUnit = module.Name == "Experience" and "XP" or module.Name
    GameTooltip:SetText(module.Name, 1, 0.82, 0)
    GameTooltip:AddLine(status, r, g, b)
    if module.CustomGetContext then GameTooltip:AddLine(module.CustomGetContext(), 0.8, 0.8, 0.8, true) end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Session", 1, 0.82, 0)
    GameTooltip:AddDoubleLine("Duration", Utils:DisplayTimer(module.Time), 0.7, 0.7, 0.7, 1, 1, 1)
    GameTooltip:AddDoubleLine("Total " .. totalUnit, Utils:DisplayNumber(module.Element), 0.7, 0.7, 0.7, 1, 0.82, 0)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Rates", 1, 0.82, 0)
    GameTooltip:AddDoubleLine(module.ShortName .. "/h", Utils:DisplayRoundedNumber(module.ElementPerHour, 0), 0.7, 0.7, 0.7, 1, 0.82, 0)
    GameTooltip:AddDoubleLine(module.ShortName .. "/min", Utils:DisplayRoundedNumber(module.ElementPerMinute, 0), 0.7, 0.7, 0.7, 1, 1, 1)
    GameTooltip:Show()
end

local function CreateValues(module)
    local frame = module.Frame
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", frame.TitleText, "BOTTOMLEFT")
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, CONTROL_SIZE)
    local rateFrame = Components:CreateRateDisplay(frame, module.ShortName .. "/h")
    rateFrame:SetPoint("CENTER", content, "CENTER")
    module.RateFrame = rateFrame

    module.ElementPerHourValue = rateFrame.Value
    module.RateUnit = rateFrame.Unit

    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        ShowRunTooltip(module)
    end)
    frame:SetScript("OnLeave", function()
        if GameTooltip:IsOwned(frame) then GameTooltip:Hide() end
    end)
end

local function CreateRestoreIndicator(module)
    local frame = module.Frame
    local restore = CreateFrame("Frame", nil, frame)
    module.RestoreIndicator = restore
    Components:CreateCircularIcon(restore, { iconSize = 16, background = true })
    restore:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 2)
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
    local frame = module.Frame
    local start = Components:CreateStatusButton(frame, "Start", CONTROL_SIZE)
    start:SetPoint("LEFT", frame.Border.Bg, "BOTTOMLEFT", FOOTER_PADDING, 0)
    start:SetScript("OnClick", function() ToggleTracking(module) end)
    module.ToggleStartButton = start

    module.ActiveIndicator = start.Indicator

    local options = CreateFrame("DropdownButton", nil, frame)
    Components:CreateCircularIcon(options, { texture = "Interface\\Icons\\Trade_Engineering" })
    -- Leave equal side padding while straddling the background's bottom boundary.
    options:SetPoint("RIGHT", frame.Border.Bg, "BOTTOMRIGHT", -FOOTER_PADDING, 0)
    start:SetPoint("RIGHT", options, "LEFT", -3, 0)
    options:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    Components:SetButtonTooltip(options, function() return "Options" end)
    options:SetupMenu(function(_, rootDescription)
        rootDescription:CreateTitle(module.Name)
        rootDescription:CreateButton("Reset", function()
            BaseModule:ResetModule(module)
            Utils:AddonMessage(module.Name .. " reset.")
        end)
        local announce = rootDescription:CreateButton("Announce")
        for _, channel in ipairs(CHANNELS) do
            announce:CreateButton(channel, function(chatType) BaseModule:SendTo(module, chatType) end, channel)
        end
    end)
    module.OptionsButton = options
end

local function CreateTracker(module)
    -- Tracking continues when the panel is hidden.
    local tracker = CreateFrame("Frame", nil, UIParent)
    module.TrackerFrame = tracker
    tracker:SetScript("OnEvent", function(self, event, ...)
        if module.HasStarted and module.CustomOnEvent then module.CustomOnEvent(self, event, ...) end
    end)
    tracker:SetScript("OnUpdate", function(self, elapsed)
        if not module.HasStarted then return end
        if not PerHour.Session.InWorld then return end
        module.TimeSinceLastUpdate = module.TimeSinceLastUpdate + elapsed
        if module.TimeSinceLastUpdate > UPDATE_INTERVAL then
            local updateElapsed = module.TimeSinceLastUpdate
            module.TimeSinceLastUpdate = 0
            if module.PendingRestore then
                PerHour.Session:ValidateRestore(module)
                return
            end
            if module.CustomOnUpdate then module.CustomOnUpdate(self, updateElapsed) end
            if module.HasStarted and not module.HasPaused then BaseModule:UpdateRates(module) end
        end
    end)
    for _, event in ipairs(module.RegisteredEvents) do tracker:RegisterEvent(event) end
end

function Displayer:SavePosition(module, x, y)
    local frame = module.Frame
    x, y = FindFreePosition(module, x or frame:GetLeft(), y or frame:GetTop())
    if not x then return false end
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
    PerHourAccount_Settings[module.Name].position = { point = "TOPLEFT", relativePoint = "BOTTOMLEFT", x = x, y = y }
    return true
end

function Displayer:RefreshTrackingState(module)
    local text, _, r, g, b = GetTrackingState(module)
    module.ToggleStartButton:SetText(text)
    module.ToggleStartButton:SetEnabled(module.PendingRestore == nil)
    module.ActiveIndicator:SetVertexColor(r, g, b)
end

function Displayer:RefreshRestoreStatus(module)
    local status = RESTORE_STATUS[module.RestoreStatus]
    local indicator = module.RestoreIndicator
    local currentStatus = module.RestoreStatus or "none"
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
    if GameTooltip:IsShown() and GameTooltip:IsOwned(module.Frame) then ShowRunTooltip(module) end
end

function Displayer:RefreshRate(module)
    local rate, unit = module.ElementPerHourValue, module.RateUnit
    rate:SetText(Utils:DisplayRoundedNumber(module.ElementPerHour, 0))
    if rate:GetStringWidth() + unit:GetStringWidth() + 4 > module.Frame:GetWidth() - 30 then
        rate:SetText(AbbreviateLargeNumbers(Utils:RoundValue(module.ElementPerHour, 0)))
    end
    module.RateFrame:SetWidth(rate:GetStringWidth() + unit:GetStringWidth() + 4)
end

function Displayer:RestorePositions()
    for _, module in ipairs(modules) do
        local position = PerHourAccount_Settings[module.Name].position
        if position then
            module.Frame:ClearAllPoints()
            module.Frame:SetPoint(position.point, UIParent, position.relativePoint, position.x, position.y)
        end
    end
    for _, module in ipairs(modules) do
        if module.Frame:IsShown() and module:IsShown() then PlaceShownPanel(module) end
    end
end

function Displayer:Init()
    for _, module in pairs(PerHour.Modules) do table.insert(modules, module) end
    table.sort(modules, function(a, b) return a.Name < b.Name end)
    for index, module in ipairs(modules) do
        CreatePanel(module, index, #modules)
        CreateRestoreIndicator(module)
        CreateValues(module)
        CreateControls(module)
        CreateTracker(module)
        BaseModule:ResetModule(module)
    end
end

Displayer:Init()
