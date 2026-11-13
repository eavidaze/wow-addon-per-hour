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
function methods:Show()
    if self.shown then return end
    self.shown = true
    if self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:Hide()
    if not self.shown then return end
    self.shown = false
    if self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:IsShown() return self.shown end
function methods:SetShown(value) if value then self:Show() else self:Hide() end end
function methods:SetText(value) self.text = value end
function methods:GetText() return self.text end
function methods:SetOwner(owner) self.owner = owner end
function methods:IsOwned(owner) return self.owner == owner end
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
function methods:AddLine(text)
    self.singleLines = rawget(self, "singleLines") or {}
    table.insert(self.singleLines, text)
end
function methods:AddDoubleLine(label, value)
    self.lines = rawget(self, "lines") or {}
    self.lines[label] = value
end
UIParent = object("UIParent")
UIParent:SetSize(1920, 1080)
Minimap = object("Minimap")
Minimap:SetSize(140, 140)
GameTooltip = object("GameTooltip")
function GameTooltip:SetText(text)
    self.text, self.lines, self.singleLines = text, {}, {}
end
local cursorX, cursorY = 400, 400
function GetCursorPosition() return cursorX, cursorY end
function CreateFrame(kind, name, parent, template)
    assert(template == nil or template == "UIPanelButtonTemplate" or template == "DialogBorderTranslucentTemplate"
        or template == "UIPanelCloseButton" or template == "UIPanelSquareButton", "unsupported template: "..tostring(template))
    if name then
        name = name:gsub("%$parent", parent.name or "")
        assert(not names[name], "duplicate frame name: "..name)
    end
    local frame = object(name)
    frame.parent, frame.template = parent, template
    if template == "UIPanelButtonTemplate" then frame.fontString = object() end
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
function UnitXP(_unit) return xp end
function UnitXPMax(_unit) return xpMax end
function UnitLevel(_unit) return level end
function UnitHonor(_unit) return honorValue end
function UnitHonorMax(_unit) return honorMax end
function UnitHonorLevel(_unit) return honorLevel end
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
equal(experience.Frame:GetTop(), 920, "saved window Y restored")
equal(reputation.Frame.point[4] - honor.Frame.point[4] > honor.Frame:GetWidth(), true, "default panels do not overlap")
local dragPanel = experience.Frame
dragPanel.scripts.OnDragStart(dragPanel)
equal(type(dragPanel.scripts.OnUpdate), "function", "panel starts cursor tracking")
experience.Frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -40, 80)
dragPanel.scripts.OnDragStop(dragPanel)
equal(dragPanel.scripts.OnUpdate, nil, "panel stops cursor tracking")
equal(PerHourAccount_Settings.Experience.position.x, 1700, "drag saves window X")
equal(PerHourAccount_Settings.Experience.position.y, 190, "drag saves window Y")
experience.Frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
PerHour.Displayer:RestorePositions()
equal(experience.Frame.point[1], "TOPLEFT", "dragged window anchor restored")
equal(experience.Frame.point[4], 1700, "dragged window position restored")
equal(experience.Frame.TitleText:GetText(), "Experience Per Hour", "panel title includes addon name")
equal(honor.Frame.TitleText:GetText(), "Honor Per Hour", "honor title includes addon name")
equal(reputation.Frame.TitleText:GetText(), "Reputation Per Hour", "reputation title includes addon name")
equal(experience.Frame:GetWidth(), 180, "compact panel width")
equal(experience.Frame:GetHeight(), 110, "compact panel height")
equal(experience.DetailsButton, nil, "details toggle removed")
equal(experience.DetailsFrame, nil, "expandable details removed")
equal(experience.ToggleStartButton.point[2], experience.OptionsButton, "start button leaves room for the footer gear")
local panelTop, panelLeft = experience.Frame:GetTop(), experience.Frame:GetLeft()
experience.Frame.scripts.OnEnter(experience.Frame)
equal(GameTooltip:GetText(), "Experience", "session tooltip title")
equal(GameTooltip.singleLines[1], "Not started", "idle session status")
equal(GameTooltip.lines.Duration, "00:00", "idle duration")
equal(GameTooltip.lines["Total XP"], "0", "idle XP total")
equal(GameTooltip.lines["XP/h"], "0", "idle hourly rate")
equal(GameTooltip.lines["XP/min"], "0", "idle minute rate")
equal(experience.Frame:GetHeight(), 110, "hover keeps compact height")
equal(experience.Frame:GetTop(), panelTop, "hover preserves panel top")
equal(experience.Frame:GetLeft(), panelLeft, "hover preserves panel left")
experience.Frame.scripts.OnLeave()
equal(GameTooltip:IsShown(), false, "leaving panel hides session tooltip")
experience.OptionsButton.scripts.OnEnter(experience.OptionsButton)
equal(GameTooltip:GetText(), "Options", "gear tooltip identifies options")
equal(table.concat(experience.OptionsButton.icon.texCoords, ","), "0,1,0,1", "gear displays its entire texture")
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
experience.Frame.scripts.OnEnter(experience.Frame)
equal(GameTooltip.singleLines[1], "Running", "running session status")
xp = 150
tick(2)
equal(experience.Element, 50, "first XP gain")
equal(experience.ElementPerHour, 90000, "XP per hour")
equal(experience.ElementPerHourValue:GetText(), "90,000", "fitting rates retain full precision")
equal(experience.RateUnit:GetText(), "XP/h", "inline rate unit")
equal(GameTooltip.lines.Duration, "00:02", "hovered duration updates live")
equal(GameTooltip.lines["Total XP"], "50", "hovered XP total updates live")
experience.Frame.scripts.OnEnter(experience.Frame)
equal(GameTooltip.lines["XP/min"], "1,500", "tooltip shows per-minute rate")
equal(GameTooltip.lines["XP/h"], "90,000", "tooltip shows full hourly rate")
experience.Frame.scripts.OnLeave()
experience.Frame:Hide()
xp = 200
tick(2)
equal(experience.Element, 100, "XP tracks while hidden")
equal(GameTooltip:IsShown(), false, "tracking does not reopen a dismissed tooltip")
experience.Frame:Show()
experience.Frame.scripts.OnEnter(experience.Frame)
xp = 250
click(experience)
equal(experience.Element, 150, "gain immediately before pause")
equal(GameTooltip.lines["Total XP"], "150", "pause refreshes tooltip immediately")
equal(GameTooltip.singleLines[1], "Paused", "tooltip reflects pause immediately")
equal(experience.ToggleStartButton:GetText(), "Resume", "paused action is Resume")
equal(indicatorColor(experience), "1,0.8,0", "paused indicator is yellow")
xp = 300
tick(2)
equal(GameTooltip.lines.Duration, "00:04", "paused tooltip duration stays frozen")
equal(GameTooltip.lines["Total XP"], "150", "paused tooltip excludes gains")
xp = 350
click(experience)
tick(2)
equal(experience.ToggleStartButton:GetText(), "Pause", "resume restores Pause action")
equal(indicatorColor(experience), "0.2,1,0.2", "resuming restores green indicator")
equal(experience.Element, 150, "paused XP excluded on resume")
equal(experience.Time, 6, "pause duration excluded")
equal(GameTooltip.lines.Duration, "00:06", "resumed tooltip excludes paused time")
equal(GameTooltip.singleLines[1], "Running", "resumed tooltip status")
level, xp, xpMax = 11, 50, 900
tick(2)
equal(experience.Element, 850, "level up with lower XP requirement")
xp = { secret = true }
tick(2)
equal(experience.Element, 850, "secret XP ignored")
xp = 100
tick(2)
equal(experience.Element, 900, "XP resumes when readable")
-- Loading screens can temporarily expose empty player progress.
xp, xpMax = 0, 0
tick(2)
equal(experience.Element, 900, "loading screen adds no XP")
xp, xpMax, level = 100, 900, 11
tick(2)
equal(experience.Element, 900, "hearthstone does not recount accumulated XP")
xp = 125
tick(2)
equal(experience.Element, 925, "real XP after travel is counted")
-- Also tolerate incomplete snapshots after the world has loaded.
xp, xpMax, level = 0, 0, 0
tick(2)
xp, xpMax, level = 125, 900, 11
tick(2)
equal(experience.Element, 925, "empty player snapshot does not create XP")
xp = 0
tick(2)
xp = 125
tick(2)
equal(experience.Element, 925, "temporary XP regression does not create XP")
xpMax = 0
tick(2)
xp, xpMax, level = 25, 1000, 12
tick(2)
equal(experience.Element, 1725, "invalid maximum does not corrupt level-up XP")
BaseModule:ResetModule(experience)
equal(experience.Element, 0, "reset XP")
equal(experience.HasStarted, false, "reset stops tracker")
equal(experience.ToggleStartButton:GetText(), "Start", "reset restores Start action")
equal(indicatorColor(experience), "0.5,0.5,0.5", "reset restores gray indicator")
equal(GameTooltip.lines["Total XP"], "0", "reset clears hovered total")
equal(GameTooltip.lines.Duration, "00:00", "reset clears hovered duration")
equal(GameTooltip.singleLines[1], "Not started", "reset updates hovered status")
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
reputation:SetIsShown(true)
reputation.Frame:Show()
reputation.Frame.scripts.OnEnter(reputation.Frame)
equal(GameTooltip.singleLines[2], "Stormwind", "tooltip identifies tracked faction")
watched.currentStanding = 100
tick(2)
equal(reputation.Element, 100, "reputation gain from zero")
watched.currentStanding = -50
tick(2)
equal(reputation.Element, -50, "reputation loss")
equal(GameTooltip.lines["Total Reputation"], "-50", "tooltip includes negative reputation total")
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
equal(GameTooltip.singleLines[2], "No active session", "reset clears tooltip faction")
click(reputation)
watched = nil
tick(10)
equal(reputation.HasStarted, false, "missing faction timeout in real seconds")
click(reputation)
equal(reputation.HasStarted, false, "start requires watched faction")
equal(indicatorColor(reputation), "0.5,0.5,0.5", "failed start keeps gray indicator")

minimapButton.scripts.OnEnter(minimapButton)
click(honor)
equal(honor.ElementPerHour, 0, "zero-time start has finite rate")
honorValue = 125
tick(2)
equal(honor.Element, 25, "honor from modern API")
equal(GameTooltip:GetText(), "Per Hour", "tracker updates preserve another owner's tooltip")
minimapButton.scripts.OnLeave(minimapButton)
honor:SetIsShown(true)
honor.Frame:Show()
honor.Frame.scripts.OnEnter(honor.Frame)
equal(GameTooltip.lines["Total Honor"], "25", "honor tooltip uses its own unit")
honor.Frame.scripts.OnLeave()
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

local panels = { experience, honor, reputation }
local function setPanelPosition(module, x, y)
    module.Frame:ClearAllPoints()
    module.Frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
end
local function showPanel(module, shown)
    module:SetIsShown(shown)
    module.Frame:SetShown(shown)
end
local function assertPanelLayout(label)
    for index, module in ipairs(panels) do
        local frame = module.Frame
        if frame:IsShown() then
            equal(frame:GetLeft() >= 0 and frame:GetLeft() + frame:GetWidth() <= UIParent:GetWidth()
                and frame:GetTop() <= UIParent:GetHeight() and frame:GetTop() - frame:GetHeight() >= 0,
                true, label .. ": " .. module.Name .. " stays on screen")
            for otherIndex = index + 1, #panels do
                local other = panels[otherIndex].Frame
                if other:IsShown() then
                    equal(frame:GetLeft() + frame:GetWidth() <= other:GetLeft()
                        or other:GetLeft() + other:GetWidth() <= frame:GetLeft()
                        or frame:GetTop() <= other:GetTop() - other:GetHeight()
                        or other:GetTop() <= frame:GetTop() - frame:GetHeight(),
                        true, label .. ": " .. module.Name .. " avoids " .. panels[otherIndex].Name)
                end
            end
        end
    end
end
for index, module in ipairs(panels) do
    showPanel(module, false)
    setPanelPosition(module, 100 + (index - 1) * 400, 500)
end
for _, module in ipairs(panels) do showPanel(module, true) end
local honorLeft, honorTop = honor.Frame:GetLeft(), honor.Frame:GetTop()
cursorX, cursorY = 400, 400
dragPanel.scripts.OnDragStart(dragPanel)
for _, target in ipairs({
    { 500, 500 }, { 900, 500 }, { 680, 500 }, { 500, 420 },
    { -500, 1600 }, { 2400, -300 }, { 1740, 86 }, { 100, 500 },
}) do
    cursorX, cursorY = 400 + (target[1] - 100) * 2, 400 + (target[2] - 500) * 2
    dragPanel.scripts.OnUpdate(dragPanel)
    assertPanelLayout("drag target " .. target[1] .. "," .. target[2])
end
dragPanel.scripts.OnDragStop(dragPanel)
equal(honor.Frame:GetLeft(), honorLeft, "drag leaves neighboring X unchanged")
equal(honor.Frame:GetTop(), honorTop, "drag leaves neighboring Y unchanged")
equal(PerHourAccount_Settings.Experience.position.x, experience.Frame:GetLeft(), "drag persists collision-free X")
equal(PerHourAccount_Settings.Experience.position.y, experience.Frame:GetTop(), "drag persists collision-free Y")

showPanel(honor, false)
setPanelPosition(honor, experience.Frame:GetLeft(), experience.Frame:GetTop())
showPanel(honor, true)
assertPanelLayout("reopening an overlapping panel")
for _, module in ipairs(panels) do
    PerHourAccount_Settings[module.Name].position = { point = "TOPLEFT", relativePoint = "BOTTOMLEFT", x = 750, y = 700 }
end
PerHour.Displayer:RestorePositions()
assertPanelLayout("restoring three identical saved positions")
local resolvedPositions = {}
for index, module in ipairs(panels) do
    resolvedPositions[index] = module.Frame:GetLeft() .. "," .. module.Frame:GetTop()
end
PerHour.Displayer:RestorePositions()
for index, module in ipairs(panels) do
    equal(module.Frame:GetLeft() .. "," .. module.Frame:GetTop(), resolvedPositions[index], "resolved position stays stable for " .. module.Name)
end
PerHourAccount_Settings.Experience.position.x, PerHourAccount_Settings.Experience.position.y = 5000, -100
PerHour.Displayer:RestorePositions()
assertPanelLayout("restoring off-screen positions")

for _, module in ipairs(panels) do showPanel(module, false) end
setPanelPosition(experience, 300, 500)
setPanelPosition(honor, 300, 380)
setPanelPosition(reputation, 800, 500)
for _, module in ipairs(panels) do showPanel(module, true) end
experience.Frame.scripts.OnEnter(experience.Frame)
assertPanelLayout("hover near another panel")
equal(experience.Frame:GetHeight(), 110, "hover does not resize panels")
equal(honor.Frame:GetTop(), 380, "hover leaves neighbor in place")
experience.Frame.scripts.OnLeave()

dragPanel.scripts.OnDragStart(dragPanel)
showPanel(experience, false)
equal(dragPanel.scripts.OnUpdate, nil, "hiding a dragged panel stops cursor tracking")
showPanel(honor, false)
showPanel(reputation, false)
UIParent:SetSize(180, 110)
setPanelPosition(experience, 0, 110)
showPanel(experience, true)
showPanel(honor, true)
equal(honor.Frame:IsShown(), false, "no free space prevents showing an overlapping panel")
equal(honor:IsShown(), false, "no free space saves hidden visibility")
experience.Frame.scripts.OnEnter(experience.Frame)
equal(experience.Frame:GetHeight(), 110, "hover fits compact screen")
experience.Time = 90061
BaseModule:RefreshDisplayedValues(experience)
equal(GameTooltip.lines.Duration, "25:01:01", "tooltip supports sessions longer than 24 hours")
showPanel(experience, false)
equal(GameTooltip:IsShown(), false, "hiding a panel dismisses its tooltip")
showPanel(experience, true)
assertPanelLayout("screen only fits one compact panel")
UIParent:SetSize(1920, 1080)
print("PASS: "..checks.." Forever migration checks (".._VERSION..")")
