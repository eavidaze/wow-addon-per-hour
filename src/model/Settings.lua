-- import
local PerHour = PerHour
local Utils = Utils

local Settings = PerHour.Settings

-- read the status
function Settings:IsShown(moduleName)
	return PerHourAccount_Settings[moduleName].isShown
end

-- write the status
function Settings:SetIsShown(moduleName, isShown)
	PerHourAccount_Settings[moduleName].isShown = isShown
end

function Settings:Init()

    local modules = PerHour.Modules
    
    if not PerHourAccount_Settings then
        -- if not initialized
        PerHourAccount_Settings = {}
    end

    for key,contextModule in pairs(modules) do
        -- for each module i have to initialize if does not exists

        local moduleName = contextModule.Name
        
        -- for each module, we check if the module are set.
        if (PerHourAccount_Settings[moduleName] == nil) then
            PerHourAccount_Settings[moduleName] = {}
        end

        -- for each module registred, we check if the configs are set.
        if (PerHourAccount_Settings[moduleName].isShown == nil) then
            self:SetIsShown(moduleName, true)
        end
    end

end