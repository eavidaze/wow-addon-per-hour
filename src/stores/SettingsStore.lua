local SettingsStore = {}
PerHour.Stores.Settings = SettingsStore
local Scales = PerHour.SpeedometerScales

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

local function IsRate(value)
    return value == "hour" or value == "minute"
end

local function MigrateRate(account)
    local agreed
    for name in pairs(PerHour.Modules) do
        local legacy = type(account[name]) == "table" and account[name].rate
        if not IsRate(legacy) or (agreed and legacy ~= agreed) then return "hour" end
        agreed = legacy
    end
    return agreed or "hour"
end

local function CopyPosition(value)
    if value then
        return { point = value.point, relativePoint = value.relativePoint, x = value.x, y = value.y }
    end
end

function SettingsStore:Init()
    if type(PerHourAccount_Settings) ~= "table" then PerHourAccount_Settings = {} end
    if type(PerHourCharacter_Settings) ~= "table" then PerHourCharacter_Settings = {} end
    local account, saved = PerHourAccount_Settings, PerHourCharacter_Settings
    if saved.rate == nil then saved.rate = MigrateRate(account)
    elseif not IsRate(saved.rate) then saved.rate = "hour" end
    if type(saved.minimap) ~= "table" then saved.minimap = {} end
    if not IsFinite(saved.minimap.angle) then saved.minimap.angle = DEFAULT_MINIMAP_ANGLE end
    if type(saved.speedometer) ~= "table" then saved.speedometer = {} end
    if type(saved.speedometer.enabled) ~= "boolean" then saved.speedometer.enabled = false end
    if not Scales:IsLevel(saved.speedometer.level) then saved.speedometer.level = Scales.DefaultLevel end

    for name in pairs(PerHour.Modules) do
        if type(saved[name]) ~= "table" then saved[name] = {} end
        if type(saved[name].isShown) ~= "boolean" then saved[name].isShown = false end
        if not IsPosition(saved[name].position) then saved[name].position = nil end
    end
end

function SettingsStore:GetRate()
    return PerHourCharacter_Settings.rate
end

function SettingsStore:SetRate(rate)
    assert(IsRate(rate), "Display rate must be hour or minute")
    PerHourCharacter_Settings.rate = rate
end

function SettingsStore:GetEstimatesEnabled()
    return PerHourCharacter_Settings.showEstimates == true
end

function SettingsStore:SetEstimatesEnabled(enabled)
    assert(type(enabled) == "boolean", "Estimate visibility must be boolean")
    PerHourCharacter_Settings.showEstimates = enabled
end

function SettingsStore:GetMinimapAngle()
    return PerHourCharacter_Settings.minimap.angle
end

function SettingsStore:SetMinimapAngle(angle)
    assert(IsFinite(angle), "Minimap angle must be finite")
    PerHourCharacter_Settings.minimap.angle = angle
end

function SettingsStore:GetSpeedometerEnabled()
    return PerHourCharacter_Settings.speedometer.enabled
end

function SettingsStore:SetSpeedometerEnabled(enabled)
    assert(type(enabled) == "boolean", "Speedometer visibility must be boolean")
    PerHourCharacter_Settings.speedometer.enabled = enabled
end

function SettingsStore:GetSpeedometerMaximum(rate)
    return Scales:GetMaximum(self:GetSpeedometerLevel(), rate)
end

function SettingsStore:GetSpeedometerLevel()
    return PerHourCharacter_Settings.speedometer.level
end

function SettingsStore:SetSpeedometerLevel(level)
    assert(Scales:IsLevel(level), "Invalid speedometer level")
    PerHourCharacter_Settings.speedometer.level = level
end

function SettingsStore:ForModule(name)
    assert(PerHour.Modules[name], "Unknown settings module")
    local settings = {}

    function settings:Get(key)
        assert(key == "isShown" or key == "position", "Unknown module setting")
        local value = PerHourCharacter_Settings[name][key]
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
        PerHourCharacter_Settings[name][key] = value
    end

    return settings
end
