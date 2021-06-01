-- import
local PerHour = PerHour
local Utils = Utils

local Settings = PerHour.Settings

function Settings:IsShown(moduleName)
	return PerHourAccount_Settings[moduleName].isShown
end

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
        local name = contextModule.Name
        
        -- for each module, we check if the module are set.
        if (PerHourAccount_Settings[name] == nil) then
            PerHourAccount_Settings[name] = {}
        end

        -- for each module registred, we check if the configs are set.
        if (PerHourAccount_Settings[name].isShown == nil) then
            self:SetIsShown(name, true)
        end
    end

end