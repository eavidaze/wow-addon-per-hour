local PerHour = PerHour
local Utils = Utils
local BaseModule = BaseModule
local Components = PerHour.Components
local Theme = PerHour.Theme
local goldR, goldG, goldB = unpack(Theme.gold.text)
local TrackerPanels = {}
PerHour.TrackerPanels = TrackerPanels

local WIDTH, HEIGHT = 180, 94
local ESTIMATE_HEIGHT, ESTIMATE_GAP = 14, 4
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

local function ScheduleRestoreDismissal(module, delay, token)
    local indicator = module.View.RestoreIndicator
    C_Timer.After(delay, function()
        -- An earlier success or acknowledgment must not dismiss a newer warning.
        if indicator.DismissToken ~= token then return end
        indicator.Dismissing = false
        if module.State.RestoreStatus == "success" then module.State.RestoreStatus = nil end
        TrackerPanels:RefreshRestoreStatus(module)
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
    x, y = math.max(0, math.min(maxX, x)), math.max(height, math.min(maxY, y))
    local free = width <= UIParent:GetWidth() and height <= maxY
    if frame:IsShown() then
        for _, other in ipairs(modules) do
            local obstacle = other.View.Frame
            if other ~= module and obstacle:IsShown() and other.Settings:Get("isShown") then
                local left, top = obstacle:GetLeft(), obstacle:GetTop()
                if x < left + obstacle:GetWidth() + PANEL_GAP and x + width + PANEL_GAP > left
                    and y > top - obstacle:GetHeight() - PANEL_GAP and y - height - PANEL_GAP < top then
                    free = false
                    break
                end
            end
        end
    end
    -- Most moves are already valid; do not allocate a candidate grid for them.
    if free then return x, y end
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
    if not TrackerPanels:SavePosition(module) then
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
        if module.CustomTrackingChanged then module.CustomTrackingChanged() end
        BaseModule:RefreshDisplayedValues(module)
    else
        if module.CustomStart and module.CustomStart() == false then return end
        module.State.RestoreStatus = nil
        module.State.RestoreIssue = nil
        module.State.HasStarted = true
        module.State.UpdatedAt = GetTime()
        module.State.PolledAt = GetTime()
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
    frame.Dragging = false
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetPoint("CENTER", UIParent, "CENTER", (index - (count + 1) / 2) * (WIDTH + 16), 0)
    if module.CustomShowDetails then
        frame:SetScript("OnMouseDown", function(self, button)
            self.DetailsClick = button == "LeftButton"
        end)
        frame:SetScript("OnMouseUp", function(self, button)
            local open = self.DetailsClick == true and button == "LeftButton" and not self.Dragging and self:IsMouseOver()
            self.DetailsClick = nil
            if open then
                if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
                module.CustomShowDetails()
            end
        end)
    end
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        local cursorX, cursorY = GetCursorPosition()
        local left, top, scale = frame:GetLeft(), frame:GetTop(), frame:GetEffectiveScale()
        local lastX, lastY = cursorX, cursorY
        self.DetailsClick = nil
        self.Dragging = true
        self:SetScript("OnUpdate", function()
            local x, y = GetCursorPosition()
            if x == lastX and y == lastY then return end
            lastX, lastY = x, y
            TrackerPanels:SavePosition(module, left + (x - cursorX) / scale, top + (y - cursorY) / scale, false)
        end)
    end)
    frame:SetScript("OnDragStop", function(self)
        self.Dragging = false
        self:SetScript("OnUpdate", nil)
        TrackerPanels:SavePosition(module)
    end)
    frame:HookScript("OnHide", function()
        frame.DetailsClick = nil
        frame:SetScript("OnUpdate", nil)
        if frame.Dragging then
            frame.Dragging = false
            TrackerPanels:SavePosition(module)
        end
        if GameTooltip:IsOwned(frame) or GameTooltip:IsOwned(module.View.RestoreIndicator) then GameTooltip:Hide() end
    end)
    frame:HookScript("OnShow", function()
        PlaceShownPanel(module)
        if module.View.RateFrame then TrackerPanels:RefreshRate(module) end
    end)
end

local function ShowRunTooltip(module)
    local status = BaseModule:GetTrackingStatus(module)
    local r, g, b = unpack(Theme.trackerStatus[status.key])
    local totalUnit = module.Name == "Experience" and "XP" or module.Name
    local format = module.FormatValue or function(value) return Utils:DisplayRoundedNumber(value, 0) end
    GameTooltip:SetText(module.Name, goldR, goldG, goldB)
    GameTooltip:AddLine(status.label, r, g, b)
    if module.CustomGetContext then GameTooltip:AddLine(module.CustomGetContext(), 0.8, 0.8, 0.8, true) end
    if module.CustomGetEstimateGoal then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Estimate", goldR, goldG, goldB)
        GameTooltip:AddLine(BaseModule:GetEstimate(module), r, g, b)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Session", goldR, goldG, goldB)
    GameTooltip:AddDoubleLine("Duration", Utils:DisplayTimer(module.State.Time), 0.7, 0.7, 0.7, 1, 1, 1)
    GameTooltip:AddDoubleLine("Total " .. totalUnit, module.FormatValue and format(module.State.Element) or Utils:DisplayNumber(module.State.Element), 0.7, 0.7, 0.7, goldR, goldG, goldB)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Rates", goldR, goldG, goldB)
    GameTooltip:AddDoubleLine(module.ShortName .. "/h", format(module.State.ElementPerHour), 0.7, 0.7, 0.7, goldR, goldG, goldB)
    GameTooltip:AddDoubleLine(module.ShortName .. "/min", format(module.State.ElementPerMinute), 0.7, 0.7, 0.7, 1, 1, 1)
    if module.CustomShowDetails then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Left-click: Details", goldR, goldG, goldB)
    end
    GameTooltip:Show()
end

local function CreateValues(module)
    local frame = module.View.Frame
    local content = CreateFrame("Frame", nil, frame.Content)
    content:SetWidth(WIDTH - 30)
    local rateFrame = Components:CreateRateDisplay(content, module.ShortName .. "/h")
    content:SetHeight(rateFrame:GetHeight())
    frame:SetContent(content)
    module.View.DisplayContent = content
    rateFrame:SetPoint("CENTER", content, "CENTER", 0, 0)
    module.View.RateFrame = rateFrame

    module.View.RateValue = rateFrame.Value
    module.View.RateUnit = rateFrame.Unit

    if module.CustomGetEstimateGoal then
        local estimate = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        local font, size, flags = estimate:GetFont()
        estimate:SetFont(font, math.min(size, 10), flags)
        estimate:SetJustifyH("CENTER")
        estimate:SetWordWrap(false)
        estimate:SetHeight(ESTIMATE_HEIGHT)
        estimate:SetPoint("TOP", rateFrame, "BOTTOM", 0, -ESTIMATE_GAP)
        estimate:Hide()
        module.View.EstimateText = estimate
    end

    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        ShowRunTooltip(module)
    end)
    frame:SetScript("OnLeave", function()
        if GameTooltip:IsOwned(frame) then GameTooltip:Hide() end
    end)
end

local function RefreshDisplayLayout(module)
    local enabled = module.Name == "Experience" and PerHour.Stores.Settings:GetSpeedometerEnabled()
    local estimates = module.CustomGetEstimateGoal ~= nil and PerHour.Stores.Settings:GetEstimatesEnabled()
    if module.View.SpeedometerEnabled == enabled and module.View.EstimatesEnabled == estimates then return end
    local frame, content, rate = module.View.Frame, module.View.DisplayContent, module.View.RateFrame
    local left, top = frame:GetLeft(), frame:GetTop()
    if enabled and not module.View.Speedometer then
        module.View.Speedometer = Components:CreateSpeedometerDisplay(content)
        module.View.Speedometer:SetPoint("TOP", content, "TOP", 0, 0)
    end
    local gaugeHeight = enabled and module.View.Speedometer:GetHeight() or 0
    local estimateHeight = estimates and (ESTIMATE_HEIGHT + ESTIMATE_GAP) or 0
    local contentWidth = enabled and math.max(WIDTH - 30, module.View.Speedometer:GetWidth()) or WIDTH - 30
    frame:SetWidth(contentWidth + 30)
    frame:SetHeight(HEIGHT + gaugeHeight + estimateHeight)
    content:SetSize(contentWidth, rate:GetHeight() + gaugeHeight + estimateHeight)
    rate:ClearAllPoints()
    if enabled then
        module.View.Speedometer:Show()
        rate:SetPoint("TOP", module.View.Speedometer, "BOTTOM", 0, 0)
    else
        if module.View.Speedometer then module.View.Speedometer:Hide() end
        if estimates then rate:SetPoint("TOP", content, "TOP", 0, 0)
        else rate:SetPoint("CENTER", content, "CENTER", 0, 0) end
    end
    if module.View.EstimateText then
        module.View.EstimateText:SetWidth(contentWidth)
        module.View.EstimateText:SetShown(estimates)
    end
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    module.View.SpeedometerEnabled = enabled
    module.View.EstimatesEnabled = estimates
    if frame:IsShown() and module.Settings:Get("isShown") then PlaceShownPanel(module) end
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
                if module.CustomShowDetails then
                    rootDescription:CreateButton("Details", module.CustomShowDetails)
                end
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
        if not module.State.HasStarted or module.State.PendingRestore or not PerHour.Session.InWorld then return end
        if module.CustomOnEvent then module.CustomOnEvent(self, event, ...) end
    end)
    for _, event in ipairs(module.RegisteredEvents) do tracker:RegisterEvent(event) end
end

local function NeedsUpdate(module)
    return module.State.HasStarted
        and (not module.State.HasPaused or module.State.PendingRestore
            or (module.CustomOnUpdate and module.UpdateWhilePaused ~= false))
end

local function UpdateModule(module, now)
    local elapsed = math.max(0, now - (module.State.PolledAt or now))
    module.State.PolledAt = now
    if module.State.PendingRestore then
        PerHour.Session:ValidateRestore(module)
    else
        if module.CustomOnUpdate then module.CustomOnUpdate(module.View.TrackerFrame, elapsed) end
        if module.State.HasStarted and not module.State.HasPaused then BaseModule:UpdateRates(module) end
    end
end

local function UpdateTrackers()
    TrackerPanels.UpdateScheduled = false
    if not PerHour.Session.InWorld then return end
    -- Schedule first and isolate module errors so one failing API cannot stop every tracker.
    TrackerPanels:RefreshScheduler()
    local now = GetTime()
    for _, module in ipairs(modules) do
        if NeedsUpdate(module) then
            local ok, err = pcall(UpdateModule, module, now)
            if not ok then geterrorhandler()(err) end
        end
    end
end

function TrackerPanels:RefreshScheduler()
    if self.UpdateScheduled or not PerHour.Session.InWorld then return end
    for _, module in ipairs(modules) do
        if NeedsUpdate(module) then
            self.UpdateScheduled = true
            C_Timer.After(UPDATE_INTERVAL, UpdateTrackers)
            return
        end
    end
end

function TrackerPanels:SavePosition(module, x, y, persist)
    local frame = module.View.Frame
    x, y = FindFreePosition(module, x or frame:GetLeft(), y or frame:GetTop())
    if not x then return false end
    local point, _, relativePoint = frame:GetPoint()
    if point ~= "TOPLEFT" or relativePoint ~= "BOTTOMLEFT" or frame:GetLeft() ~= x or frame:GetTop() ~= y then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
    end
    if persist ~= false then
        local position = module.Settings:Get("position")
        if not position or position.point ~= "TOPLEFT" or position.relativePoint ~= "BOTTOMLEFT"
            or position.x ~= x or position.y ~= y then
            module.Settings:Set("position", { point = "TOPLEFT", relativePoint = "BOTTOMLEFT", x = x, y = y })
        end
    end
    return true
end

function TrackerPanels:SaveDraggingPositions()
    for _, module in ipairs(modules) do
        if module.View.Frame.Dragging then self:SavePosition(module) end
    end
end

function TrackerPanels:RefreshTrackingState(module)
    local status = BaseModule:GetTrackingStatus(module)
    if module.View.TrackingStatus ~= status.key then
        module.View.TrackingStatus = status.key
        module.View.ToggleStartButton:SetText(status.action)
        module.View.ActiveIndicator:SetVertexColor(unpack(Theme.trackerStatus[status.key]))
    end
    local enabled = module.State.PendingRestore == nil
    if module.View.TrackingEnabled ~= enabled then
        module.View.TrackingEnabled = enabled
        module.View.ToggleStartButton:SetEnabled(enabled)
    end
end

function TrackerPanels:RefreshRestoreStatus(module)
    local status = RESTORE_STATUS[module.State.RestoreStatus]
    local indicator = module.View.RestoreIndicator
    local currentStatus = module.State.RestoreStatus or "none"
    if indicator.Status ~= currentStatus then
        local dismissError = indicator.Status == "error" and currentStatus == "none"
        indicator.Status = currentStatus
        indicator.DismissToken = {}
        indicator.Dismissing = dismissError
        indicator:SetAlpha(1)
        indicator:EnableMouse(not dismissError)
        if dismissError then
            if GameTooltip:IsOwned(indicator) then GameTooltip:Hide() end
            ScheduleRestoreDismissal(module, RESTORE_ERROR_DELAY_SECONDS, indicator.DismissToken)
        elseif currentStatus == "success" then
            ScheduleRestoreDismissal(module, RESTORE_SUCCESS_SECONDS, indicator.DismissToken)
        end
    end
    if not status then
        if not indicator.Dismissing and indicator:IsShown() then indicator:Hide() end
        return
    end
    if indicator.Atlas ~= status.atlas then
        indicator.Atlas = status.atlas
        indicator.Icon:SetAtlas(status.atlas)
    end
    if not indicator:IsShown() then indicator:Show() end
    if GameTooltip:IsShown() and GameTooltip:IsOwned(indicator) then ShowRestoreTooltip(module) end
end

function TrackerPanels:RefreshTooltip(module)
    if GameTooltip:IsShown() and GameTooltip:IsOwned(module.View.Frame) then ShowRunTooltip(module) end
end

function TrackerPanels:RefreshRate(module, skipHidden)
    RefreshDisplayLayout(module)
    if skipHidden and not module.View.Frame:IsVisible() then return end
    local perMinute = PerHour.Stores.Settings:GetRate() == "minute"
    local value = perMinute and module.State.ElementPerMinute or module.State.ElementPerHour
    module.View.RateFrame:SetRate(value / (module.RateDivisor or 1),
        module.ShortName .. (perMinute and "/min" or "/h"), module.RateDecimals)
    if module.View.EstimatesEnabled then
        local status = BaseModule:GetTrackingStatus(module)
        if module.View.EstimateStatus ~= status.key then
            module.View.EstimateStatus = status.key
            module.View.EstimateText:SetTextColor(unpack(Theme.trackerStatus[status.key]))
        end
        local estimate = BaseModule:GetEstimate(module)
        if module.View.EstimateText:GetText() ~= estimate then module.View.EstimateText:SetText(estimate) end
    end
    if module.View.SpeedometerEnabled then
        module.View.Speedometer:SetRate(value,
            PerHour.Stores.Settings:GetSpeedometerMaximum(perMinute and "minute" or "hour"))
    end
end

function TrackerPanels:RefreshDisplays()
    for _, module in ipairs(modules) do self:RefreshRate(module) end
end

function TrackerPanels:RestorePositions()
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

function TrackerPanels:Init()
    for _, module in pairs(PerHour.Modules) do table.insert(modules, module) end
    table.sort(modules, function(a, b) return a.Name < b.Name end)
    for index, module in ipairs(modules) do
        CreatePanel(module, index, #modules)
        CreateRestoreIndicator(module)
        CreateControls(module)
        CreateValues(module)
        CreateTracker(module)
        BaseModule:ResetModule(module, true)
        Components:SetupCloseButtonHover(module.View.Frame)
    end
end
