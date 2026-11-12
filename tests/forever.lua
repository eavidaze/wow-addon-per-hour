-- Run from the repository root with Lua 5.1: lua tests/forever.lua
local frames, names, messages, sent = {}, {}, {}, {}
local now, xp, xpMax, level = 0, 100, 1000, 10
local honorValue, honorMax, honorLevel = 100, 500, 1
local watched = { name = "Stormwind", factionID = 72, currentStanding = 0 }
local checks = 0
local function equal(actual, expected, label)
    assert(actual == expected, label..": expected "..tostring(expected)..", got "..tostring(actual))
    checks = checks + 1
end

local methods = {}
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:HookScript(event, callback)
    local previous = self.scripts[event]
    self.scripts[event] = function(...)
        if previous then previous(...) end
        callback(...)
    end
end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:UnregisterEvent(event) self.events[event] = nil end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:IsShown() return self.shown end
function methods:SetShown(value) self.shown = value end
function methods:SetText(value) self.text = value end
function methods:GetText() return self.text end
function methods:GetFontString() return self.fontString end
function methods:SetVertexColor(...) self.vertexColor = { ... } end
function methods:AddMaskTexture(mask) self.mask = mask end
function methods:OverrideText(value) self:SetText(value) end
function methods:SetSize(width, height) self.width, self.height = width, height end
function methods:SetWidth(value) self.width = value end
function methods:SetHeight(value) self.height = value end
function methods:SetTexCoord(...) self.texCoords = { ... } end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:GetStringWidth()
    return #self.text * (self.template == "GameFontNormalHuge" and 10 or 6)
end
function methods:SetPoint(...) self.point = { ... } end
function methods:GetPoint() return unpack(self.point) end
function methods:GetLeft()
    local point = rawget(self, "point")
    if not point then return 0 end
    local anchor, parent, relative, x = point[1], point[2], point[3], point[4]
    local left = parent:GetLeft() + x
    if relative:find("RIGHT") then left = left + parent:GetWidth()
    elseif not relative:find("LEFT") then left = left + parent:GetWidth() / 2 end
    if anchor:find("RIGHT") then left = left - self:GetWidth()
    elseif not anchor:find("LEFT") then left = left - self:GetWidth() / 2 end
    return left
end
function methods:GetTop()
    local point = rawget(self, "point")
    if not point then return self:GetHeight() end
    local anchor, parent, relative, y = point[1], point[2], point[3], point[5]
    local top = parent:GetTop() + y
    if relative:find("BOTTOM") then top = top - parent:GetHeight()
    elseif not relative:find("TOP") then top = top - parent:GetHeight() / 2 end
    if anchor:find("BOTTOM") then top = top + self:GetHeight()
    elseif not anchor:find("TOP") then top = top + self:GetHeight() / 2 end
    return top
end
function methods:ClearAllPoints() self.point = nil end
function methods:StartMoving() self.moving = true end
function methods:StopMovingOrSizing() self.moving = false end
function methods:GetCenter() return 100, 200 end
function methods:GetEffectiveScale() return 2 end
function methods:SetupMenu(generator) self.menuGenerator = generator end
function methods:IsMenuOpen() return self.menuOpen == true end
function methods:CloseMenu() self.menuOpen = false end
local function menuDescription()
    local root = { items = {} }
    function root:CreateTitle(text) self.title = text end
    function root:CreateCheckbox(text, isSelected, callback, data)
        self.items[#self.items + 1] = { text = text, isSelected = isSelected, callback = callback, data = data }
    end
    function root:CreateButton(text, callback, data)
        local item = menuDescription()
        item.text, item.callback, item.data = text, callback, data
        self.items[#self.items + 1] = item
        return item
    end
    return root
end
function methods:SetMenuOpen(open)
    self.menuOpen = open
    if not open then return end
    local root = menuDescription()
    self.menuGenerator(self, root)
    self.menuDescription = root
end
local function object(name)
    assert(name == nil or type(name) == "string", "UI object name must be a string")
    return setmetatable({ name = name, scripts = {}, events = {}, shown = true }, {
        __index = function(_, key) return methods[key] or function() end end,
    })
end
function methods:CreateFontString(name, layer, template)
    assert(layer == "OVERLAY", "font strings need a valid draw layer")
    local fontString = object(name)
    fontString.template = template
    return fontString
end
function methods:CreateTexture() return object() end
function methods:CreateMaskTexture() return object() end
function methods:AddDoubleLine(label, value)
    self.lines = rawget(self, "lines") or {}
    self.lines[label] = value
end
UIParent = object("UIParent")
UIParent:SetSize(1920, 1080)
Minimap = object("Minimap")
Minimap:SetSize(140, 140)
GameTooltip = object("GameTooltip")
local cursorX, cursorY = 400, 400
function GetCursorPosition() return cursorX, cursorY end
function CreateFrame(kind, name, parent, template)
    assert(template == nil or template == "UIPanelButtonTemplate" or template == "BasicFrameTemplate"
        or template == "UIPanelSquareButton", "unsupported template: "..tostring(template))
    if name then
        name = name:gsub("%$parent", parent.name or "")
        assert(not names[name], "duplicate frame name: "..name)
    end
    local frame = object(name)
    frame.parent, frame.template = parent, template
    if template == "UIPanelButtonTemplate" then frame.fontString = object() end
    if template == "BasicFrameTemplate" then
        frame.TitleText, frame.CloseButton = object(), object()
    end
    if template == "UIPanelSquareButton" then
        frame.icon = object()
        frame.icon:SetTexCoord(0.015625, 0.203125, 0.015625, 0.203125)
    end
    if kind == "DropdownButton" then
        frame.scripts.OnMouseDown = function(self) self:SetMenuOpen(not self:IsMenuOpen()) end
    end
    frames[#frames + 1] = frame
    if name then names[name] = frame end
    return frame
end
function GetTime() return now end
local abbreviatedValue
function AbbreviateLargeNumbers(value)
    abbreviatedValue = value
    return "1T"
end
function UnitXP() return xp end
function UnitXPMax() return xpMax end
function UnitLevel() return level end
function UnitHonor() return honorValue end
function UnitHonorMax() return honorMax end
function UnitHonorLevel() return honorLevel end
function issecretvalue(value) return type(value) == "table" and value.secret == true end
DEFAULT_CHAT_FRAME = { AddMessage = function(_, message) messages[#messages + 1] = message end }
C_Reputation = { GetWatchedFactionData = function() return watched end }
C_ChatInfo = { SendChatMessage = function(message, channel) sent[#sent + 1] = { message, channel } end }
SlashCmdList = {}
-- Ensure saved visibility survives ADDON_LOADED.
PerHourAccount_Settings = {
    Experience = { isShown = true, position = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 90, y = -160 } },
}

local function read(path)
    local file = assert(io.open(path, "r"))
    local contents = file:read("*a")
    file:close()
    return contents
end
local function loadSource(path)
    path = path:gsub("\\", "/")
    if path:match("%.xml$") then
        local directory = path:match("^(.*[/])") or ""
        for file in read(path):gmatch('file="([^"]+)"') do loadSource(directory..file) end
    else
        assert(loadfile(path))("per-hour", {})
    end
end
for line in read("per-hour.toc"):gmatch("[^\r\n]+") do
    if not line:match("^#") and line:match("%S") then loadSource(line) end
end
local function event(name, ...)
    for _, frame in ipairs(frames) do
        if frame.events[name] then frame.scripts.OnEvent(frame, name, ...) end
    end
end
local function tick(seconds)
    now = now + seconds
    for _, frame in ipairs(frames) do
        if frame.shown and frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, seconds) end
    end
end
local function click(module) module.ToggleStartButton.scripts.OnClick() end
local experience, reputation, honor = PerHour.Modules.Experience, PerHour.Modules.Reputation, PerHour.Modules.Honor
local function indicatorColor(module)
    return table.concat(module.ActiveIndicator.vertexColor, ",")
end
event("ADDON_LOADED", "another-addon")
event("ADDON_LOADED", "per-hour")

equal(indicatorColor(experience), "0.5,0.5,0.5", "idle indicator is gray")
equal(experience.Frame:IsShown(), true, "saved visibility")
equal(reputation.Frame:IsShown(), false, "default visibility")
equal(experience.Frame.point[1], "TOPLEFT", "saved window anchor restored")
equal(experience.Frame.point[4], 90, "saved window X restored")
equal(experience.Frame.point[5], -160, "saved window Y restored")
equal(reputation.Frame.point[4] - honor.Frame.point[4] > honor.Frame:GetWidth(), true, "default panels do not overlap")
local header
for _, frame in ipairs(frames) do
    if frame.parent == experience.Frame and frame.scripts.OnDragStop then header = frame end
end
header.scripts.OnDragStart()
equal(experience.Frame.moving, true, "title bar starts dragging")
experience.Frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -40, 80)
header.scripts.OnDragStop()
equal(experience.Frame.moving, false, "title bar stops dragging")
equal(PerHourAccount_Settings.Experience.position.x, 1700, "drag saves window X")
equal(PerHourAccount_Settings.Experience.position.y, 166, "drag saves window Y")
experience.Frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
PerHour.Displayer:RestorePositions()
equal(experience.Frame.point[1], "TOPLEFT", "dragged window anchor restored")
equal(experience.Frame.point[4], 1700, "dragged window position restored")
equal(experience.Frame.TitleText:GetText(), "Per Hour - Experience", "panel title includes addon name")
equal(honor.Frame.TitleText:GetText(), "Per Hour - Honor", "honor title includes addon name")
equal(reputation.Frame.TitleText:GetText(), "Per Hour - Reputation", "reputation title includes addon name")
equal(experience.Frame:GetWidth(), 180, "compact panel width")
equal(experience.Frame:GetHeight(), 86, "compact panel height")
equal(experience.DetailsFrame:IsShown(), false, "run details start collapsed")
local panelTop, panelLeft = experience.Frame:GetTop(), experience.Frame:GetLeft()
experience.DetailsButton.scripts.OnEnter(experience.DetailsButton)
equal(GameTooltip:GetText(), "Show run details", "collapsed details hint")
experience.DetailsButton.scripts.OnClick()
equal(experience.DetailsFrame:IsShown(), true, "note expands run details")
equal(experience.Frame:GetHeight(), 126, "expanded panel fits details")
local rowSpacing = experience.ElementValue.point[3] - experience.TimeValue.point[3]
equal(experience.DetailsFrame:GetHeight() + experience.TimeValue.point[3], rowSpacing, "Time to actions matches Total to Time spacing")
equal(experience.Frame:GetTop(), panelTop, "expanding keeps panel top fixed")
equal(experience.Frame:GetLeft(), panelLeft, "expanding keeps panel left fixed")
experience.DetailsButton.scripts.OnEnter(experience.DetailsButton)
equal(GameTooltip:GetText(), "Hide run details", "expanded details hint")
experience.DetailsButton.scripts.OnClick()
equal(experience.DetailsFrame:IsShown(), false, "note collapses run details")
equal(experience.Frame:GetHeight(), 86, "collapse restores compact height")
equal(experience.Frame:GetTop(), panelTop, "collapsing keeps panel top fixed")
experience.OptionsButton.scripts.OnEnter(experience.OptionsButton)
equal(GameTooltip:GetText(), "Options", "gear tooltip identifies options")
equal(table.concat(experience.OptionsButton.icon.texCoords, ","), "0,1,0,1", "gear displays its entire texture")
equal(table.concat(experience.DetailsButton.icon.texCoords, ","), "0,1,0,1", "note displays its entire texture")
reputation.DetailsButton.scripts.OnClick()
equal(reputation.Frame:GetHeight(), 144, "reputation details include space for faction")
equal(reputation.DetailsFrame:GetHeight() + reputation.ContextText.point[3], rowSpacing, "faction to actions keeps consistent spacing")
reputation.DetailsButton.scripts.OnClick()
experience.Frame.CloseButton.scripts.OnClick()
equal(experience.Frame:IsShown(), false, "close button hides panel")
equal(experience:IsShown(), false, "close button saves visibility")
experience:SetIsShown(true)
experience.Frame:Show()
local minimapButton = PerHour.MinimapButton
equal(minimapButton.events.ADDON_LOADED, nil, "initialize once")
equal(minimapButton:IsShown(), true, "minimap button visible")
equal(minimapButton:IsMenuOpen(), false, "menu starts closed")
equal(PerHourAccount_Settings.minimap.angle, math.rad(225), "default minimap position")
SlashCmdList.PERHOUR()
equal(minimapButton:IsMenuOpen(), true, "slash opens menu")
equal(minimapButton.menuDescription.title, "Per Hour", "native menu title")
equal(#minimapButton.menuDescription.items, 3, "all modules in menu")
local experienceItem = minimapButton.menuDescription.items[1]
equal(experienceItem.text, "Experience", "stable alphabetical menu order")
equal(experienceItem.isSelected(experienceItem.data), true, "menu reflects saved visibility")
experienceItem.callback(experienceItem.data)
equal(experience.Frame:IsShown(), false, "menu hides module")
equal(experience:IsShown(), false, "menu saves hidden module")
equal(experienceItem.isSelected(experienceItem.data), false, "menu check updates after hide")
experienceItem.callback(experienceItem.data)
equal(experience.Frame:IsShown(), true, "menu shows module")
equal(experience:IsShown(), true, "menu saves visible module")
SlashCmdList.PERHOUR()
equal(minimapButton:IsMenuOpen(), false, "slash closes menu")
minimapButton.scripts.OnMouseDown(minimapButton)
equal(minimapButton:IsMenuOpen(), true, "minimap click opens menu")
minimapButton.scripts.OnMouseDown(minimapButton)
equal(minimapButton:IsMenuOpen(), false, "minimap click closes menu")
SlashCmdList.PERHOUR()
minimapButton.scripts.OnDragStart(minimapButton)
equal(minimapButton:IsMenuOpen(), false, "drag closes menu")
minimapButton.scripts.OnUpdate(minimapButton)
equal(PerHourAccount_Settings.minimap.angle, 0, "scaled cursor determines drag angle")
equal(minimapButton.point[4], 75, "drag stays on minimap edge")
equal(minimapButton.point[5], 0, "drag aligns with scaled cursor")
cursorX, cursorY = 200, 600
minimapButton.scripts.OnDragStop(minimapButton)
equal(minimapButton.scripts.OnUpdate, nil, "drag stops polling cursor")
equal(PerHourAccount_Settings.minimap.angle, math.pi / 2, "drag stop saves final position")
PerHour.Settings:Init()
equal(PerHourAccount_Settings.minimap.angle, math.pi / 2, "saved position survives settings initialization")
minimapButton.scripts.OnEnter(minimapButton)
equal(GameTooltip:GetText(), "Per Hour", "minimap tooltip title")
equal(GameTooltip:IsShown(), true, "minimap tooltip shown")
minimapButton.scripts.OnLeave(minimapButton)
equal(GameTooltip:IsShown(), false, "minimap tooltip hidden")

click(experience)
equal(experience.ToggleStartButton:GetText(), "Pause", "running action is Pause")
equal(indicatorColor(experience), "0.2,1,0.2", "running indicator is green")
xp = 150
tick(2)
equal(experience.Element, 50, "first XP gain")
equal(experience.ElementPerHour, 90000, "XP per hour")
equal(experience.ElementPerHourValue:GetText(), "90,000", "fitting rates retain full precision")
equal(experience.RateUnit:GetText(), "XP/h", "inline rate unit")
equal(experience.DetailsFrame:IsShown(), false, "tracking keeps details collapsed")
equal(experience.ElementValue:GetText(), "50", "collapsed details stay current")
experience.Frame.scripts.OnEnter(experience.Frame)
equal(GameTooltip.lines["XP/min"], "1,500", "tooltip shows per-minute rate")
equal(GameTooltip.lines["XP/h"], "90,000", "tooltip shows full hourly rate")
experience.Frame.scripts.OnLeave()
experience.Frame:Hide()
xp = 200
tick(2)
equal(experience.Element, 100, "XP tracks while hidden")
xp = 250
click(experience)
equal(experience.Element, 150, "gain immediately before pause")
equal(experience.ElementValue:GetText(), "150", "pause refreshes display immediately")
equal(experience.ToggleStartButton:GetText(), "Resume", "paused action is Resume")
equal(indicatorColor(experience), "1,0.8,0", "paused indicator is yellow")
xp = 300
tick(2)
xp = 350
click(experience)
tick(2)
equal(experience.ToggleStartButton:GetText(), "Pause", "resume restores Pause action")
equal(indicatorColor(experience), "0.2,1,0.2", "resuming restores green indicator")
equal(experience.Element, 150, "paused XP excluded on resume")
equal(experience.Time, 6, "pause duration excluded")
level, xp, xpMax = 11, 50, 900
tick(2)
equal(experience.Element, 850, "level up with lower XP requirement")
xp = { secret = true }
tick(2)
equal(experience.Element, 850, "secret XP ignored")
xp = 100
tick(2)
equal(experience.Element, 900, "XP resumes when readable")
BaseModule:ResetModule(experience)
equal(experience.Element, 0, "reset XP")
equal(experience.HasStarted, false, "reset stops tracker")
equal(experience.ToggleStartButton:GetText(), "Start", "reset restores Start action")
equal(indicatorColor(experience), "0.5,0.5,0.5", "reset restores gray indicator")
experience.ElementPerHour = 1000000000000
BaseModule:RefreshDisplayedValues(experience)
equal(abbreviatedValue, experience.ElementPerHour, "overflow uses native number abbreviation")
equal(experience.ElementPerHourValue:GetText(), "1T", "panel displays native abbreviated result")
equal(experience.RateFrame:GetWidth() <= experience.Frame:GetWidth() - 16, true, "abbreviated rate and unit fit together")
experience.Frame.scripts.OnEnter(experience.Frame)
equal(GameTooltip.lines["XP/h"], "1,000,000,000,000", "tooltip retains full abbreviated rate")
experience.Frame.scripts.OnLeave()
BaseModule:ResetModule(experience)
equal(experience.ElementPerHourValue:GetText(), "0", "reset restores full rate formatting")

click(reputation)
equal(reputation.ContextText:GetText(), "Stormwind", "panel identifies tracked faction")
watched.currentStanding = 100
tick(2)
equal(reputation.Element, 100, "reputation gain from zero")
watched.currentStanding = -50
tick(2)
equal(reputation.Element, -50, "reputation loss")
click(reputation)
watched.currentStanding = 200
click(reputation)
tick(2)
equal(reputation.Element, -50, "paused reputation excluded")
local original = watched
watched = nil
tick(4)
tick(4)
equal(reputation.HasStarted, true, "missing faction grace period")
watched = original
tick(2)
equal(reputation.HasStarted, true, "faction restored")
watched = { name = "Ironforge", factionID = 47, currentStanding = 100 }
tick(2)
equal(reputation.HasStarted, false, "faction change stops tracker")
equal(reputation.Element, 0, "faction change resets totals")
equal(reputation.ToggleStartButton:GetText(), "Start", "automatic reset restores Start action")
equal(indicatorColor(reputation), "0.5,0.5,0.5", "automatic reset restores gray indicator")
equal(reputation.ContextText:GetText(), "No active session", "reset clears tracked faction")
click(reputation)
watched = nil
tick(10)
equal(reputation.HasStarted, false, "missing faction timeout in real seconds")
click(reputation)
equal(reputation.HasStarted, false, "start requires watched faction")
equal(indicatorColor(reputation), "0.5,0.5,0.5", "failed start keeps gray indicator")

click(honor)
equal(honor.ElementPerHour, 0, "zero-time start has finite rate")
honorValue = 125
tick(2)
equal(honor.Element, 25, "honor from modern API")
honorValue = 225
tick(2)
equal(honor.Element, 125, "bonus honor")
honorLevel, honorValue, honorMax = 2, 50, 500
tick(2)
equal(honor.Element, 450, "honor level rollover")
honorValue = { secret = true }
tick(2)
equal(honor.Element, 450, "secret honor ignored")
honorValue = 75
tick(2)
equal(honor.Element, 475, "honor resumes when readable")
click(honor)
honorValue = 100
click(honor)
tick(2)
equal(honor.Element, 475, "paused honor ignored")
BaseModule:SendTo(honor, "Party")
equal(sent[1][2], "PARTY", "modern chat API and channel")
local options = honor.OptionsButton
options:SetMenuOpen(true)
local announce = options.menuDescription.items[2]
equal(announce.text, "Announce", "native announcement submenu")
equal(#announce.items, 5, "all announcement channels available")
local expectedChannels = { "SAY", "YELL", "PARTY", "GUILD", "RAID" }
for index, item in ipairs(announce.items) do
    local firstMessage = #sent + 1
    item.callback(item.data)
    equal(sent[firstMessage][2], expectedChannels[index], "announcement channel "..item.text)
end
local reset = options.menuDescription.items[1]
equal(reset.text, "Reset", "reset available in Options")
reset.callback()
equal(honor.Element, 0, "Options reset clears results")
equal(honor.HasStarted, false, "Options reset stops tracking")
equal(honor.ToggleStartButton:GetText(), "Start", "Options reset restores Start action")
equal(indicatorColor(honor), "0.5,0.5,0.5", "Options reset restores gray indicator")
equal(Utils:DisplayTimer(90061), "25:01:01", "timers longer than 24 hours")
print("PASS: "..checks.." Forever migration checks (".._VERSION..")")
