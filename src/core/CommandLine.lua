-- class
CommandLine = {}

-- private variables
local COMMAND = "/perhour"

-- public functions
function CommandLine:Init()

    SLASH_PERHOUR1 = COMMAND
    SlashCmdList["PERHOUR"] = function()
        local frame = PerHour.ToggleMenu.Frame
        frame:SetShown(not frame:IsShown())
    end
     
end

CommandLine:Init()
