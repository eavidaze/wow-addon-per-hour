local Store = { SessionLimit=100, DetailLimit=20, EventLimit=1000 }
PerHour.Stores.Sessions = Store
function PerHour.Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = PerHour.Copy(item) end
    return result
end
function Store:Init()
    if type(PerHourRevampSession) ~= "table" or PerHourRevampSession.version ~= 1 then
        PerHourRevampSession = { version=1 }
    end
    if type(PerHourRevampHistory) ~= "table" or PerHourRevampHistory.version ~= 1 then
        PerHourRevampHistory = { version=1, characters={} }
    end
    if type(PerHourRevampHistory.characters) ~= "table" then PerHourRevampHistory.characters = {} end
    self.Data, self.Account = PerHourRevampSession, PerHourRevampHistory
    self.Character = nil
    self.Validated = setmetatable({}, {__mode="k"})
    self.InvalidHistory = false
end
function Store:BindCharacter()
    -- Forever returns first name and surname, rather than a realm, from UnitName.
    local name, surname = UnitName("player")
    name = name or "Unknown"
    local realm = GetRealmName() or "Unknown"
    local id = UnitGUID("player") or (realm .. ":" .. name)
    self.Character = id
    local entry = self.Account.characters[id]
    if type(entry) ~= "table" then entry = {}; self.Account.characters[id] = entry end
    entry.name = type(surname) == "string" and surname ~= "" and name .. " " .. surname or name
    entry.realm = realm
    if type(entry.sessions) ~= "table" then entry.sessions = {} end
    return id
end
function Store:CharacterLabel(owner)
    if type(owner) ~= "table" then return "Current character" end
    local name = tostring(owner.name)
    local realm = type(owner.realm) == "string" and owner.realm:match("%S") and owner.realm
    return realm and name .. " - " .. realm or name
end
function Store:IsRecord(record)
    if type(record) ~= "table" or type(record.id) ~= "string" or type(record.name) ~= "string"
        or type(record.map) ~= "string" or not Utils:IsFiniteNumber(record.startLevel)
        or not Utils:IsFiniteNumber(record.duration) or record.duration < 0
        or not Utils:IsFiniteNumber(record.startedAt) or type(record.metrics) ~= "table" then return false end
    if record.startXpPercent ~= nil and (not Utils:IsFiniteNumber(record.startXpPercent)
        or record.startXpPercent < 0 or record.startXpPercent > 100) then return false end
    if record.finishedAt ~= nil and not Utils:IsFiniteNumber(record.finishedAt) then return false end
    if type(record.zones) ~= "table" then return false end
    for _,zone in ipairs(record.zones) do if type(zone) ~= "string" then return false end end
    for _, name in ipairs(PerHour.MetricOrder) do
        local metric = record.metrics[name]
        if type(metric) ~= "table" or not Utils:IsFiniteNumber(metric.total)
            or not Utils:IsFiniteNumber(metric.duration) or metric.duration < 0 then return false end
        if type(metric.available) ~= "boolean" or type(metric.partial) ~= "boolean" then return false end
        if metric.issue ~= nil and type(metric.issue) ~= "string" then return false end
    end
    if type(record.gold) ~= "table" or not Utils:IsFiniteNumber(record.gold.coins)
        or not Utils:IsFiniteNumber(record.gold.items) or not Utils:IsFiniteNumber(record.gold.expenses)
        or type(record.reputation) ~= "table" then return false end
    for id,faction in pairs(record.reputation) do
        if not Utils:IsFiniteNumber(id) or type(faction) ~= "table" or type(faction.name) ~= "string"
            or faction.id ~= id or not Utils:IsFiniteNumber(faction.total)
            or not Utils:IsFiniteNumber(faction.duration) or faction.duration < 0 then return false end
    end
    if record.events ~= nil and type(record.events) ~= "table" then return false end
    for _,entry in ipairs(record.events or {}) do
        if type(entry) ~= "table" or type(entry.source) ~= "string" or not Utils:IsFiniteNumber(entry.amount)
            or (entry.direction ~= 1 and entry.direction ~= -1) then return false end
    end
    if record.segments ~= nil and type(record.segments) ~= "table" then return false end
    for _,segment in ipairs(record.segments or {}) do
        if type(segment) ~= "table" or type(segment.name) ~= "string"
            or not Utils:IsFiniteNumber(segment.start) or segment.start < 0
            or not Utils:IsFiniteNumber(segment.duration) or segment.duration < 0
            or not Utils:IsFiniteNumber(segment.total) then return false end
    end
    return true
end
function Store:SaveCurrent(value) self.Data.current = value and PerHour.Copy(value) or nil end
function Store:ReadCurrent() return self.Data.current and PerHour.Copy(self.Data.current) end
function Store:Quarantine(value, reason) self.Data.recovery = { data=PerHour.Copy(value), reason=reason } end
function Store:GetHistory(character)
    local owner = self.Account.characters[character or self.Character]
    local result = {}
    local invalid = 0
    for _, record in ipairs(type(owner) == "table" and type(owner.sessions) == "table" and owner.sessions or {}) do
        local valid = type(record) == "table" and self.Validated[record]
        if valid == nil then valid=self:IsRecord(record); self.Validated[record]=valid end
        if valid then result[#result+1] = record else invalid = invalid + 1 end
    end
    self.InvalidHistory = self.InvalidHistory or invalid > 0
    return result
end
function Store:GetCharacters()
    local result = {}
    for id, owner in pairs(self.Account.characters) do
        if type(owner) == "table" then
            result[#result+1] = { value=id, label=self:CharacterLabel(owner) }
        end
    end
    table.sort(result, function(a,b) return a.label < b.label end)
    return result
end
function Store:Archive(record)
    assert(self:IsRecord(record), "Invalid session summary")
    local sessions = self.Account.characters[self.Character].sessions
    table.insert(sessions, 1, PerHour.Copy(record))
    self.Validated[sessions[1]] = true
    while #sessions > self.SessionLimit do table.remove(sessions) end
    for index=self.DetailLimit+1,#sessions do
        local saved = sessions[index]
        if self:IsRecord(saved) then
            saved.events, saved.segments = nil, nil
            saved.detailsExpired = true
        end
    end
    self:SaveCurrent(nil)
    return sessions[1]
end
local function ValidName(name)
    if type(name) ~= "string" then return end
    name = name:match("^%s*(.-)%s*$")
    local _, count = name:gsub("[^\128-\191]", "")
    if name ~= "" and count <= 80 then return name end
end
Store.ValidName = ValidName
function Store:Rename(record, name)
    name = ValidName(name)
    if not name or not self:IsRecord(record) then return false end
    record.name = name
    return true
end
function Store:Delete(record, character)
    local owner = self.Account.characters[character or self.Character]
    if type(owner) ~= "table" or type(owner.sessions) ~= "table" then return false end
    for index, item in ipairs(owner.sessions) do
        if item == record then table.remove(owner.sessions, index); return true end
    end
    return false
end
