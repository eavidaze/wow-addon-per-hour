PerHour = {}
PerHour.AddonName = select(1, ...)
PerHour.Modules = {}
PerHour.Settings = {}

-- import
local Utils = Utils

-- definitions
-- Settings.lua
local Settings = PerHour.Settings

function Settings:IsShown(moduleName)
	return PerHourDB_Settings[moduleName].isShown
end

function Settings:SetIsShown(moduleName, isShown)
	PerHourDB_Settings[moduleName].isShown = isShown
end

function Settings:Init()

    local modules = PerHour.Modules
    
    if not PerHourDB_Settings then
        -- if not initialized
        PerHourDB_Settings = {}
    end

    for key,contextModule in pairs(modules) do
        local name = contextModule.Name

        -- for each module, we check if the module are set.
        if (PerHourDB_Settings[name] == nil) then
            PerHourDB_Settings[name] = {}
        end

        -- for each module registred, we check if the configs are set.
        if (PerHourDB_Settings[name].isShown == nil) then
            self:SetIsShown(name, true)
        end
    end

end