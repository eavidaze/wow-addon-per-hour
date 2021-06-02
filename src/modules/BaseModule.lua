-- definition
BaseModule = {}

function BaseModule:RefreshDisplayedValues(contextModule)
    contextModule.TimeValue:SetText(Utils:DisplayTimer(contextModule.Time))
    contextModule.ElementValue:SetText(Utils:DisplayNumber(contextModule.Element))
    contextModule.ElementPerHourValue:SetText(Utils:DisplayRoundedNumber(contextModule.ElementPerHour, 1))
    contextModule.ElementPerMinuteValue:SetText(Utils:DisplayRoundedNumber(contextModule.ElementPerMinute, 1))
end

-- public functions
function BaseModule:ResetModule(contextModule)
    -- control values
    contextModule.HasStarted = false
    contextModule.HasPaused = false

    contextModule.StartedAt = 0
    contextModule.PausedAt = 0
    contextModule.PausedTime = 0

    contextModule.TimeSinceLastUpdate = 0

    -- displayable values
    contextModule.Time = 0
    contextModule.Element = 0
    contextModule.ElementPerHour = 0
    contextModule.ElementPerMinute = 0
    
    -- run custom
    if contextModule.CustomReset~=nil then
        contextModule.CustomReset()
    end

    -- reset the button
    if contextModule.ToggleStartButtom~=nil then
        contextModule.ToggleStartButtom:SetText("Start")
    end
    
    BaseModule:RefreshDisplayedValues(contextModule)
end

