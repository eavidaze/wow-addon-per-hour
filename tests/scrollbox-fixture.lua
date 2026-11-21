-- Contracts used by Gold Details, with a bounded reusable viewport. Blizzard's
-- actual drawing, clipping, mouse wheel and scrollbar behavior need in-game QA.
ScrollBoxConstants = { RetainScrollPosition = true, NoScrollInterpolation = true }
function CreateDataProvider(elements) return { elements = elements } end
function CreateScrollBoxListLinearView()
    local view = {}
    function view:SetElementExtent(extent) self.extent = extent end
    function view:SetElementInitializer(kind, initializer) self.kind, self.initializer = kind, initializer end
    return view
end
ScrollUtil = {
    InitScrollBoxListWithScrollBar = function(box, bar, view)
        box.view, box.bar = view, bar
        bar.box = box
    end,
}
local fixture = {}
function fixture.Initialize(box)
    box.pool, box.offset, box.elements = {}, 0, {}
    function box:GetDerivedScrollRange()
        return math.max(0, #self.elements * self.view.extent - self:GetHeight())
    end
    function box:GetDerivedScrollOffset() return self.offset end
    function box:Render()
        local extent = self.view.extent
        local first = math.floor(self.offset / extent) + 1
        local count = math.min(#self.elements - first + 1, math.ceil((self:GetHeight() + self.offset % extent) / extent))
        for index = 1, math.max(#self.pool, count) do
            local row = self.pool[index]
            if index <= count then
                if not row then
                    row = CreateFrame(self.view.kind, nil, self)
                    self.pool[index] = row
                end
                row:SetSize(self:GetWidth(), extent)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -((first + index - 2) * extent - self.offset))
                self.view.initializer(row, self.elements[first + index - 1])
                row:Show()
            elseif row then row:Hide() end
        end
    end
    function box:SetDataProvider(provider, retainPosition)
        self.provider, self.elements = provider, provider.elements
        self.offset = retainPosition and math.min(self.offset, self:GetDerivedScrollRange()) or 0
        self:Render()
    end
    function box:ScrollToOffset(offset)
        self.offset = math.max(0, math.min(offset, self:GetDerivedScrollRange()))
        self:Render()
    end
    function box:ForEachFrame(callback)
        for _, row in ipairs(self.pool) do if row:IsShown() then callback(row) end end
    end
end
return fixture
