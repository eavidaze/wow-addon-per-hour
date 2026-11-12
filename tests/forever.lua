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
function methods:RegisterEvent(event) self.events[event] = true end
function methods:UnregisterEvent(event) self.events[event] = nil end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:IsShown() return self.shown end
function methods:SetShown(value) self.shown = value end
function methods:SetText(value) self.text = value end
function methods:GetText() return self.text end
local function object(name)
    assert(name == nil or type(name) == "string", "UI object name must be a string")
    return setmetatable({ name = name, scripts = {}, events = {}, shown = true }, {
        __index = function(_, key) return methods[key] or function() end end,
    })
end
function methods:CreateFontString(name, layer, template)
    assert(layer == "OVERLAY", "font strings need a valid draw layer")
    return object(name)
end
function methods:CreateTexture() return object() end
UIParent = object("UIParent")
function CreateFrame(kind, name, parent, template)
    assert(template == nil or template == "UIPanelButtonTemplate", "unsupported legacy template")
    if name then
        name = name:gsub("%$parent", parent.name or "")
        assert(not names[name], "duplicate frame name: "..name)
    end
    local frame = object(name)
    frames[#frames + 1] = frame
    if name then names[name] = frame end
    return frame
end
function GetTime() return now end
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
PerHourAccount_Settings = { Experience = { isShown = true } }

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
local function click(module) module.ToggleStartButtom.scripts.OnClick() end
local experience, reputation, honor = PerHour.Modules.Experience, PerHour.Modules.Reputation, PerHour.Modules.Honor
event("ADDON_LOADED", "another-addon")
event("ADDON_LOADED", "per-hour")
equal(experience.Frame:IsShown(), true, "saved visibility")
equal(reputation.Frame:IsShown(), false, "default visibility")
equal(PerHour.ToggleMenu.Frame.events.ADDON_LOADED, nil, "initialize once")
SlashCmdList.PERHOUR()
equal(PerHour.ToggleMenu.Frame:IsShown(), false, "slash hide")
SlashCmdList.PERHOUR()
equal(PerHour.ToggleMenu.Frame:IsShown(), true, "slash show")

click(experience)
xp = 150
tick(2)
equal(experience.Element, 50, "first XP gain")
equal(experience.ElementPerHour, 90000, "XP per hour")
experience.Frame:Hide()
xp = 200
tick(2)
equal(experience.Element, 100, "XP tracks while hidden")
xp = 250
click(experience)
equal(experience.Element, 150, "gain immediately before pause")
equal(experience.ElementValue:GetText(), "150", "pause refreshes display immediately")
xp = 300
tick(2)
xp = 350
click(experience)
tick(2)
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

click(reputation)
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
click(reputation)
watched = nil
tick(10)
equal(reputation.HasStarted, false, "missing faction timeout in real seconds")
click(reputation)
equal(reputation.HasStarted, false, "start requires watched faction")

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
equal(Utils:DisplayTimer(90061), "25:01:01", "timers longer than 24 hours")
print("PASS: "..checks.." Forever migration checks (".._VERSION..")")
