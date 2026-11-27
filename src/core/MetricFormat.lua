local Format = {}
PerHour.Format = Format
function Format:Unit(name,period)
    return PerHour.Modules[name].ShortName .. ((period or PerHour.Stores.Settings:GetRate()) == "minute" and "/m" or "/h")
end
function Format:Rate(metric,period)
    if not metric or metric.available == false or metric.duration <= 0 then return end
    return metric.total * ((period or PerHour.Stores.Settings:GetRate()) == "minute" and 60 or 3600) / metric.duration
end
-- Absolute amounts use native coins; tracked rates use a numeric value and unit.
function Format:Amount(name, value)
    if name == "Gold" then return (value < 0 and "- " or "")..self:Money(value) end
    return Utils:DisplayRoundedNumber(value, 2)
end
-- Native coin icons, shared by event rows and the session card. Callers own signs/colors.
function Format:Money(value,largestOnly)
    local copper=math.floor(math.abs(value)+0.5)
    if largestOnly then
        local denomination,divisor=Enum.CurrencyType.Copper,1
        if copper >= 10000 then denomination,divisor=Enum.CurrencyType.Gold,10000
        elseif copper >= 100 then denomination,divisor=Enum.CurrencyType.Silver,100 end
        return MoneyFormatterUtil.FormatDenomination(MoneyFormatterPresets.CompactWithZero,denomination,math.floor(copper/divisor))
    end
    return GetMoneyString(copper,true)
end
function Format:TruncatedCompact(value,decimals)
    local magnitude,unit=math.abs(value),""
    if magnitude >= 1e6 then magnitude,unit=magnitude/1e6,"M"
    elseif magnitude >= 1e3 then magnitude,unit=magnitude/1e3,"k" end
    local factor=10^decimals
    local truncated=math.floor(magnitude*factor)/factor
    return Utils:DisplayRoundedNumber(value < 0 and -truncated or truncated,decimals)..unit
end
function Format:RateReading(name,metric,period,exact)
    local value = metric and metric.available ~= false and metric.total == 0 and 0 or self:Rate(metric,period)
    if not value then return "—" end
    value = value/(PerHour.Modules[name].RateDivisor or 1)
    return exact and Utils:DisplayRoundedNumber(value,2) or self:Compact(value),self:Unit(name,period)
end
function Format:RateText(name,metric,period)
    local value,unit = self:RateReading(name,metric,period,true)
    return unit and value.." "..unit or value
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
function Format:Date(timestamp,dateOnly)
    local months = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"}
    if not Utils:IsFiniteNumber(timestamp) then return "—" end
    local parts = date("*t",timestamp)
    if dateOnly then return string.format("%s %02d, %04d",months[parts.month],parts.day,parts.year) end
    return string.format("%s %02d, %04d %02d:%02d",months[parts.month],parts.day,parts.year,parts.hour,parts.min)
end
function Format:MeasuredDuration(seconds)
    seconds=math.floor(seconds)
    local hours,minutes=math.floor(seconds/3600),math.floor(seconds/60)%60
    return (hours > 0 and hours.."h " or "")..((hours > 0 or minutes > 0) and minutes.."m " or "")..(seconds%60).."s"
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
    local store = PerHour.Stores.Sessions
    return store:CharacterLabel(store.Account.characters[record.character])
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
