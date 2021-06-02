-- class
Utils = {}

-- public functions
function Utils:AddonMessage(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700Per Hour™|r "..text)
end

function Utils:Print(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000###########|r LOG: "..text)
end

function Utils:DisplayTimer(time)
    local hours = floor(mod(time, 86400)/3600)
    local minutes = floor(mod(time,3600)/60)
    local seconds = floor(mod(time,60))
    local time_formated = ""
    -- if the time has hours
    if hours >= 1 then
        time_formated = format("%02d:",hours)
    end
    -- if the time has minutes
    -- I set TRUE to disable this verification
    if true or minutes >= 1 or hours >= 1 then
        time_formated = time_formated .. format("%02d:",minutes)
    end
    -- doest metter if have hours or minutes, I just concat seconds
    time_formated = time_formated .. format("%02d",seconds)
    return time_formated
end

function Utils:isINF(value)
    return value == math.huge or value == -math.huge
end

function Utils:GetTableSize(tableName)
    local count = 0
    for k,v in pairs(tableName) do
        count = count + 1
    end
    return count
end

function Utils:RoundValue(num, numDecimals)
    local mult = 10^(numDecimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

function Utils:DisplayNumber(n) -- credit http://richard.warburton.it
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

function Utils:DisplayRoundedNumber(num, numDecimals)
    return Utils:DisplayNumber(Utils:RoundValue(num, numDecimals))
end
