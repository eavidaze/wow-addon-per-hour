local PerHour = PerHour
local Utils = Utils
local BaseModule = BaseModule
local Displayer = {}
PerHour.Displayer = Displayer

local WIDTH, HEIGHT = 180, 86
local CONTROL_SIZE = 24
local UPDATE_INTERVAL = 1
local CHANNELS = { "Say", "Yell", "Party", "Guild", "Raid" }
local PANEL_GAP = 4
local modules = {}

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
    if module.HasStarted then
        -- Sample before changing state so pause/resume excludes the right gains.
        if module.CustomOnUpdate then module.CustomOnUpdate(nil, 0) end
        if not module.HasStarted then return end

        if module.HasPaused then
            module.PausedTime = module.PausedTime + GetTime() - module.PausedAt
            module.HasPaused = false
            Utils:AddonMessage(module.Name .. " resumed.")
        else
            module.HasPaused = true
            module.PausedAt = GetTime()
            Utils:AddonMessage(module.Name .. " paused.")
        end
        BaseModule:UpdateRates(module)
    else
        if module.CustomStart and module.CustomStart() == false then return end
        module.HasStarted = true
        module.StartedAt = GetTime()
        local message = module.CustomStartedMessage and module.CustomStartedMessage() or " started."
        Utils:AddonMessage(module.Name .. message)
        BaseModule:RefreshDisplayedValues(module)
    end
end

local function CreatePanel(module, index, count)
    local frame = CreateFrame("Frame", PerHour.AddonName .. "-" .. module.TagName .. "-frame", UIParent, "BasicFrameTemplate")
    module.Frame = frame
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetPoint("CENTER", UIParent, "CENTER", (index - (count + 1) / 2) * (WIDTH + 16), 0)
    frame.TitleText:SetText("Per Hour - " .. module.Name)
    frame.TitleText:ClearAllPoints()
    frame.TitleText:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -5)
    frame.TitleText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -26, -5)
    frame.TitleText:SetJustifyH("LEFT")
    frame.CloseButton:SetSize(21, 21)
    frame.CloseButton:ClearAllPoints()
    frame.CloseButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -1)
    frame.CloseButton:SetScript("OnClick", function()
        module:SetIsShown(false)
        frame:Hide()
    end)

    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT", -26, 0)
    header:SetHeight(22)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function(self)
        local cursorX, cursorY = GetCursorPosition()
        local left, top, scale = frame:GetLeft(), frame:GetTop(), frame:GetEffectiveScale()
        self:SetScript("OnUpdate", function()
            local x, y = GetCursorPosition()
            Displayer:SavePosition(module, left + (x - cursorX) / scale, top + (y - cursorY) / scale)
        end)
    end)
    header:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        Displayer:SavePosition(module)
    end)
    frame:HookScript("OnHide", function()
        header:SetScript("OnUpdate", nil)
        if GameTooltip:IsOwned(frame) then GameTooltip:Hide() end
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
    local rateFrame = CreateFrame("Frame", nil, frame)
    rateFrame:SetPoint("TOP", 0, -33)
    rateFrame:SetHeight(24)
    module.RateFrame = rateFrame

    local rate = rateFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    rate:SetPoint("LEFT")
    rate:SetWordWrap(false)
    module.ElementPerHourValue = rate

    local unit = rateFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    unit:SetPoint("BOTTOMLEFT", rate, "BOTTOMRIGHT", 4, 0)
    unit:SetText(module.ShortName .. "/h")
    module.RateUnit = unit

    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        ShowRunTooltip(module)
    end)
    frame:SetScript("OnLeave", function()
        if GameTooltip:IsOwned(frame) then GameTooltip:Hide() end
    end)
end

local function SetButtonTooltip(button, getText)
    button:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(getText())
        GameTooltip:Show()
    end)
    button:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

local function CreateControls(module)
    local frame = module.Frame
    local start = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    start:SetHeight(CONTROL_SIZE)
    start:SetPoint("BOTTOMLEFT")
    start:SetScript("OnClick", function() ToggleTracking(module) end)
    module.ToggleStartButton = start

    local label = start:GetFontString()
    label:ClearAllPoints()
    -- Center the label together with the 20 px notification atlas.
    label:SetPoint("CENTER", start, "CENTER", 10, 0)

    local indicator = start:CreateTexture(nil, "OVERLAY")
    indicator:SetSize(20, 20)
    indicator:SetPoint("RIGHT", label, "LEFT", 0, 0)
    indicator:SetAtlas("UI-HUD-MicroMenu-Communities-Icon-Notification")
    indicator:SetDesaturated(true)
    module.ActiveIndicator = indicator

    local options = CreateFrame("DropdownButton", nil, frame, "UIPanelSquareButton")
    options:SetSize(CONTROL_SIZE, CONTROL_SIZE)
    options:SetPoint("BOTTOMRIGHT", -2, 0)
    options.icon:SetTexture("Interface\\Icons\\Trade_Engineering")
    options.icon:SetTexCoord(0, 1, 0, 1)
    options.icon:SetSize(16, 16)
    SetButtonTooltip(options, function() return "Options" end)
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

    start:SetPoint("RIGHT", options, "LEFT")
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
        module.TimeSinceLastUpdate = module.TimeSinceLastUpdate + elapsed
        if module.TimeSinceLastUpdate > UPDATE_INTERVAL then
            local updateElapsed = module.TimeSinceLastUpdate
            module.TimeSinceLastUpdate = 0
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
    module.ActiveIndicator:SetVertexColor(r, g, b)
end

function Displayer:RefreshTooltip(module)
    if GameTooltip:IsShown() and GameTooltip:IsOwned(module.Frame) then ShowRunTooltip(module) end
end

function Displayer:RefreshRate(module)
    local rate, unit = module.ElementPerHourValue, module.RateUnit
    rate:SetText(Utils:DisplayRoundedNumber(module.ElementPerHour, 0))
    if rate:GetStringWidth() + unit:GetStringWidth() + 4 > module.Frame:GetWidth() - 16 then
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
        CreateValues(module)
        CreateControls(module)
        CreateTracker(module)
        BaseModule:ResetModule(module)
    end
end

Displayer:Init()
