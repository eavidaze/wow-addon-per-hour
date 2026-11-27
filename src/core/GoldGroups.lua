-- Read-only presentation of the retained journal; never recalculate the session result.
local Groups={}
PerHour.GoldGroups=Groups

local function Key(entry)
    if entry.itemID then
        local variant=entry.itemLink and entry.itemLink:match("item:[^|]+") or tostring(entry.itemID)
        return "item:"..variant..":"..entry.direction
    end
    return "source:"..entry.source..":"..entry.direction
end

local function Quote(group,part)
    local key=table.concat({tostring(part.unitPrice),tostring(part.priceSource),tostring(part.priceMetric),tostring(part.acquired)},":")
    local quote=group.quotes[key]
    if not quote then
        quote={quantity=0,unitPrice=part.unitPrice,priceSource=part.priceSource,priceMetric=part.priceMetric,acquired=part.acquired}
        group.quotes[key]=quote; group.valuations[#group.valuations+1]=quote
    end
    quote.quantity=quote.quantity+(part.quantity or 0)
end

function Groups:Build(events,flow)
    local groups,byKey={},{}
    local outgoing=flow == "Expenses"
    for _,entry in ipairs(events or {}) do
        if (entry.direction < 0) == outgoing then
            local key=Key(entry)
            local group=byKey[key]
            if not group then
                group={id="gold:"..key,grouped=true,source=entry.source,direction=entry.direction,
                    itemID=entry.itemID,itemLink=entry.itemLink,quantity=0,eventCount=0,amount=0,
                    resolvedCount=0,pendingCount=0,excludedCount=0,sources={},questIDs={},valuations={},quotes={}}
                byKey[key]=group; groups[#groups+1]=group
            end
            group.quantity=group.quantity+(entry.itemID and (entry.quantity or 1) or 1)
            group.eventCount=group.eventCount+1
            group.sources[entry.source]=true
            if group.source ~= entry.source and entry.itemID then
                group.source=outgoing and "item_expense" or "item_income"
            end
            if entry.timestamp and (not group.timestamp or entry.timestamp > group.timestamp) then
                group.timestamp,group.elapsed=entry.timestamp,entry.elapsed
            end
            if entry.questID then group.questIDs[entry.questID]=true end
            if entry.pending then group.pendingCount=group.pendingCount+1
            elseif entry.excluded then group.excludedCount=group.excludedCount+1
            else
                group.amount=group.amount+entry.amount
                group.resolvedCount=group.resolvedCount+1
            end
            if entry.itemID then
                if entry.valuations then
                    for _,part in ipairs(entry.valuations) do Quote(group,part) end
                else
                    Quote(group,{quantity=entry.quantity or 1,unitPrice=entry.unitPrice,
                        priceSource=entry.priceSource,priceMetric=entry.priceMetric,acquired=true})
                end
            end
        end
    end
    for _,group in ipairs(groups) do
        group.pending=group.pendingCount > 0
        group.excluded=group.excludedCount > 0
        group.questCount=0
        for id in pairs(group.questIDs) do group.questCount=group.questCount+1; group.questID=id end
        if group.questCount ~= 1 then group.questID=nil end
        local first,uniform,complete=nil,true,true
        for _,quote in ipairs(group.valuations) do
            if quote.unitPrice == nil then complete=false
            elseif not first then
                first=quote
                group.priceSource,group.priceMetric=quote.priceSource,quote.priceMetric
            else
                if quote.unitPrice ~= first.unitPrice then uniform=false end
                if quote.priceSource ~= group.priceSource or quote.priceMetric ~= group.priceMetric then
                    group.priceSource,group.priceMetric="mixed",nil
                end
            end
        end
        if first and uniform and complete then group.unitPrice=first.unitPrice end
        group.quotes=nil
    end
    table.sort(groups,function(a,b)
        local av,bv=outgoing and math.abs(a.amount) or a.amount,outgoing and math.abs(b.amount) or b.amount
        if av ~= bv then return av > bv end
        if (a.timestamp or 0) ~= (b.timestamp or 0) then return (a.timestamp or 0) > (b.timestamp or 0) end
        return a.id < b.id
    end)
    return groups
end
