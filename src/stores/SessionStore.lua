local SessionStore = {}
PerHour.Stores.Sessions = SessionStore

local VERSION = 2

local function IsFinite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function IsSession(value)
    return type(value) == "table" and IsFinite(value.total)
        and IsFinite(value.duration) and value.duration >= 0 and type(value.paused) == "boolean"
        and (value.needsReview == nil or type(value.needsReview) == "boolean")
end

local function Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = Copy(item) end
    return result
end

function SessionStore:Init()
    local saved = PerHourCharacter_Values
    if type(saved) ~= "table" or (saved.version ~= 1 and saved.version ~= VERSION)
        or type(saved.sessions) ~= "table" then
        PerHourCharacter_Values = { version = VERSION, sessions = {} }
    end
end

function SessionStore:GetPlayedAtSave()
    local value = PerHourCharacter_Values.playedAtSave
    if IsFinite(value) and value >= 0 then return value end
end

-- Commit every module snapshot with the played-time reference captured for that batch.
function SessionStore:SaveAll(sessions, playedAtSave)
    assert(playedAtSave == nil or (IsFinite(playedAtSave) and playedAtSave >= 0), "Invalid played time")
    for name, data in pairs(sessions) do
        assert(PerHour.Modules[name] and IsSession(data), "Invalid module session")
    end
    PerHourCharacter_Values = { version = VERSION, playedAtSave = playedAtSave, sessions = Copy(sessions) }
end

function SessionStore:ForModule(name)
    assert(PerHour.Modules[name], "Unknown session module")
    local store = {}

    function store:ReadSession()
        local data = PerHourCharacter_Values.sessions[name]
        if data == nil then return nil end
        if not IsSession(data) then return nil, true end
        return Copy(data)
    end

    function store:ClearSession()
        PerHourCharacter_Values.sessions[name] = nil
    end

    return store
end
