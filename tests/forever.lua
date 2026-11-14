-- Run from the repository root with Lua 5.1: lua tests/forever.lua
local frames, names, messages, sent = {}, {}, {}, {}
local now, xp, xpMax, level = 0, 100, 1000, 10
local playedTotal, playedRequests = 100000, 0
local playedRequested, autoPlayedReply = false, true
local timers = {}
local honorBalance = 100
local watched = { name = "Stormwind", factionID = 72, currentStanding = 0 }
local checks = 0
local function equal(actual, expected, label)
    assert(actual == expected, label..": expected "..tostring(expected)..", got "..tostring(actual))
    checks = checks + 1
end
local function near(actual, expected, label)
    assert(math.abs(actual - expected) < 0.000001, label..": expected "..expected..", got "..actual)
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
function methods:IsVisible()
    local parent = rawget(self, "parent")
    return self.shown and (not parent or parent:IsVisible())
end
function methods:SetAlpha(alpha) self.alpha = alpha end
function methods:GetAlpha() return rawget(self, "alpha") or 1 end
function methods:SetIgnoreParentAlpha(ignore) self.ignoreParentAlpha = ignore end
function methods:GetEffectiveAlpha()
    local parent = rawget(self, "parent")
    if not parent or rawget(self, "ignoreParentAlpha") then return self:GetAlpha() end
    return self:GetAlpha() * parent:GetEffectiveAlpha()
end
function methods:SetShown(value) if value then self:Show() else self:Hide() end end
function methods:SetText(value)
    self.text = value
    if rawget(self, "template") == "SharedGoldRedButtonSmallTemplate" and not rawget(self, "fontString") then
        self.fontString = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    end
end
function methods:GetText() return self.text end
function methods:SetOwner(owner) self.owner = owner end
function methods:IsOwned(owner) return self.owner == owner end
function methods:GetFontString() return rawget(self, "fontString") end
function methods:SetVertexColor(...) self.vertexColor = { ... } end
function methods:SetTexture(texture)
    assert(texture ~= nil, "texture must be available")
    self.texture = texture
end
function methods:SetColorTexture(...) self.color = { ... } end
function methods:SetAtlas(atlas)
    assert(type(atlas) == "string", "atlas must be available")
    self.atlas = atlas
end
function methods:SetEnabled(enabled) self.enabled = enabled end
function methods:EnableMouse(enabled) self.mouseEnabled = enabled end
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
    assert(template == nil or template == "UIPanelButtonTemplate" or template == "SharedGoldRedButtonSmallTemplate"
        or template == "DialogBorderTranslucentTemplate"
        or template == "UIPanelCloseButton" or template == "UIPanelSquareButton", "unsupported template: "..tostring(template))
    if name then
        name = name:gsub("%$parent", parent.name or "")
        assert(not names[name], "duplicate frame name: "..name)
    end
    local frame = object(name)
    frame.parent, frame.template = parent, template
    if template == "DialogBorderTranslucentTemplate" then
        frame.Bg = object()
    end
    if template == "UIPanelButtonTemplate" then
        frame.fontString = object()
    end
    if template == "SharedGoldRedButtonSmallTemplate" then
        frame.Left, frame.Center, frame.Right = object(), object(), object()
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
C_Timer = { After = function(delay, callback)
    timers[#timers + 1] = { deadline = now + delay, callback = callback }
end }
function RequestTimePlayed()
    playedRequests = playedRequests + 1
    playedRequested = true
end
READY_CHECK_READY_TEXTURE_RAID = "ready"
READY_CHECK_NOT_READY_TEXTURE_RAID = "not-ready"
READY_CHECK_WAITING_TEXTURE_RAID = "waiting"
local abbreviatedValue
function AbbreviateLargeNumbers(value)
    abbreviatedValue = value
    return "1T"
end
function UnitXP(_unit) return xp end
function UnitXPMax(_unit) return xpMax end
function UnitLevel(_unit) return level end
-- Keep honor-level XP fixed, matching the live dump even when Honor Points increase.
function UnitHonor(_unit) return 0 end
function UnitHonorMax(_unit) return 5500 end
function UnitHonorLevel(_unit) return 1 end
function issecretvalue(value) return type(value) == "table" and value.secret == true end
DEFAULT_CHAT_FRAME = { AddMessage = function(_, message) messages[#messages + 1] = message end }
C_Reputation = { GetWatchedFactionData = function() return watched end }
C_CurrencyInfo = { GetCurrencyInfo = function(id)
    if id == 1792 then return { name = "Honor Points", quantity = honorBalance, totalEarned = 0 } end
end }
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
local function loadAddon()
    for line in read("per-hour.toc"):gmatch("[^\r\n]+") do
        if not line:match("^#") and line:match("%S") then loadSource(line) end
    end
end
loadAddon()
local function event(name, ...)
    if name == "TIME_PLAYED_MSG" then playedRequested = false end
    for _, frame in ipairs(frames) do
        if frame.events[name] then frame.scripts.OnEvent(frame, name, ...) end
    end
    if name == "PLAYER_ENTERING_WORLD" and autoPlayedReply and playedRequested then
        event("TIME_PLAYED_MSG", playedTotal, 0)
    end
end
local function changeHonor(amount)
    honorBalance = honorBalance + amount
    event("CURRENCY_DISPLAY_UPDATE", 1792, honorBalance, amount)
end
local function tick(seconds)
    if PerHour.Session.InWorld then playedTotal = playedTotal + seconds end
    now = now + seconds
    for _, frame in ipairs(frames) do
        if frame:IsVisible() and frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, seconds) end
    end
    for index = #timers, 1, -1 do
        if timers[index].deadline <= now then
            local callback = table.remove(timers, index).callback
            callback()
        end
    end
end
local function click(module) module.ToggleStartButton.scripts.OnClick() end
local experience, reputation, honor = PerHour.Modules.Experience, PerHour.Modules.Reputation, PerHour.Modules.Honor
local function indicatorColor(module)
    return table.concat(module.ActiveIndicator.vertexColor, ",")
end
event("ADDON_LOADED", "another-addon")
event("ADDON_LOADED", "per-hour")
event("PLAYER_ENTERING_WORLD")

equal(indicatorColor(experience), "0.5,0.5,0.5", "idle indicator is gray")
equal(experience.RestoreIndicator:IsShown(), false, "new session has no restore indicator")
equal(experience.RestoreIndicator.parent, experience.Frame, "restore indicator belongs to panel")
equal(experience.RestoreIndicator.point[1], "TOPLEFT", "restore indicator uses panel upper-left corner")
equal(experience.RestoreIndicator.point[2], experience.Frame, "restore indicator anchors to panel")
equal(experience.RestoreIndicator.point[3], "TOPLEFT", "restore indicator aligns with panel upper-left corner")
equal(experience.RestoreIndicator:GetWidth(), experience.Frame.CloseButton:GetWidth(), "restore indicator matches close button size")
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
equal(PerHourAccount_Settings.Experience.position.y, 174, "drag saves window Y")
experience.Frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
PerHour.Displayer:RestorePositions()
equal(experience.Frame.point[1], "TOPLEFT", "dragged window anchor restored")
equal(experience.Frame.point[4], 1700, "dragged window position restored")
equal(experience.Frame.TitleText:GetText(), "Experience Per Hour", "panel title includes addon name")
equal(honor.Frame.TitleText:GetText(), "Honor Per Hour", "honor title includes addon name")
equal(reputation.Frame.TitleText:GetText(), "Reputation Per Hour", "reputation title includes addon name")
equal(experience.Frame:GetWidth(), 180, "compact panel width")
equal(experience.Frame:GetHeight(), 94, "compact panel height")
equal(experience.DetailsButton, nil, "details toggle removed")
equal(experience.DetailsFrame, nil, "expandable details removed")
equal(experience.ToggleStartButton.point[2], experience.OptionsButton, "start button leaves room for the footer gear")

-- Close visibility follows panel geometry, including child controls and its protruding corner.
do
    local panel, close = experience.Frame, experience.Frame.CloseButton
    local savedCursorX, savedCursorY = cursorX, cursorY
    local function hoverAt(x, y, seconds)
        cursorX, cursorY = x * panel:GetEffectiveScale(), y * panel:GetEffectiveScale()
        close.scripts.OnUpdate(close, seconds)
    end
    local insideX, insideY = panel:GetLeft() + 20, panel:GetTop() - 20
    local outsideX, outsideY = panel:GetLeft() - 50, panel:GetTop() + 50
    equal(close:GetAlpha(), 0, "close starts transparent")
    equal(close.mouseEnabled, false, "transparent close cannot intercept clicks")
    panel.GetLeft = function() return nil end
    hoverAt(insideX, insideY, 0.04)
    equal(close:GetAlpha(), 0, "close tolerates panel bounds before layout")
    panel.GetLeft = nil
    hoverAt(insideX, insideY, 0.04)
    equal(close:GetAlpha(), 0.5, "close fades halfway in after 0.04 seconds")
    equal(close.mouseEnabled, true, "visible close accepts clicks")
    hoverAt(insideX, insideY, 0.04)
    equal(close:GetAlpha(), 1, "close finishes fade in after 0.08 seconds")
    hoverAt(insideX, panel:GetTop() - panel:GetHeight() + 2, 0.2)
    equal(close:GetAlpha(), 1, "hovering the footer keeps close visible")
    hoverAt(panel:GetLeft() + panel:GetWidth() + 1, panel:GetTop() + 1, 0.2)
    equal(close:GetAlpha(), 1, "protruding close stays visible while hovered")
    hoverAt(outsideX, outsideY, 0.04)
    equal(close:GetAlpha(), 0.5, "close fades halfway out after 0.04 seconds")
    hoverAt(outsideX, outsideY, 0.04)
    equal(close:GetAlpha(), 0, "close finishes fade out after 0.08 seconds")
    equal(close.mouseEnabled, false, "transparent close stops intercepting clicks")
    hoverAt(insideX, insideY, 0.04)
    hoverAt(outsideX, outsideY, 0.02)
    equal(close:GetAlpha(), 0.25, "leaving during fade reverses from current alpha")
    hoverAt(insideX, insideY, 0.02)
    equal(close:GetAlpha(), 0.5, "reentering restarts the short fade in")
    panel:Hide()
    equal(close:GetAlpha(), 0, "hiding panel clears partial close fade")
    equal(close.mouseEnabled, false, "hiding panel disables close interaction")
    panel:Show()
    equal(close:GetAlpha(), 0, "reopened panel starts with transparent close")
    hoverAt(outsideX, outsideY, 1)
    equal(close:GetAlpha(), 0, "close remains transparent outside panel")
    cursorX, cursorY = savedCursorX, savedCursorY
end
local panelTop, panelLeft = experience.Frame:GetTop(), experience.Frame:GetLeft()
experience.Frame.scripts.OnEnter(experience.Frame)
equal(GameTooltip:GetText(), "Experience", "session tooltip title")
equal(GameTooltip.singleLines[1], "Not started", "idle session status")
equal(GameTooltip.lines.Duration, "00:00", "idle duration")
equal(GameTooltip.lines["Total XP"], "0", "idle XP total")
equal(GameTooltip.lines["XP/h"], "0", "idle hourly rate")
equal(GameTooltip.lines["XP/min"], "0", "idle minute rate")
equal(experience.Frame:GetHeight(), 94, "hover keeps compact height")
equal(experience.Frame:GetTop(), panelTop, "hover preserves panel top")
equal(experience.Frame:GetLeft(), panelLeft, "hover preserves panel left")
experience.Frame.scripts.OnLeave()
equal(GameTooltip:IsShown(), false, "leaving panel hides session tooltip")
experience.OptionsButton.scripts.OnEnter(experience.OptionsButton)
equal(GameTooltip:GetText(), "Options", "gear tooltip identifies options")
equal(table.concat(experience.OptionsButton.Icon.texCoords, ","), "0,1,0,1", "gear displays its entire texture")
for name, module in pairs(PerHour.Modules) do
    equal(table.concat(module.RestoreIndicator.Border.vertexColor, ","),
        table.concat(module.OptionsButton.Border.vertexColor, ","), name .. " uses the same gold for both circular borders")
    equal(module.RestoreIndicator.Border ~= module.OptionsButton.Border, true, name .. " keeps circular artwork independent")
end
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

-- Live Forever reports honor as currency 1792 while UnitHonor stays at zero.
do
    local balance = honorBalance
    honorBalance = 118
    click(honor)
    equal(honor.Element, 0, "starting does not count the existing honor balance")
    equal(C_CurrencyInfo.GetCurrencyInfo(1792).totalEarned, 0, "live honor currency has no useful lifetime total")
    equal(UnitHonor("player"), 0, "honor-level XP stays independent of spendable honor")
    tick(2)
    changeHonor(8)
    equal(honor.Element, 8, "an eight-point honor currency gain is captured")
    equal(honor.ElementPerHourValue:GetText(), "14,400", "honor gains refresh the displayed rate immediately")
    equal(honor.Frame:IsShown(), false, "currency gains are captured while the panel is hidden")
    changeHonor(-100)
    equal(honor.Element, 8, "spending does not subtract from earned honor")
    changeHonor(8)
    equal(honor.Element, 16, "gains count even when the balance is below the starting balance")
    event("CHAT_MSG_COMBAT_HONOR_GAIN", "Enemy slain: 8 honor.")
    equal(honor.Element, 16, "chat announcements do not double-count currency gains")
    for _, payload in ipairs({
        { 1901, 100, 8 }, { 1602, 100, 8 }, {}, { 1792, 100 },
        { 1792, 100, 0 }, { 1792, 100, -8 }, { 1792, 100, math.huge },
        { 1792, 100, 0 / 0 }, { 1792, 100, "8" }, { 1792, 100, { secret = true } },
        { { secret = true }, 100, 8 },
    }) do
        event("CURRENCY_DISPLAY_UPDATE", unpack(payload))
        equal(honor.Element, 16, "unrelated, invalid and non-gain currency updates are ignored")
    end
    click(honor)
    changeHonor(8)
    equal(honor.Element, 16, "paused currency gains are excluded")
    click(honor)
    changeHonor(3)
    equal(honor.Element, 19, "resuming counts only new currency gains")
    event("PLAYER_LEAVING_WORLD")
    changeHonor(8)
    equal(honor.Element, 19, "currency events outside the world are excluded")
    event("PLAYER_ENTERING_WORLD")
    changeHonor(2)
    equal(honor.Element, 21, "returning to the world counts new gains")
    event("PLAYER_LOGOUT")
    equal(PerHourCharacter_Values.sessions.Honor.total, 21, "logout saves currency gains without waiting for a tracker tick")
    BaseModule:ResetModule(honor)
    changeHonor(8)
    equal(honor.Element, 0, "reset stops currency event tracking")
    honorBalance = balance
end

minimapButton.scripts.OnEnter(minimapButton)
click(honor)
equal(honor.ElementPerHour, 0, "zero-time start has finite rate")
changeHonor(25)
tick(2)
equal(honor.Element, 25, "honor from the currency gain event")
equal(GameTooltip:GetText(), "Per Hour", "tracker updates preserve another owner's tooltip")
minimapButton.scripts.OnLeave(minimapButton)
honor:SetIsShown(true)
honor.Frame:Show()
honor.Frame.scripts.OnEnter(honor.Frame)
equal(GameTooltip.lines["Total Honor"], "25", "honor tooltip uses its own unit")
honor.Frame.scripts.OnLeave()
changeHonor(100)
tick(2)
equal(honor.Element, 125, "bonus honor")
changeHonor(325)
tick(2)
equal(honor.Element, 450, "currency rewards accumulate without honor-level changes")
changeHonor(-500)
equal(honor.Element, 450, "spending honor does not reduce earned totals")
event("CURRENCY_DISPLAY_UPDATE", 1792, honorBalance, { secret = true })
tick(2)
equal(honor.Element, 450, "secret honor ignored")
changeHonor(25)
tick(2)
equal(honor.Element, 475, "honor resumes when readable")
click(honor)
changeHonor(25)
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
equal(experience.Frame:GetHeight(), 94, "hover does not resize panels")
equal(honor.Frame:GetTop(), 380, "hover leaves neighbor in place")
experience.Frame.scripts.OnLeave()

dragPanel.scripts.OnDragStart(dragPanel)
showPanel(experience, false)
equal(dragPanel.scripts.OnUpdate, nil, "hiding a dragged panel stops cursor tracking")
showPanel(honor, false)
showPanel(reputation, false)
UIParent:SetSize(180, 94)
setPanelPosition(experience, 0, 94)
showPanel(experience, true)
showPanel(honor, true)
equal(honor.Frame:IsShown(), false, "no free space prevents showing an overlapping panel")
equal(honor:IsShown(), false, "no free space saves hidden visibility")
experience.Frame.scripts.OnEnter(experience.Frame)
equal(experience.Frame:GetHeight(), 94, "hover fits compact screen")
experience.Time = 90061
BaseModule:RefreshDisplayedValues(experience)
equal(GameTooltip.lines.Duration, "25:01:01", "tooltip supports sessions longer than 24 hours")
showPanel(experience, false)
equal(GameTooltip:IsShown(), false, "hiding a panel dismisses its tooltip")
showPanel(experience, true)
assertPanelLayout("screen only fits one compact panel")
UIParent:SetSize(1920, 1080)

-- Recreate the addon and its frames, preserving only SavedVariables as the client does.
local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end
local function login(savedValues, clock, options)
    options = options or {}
    frames, names = {}, {}
    timers = {}
    GameTooltip:Hide()
    PerHourCharacter_Values = copy(savedValues)
    local loaded = PerHourCharacter_Values
    playedTotal = options.total or (savedValues and savedValues.playedAtSave) or 100000
    autoPlayedReply = options.autoReply ~= false
    playedRequested = false
    now = clock
    loadAddon()
    experience, reputation, honor = PerHour.Modules.Experience, PerHour.Modules.Reputation, PerHour.Modules.Honor
    equal(PerHourCharacter_Values, loaded, "initial panel reset preserves saved sessions")
    event("ADDON_LOADED", "per-hour")
    local loadingSeconds = options.loadingSeconds or 4
    tick(loadingSeconds)
    playedTotal = playedTotal + loadingSeconds
    equal(experience.HasStarted, false, "restore waits for world entry")
    event("PLAYER_ENTERING_WORLD")
end
local function showRestoreTooltip(module)
    module.RestoreIndicator.scripts.OnEnter(module.RestoreIndicator)
end

for _, module in pairs(PerHour.Modules) do BaseModule:ResetModule(module) end
xp, xpMax, level = 100, 1000, 10
honorBalance = 100
watched = { name = "Stormwind", factionID = 72, currentStanding = -100 }
for _, module in pairs(PerHour.Modules) do click(module) end
xp, watched.currentStanding = 200, -50
changeHonor(25)
tick(2)
click(honor)
xp, watched.currentStanding = 225, -60
changeHonor(75)
now, playedTotal = now + 0.5, playedTotal + 0.5
event("PLAYER_LOGOUT")
local saved = copy(PerHourCharacter_Values)
equal(saved.version, 2, "save uses global played-time format")
equal(saved.playedAtSave, playedTotal, "played reference aligns with final module sample")
equal(saved.sessions.Experience.total, 125, "logout samples pending XP")
equal(saved.sessions.Experience.duration, 2.5, "logout samples pending active time")
equal(saved.sessions.Honor.total, 25, "logout excludes paused honor")
equal(saved.sessions.Honor.duration, 2, "logout excludes paused time")
equal(saved.sessions.Honor.paused, true, "logout preserves manual pause")
equal(saved.sessions.Reputation.total, 40, "logout samples reputation loss")
for name, module in pairs(PerHour.Modules) do
    equal(saved.sessions[name].checkpoint, nil, name .. " has no individual checkpoint")
    equal(module.CustomGetCheckpoint, nil, name .. " has no checkpoint hook")
end

-- A matching global clock accepts every module, regardless of its raw counters.
xp, honorBalance, watched.currentStanding = 400, 300, 100
local requestsBefore = playedRequests
login(saved, now + 7200)
equal(playedRequests, requestsBefore + 1, "one played query serves all modules")
for name, module in pairs(PerHour.Modules) do
    equal(module.RestoreStatus, "success", name .. " shares successful continuity check")
    equal(module.RestoreIndicator.Icon.atlas, READY_CHECK_READY_TEXTURE_RAID, name .. " shows positive icon")
end
equal(experience.Element, 125, "reload preserves XP total and excludes offline gains")
equal(experience.Time, 2.5, "reload excludes offline and initialization time")
equal(experience.ElementPerHour, 180000, "restored rates use active duration")
equal(honor.HasPaused, true, "manual pause survives successful validation")
equal(reputation.LastFactionID, 72, "reputation retains faction context")
showRestoreTooltip(experience)
equal(GameTooltip:GetText(), "Session restored successfully.", "success tooltip title")
equal(GameTooltip.singleLines[1], "Played time matches the saved session (30-second tolerance).", "success tooltip explains global check")
xp, watched.currentStanding = 450, 120
changeHonor(50)
tick(2)
equal(experience.Element, 175, "first XP gain after restore is included")
equal(experience.Time, 4.5, "active duration continues after restore")
equal(honor.Element, 25, "restored pause excludes gains")
equal(honor.Time, 2, "restored pause freezes duration")
equal(reputation.Element, 60, "first reputation gain after restore is included")
equal(GameTooltip:GetText(), "Session restored successfully.", "tracker preserves indicator tooltip")
experience.Frame:Hide()
equal(GameTooltip:IsShown(), false, "hiding panel dismisses restore tooltip")
experience.Frame:Show()
click(honor)
changeHonor(25)
tick(2)
equal(honor.Element, 50, "honor resumes counting new currency events")
equal(honor.Time, 4, "honor excludes the full manual pause")
event("PLAYER_LOGOUT")
local resumedSave = copy(PerHourCharacter_Values)
login(resumedSave, 0)
equal(experience.Time, 6.5, "relogin survives a restarted local clock")
equal(experience.HasPaused, false, "running session resumes after relogin")
xp = 475
changeHonor(25)
tick(2)
equal(experience.Element, 200, "XP continues after relogin")
equal(honor.Element, 75, "honor continues after relogin")

-- Losing only duration is enough to fail, even when no module counter changes.
event("PLAYER_LOGOUT")
local unchangedProgressSave = copy(PerHourCharacter_Values)
local unchangedXP, unchangedHonor, unchangedReputation = xp, honorBalance, watched.currentStanding
login(unchangedProgressSave, 0, { total = unchangedProgressSave.playedAtSave + 120 })
equal(xp, unchangedXP, "duration-only interruption leaves XP unchanged")
equal(honorBalance, unchangedHonor, "duration-only interruption leaves honor unchanged")
equal(watched.currentStanding, unchangedReputation, "duration-only interruption leaves reputation unchanged")
for name, module in pairs(PerHour.Modules) do
    equal(module.RestoreStatus, "error", name .. " detects unsaved duration without gains")
end

-- Tolerance is shared, inclusive, and independent of gains or progression levels.
for _, delta in ipairs({ -31, -30, 0, 30, 31, 120 }) do
    login(saved, 0, { total = saved.playedAtSave + delta })
    local expected = math.abs(delta) <= 30 and "success" or "error"
    for name, module in pairs(PerHour.Modules) do
        equal(module.RestoreStatus, expected, name .. " validates played delta " .. delta)
        if expected == "error" then
            equal(module.HasPaused, true, name .. " pauses after continuity loss")
            equal(module.Element, saved.sessions[name].total, name .. " preserves totals after continuity loss")
        end
    end
end
showRestoreTooltip(experience)
equal(GameTooltip:GetText(), "Session integrity check failed.", "error tooltip title")
equal(GameTooltip.singleLines[1], "Played time differs from the last save by more than 30 seconds.", "error explains played-time mismatch")
equal(GameTooltip.singleLines[3], "Exit the game normally to save your session.", "error recommends only normal exit")
tick(30)
equal(experience.RestoreIndicator:IsShown(), true, "unresolved error has no timeout")
equal(experience.Time, saved.sessions.Experience.duration, "error does not accrue active time")
event("PLAYER_LOGOUT")
equal(PerHourCharacter_Values.sessions.Experience.needsReview, true, "unresolved error remains saved")
login(PerHourCharacter_Values, 0)
showRestoreTooltip(experience)
equal(GameTooltip.singleLines[1], "This session contains unverified progress.", "new checkpoint does not hide unresolved review")
click(experience)
equal(experience.RestoreStatus, nil, "Resume acknowledges error")
equal(GameTooltip:IsShown(), false, "Resume dismisses error tooltip")
tick(0.5)
equal(experience.RestoreIndicator:GetAlpha(), 1, "error waits half a second after decision")
tick(0.04)
near(experience.RestoreIndicator:GetAlpha(), 0.5, "error fades halfway after 0.04 seconds")
tick(0.05)
equal(experience.RestoreIndicator:IsShown(), false, "error hides at end of fade")
equal(honor.RestoreStatus, "error", "acknowledging one module leaves others for review")
event("PLAYER_LOGOUT")
equal(PerHourCharacter_Values.sessions.Experience.needsReview, false, "acknowledged error is no longer persisted")
honor.Frame:Show()
BaseModule:ResetModule(honor)
tick(0.5)
equal(honor.RestoreIndicator:GetAlpha(), 1, "Reset also waits before fading error")
tick(0.04)
near(honor.RestoreIndicator:GetAlpha(), 0.5, "Reset uses the standard fade out")
tick(0.05)
equal(honor.RestoreIndicator:IsShown(), false, "Reset completes error fade")
equal(PerHourCharacter_Values.sessions.Honor, nil, "Reset clears saved session")

-- Normalize delayed replies: 28 extra seconds plus 8 seconds in this login still pass.
login(saved, 0, { total = saved.playedAtSave + 28, autoReply = false })
equal(experience.RestoreIndicator:GetAlpha(), 0, "pending indicator starts transparent")
tick(0.04)
near(experience.RestoreIndicator:GetAlpha(), 0.5, "pending indicator uses the standard fade in")
tick(0.05)
equal(experience.RestoreIndicator:GetAlpha(), 1, "pending indicator completes fade in")
equal(experience.RestoreIndicator.scripts.OnUpdate, nil, "persistent indicator stops updating after fade in")
for name, module in pairs(PerHour.Modules) do
    equal(module.RestoreStatus, "pending", name .. " waits for played reply")
    equal(module.ToggleStartButton.enabled, false, name .. " cannot resume before check")
end
changeHonor(8)
equal(honor.Element, saved.sessions.Honor.total, "currency gains during pending restore are excluded")
click(experience)
equal(experience.HasPaused, true, "pending validation blocks early Resume")
tick(8)
equal(experience.Time, 2.5, "waiting for reply does not inflate session duration")
event("TIME_PLAYED_MSG", playedTotal, 0)
equal(experience.RestoreStatus, "success", "delayed reply excludes time since login")
event("PLAYER_LOGOUT")
equal(PerHourCharacter_Values.playedAtSave, playedTotal, "save uses received played sample")
tick(7)
event("PLAYER_LOGOUT")
equal(PerHourCharacter_Values.playedAtSave, playedTotal, "save extrapolates played sample to current time")

-- Saving before the reply preserves the original reference and pause choice.
login(saved, 0, { autoReply = false })
tick(2)
event("PLAYER_LOGOUT")
equal(PerHourCharacter_Values.playedAtSave, saved.playedAtSave, "pending save preserves original played reference")
equal(PerHourCharacter_Values.sessions.Experience.paused, false, "pending save preserves running choice")
equal(PerHourCharacter_Values.sessions.Honor.paused, true, "pending save preserves manual pause")
equal(PerHourCharacter_Values.sessions.Experience.total, 125, "pending save preserves totals")

-- A missing or failed query must never turn into success, including after a late reply.
login(saved, 0, { autoReply = false })
event("TIME_PLAYED_MSG", { secret = true }, 0)
event("TIME_PLAYED_MSG", math.huge, 0)
event("TIME_PLAYED_MSG", -1, 0)
equal(experience.RestoreStatus, "pending", "unreadable played replies are ignored")
tick(10)
equal(experience.RestoreStatus, "error", "played query timeout reports failure")
equal(experience.RestoreIssue, "Could not verify played time.", "timeout explains unavailable verification")
equal(experience.ToggleStartButton.enabled, true, "timeout allows explicit Resume or Reset")
event("TIME_PLAYED_MSG", playedTotal, 0)
equal(experience.RestoreStatus, "error", "late reply does not silently resume failed session")
local requestPlayed = RequestTimePlayed
RequestTimePlayed = nil
login(saved, 0)
equal(experience.RestoreIssue, "Played time is unavailable.", "missing API fails safely")
RequestTimePlayed = function() error("API unavailable") end
login(saved, 0)
equal(experience.RestoreStatus, "error", "API error does not break addon loading")
RequestTimePlayed = requestPlayed

-- Time spent loading before world entry is part of the new login, not an interruption.
login(saved, 0, { loadingSeconds = 90 })
equal(experience.RestoreStatus, "success", "long loading screen is excluded from continuity delta")
equal(experience.Time, saved.sessions.Experience.duration, "loading screen does not inflate active duration")

-- A new run without a server sample cannot reuse an older reference for newer totals.
login(saved, 0, { autoReply = false })
tick(10)
click(experience)
event("PLAYER_LOGOUT")
equal(PerHourCharacter_Values.playedAtSave, nil, "unsampled active run does not reuse stale played reference")

-- A successful clock check still waits for readable module baselines.
xp, xpMax, level = 0, 0, 0
watched = nil
login(saved, 0)
for name, module in pairs(PerHour.Modules) do
    equal(module.RestoreStatus, name == "Honor" and "success" or "pending",
        name .. " requires a baseline only when tracking counter differences")
end
tick(2)
xp, xpMax, level = 600, 1000, 10
honorBalance = 400
watched = { name = "Stormwind", factionID = 72, currentStanding = 500 }
tick(2)
for name, module in pairs(PerHour.Modules) do
    equal(module.RestoreStatus, "success", name .. " accepts delayed baseline without checkpoint")
end
equal(experience.Element, 125, "delayed XP baseline does not add unavailable-period gains")
equal(reputation.Element, 40, "delayed reputation baseline does not add unavailable-period gains")
xp, watched.currentStanding = 625, 510
tick(2)
equal(experience.Element, 150, "XP tracks after delayed baseline")
equal(reputation.Element, 50, "reputation tracks after delayed baseline")

-- Reputation identity remains module context, separate from the shared continuity check.
watched = { name = "Ironforge", factionID = 47, currentStanding = 100 }
login(saved, 0)
equal(reputation.HasStarted, false, "changed faction resets reputation")
equal(reputation.RestoreStatus, "error", "changed faction is reported")
equal(experience.RestoreStatus, "success", "faction reset does not affect XP validation")
watched = { name = "Stormwind", factionID = 72, currentStanding = 100 }

-- Old snapshots retain totals but require review until a played reference exists.
login({ version = 1, sessions = {
    Experience = { total = 50, duration = 2, paused = false, checkpoint = { value = xp, level = level } },
} }, 0)
equal(experience.Element, 50, "legacy save preserves totals")
equal(experience.RestoreStatus, "error", "legacy save cannot claim played verification")
equal(experience.RestoreIssue, "No saved played-time reference is available.", "legacy warning identifies missing reference")
click(experience)
event("PLAYER_LOGOUT")
equal(PerHourCharacter_Values.version, 2, "legacy save upgrades format")
equal(PerHourCharacter_Values.sessions.Experience.checkpoint, nil, "legacy checkpoint is removed on next save")
login(PerHourCharacter_Values, 0)
equal(experience.RestoreStatus, "success", "acknowledged legacy session verifies next time")

login(nil, 0)
equal(honor.HasStarted, false, "new character does not inherit sessions")
login({ version = 99, sessions = saved.sessions }, 0)
equal(experience.HasStarted, false, "unsupported format is ignored")
login({ version = 2, playedAtSave = 100000, sessions = {
    Experience = { total = 10, duration = -1, paused = false },
    Honor = { total = math.huge, duration = 10, paused = false },
    Reputation = { total = -20, duration = 10, paused = true, context = {} },
} }, 0)
for name, module in pairs(PerHour.Modules) do
    equal(module.HasStarted, false, name .. " rejects malformed save")
    equal(module.RestoreStatus, "error", name .. " explains malformed save")
end

-- Preserve success lifetime, error fades, circular appearance and parent-alpha isolation.
local verifiedSave = { version = 2, playedAtSave = 100000, sessions = {
    Experience = { total = 50, duration = 2, paused = false },
} }
login(verifiedSave, 0)
equal(experience.RestoreIndicator:GetAlpha(), 0, "success indicator starts transparent")
tick(0.04)
near(experience.RestoreIndicator:GetAlpha(), 0.5, "success indicator fades halfway in after 0.04 seconds")
tick(0.05)
equal(experience.RestoreIndicator:GetAlpha(), 1, "success indicator completes the standard fade in")
tick(4)
equal(experience.RestoreIndicator:GetAlpha(), 1, "success remains opaque before five seconds")
tick(0.91)
near(experience.RestoreIndicator:GetAlpha(), 1, "success starts fade at five seconds")
tick(0.04)
near(experience.RestoreIndicator:GetAlpha(), 0.5, "success uses the standard fade out")
showRestoreTooltip(experience)
tick(0.05)
equal(experience.RestoreIndicator:IsShown(), false, "success hides after fade")
equal(GameTooltip:IsShown(), false, "success fade closes tooltip")
equal(experience.RestoreIndicator.scripts.OnUpdate, nil, "success fade removes callback")
tick(2)
equal(experience.RestoreIndicator:IsShown(), false, "tracker cannot restart dismissed success")
verifiedSave.sessions.Experience.paused = true
login(verifiedSave, 0)
tick(5.04)
near(experience.RestoreIndicator:GetAlpha(), 0.5, "paused session success also fades")
tick(0.05)
equal(experience.HasPaused, true, "fade preserves manual pause")
login(verifiedSave, 0)
experience.Frame:Hide()
tick(20)
experience.Frame:Show()
tick(0.1)
equal(experience.RestoreIndicator:IsShown(), false, "reopening panel does not restart expired success")
login(verifiedSave, 0)
tick(5.04)
BaseModule:ResetModule(experience)
equal(experience.RestoreIndicator:GetAlpha(), 1, "Reset clears partial fade")
equal(experience.RestoreIndicator.scripts.OnUpdate, nil, "Reset cancels active fade")
experience.Frame:SetAlpha(0.5)
equal(experience.RestoreIndicator:GetEffectiveAlpha(), 1, "panel transparency does not dim indicator")
experience.Frame:SetAlpha(1)
local background = experience.RestoreIndicator.Background
equal(background.color[4], 1, "background fill is fully opaque")
equal(background.mask.texture, "Interface\\CharacterFrame\\TempPortraitAlphaMask", "background uses native circular mask")
equal(experience.OptionsButton.Icon.texture, "Interface\\Icons\\Trade_Engineering", "restore status preserves options artwork")

-- Normal character selection saves before teardown and queries again only on a new login.
login(saved, 0)
xp = 650
tick(2)
xp = 675
now, playedTotal = now + 0.5, playedTotal + 0.5
event("PLAYER_LEAVING_WORLD")
local selectionSave = copy(PerHourCharacter_Values)
xp, xpMax, level = 0, 0, 0
honorBalance = 0
watched = nil
tick(2)
event("PLAYER_LOGOUT")
equal(PerHourCharacter_Values.playedAtSave, selectionSave.playedAtSave, "teardown cannot overwrite played reference")
equal(PerHourCharacter_Values.sessions.Experience.total, selectionSave.sessions.Experience.total, "teardown preserves final XP total")
xp, xpMax, level = 675, 1000, 10
honorBalance = 400
watched = { name = "Stormwind", factionID = 72, currentStanding = 100 }
login(selectionSave, 0)
equal(experience.RestoreStatus, "success", "normal character selection passes played validation")
requestsBefore = playedRequests
local previousTotal = experience.Element
event("PLAYER_LEAVING_WORLD")
tick(10)
event("PLAYER_ENTERING_WORLD")
equal(playedRequests, requestsBefore, "zone transitions do not request played time again")
xp = 700
tick(2)
equal(experience.Element, previousTotal + 25, "zone transitions retain current totals")
print("PASS: "..checks.." Forever migration checks (".._VERSION..")")
