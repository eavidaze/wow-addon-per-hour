local PerHour = PerHour
local ToggleMenu = {}
PerHour.ToggleMenu = ToggleMenu

local function IsModuleShown(module)
    return module.Frame:IsShown()
end

local function ToggleModule(module)
    local shown = not module.Frame:IsShown()
    module.Settings:Set("isShown", shown)
    module.Frame:SetShown(shown)
    Utils:AddonMessage(module.Name .. (shown and " show." or " hide."))
end

function ToggleMenu:Init(button)
    local modules = {}
    for _, module in pairs(PerHour.Modules) do
        module.Frame:SetShown(module.Settings:Get("isShown"))
        table.insert(modules, module)
    end
    table.sort(modules, function(a, b) return a.Name < b.Name end)

    button:SetupMenu(function(_, rootDescription)
        rootDescription:CreateTitle("Per Hour")
        for _, module in ipairs(modules) do
            rootDescription:CreateCheckbox(module.Name, IsModuleShown, ToggleModule, module)
        end
    end)
end

function ToggleMenu:Toggle()
    local button = PerHour.MinimapButton
    button:SetMenuOpen(not button:IsMenuOpen())
end
