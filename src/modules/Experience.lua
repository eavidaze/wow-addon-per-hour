-- import
local PerHour = PerHour
local Utils = Utils

-- declaretion
local Module = {}
PerHour.Modules.Experience = Module

-- properties
Module.Name = "Experience"
Module.TagName = "experience"
Module.ShortName = "XP"
Module.RegisteredEvents = {"CHAT_MSG_COMBAT_XP_GAIN"}

-- custom fucntions
function Module:CustomOnEvent(self, event, ...)
    if (Module.HasStarted) then
        if event == "CHAT_MSG_COMBAT_HONOR_GAIN" then
            local arg = {...}
            -- have to be better tested
            startPoint, endPoint, honorPoints = string.find(arg[1], "(%d+)")
            Module.Element = Module.Element + tonumber(honorPoints, 10)
        elseif event == "TIME_PLAYED_MSG" then
            -- nothing
            Module.Element = Module.Element + 420
        end
    end
end
