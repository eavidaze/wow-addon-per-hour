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

-- custom messages
Module.CustomSendToMessages = {
    ["message1"] = function()
        local reputationName = ""
        if Module.LastReputationName ~= "" then
            reputationName = Module.LastReputationName
        end
        return "Reputation: "..reputationName
    end
    
}

-- bugfix:  sometimes, when the screen is reloaded (a portal for example)
--          the GetWatchedFactionInfo() returns null witch means without faction.
--          because of that we have to tolerate some seconds util reset.
Module.HasWaitingWithoutFaction = false
Module.WaitingWithoutFactionTime = 0

-- toleration time is considering the "outside elapsed" (Displayer elapse)
-- here "0.1" is almost 10 seconds.
local STATIC_TOLERATION_INTERVAL = 0.1

-- custom functions
Module.CustomOnUpdate = function(self, elapsed)
    local reputationReceived = 0
    local currentName, standing, minBound, maxBound, currentValue, factionID = GetWatchedFactionInfo()

    if currentName~=nil then

        -- wait condition is true because the tracker is working
        Module.HasWaitingWithoutFaction = true
        Module.WaitingWithoutFactionTime = 0

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
        if Module.HasWaitingWithoutFaction then
            -- wait condition is reached
            Module.WaitingWithoutFactionTime = Module.WaitingWithoutFactionTime + elapsed
            if Module.WaitingWithoutFactionTime > STATIC_TOLERATION_INTERVAL then
                -- time tolerated is reached
                Module.HasWaitingWithoutFaction = false
            end
        else
            Utils:AddonMessage(Module.Name.." must be selected to be displayed as Experience Bar.")
            BaseModule:ResetModule(Module)
        end
    end
end

Module.CustomReset = function()
    Module.LastReputationName = ""
    Module.LastReputationValue = 0
    Module.HasWaitingWithoutFaction = false
    Module.WaitingWithoutFactionTime = 0
end

Module.CustomStartedMessage = function ()
    local startedMessage = " was not selected."
    local currentName, standing, minBound, maxBound, currentValue, factionID = GetWatchedFactionInfo()
    if currentName~=nil then
        startedMessage = " ["..currentName.."] monitoring started."
    end
    return startedMessage
end
