local Format = {}
PerHour.Format = Format
function Format:Unit(name)
    return PerHour.Modules[name].ShortName .. (PerHour.Stores.Settings:GetRate() == "minute" and "/m" or "/h")
end
function Format:Rate(metric)
    if not metric or metric.available == false or metric.duration <= 0 then return end
    return metric.total * (PerHour.Stores.Settings:GetRate() == "minute" and 60 or 3600) / metric.duration
end
function Format:Amount(name, value)
    if name == "Gold" then return PerHour.Modules.Gold.FormatValue(value) end
    return Utils:DisplayRoundedNumber(value, 2)
end
function Format:RateText(name, metric)
    local value = self:Rate(metric)
    return value and self:Amount(name,value) .. (PerHour.Stores.Settings:GetRate() == "minute" and "/m" or "/h") or "—"
end
function Format:Compact(value)
    local magnitude = math.abs(value)
    if magnitude >= 1e6 then return string.format("%.1fM",value/1e6)
    elseif magnitude >= 1e3 then return string.format("%.1fk",value/1e3) end
    return Utils:DisplayRoundedNumber(value, 1)
end
function Format:Flags(metric)
    if not metric then return "Unavailable" end
    local parts = {}
    if metric.available == false then parts[#parts+1] = "Unavailable" end
    if metric.partial then parts[#parts+1] = "Partial" end
    if metric.pending then parts[#parts+1] = "Pending" end
    if metric.incomplete then parts[#parts+1] = "Incomplete · frozen" end
    return table.concat(parts," · ")
end
function Format:Date(timestamp)
    local months = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"}
    if not Utils:IsFiniteNumber(timestamp) then return "—" end
    local parts = date("*t",timestamp)
    return string.format("%s %02d, %04d %02d:%02d",months[parts.month],parts.day,parts.year,parts.hour,parts.min)
end
function Format:Duration(seconds)
    if seconds < 60 then return math.floor(seconds).."s" end
    local totalMinutes = math.floor(seconds/60)
    local hours,minutes = math.floor(totalMinutes/60),totalMinutes%60
    return (hours > 0 and hours.."h " or "")..minutes.."m"
end
function Format:Title(record)
    return record.name .. " · " .. (record.startLevel > 0 and "Level " .. record.startLevel or "Level unavailable") .. " · "
        .. (record.startXpPercent and record.startXpPercent .. "% XP at start"
            or record.startAtMaxLevel and "Max level at start" or "XP unavailable at start")
end
function Format:Character(record)
    local owner = PerHour.Stores.Sessions.Account.characters[record.character]
    return type(owner) == "table" and tostring(owner.name).." - "..tostring(owner.realm) or "Current character"
end
function Format:FitText(label,text)
    local width = label:GetWidth()
    if label.FullText == text and label.FitWidth == width then return end
    label.FullText,label.FitWidth = text,width
    label:SetText(text)
    if width <= 0 or label:GetStringWidth() <= width then return end
    local chars = {}
    for char in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do chars[#chars+1] = char end
    local low,high,best = 0,#chars,"…"
    while low <= high do
        local mid=math.floor((low+high)/2)
        local candidate=table.concat(chars,"",1,mid).."…"
        label:SetText(candidate)
        if label:GetStringWidth() <= width then best=candidate; low=mid+1 else high=mid-1 end
    end
    label:SetText(best)
end
