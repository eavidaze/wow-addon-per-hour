local PerHour = PerHour
local ToggleMenu = {}
PerHour.ToggleMenu = ToggleMenu

local function IsModuleShown(module)
    return module.View.Frame:IsShown()
end

local function ToggleModule(module)
    local shown = not module.View.Frame:IsShown()
    module.Settings:Set("isShown", shown)
    module.View.Frame:SetShown(shown)
    Utils:AddonMessage(module.Name .. (shown and " show." or " hide."))
end

function ToggleMenu:Init()
    local modules = {}
    for _, module in pairs(PerHour.Modules) do
        module.View.Frame:SetShown(module.Settings:Get("isShown"))
        table.insert(modules, module)
    end
    table.sort(modules, function(a, b) return a.Name < b.Name end)

    self.Generator = function(_, rootDescription)
        rootDescription:CreateTitle("Show trackers")
        for _, module in ipairs(modules) do
            rootDescription:CreateCheckbox(module.Name, IsModuleShown, ToggleModule, module)
        end
    end
end

function ToggleMenu:IsOpen()
    return self.Menu ~= nil
end

function ToggleMenu:Close()
    if self.Menu then self.Menu:Close() end
end

function ToggleMenu:Toggle(owner)
    if self:IsOpen() then self:Close(); return end
    local menu = MenuUtil.CreateContextMenu(owner, self.Generator)
    self.Menu = menu
    if menu then menu:SetClosedCallback(function() self.Menu = nil end) end
end
