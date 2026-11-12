-- class
CommandLine = {}

-- private variables
local COMMAND = "/perhour"

-- public functions
function CommandLine:Init()

    SLASH_PERHOUR1 = COMMAND
    SlashCmdList["PERHOUR"] = function()
        PerHour.ToggleMenu:Toggle()
    end
     
end

CommandLine:Init()
