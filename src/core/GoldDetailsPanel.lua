local Details = { Dirty = true }
PerHour.GoldDetailsPanel = Details
local Theme = PerHour.Theme

local LEFT_INSET = 15
local ROW_HEIGHT, LIST_WIDTH, LIST_HEIGHT = 26, 508 - LEFT_INSET, 312
local VALUE_X, VALUE_WIDTH = LIST_WIDTH - 160, 160
local EVENT_X, EVENT_WIDTH = 126, VALUE_X - 126 - 10
local SOURCES = {
    loot_money = { title = "Looted", icon = "Interface\\Icons\\INV_Misc_Bag_10" },
    loot_item = { title = "Item looted" },
    item_reward = { title = "Item reward" },
    quest_money = { title = "Reward", icon = "Interface\\Icons\\INV_Misc_Bag_10" },
    consumable = { title = "Consumable used" },
    quest_turnin = { title = "Quest turn-in" },
    repair = { title = "Repair", icon = "Interface\\Icons\\Trade_BlackSmithing" },
    transport = { title = "Transport", icon = "Interface\\Minimap\\Tracking\\FlightMaster" },
}

local function Money(value)
    return (value < 0 and "- " or "") .. GetMoneyString(math.floor(math.abs(value) + 0.5), true)
end

local function Text(parent, font, x, width, justify)
    local text = parent:CreateFontString(nil, "OVERLAY", font)
    text:SetPoint("LEFT", parent, "LEFT", x, 0)
    text:SetWidth(width)
    text:SetJustifyH(justify or "LEFT")
    text:SetWordWrap(false)
    return text
end

function Details:HideTooltip()
    if self.TooltipOwner and GameTooltip:IsOwned(self.TooltipOwner) then GameTooltip:Hide() end
    self.TooltipOwner, self.TooltipEntry, self.TooltipQuest = nil, nil, nil
end

local function ValuationTooltip(entry)
    local r, g, b = unpack(Theme.text)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Per Hour valuation:", unpack(Theme.gold.text))
    GameTooltip:AddDoubleLine("Price source", PerHour.Pricing:EntrySourceLabel(entry), r, g, b, r, g, b)
    GameTooltip:AddDoubleLine("Recorded value", entry.pending and "Pending" or Money(math.abs(entry.amount)), r, g, b, r, g, b)
    if not entry.valuations or #entry.valuations < 2 then return end
    local groups, ordered = {}, {}
    for _, part in ipairs(entry.valuations) do
        local key = table.concat({ part.priceSource or "pending", part.priceMetric or "", tostring(part.unitPrice) }, ":")
        local group = groups[key]
        if group then group.quantity = group.quantity + part.quantity
        else
            group = { quantity = part.quantity, unitPrice = part.unitPrice, source = part.priceSource, metric = part.priceMetric }
            groups[key], ordered[#ordered + 1] = group, group
        end
    end
    if #ordered < 2 then return end
    for _, group in ipairs(ordered) do
        local label = group.unitPrice and PerHour.Pricing:SourceLabel(group.source, group.metric) or "Price pending"
        GameTooltip:AddDoubleLine(label .. " x" .. group.quantity,
            group.unitPrice and Money(group.quantity * group.unitPrice) or "Pending", r, g, b, r, g, b)
    end
end

local function EventTooltip(owner, entry, showQuest)
    Details:HideTooltip()
    local link = showQuest and entry.questID and ("quest:" .. entry.questID)
        or (not showQuest and entry.itemLink)
    local money = not showQuest and (entry.source == "loot_money" or entry.source == "quest_money")
    if not link and not money then return end
    Details.TooltipOwner, Details.TooltipEntry, Details.TooltipQuest = owner, entry, showQuest
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if link then
        GameTooltip:SetHyperlink(link)
        if not showQuest and entry.itemID then ValuationTooltip(entry) end
    else
        GameTooltip:SetText(entry.source == "loot_money" and "Looted money" or "Quest reward")
        GameTooltip:AddLine(Money(math.abs(entry.amount)), unpack(Theme.text))
    end
    GameTooltip:Show()
end

local function CreateDivider(parent)
    local divider = parent:CreateTexture(nil, "BACKGROUND", nil, -1)
    divider:SetHeight(Theme.rowDivider.height)
    divider:SetColorTexture(unpack(Theme.rowDivider.color))
    divider:SetAlpha(Theme.rowDivider.alpha)
    return divider
end

local function SetupRow(row)
    row.Divider = CreateDivider(row)
    row.Divider:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    row.Divider:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
    -- Center content in the space between borders, excluding the lower divider.
    local contentHeight = ROW_HEIGHT - Theme.rowDivider.height
    local content = CreateFrame("Frame", nil, row)
    content:SetSize(LIST_WIDTH, contentHeight)
    content:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    row.Time = Text(content, "GameFontHighlightSmall", 0, 64)
    row.Direction = content:CreateTexture(nil, "BACKGROUND")
    row.Direction:SetSize(16, 16)
    row.Direction:SetPoint("CENTER", content, "LEFT", 74, 0)
    row.Direction:SetTexCoord(0.2, 0.8, 0.25, 0.75)
    row.Direction:SetDesaturated(true)
    local iconSlot = CreateFrame("Frame", nil, content)
    iconSlot:SetSize(20, 20)
    iconSlot:SetPoint("LEFT", content, "LEFT", 80, 0)
    row.Icon = CreateFrame("ItemButton", nil, iconSlot)
    row.Icon:SetScale(0.5)
    row.Icon:SetPoint("CENTER", iconSlot, "CENTER", 0, 0)
    row.Quest = CreateFrame("Button", nil, content)
    row.Quest:SetSize(18, contentHeight)
    row.Quest:SetPoint("LEFT", content, "LEFT", 103, 0)
    row.Quest.Icon = row.Quest:CreateTexture(nil, "ARTWORK")
    row.Quest.Icon:SetSize(16, 16)
    row.Quest.Icon:SetPoint("CENTER", row.Quest, "CENTER", 0, 0)
    row.Quest.Icon:SetAtlas("QuestNormal")
    row.Event = CreateFrame("Frame", nil, content)
    row.Event:SetPoint("LEFT", content, "LEFT", EVENT_X, 0)
    row.Event:SetSize(EVENT_WIDTH, contentHeight)
    row.Name = Text(row.Event, "GameFontHighlight", 0, EVENT_WIDTH)
    row.Amount = Text(content, "GameFontHighlight", VALUE_X, VALUE_WIDTH, "RIGHT")
    for _, owner in ipairs({ row.Icon, row.Quest }) do
        owner:HookScript("OnEnter", function(self) EventTooltip(self, row.Entry, self == row.Quest) end)
        owner:HookScript("OnLeave", function() Details:HideTooltip() end)
        owner:HookScript("OnHide", function() Details:HideTooltip() end)
        owner:SetMouseClickEnabled(false)
    end
end

local function InitializeRow(row, entry)
    if row.Initialized ~= true then
        SetupRow(row)
        row.Initialized = true
    end
    row.Entry = entry
    row.Icon.DetailEntry, row.Quest.DetailEntry = entry, entry
    row.Quest:SetShown(entry.questID ~= nil)
    row.Direction:SetTexture(entry.direction > 0 and "Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up"
        or "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    row.Direction:SetVertexColor(unpack(entry.direction > 0 and Theme.green.text or Theme.red.text))
    local source = SOURCES[entry.source]
    row.Time:SetText(entry.timestamp and date("%H:%M:%S", entry.timestamp) or "—")
    local name
    -- The panel owns delayed metadata refreshes. Native SetItem's asynchronous
    -- binding could outlive a recycled row and overwrite a different event icon.
    row.Icon:SetItemButtonCount(0)
    if entry.itemID then
        local itemName, link, quality, _, _, _, _, _, _, icon = C_Item.GetItemInfo(entry.itemLink or entry.itemID)
        name = itemName
        row.Icon:SetItemButtonTexture(icon or C_Item.GetItemIconByID(entry.itemID) or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.Icon:SetItemButtonQuality(quality, link or entry.itemLink)
        if not name then
            name = RETRIEVING_ITEM_INFO or "Loading item..."
        end
    else
        row.Icon:SetItemButtonQuality()
        row.Icon:SetItemButtonTexture(source.icon)
        name = source.title
    end
    if entry.quantity and entry.quantity > 1 then name = name .. " x" .. entry.quantity end
    row.Name:SetText(name)
    row.Amount:SetTextColor(unpack(not entry.pending and entry.direction < 0 and Theme.red.text or Theme.text))
    if entry.pending then
        row.Amount:SetText("Pending")
    else
        row.Amount:SetText(Money(math.abs(entry.amount)))
    end
end

function Details:Refresh()
    if not self.Frame or not self.Frame:IsShown() then return end
    local tooltipOwner, tooltipEntry, tooltipQuest = self.TooltipOwner, self.TooltipEntry, self.TooltipQuest
    if tooltipOwner and not GameTooltip:IsOwned(tooltipOwner) then tooltipOwner = nil end
    self:HideTooltip()
    local history = PerHour.Modules.Gold.State.History
    local count, income, expenses, pending = #history, 0, 0, 0
    local rows = {}
    local indices = {}
    for index = count, 1, -1 do
        local entry = history[index]
        -- Older journals may contain resolved zero-value items. Hide them in
        -- the view without rewriting saved history or migrating its format.
        if entry.pending or not (entry.itemID and entry.unitPrice == 0) then
            rows[#rows + 1] = entry
            indices[entry] = #rows
        end
        if entry.pending then pending = pending + 1
        elseif entry.amount >= 0 then income = income + entry.amount
        else expenses = expenses - entry.amount end
    end
    self.Income:SetText(Money(income))
    self.Expenses:SetText(Money(expenses))
    self.Net:SetText(Money(income - expenses))
    self.Pending:SetText(pending > 0 and string.format("Pending prices: %d", pending) or "")
    self.Empty:SetShown(#rows == 0)
    self.TopDivider:SetShown(#rows > 0)
    local offset = self.ScrollBox:GetDerivedScrollOffset()
    if self.History ~= history then offset = 0
    elseif offset > 0 then
        local oldIndex = math.floor(offset / ROW_HEIGHT) + 1
        local fraction = offset % ROW_HEIGHT
        local anchor
        -- Preserve the first surviving entry, even when a pending zero-value
        -- item disappears above or below the reader's current position.
        for index = oldIndex, #self.Rows do
            local newIndex = indices[self.Rows[index]]
            if newIndex then anchor = newIndex; break end
        end
        if not anchor then
            for index = oldIndex - 1, 1, -1 do
                local newIndex = indices[self.Rows[index]]
                if newIndex then anchor = newIndex; break end
            end
        end
        offset = anchor and (anchor - 1) * ROW_HEIGHT + fraction or 0
    end
    self.ScrollBox:SetDataProvider(CreateDataProvider(rows), ScrollBoxConstants.RetainScrollPosition)
    self.ScrollBox:ScrollToOffset(offset, ScrollBoxConstants.NoScrollInterpolation)
    self.History, self.Rows, self.Count, self.Dirty = history, rows, #rows, false
    if tooltipOwner and tooltipOwner:IsVisible() and tooltipOwner.DetailEntry == tooltipEntry then
        EventTooltip(tooltipOwner, tooltipEntry, tooltipQuest)
    end
end

function Details:Invalidate()
    self.Dirty = true
    if not self.Frame or not self.Frame:IsShown() or self.RefreshScheduled then return end
    self.RefreshScheduled = true
    C_Timer.After(0, function()
        self.RefreshScheduled = false
        if self.Dirty then self:Refresh() end
    end)
end

function Details:Show()
    if not self.Frame then
        local frame = PerHour.Components:CreatePanel(UIParent, {
            name = "PerHourGoldDetailsPanel", title = "Gold Details", titleBox = true,
            titleSize = "default", width = 560, height = 512,
            contentSpacing = 12, draggable = true,
            actions = {
                { key = "close", text = "Close", widthFraction = 0.3, align = "CENTER",
                    onClick = function(panel) panel:Hide() end },
            },
        })
        frame:Hide()
        frame:SetFrameStrata("DIALOG")
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        self.Frame = frame
        local content = frame.Content
        local headers = CreateFrame("Frame", nil, content)
        headers:SetSize(LIST_WIDTH, 20)
        headers:SetPoint("TOPLEFT", content, "TOPLEFT", LEFT_INSET, -68)
        for _, column in ipairs({ { "Time", 0, 64 }, { "Event", 74, VALUE_X - 84 }, { "Value", VALUE_X, VALUE_WIDTH, "RIGHT" } }) do
            Text(headers, "GameFontNormal", column[2], column[3], column[4]):SetText(column[1])
        end
        local summary = CreateFrame("Frame", nil, content)
        summary:SetSize(LIST_WIDTH, 54)
        summary:SetPoint("TOPLEFT", content, "TOPLEFT", LEFT_INSET, 0)
        for index, metric in ipairs({
            { "Loot & rewards", "Income", Theme.text },
            { "Expenses & items used", "Expenses", Theme.red.text },
            { "Estimated net profit", "Net", Theme.gold.text },
        }) do
            local row = CreateFrame("Frame", nil, summary)
            row:SetSize(LIST_WIDTH, 18)
            row:SetPoint("TOPLEFT", summary, "TOPLEFT", 0, -(index - 1) * 18)
            row.Label = Text(row, "GameFontHighlight", EVENT_X, EVENT_WIDTH)
            row.Label:SetText(metric[1])
            row.Label:SetTextColor(unpack(metric[3]))
            self[metric[2]] = Text(row, "GameFontHighlight", VALUE_X, VALUE_WIDTH, "RIGHT")
            self[metric[2]]:SetTextColor(unpack(metric[3]))
        end
        self.Pending = Text(content, "GameFontDisableSmall", 0, LIST_WIDTH)
        self.Pending:ClearAllPoints()
        self.Pending:SetPoint("TOPLEFT", content, "TOPLEFT", LEFT_INSET, -54)
        self.ScrollBox = CreateFrame("Frame", nil, content, "WowScrollBoxList")
        self.ScrollBox:SetSize(LIST_WIDTH, LIST_HEIGHT)
        self.ScrollBox:SetPoint("TOPLEFT", content, "TOPLEFT", LEFT_INSET, -90)
        self.TopDivider = CreateDivider(content)
        self.TopDivider:SetPoint("BOTTOMLEFT", self.ScrollBox, "TOPLEFT", 0, 0)
        self.TopDivider:SetPoint("BOTTOMRIGHT", self.ScrollBox, "TOPRIGHT", 0, 0)
        self.ScrollBar = CreateFrame("EventFrame", nil, content, "MinimalScrollBar")
        self.ScrollBar:SetPoint("TOPLEFT", self.ScrollBox, "TOPRIGHT", 8, 0)
        self.ScrollBar:SetPoint("BOTTOMLEFT", self.ScrollBox, "BOTTOMRIGHT", 8, 0)
        local view = CreateScrollBoxListLinearView()
        view:SetElementExtent(ROW_HEIGHT)
        view:SetElementInitializer("Frame", InitializeRow)
        ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view)
        self.Empty = self.ScrollBox:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        self.Empty:SetPoint("CENTER", self.ScrollBox, "CENTER", 0, 0)
        self.Empty:SetText("No events in this session.")
        self.ValuationNote = Text(content, "GameFontDisableSmall", 0, LIST_WIDTH)
        self.ValuationNote:ClearAllPoints()
        self.ValuationNote:SetPoint("TOPLEFT", self.ScrollBox, "BOTTOMLEFT", 0, -6)
        self.ValuationNote:SetText(PerHour.Modules.Gold.ValuationNote)
        frame:SetScript("OnEvent", function() self:Invalidate() end)
        frame:HookScript("OnShow", function()
            for _, event in ipairs({ "GET_ITEM_INFO_RECEIVED", "ITEM_DATA_LOAD_RESULT", "QUEST_DATA_LOAD_RESULT" }) do
                frame:RegisterEvent(event)
            end
            self:Refresh()
        end)
        frame:HookScript("OnHide", function()
            for _, event in ipairs({ "GET_ITEM_INFO_RECEIVED", "ITEM_DATA_LOAD_RESULT", "QUEST_DATA_LOAD_RESULT" }) do
                frame:UnregisterEvent(event)
            end
            self:HideTooltip()
        end)
    end
    if self.Frame:IsShown() then self:Refresh() else self.Frame:Show() end
    self.Frame:Raise()
end
