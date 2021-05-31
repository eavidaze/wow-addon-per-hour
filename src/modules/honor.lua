-- import
local PerHour = PerHour
local Utils = Utils

-- declaretion
local Module = {}
PerHour.Modules.Honor = Module

-- properties
Module.Name = "Honor"
Module.TagName = "honor"
Module.ShortName = "hon"
Module.RegisteredEvents = {"CHAT_MSG_COMBAT_HONOR_GAIN","TIME_PLAYED_MSG"}

-- custom fucntions
Module.CustomOnEvent = function(self, event, ...)
    if event == "CHAT_MSG_COMBAT_HONOR_GAIN" then
        local arg = {...}
        -- have to be better tested
        startPoint, endPoint, honorPoints = string.find(arg[1], "(%d+)")
        Module.Element = Module.Element + tonumber(honorPoints, 10)
    elseif event == "TIME_PLAYED_MSG" then
        -- testing
        -- Module.Element = Module.Element + 420
    end
    
end
