-- import
local PerHour = PerHour
local Utils = Utils

local Settings = PerHour.Settings

local function DefineSettingsFunctions(contextModule)

    -- read the status
    function contextModule:IsShown()
        return PerHourAccount_Settings[self.Name].isShown
    end
    
    -- write the status
    function contextModule:SetIsShown(isShown)
        PerHourAccount_Settings[self.Name].isShown = isShown
    end
end

function Settings:Init()
    local modules = PerHour.Modules
    
    if not PerHourAccount_Settings then
        -- if not initialized
        PerHourAccount_Settings = {}
    end

    for key,contextModule in pairs(modules) do

        -- for each module I have to initialize if does not exists
        local moduleName = contextModule.Name
        
        -- for each module, we check if the module are set.
        if (PerHourAccount_Settings[moduleName] == nil) then
            PerHourAccount_Settings[moduleName] = {}
        end

        -- after modules are defined
        -- than define settings functions in the module
        DefineSettingsFunctions(contextModule)

        -- for each module registred, we check if the configs are set.
        if (PerHourAccount_Settings[moduleName].isShown == nil) then
            contextModule:SetIsShown(true)
        end
    end

end