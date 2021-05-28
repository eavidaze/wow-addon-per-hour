-- class
CommandLine = {}

-- private variables
local COMMAND = "/ph"

-- public functions
function CommandLine:Init()

    SLASH_PerHour1 = COMMAND
    SlashCmdList["PerHour"] = function(text)
        Honor:Toggle()
    end
     
end

CommandLine:Init()