-- Contracts used by Gold Details, with a bounded reusable viewport. Blizzard's
-- actual drawing, clipping, mouse wheel and scrollbar behavior need in-game QA.
ScrollBoxConstants = { RetainScrollPosition = true, NoScrollInterpolation = true }
function CreateDataProvider(elements) return { elements = elements } end
function CreateScrollBoxListLinearView()
    local view = {}
    function view:SetElementExtent(extent) self.extent = extent end
    function view:SetElementExtentCalculator(calculator) self.calculator = calculator end
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
    function box:GetElementExtent(index)
        return self.view.calculator and self.view.calculator(index,self.elements[index]) or self.view.extent
    end
    function box:GetDerivedScrollRange()
        local height=0
        for index=1,#self.elements do height=height+self:GetElementExtent(index) end
        return math.max(0,height-self:GetHeight())
    end
    function box:GetDerivedScrollOffset() return self.offset end
    function box:Render()
        local visible,position={},0
        for index,element in ipairs(self.elements) do
            local extent=self:GetElementExtent(index)
            if position >= self.offset+self:GetHeight() then break end
            if position+extent > self.offset then
                visible[#visible+1]={data=element,extent=extent,position=position}
            end
            position=position+extent
        end
        local count=#visible
        for index = 1, math.max(#self.pool, count) do
            local row = self.pool[index]
            if index <= count then
                if not row then
                    row = CreateFrame(self.view.kind, nil, self)
                    self.pool[index] = row
                end
                local item=visible[index]
                row:SetSize(self:GetWidth(),item.extent)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT",self,"TOPLEFT",0,-(item.position-self.offset))
                self.view.initializer(row,item.data)
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
