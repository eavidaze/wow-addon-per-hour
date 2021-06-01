-- definition
BaseModule = {}

-- public functions
function BaseModule:ResetModule(baseModule)
    -- displayable values
    baseModule.Time = 0
    baseModule.Element = 0
    baseModule.ElementPerHour = 0
    baseModule.ElementPerMinute = 0
    
    -- control values
    baseModule.HasStarted = false
    baseModule.HasPaused = false

    baseModule.StartedAt = 0
    baseModule.PausedAt = 0
    baseModule.PausedTime = 0

    baseModule.TimeSinceLastUpdate = 0

    -- run custom
    if baseModule.CustomReset~=nil then
        baseModule.CustomReset()
    end

end

