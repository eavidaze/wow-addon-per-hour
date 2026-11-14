local SettingsStore = {}
PerHour.Stores.Settings = SettingsStore

local DEFAULT_MINIMAP_ANGLE = math.rad(225)
local ANCHORS = {
    TOPLEFT = true, TOP = true, TOPRIGHT = true,
    LEFT = true, CENTER = true, RIGHT = true,
    BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}

local function IsFinite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function IsPosition(value)
    return type(value) == "table" and ANCHORS[value.point] == true
        and ANCHORS[value.relativePoint] == true and IsFinite(value.x) and IsFinite(value.y)
end

local function CopyPosition(value)
    if value then
        return { point = value.point, relativePoint = value.relativePoint, x = value.x, y = value.y }
    end
end

function SettingsStore:Init()
    if type(PerHourAccount_Settings) ~= "table" then PerHourAccount_Settings = {} end
    local saved = PerHourAccount_Settings
    if type(saved.minimap) ~= "table" then saved.minimap = {} end
    if not IsFinite(saved.minimap.angle) then saved.minimap.angle = DEFAULT_MINIMAP_ANGLE end

    for name in pairs(PerHour.Modules) do
        if type(saved[name]) ~= "table" then saved[name] = {} end
        if type(saved[name].isShown) ~= "boolean" then saved[name].isShown = false end
        if not IsPosition(saved[name].position) then saved[name].position = nil end
    end
end

function SettingsStore:GetMinimapAngle()
    return PerHourAccount_Settings.minimap.angle
end

function SettingsStore:SetMinimapAngle(angle)
    assert(IsFinite(angle), "Minimap angle must be finite")
    PerHourAccount_Settings.minimap.angle = angle
end

function SettingsStore:ForModule(name)
    assert(PerHour.Modules[name], "Unknown settings module")
    local settings = {}

    function settings:Get(key)
        assert(key == "isShown" or key == "position", "Unknown module setting")
        local value = PerHourAccount_Settings[name][key]
        if key == "position" then return CopyPosition(value) end
        return value
    end

    function settings:Set(key, value)
        assert(key == "isShown" or key == "position", "Unknown module setting")
        if key == "isShown" then
            assert(type(value) == "boolean", "Module visibility must be boolean")
        else
            assert(value == nil or IsPosition(value), "Invalid panel position")
            value = CopyPosition(value)
        end
        PerHourAccount_Settings[name][key] = value
    end

    return settings
end
