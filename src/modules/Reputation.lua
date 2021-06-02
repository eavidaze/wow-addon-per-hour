-- import
local PerHour = PerHour
local Utils = Utils
local BaseModule = BaseModule

-- declaretion
local Module = {}
PerHour.Modules.Reputation = Module

-- properties
Module.Name = "Reputation"
Module.TagName = "Reputation"
Module.ShortName = "Rep"
Module.RegisteredEvents = {}

-- custom properties
Module.LastReputationName = ""
Module.LastReputationValue = 0

-- custom functions
Module.CustomOnUpdate = function(self, elapsed)
    local reputationReceived = 0
    local currentName, standing, minBound, maxBound, currentValue, factionID = GetWatchedFactionInfo()
    -- Utils:Print("currentName: "..currentName)
    -- Utils:Print("standing: "..standing)
    -- Utils:Print("minBound: "..minBound)
    -- Utils:Print("maxBound: "..maxBound)
    -- Utils:Print("currentValue: "..currentValue)
    -- Utils:Print("factionID: "..factionID)

    if currentName~=nil then

        if Module.LastReputationName ~= "" and Module.LastReputationName ~= currentName then
            -- Reputation changed
            Utils:AddonMessage(Module.Name.." was changed from "..Module.LastReputationName.." to "..currentName..".")
            Utils:AddonMessage(Module.Name.." reseted.")
            BaseModule:ResetModule(Module)
        else
            -- still in the Reputation
            if Module.LastReputationValue ~= 0 then
                reputationReceived = currentValue - Module.LastReputationValue
            end
        
            -- update lasts
            Module.LastReputationValue = currentValue
            Module.LastReputationName = currentName
            
            -- Element is the amount of Reputation
            if not Module.HasPaused then
                Module.Element = Module.Element + reputationReceived
            end

        end
    else
        Utils:AddonMessage(Module.Name.." must be selected to be displayed as Experience Bar.")
        BaseModule:ResetModule(Module)
    end
end

Module.CustomReset = function()
    Module.LastReputationName = ""
    Module.LastReputationValue = 0
end

Module.CustomStartedMessage = function ()
    local startedMessage = " was not selected."
    local currentName, standing, minBound, maxBound, currentValue, factionID = GetWatchedFactionInfo()
    if currentName~=nil then
        startedMessage = " ["..currentName.."] monitoring started."
    end
    return startedMessage
end
