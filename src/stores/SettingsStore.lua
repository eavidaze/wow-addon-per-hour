local Settings = {}
PerHour.Stores.Settings = Settings
local ORDER = { "Experience", "Gold", "Honor", "Reputation" }
local ESTIMATE_KEYS = { Experience="showExperienceEstimates", Reputation="showReputationEstimates" }
local function Position(value)
    local anchors = { TOPLEFT=true, TOP=true, TOPRIGHT=true, LEFT=true, CENTER=true,
        RIGHT=true, BOTTOMLEFT=true, BOTTOM=true, BOTTOMRIGHT=true }
    return type(value) == "table" and anchors[value.point] and anchors[value.relativePoint]
        and Utils:IsFiniteNumber(value.x) and Utils:IsFiniteNumber(value.y)
end
function Settings:Init()
    -- New namespaces deliberately ignore all pre-revamp SavedVariables.
    if type(PerHourRevampSettings) ~= "table" or PerHourRevampSettings.version ~= 1 then
        PerHourRevampSettings = { version=1 }
    end
    self.Data = PerHourRevampSettings
    local data = self.Data
    if data.rate ~= "minute" then data.rate = "hour" end
    if data.panelType ~= "focused" and data.panelType ~= "extended" then data.panelType = "full" end
    if type(data.shown) ~= "boolean" then data.shown = true end
    if type(data.showDuration) ~= "boolean" then data.showDuration = true end
    for _, key in pairs(ESTIMATE_KEYS) do data[key] = data[key] == true end
    data.speedometer = type(data.speedometer) == "table" and data.speedometer or {}
    data.speedometer.enabled = data.speedometer.enabled == true
    if not PerHour.SpeedometerScales:IsLevel(data.speedometer.level) then data.speedometer.level = 5 end
    if not Utils:IsFiniteNumber(data.minimapAngle) then data.minimapAngle = math.rad(225) end
    if not Position(data.position) then data.position = nil end
    local seen, valid = {}, type(data.order) == "table" and #data.order == 4
    if valid then
        for _, name in ipairs(data.order) do
            if not PerHour.Modules[name] or seen[name] then valid = false; break end
            seen[name] = true
        end
    end
    if not valid then data.order = { unpack(ORDER) } end
end
function Settings:Get(key) return self.Data[key] end
function Settings:Set(key, value)
    assert(key == "panelType" or key == "shown" or key == "showDuration", "Unknown setting")
    if key == "panelType" then assert(value == "focused" or value == "extended" or value == "full")
    else assert(type(value) == "boolean") end
    self.Data[key] = value
end
function Settings:GetRate() return self.Data.rate end
function Settings:SetRate(value) assert(value == "hour" or value == "minute"); self.Data.rate = value end
function Settings:GetEstimatesEnabled(source)
    return self.Data[assert(ESTIMATE_KEYS[source], "Unknown estimate source")]
end
function Settings:SetEstimatesEnabled(source, value)
    local key = assert(ESTIMATE_KEYS[source], "Unknown estimate source")
    assert(type(value) == "boolean"); self.Data[key] = value
end
function Settings:GetMinimapAngle() return self.Data.minimapAngle end
function Settings:SetMinimapAngle(value) assert(Utils:IsFiniteNumber(value)); self.Data.minimapAngle = value end
function Settings:GetSpeedometerEnabled() return self.Data.speedometer.enabled end
function Settings:SetSpeedometerEnabled(value) assert(type(value) == "boolean"); self.Data.speedometer.enabled = value end
function Settings:GetSpeedometerLevel() return self.Data.speedometer.level end
function Settings:SetSpeedometerLevel(value) assert(PerHour.SpeedometerScales:IsLevel(value)); self.Data.speedometer.level = value end
function Settings:GetSpeedometerMaximum(rate) return PerHour.SpeedometerScales:GetMaximum(self:GetSpeedometerLevel(), rate) end
function Settings:GetPosition() return self.Data.position and PerHour.Copy(self.Data.position) end
function Settings:SetPosition(value) assert(value == nil or Position(value)); self.Data.position = value and PerHour.Copy(value) end
function Settings:GetOrder() return { unpack(self.Data.order) } end
function Settings:Swap(first, second)
    assert(first >= 1 and first <= 4 and second >= 1 and second <= 4)
    self.Data.order[first], self.Data.order[second] = self.Data.order[second], self.Data.order[first]
end
