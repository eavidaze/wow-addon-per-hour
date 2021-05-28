-- class
Utils = {}

-- functions
function Utils:DisplayTimer(time)
    local hours = floor(mod(time, 86400)/3600)
    local minutes = floor(mod(time,3600)/60)
    local seconds = floor(mod(time,60))
    local time_formated = ""
    -- if the time has hours
    if hours >= 1 then
        time_formated = format("%02dh ",hours)
    end
    -- if the time has minutes
    if minutes >= 1 or hours >= 1 then
        time_formated = time_formated .. format("%02dm ",minutes)
    end
    -- doest metter if have hours or minutes, I just concat seconds
    time_formated = time_formated .. format("%02ds",seconds)
    return time_formated
end

function Utils:RoundValue(num, numDecimals)
    local mult = 10^(numDecimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

function Utils:isINF(value)
    return value == math.huge or value == -math.huge
end