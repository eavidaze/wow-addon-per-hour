-- Native Forever UI and API fixture, shared by the revamp regression tests.
local frames, names, messages, sent = {}, {}, {}, {}
local now, xp, xpMax, level = 0, 100, 1000, 10
local playedTotal, playedRequests = 100000, 0
local playedRequested, autoPlayedReply = false, true
local timers = {}
local honorBalance = 100
local watched = { name = "Stormwind", factionID = 72, currentStanding = 0 }
local checks = 0
local function equal(actual, expected, label)
    assert(actual == expected, label..": expected "..tostring(expected)..", got "..tostring(actual))
    checks = checks + 1
end
local function near(actual, expected, label)
    assert(math.abs(actual - expected) < 0.000001, label..": expected "..expected..", got "..actual)
    checks = checks + 1
end

local methods = {}
strmatch = string.match
function securecallfunction(callback, ...) return callback(...) end
function methods:SetScript(event, callback)
    self.scripts[event] = callback
    if callback and (event == "OnEnter" or event == "OnLeave" or event == "OnMouseDown" or event == "OnMouseUp") then
        self:EnableMouse(true)
    end
end
function methods:GetScript(event) return self.scripts[event] end
function methods:HookScript(event, callback)
    local previous = self.scripts[event]
    self:SetScript(event, function(...)
        if previous then previous(...) end
        callback(...)
    end)
end
function hooksecurefunc(target, method, callback)
    local previous = target[method]
    target[method] = function(...)
        previous(...)
        callback(...)
    end
end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:UnregisterEvent(event) self.events[event] = nil end
local function VisibilityScripts(frame, event)
    if frame.scripts[event] then frame.scripts[event](frame) end
    for _, child in ipairs({ frame:GetChildren() }) do
        if child:IsShown() then VisibilityScripts(child, event) end
    end
end
function methods:Show()
    if self.shown then return end
    self.shown = true
    if self:IsVisible() then VisibilityScripts(self, "OnShow") end
end
function methods:Hide()
    if not self.shown then return end
    local visible = self:IsVisible()
    self.shown = false
    if visible then VisibilityScripts(self, "OnHide") end
end
function methods:IsShown() return self.shown end
function methods:IsVisible()
    local parent = rawget(self, "parent")
    return self.shown and (not parent or parent:IsVisible())
end
function methods:SetAlpha(alpha) self.alpha = alpha end
function methods:GetAlpha() return rawget(self, "alpha") or 1 end
function methods:SetIgnoreParentAlpha(ignore) self.ignoreParentAlpha = ignore end
function methods:GetEffectiveAlpha()
    local parent = rawget(self, "parent")
    if not parent or rawget(self, "ignoreParentAlpha") then return self:GetAlpha() end
    return self:GetAlpha() * parent:GetEffectiveAlpha()
end
function methods:SetShown(value) if value then self:Show() else self:Hide() end end
function methods:SetText(value)
    self.text = value
    if rawget(self, "Text") then self.Text:SetText(value) end
    if rawget(self, "template") == "SharedGoldRedButtonSmallTemplate" and value ~= ""
        and not rawget(self, "fontString") then
        self.fontString = self:CreateFontString(nil, "OVERLAY", rawget(self,"normalFontObject"))
    end
    if rawget(self, "fontString") then self.fontString:SetText(value) end
end
function methods:GetText() return self.text end
function methods:SetOwner(owner) self.owner = owner end
function methods:IsOwned(owner) return self.owner == owner end
function methods:GetFontString() return rawget(self, "fontString") end
function methods:SetNormalFontObject(font)
    self.normalFontObject=font
    if rawget(self,"fontString") then self.fontString:SetFontObject(font) end
end
function methods:GetNormalFontObject() return rawget(self,"normalFontObject") end
function methods:SetHighlightFontObject(font) self.highlightFontObject=font end
function methods:GetHighlightFontObject() return rawget(self,"highlightFontObject") end
function methods:SetDisabledFontObject(font) self.disabledFontObject=font end
function methods:GetDisabledFontObject() return rawget(self,"disabledFontObject") end
function methods:SetFontObject(font) self.template = font end
function methods:GetFont()
    return rawget(self, "fontPath") or "Fonts\\FRIZQT__.TTF",
        rawget(self, "fontSize") or (self.template == "GameFontDisableSmall" and 10 or 12),
        rawget(self, "fontFlags") or ""
end
function methods:SetFont(path, size, flags) self.fontPath, self.fontSize, self.fontFlags = path, size, flags end
function methods:SetVertexColor(...) self.vertexColor = { ... } end
function methods:GetVertexColor() return unpack(rawget(self, "vertexColor") or { 1, 1, 1, 1 }) end
function methods:SetTextColor(r,g,b,a)
    assert(type(r)=="number" and type(g)=="number" and type(b)=="number", "SetTextColor requires numeric RGB components")
    assert(a==nil or type(a)=="number", "SetTextColor alpha must be numeric, not an item quality string")
    self.textColor={r,g,b,a}
end
function methods:SetJustifyH(value) self.justifyH = value end
function methods:SetTexture(texture, wrapHorizontal, wrapVertical, filterMode)
    assert(texture ~= nil, "texture must be available")
    self.texture = texture
    self.filterMode = filterMode
end
function methods:SetRotation(radians) self.rotation = radians end
function methods:SetBlendMode(mode) self.blendMode = mode end
function methods:SetColorTexture(...) self.color = { ... } end
function methods:SetAtlas(atlas,useAtlasSize)
    assert(type(atlas) == "string", "atlas must be available")
    self.atlas = atlas
    if atlas == "Options_InnerFrame" then
        -- Synthetic atlas bounds exercise cropping within a larger texture sheet.
        self:SetTexCoord(0.125,0.625,0.25,0.8125)
        if useAtlasSize then self:SetSize(880,580) end
    end
end
function methods:SetEnabled(enabled) self.enabled = enabled end
function methods:EnableMouse(enabled) self.mouseEnabled, self.mouseMotionEnabled = enabled, enabled end
function methods:IsMouseClickEnabled() return self.mouseEnabled == true end
function methods:IsMouseMotionEnabled() return self.mouseMotionEnabled == true end
function methods:SetMouseClickEnabled(enabled) self.mouseEnabled = enabled end
function methods:SetMouseMotionEnabled(enabled) self.mouseMotionEnabled = enabled end
function methods:RegisterForMouse(...) self.mouseButtons = { ... } end
function methods:RegisterForClicks(...) self.clickButtons = { ... } end
function methods:RegisterForDrag(...) self.dragButtons = { ... } end
function methods:RegisterCallback(event, callback)
    self.callbacks = rawget(self, "callbacks") or {}
    self.callbacks[event] = self.callbacks[event] or {}
    table.insert(self.callbacks[event], callback)
end
function methods:TriggerEvent(event, ...)
    for _, callback in ipairs((rawget(self, "callbacks") or {})[event] or {}) do callback(self, ...) end
end
function methods:SetChecked(checked) self.checked = checked end
function methods:GetChecked() return self.checked == true end
function methods:Click(mouseButton)
    if self.kind == "CheckButton" then self:SetChecked(not self:GetChecked()) end
    if self.scripts.OnClick then self.scripts.OnClick(self, mouseButton or "LeftButton") end
end
function methods:AddMaskTexture(mask) self.mask = mask end
function methods:OverrideText(value) self:SetText(value) end
function methods:SetSize(width, height) self.width, self.height = width, height end
function methods:SetParent(parent) self.parent = parent end
function methods:GetParent() return self.parent end
function methods:SetScale(scale) self.scale = scale end
function methods:GetScale() return rawget(self, "scale") or 1 end
function methods:SetFrameStrata(strata) self.strata = strata end
function methods:GetFrameStrata() return rawget(self,"strata") or "MEDIUM" end
function methods:SetFrameLevel(level) self.frameLevel=level end
function methods:GetFrameLevel()
    return rawget(self,"frameLevel") or (rawget(self,"parent") and self.parent:GetFrameLevel()+1 or 0)
end
function methods:SetToplevel(value) self.topLevel = value end
function methods:IsToplevel() return rawget(self,"topLevel") == true end
function methods:SetFlattensRenderLayers(value) self.flattenLayers = value end
function methods:GetFlattensRenderLayers() return rawget(self,"flattenLayers") == true end
function methods:GetChildren()
    local children = {}
    for _, frame in ipairs(frames) do
        if rawget(frame, "parent") == self then children[#children + 1] = frame end
    end
    return unpack(children)
end
function methods:SetWidth(value) self.width = value end
function methods:SetHeight(value)
    local previous = rawget(self, "height")
    self.height = value
    if previous ~= value and self.scripts.OnSizeChanged then
        self.scripts.OnSizeChanged(self, rawget(self, "width") or 0, value)
    end
end
function methods:SetMinMaxValues(minimum, maximum) self.minimum, self.maximum = minimum, maximum end
function methods:SetValueStep(step) self.valueStep = step end
function methods:SetObeyStepOnDrag(obey) self.obeyStep = obey end
function methods:SetValue(value)
    local previous = rawget(self, "value")
    self.value = value
    if previous ~= value and self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end
end
function methods:GetValue() return self.value end
function methods:SetAutoFocus(autoFocus) self.autoFocus = autoFocus end
function methods:SetFocus() self.focused = true end
function methods:ClearFocus()
    if not rawget(self, "focused") then return end
    self.focused = false
    if self.scripts.OnEditFocusLost then self.scripts.OnEditFocusLost(self) end
end
function methods:SetTexCoord(...) self.texCoords = { ... } end
function methods:GetTexCoord()
    local coords=self.texCoords
    if #coords == 4 then return coords[1],coords[3],coords[1],coords[4],coords[2],coords[3],coords[2],coords[4] end
    return unpack(coords)
end
function methods:GetWidth()
    local width = rawget(self, "width")
    if width then return width end
    local points = rawget(self, "points") or {}
    local left = points.LEFT or points.TOPLEFT or points.BOTTOMLEFT
    local right = points.RIGHT or points.TOPRIGHT or points.BOTTOMRIGHT
    if left and right and left[2] == right[2] then
        return left[2]:GetWidth() + right[4] - left[4]
    end
    return 0
end
function methods:GetHeight() return self.height end
function methods:GetStringWidth()
    local width = self.template == "GameFontNormalHuge" and 10 or 6
    if self.template == "GameFontDisableSmall" then width = select(2, self:GetFont()) / 2 end
    return #self.text * width
end
function methods:GetUnboundedStringWidth() return self:GetStringWidth() end
function methods:GetStringHeight()
    local width=rawget(self,"width") or 0
    local _,fontSize=self:GetFont()
    local lines=0
    for line in ((self:GetText() or "").."\n"):gmatch("(.-)\n") do
        lines=lines+math.max(1,width > 0 and math.ceil(#line*fontSize/2/width) or 1)
    end
    return lines*(fontSize+2)
end
function methods:SetPoint(...)
    self.point = { ... }
    self.points = rawget(self, "points") or {}
    self.points[self.point[1]] = self.point
end
function methods:GetPoint() return unpack(self.point) end
function methods:GetLeft()
    local point = rawget(self, "point")
    if not point then return 0 end
    local anchor, parent, relative, x = point[1], point[2], point[3], point[4]
    local left = parent:GetLeft() + x
    if relative:find("RIGHT") then left = left + parent:GetWidth()
    elseif not relative:find("LEFT") then left = left + parent:GetWidth() / 2 end
    if anchor:find("RIGHT") then left = left - self:GetWidth()
    elseif not anchor:find("LEFT") then left = left - self:GetWidth() / 2 end
    return left
end
function methods:GetTop()
    local point = rawget(self, "point")
    if not point then return self:GetHeight() end
    local anchor, parent, relative, y = point[1], point[2], point[3], point[5]
    local top = parent:GetTop() + y
    if relative:find("BOTTOM") then top = top - parent:GetHeight()
    elseif not relative:find("TOP") then top = top - parent:GetHeight() / 2 end
    if anchor:find("BOTTOM") then top = top + self:GetHeight()
    elseif not anchor:find("TOP") then top = top + self:GetHeight() / 2 end
    return top
end
function methods:ClearAllPoints() self.point, self.points = nil, {} end
function methods:StartMoving() self.moving = true end
function methods:StopMovingOrSizing() self.moving = false end
function methods:GetCenter() return 100, 200 end
function methods:GetEffectiveScale()
    local parent = rawget(self,"parent")
    return self:GetScale()*(parent and parent:GetEffectiveScale() or 2)
end
function methods:SetupMenu(generator) self.menuGenerator = generator end
function methods:IsMenuOpen() return self.menuOpen == true end
function methods:CloseMenu()
    self.menuOpen = false
    local description=rawget(self,"menuDescription")
    for _,item in ipairs(description and description.items or {}) do
        if item.frame then item.frame:Hide() end
    end
end
local function menuDescription()
    local root = { items = {} }
    function root:SetScrollMode(height) self.maxScrollExtent = height end
    function root:CreateTitle(text) self.title = text end
    function root:CreateDivider() self.items[#self.items + 1] = {kind="divider"} end
    -- MenuUtil.CreateFrame takes no arguments; initializers/data are registered
    -- on the returned description, unlike the lower-level MenuTemplates API.
    function root:CreateFrame()
        local item={initializers={}}
        function item:AddInitializer(initializer) self.initializers[#self.initializers+1]=initializer end
        function item:SetData(data) self.data=data end
        function item:SetResponder(callback) self.callback=callback end
        function item:Pick(context,buttonName)
            self.inputContext,self.buttonName=context,buttonName
            local response=self.callback()
            if response == MenuResponse.CloseAll then self.owner:CloseMenu() end
        end
        self.items[#self.items+1]=item
        return item
    end
    function root:CreateCheckbox(text, isSelected, callback, data)
        self.items[#self.items + 1] = { text = text, isSelected = isSelected, callback = callback, data = data }
    end
    function root:CreateRadio(text, isSelected, callback, data)
        self.items[#self.items + 1] = { text = text, isSelected = isSelected, callback = callback, data = data }
    end
    function root:CreateButton(text, callback, data)
        local item = menuDescription()
        item.text, item.callback, item.data = text, callback, data
        self.items[#self.items + 1] = item
        return item
    end
    return root
end
function methods:GenerateMenu()
    local previous=rawget(self,"menuDescription")
    for _,item in ipairs(previous and previous.items or {}) do
        if item.frame then item.frame:Hide() end
    end
    local root = menuDescription()
    self.menuGenerator(self, root)
    self.menuDescription = root
    for _,item in ipairs(root.items) do
        if item.initializers then
            item.owner=self
            item.frame=CreateFrame("Frame",nil,self)
            item.width,item.height=1,1
            for _,initializer in ipairs(item.initializers) do
                local width,height=initializer(item.frame,item)
                if width and height then item.width,item.height=width,height end
            end
            item.frame:SetSize(item.width,item.height)
        end
    end
    if rawget(self, "Text") then
        for index, item in ipairs(root.items) do
            if item.isSelected and item.isSelected(item.data) then
                self:SetText(item.text)
                local selector = rawget(self, "settingsSelector")
                if selector then
                    selector.DecrementButton:SetEnabled(index > 1)
                    selector.IncrementButton:SetEnabled(index < #root.items)
                end
            end
        end
    end
end
function methods:SetMenuOpen(open)
    if not open then self:CloseMenu(); return end
    self.menuOpen = open
    if open then self:GenerateMenu() end
end
local function object(name)
    assert(name == nil or type(name) == "string", "UI object name must be a string")
    return setmetatable({ name = name, scripts = {}, events = {}, shown = true }, {
        __index = function(_, key) return methods[key] or function() end end,
    })
end
function methods:CreateFontString(name, layer, template)
    assert(layer == "OVERLAY", "font strings need a valid draw layer")
    local fontString = object(name)
    fontString.parent = self
    fontString.template = template
    return fontString
end
function methods:CreateTexture(name, layer)
    local texture = object(name)
    texture.parent = self
    texture.layer = layer
    return texture
end
function methods:CreateAnimationGroup()
    local group = object()
    group.animations, group.playing, group.playCount = {}, false, 0
    function group:SetLooping(looping) self.looping = looping end
    function group:CreateAnimation(kind)
        local animation = object()
        animation.kind = kind
        function animation:SetOrder(order) self.order = order end
        function animation:SetFromAlpha(alpha) self.fromAlpha = alpha end
        function animation:SetToAlpha(alpha) self.toAlpha = alpha end
        function animation:SetDuration(duration) self.duration = duration end
        function animation:SetFlipBookRows(rows) self.rows = rows end
        function animation:SetFlipBookColumns(columns) self.columns = columns end
        function animation:SetFlipBookFrames(frames) self.frames = frames end
        function animation:SetFlipBookFrameWidth(width) self.frameWidth = width end
        function animation:SetFlipBookFrameHeight(height) self.frameHeight = height end
        function animation:SetStartDelay(delay) self.startDelay = delay end
        function animation:SetDegrees(degrees) self.degrees = degrees end
        function animation:SetOrigin(...) self.origin = { ... } end
        table.insert(self.animations, animation)
        return animation
    end
    function group:Play() self.playing, self.playCount = true, self.playCount + 1 end
    function group:Stop() self.playing = false end
    function group:IsPlaying() return self.playing end
    return group
end
function methods:CreateLine() return object() end
function methods:SetStartPoint(...) self.startPoint = { ... } end
function methods:SetEndPoint(...) self.endPoint = { ... } end
function methods:CreateMaskTexture() return object() end
function methods:AddLine(text, r, g, b)
    self.singleLines = rawget(self, "singleLines") or {}
    self.singleLineColors = rawget(self, "singleLineColors") or {}
    table.insert(self.singleLines, text)
    table.insert(self.singleLineColors, { r, g, b })
end
function methods:AddDoubleLine(label, value)
    self.lines = rawget(self, "lines") or {}
    self.lines[label] = value
end
UIParent = object("UIParent")
UIParent:SetSize(1920, 1080)
Minimap = object("Minimap")
Minimap:SetSize(140, 140)
GameTooltip = object("GameTooltip")
-- Defined in Forever's Blizzard_GameTooltip/Mainline/GameTooltip.xml.
GameNoHeaderTooltip = object("GameNoHeaderTooltip")
GameNoHeaderTooltip:Hide()
function methods:ClearLines()
    self.text, self.lines, self.singleLines = "", {}, {}
    self.singleLineColors = {}
end
function GameTooltip:SetText(text)
    self.text, self.lines, self.singleLines = text, {}, {}
    self.singleLineColors = {}
end
local cursorX, cursorY = 400, 400
function GetCursorPosition() return cursorX, cursorY end
-- Forever exposes the region method, not the old MouseIsOver global.
MouseIsOver = nil
function methods:IsMouseOver()
    local frame = self
    if not frame:IsVisible() then return false end
    local left, top = frame:GetLeft(), frame:GetTop()
    if not left or not top then return false end
    local scale = frame:GetEffectiveScale()
    local x, y = cursorX / scale, cursorY / scale
    return x >= left and x <= left + frame:GetWidth()
        and y <= top and y >= top - frame:GetHeight()
end
MinimalSliderWithSteppersMixin = { Label = { Right = 2 }, Event = { OnValueChanged = "OnValueChanged" } }
SettingsCheckboxMixin = { Event = { OnValueChanged = "OnValueChanged" } }
local scrollBoxFixture = assert(loadfile("tests/scrollbox-fixture.lua"))()
ButtonGroupBaseMixin={Event={Selected="Selected"}}
SOUNDKIT={IG_CHARACTER_INFO_TAB=1}
function PlaySound(sound) end
-- Simulate native radio selection/callback contracts, without simulating drawing.
function CreateRadioButtonGroup()
    local group={buttons={}}
    function group:RegisterCallback(event,callback,owner) self.callback,self.owner=callback,owner end
    function group:Select(button)
        if button:IsSelected() then return end
        for _,candidate in ipairs(self.buttons) do candidate:SetSelected(candidate==button) end
        self.callback(self.owner,button)
    end
    function group:AddButton(button)
        self.buttons[#self.buttons+1]=button
        button:SetScript("OnClick",function() self:Select(button) end)
    end
    return group
end
function CreateFrame(kind, name, parent, template)
    assert(template == nil or template == "UIPanelButtonTemplate" or template == "SharedGoldRedButtonSmallTemplate"
        or template == "DialogBorderTranslucentTemplate" or template == "FlatPanelBackgroundTemplate"
        or template == "MinimalTabTemplate"
        or template == "DialogHeaderTemplate" or template == "GameTooltipTemplate"
        or template == "UIPanelCloseButton" or template == "UIPanelSquareButton"
        or template == "UICheckButtonTemplate" or template == "InputBoxTemplate"
        or template == "SettingsCheckboxTemplate" or template == "MinimalSliderWithSteppersTemplate"
        or template == "MinimalSliderTemplate" or template == "SettingsDropdownWithButtonsTemplate"
        or template == "WowScrollBoxList" or template == "MinimalScrollBar",
        "unsupported template: "..tostring(template))
    if name then
        name = name:gsub("%$parent", parent.name or "")
        assert(not names[name], "duplicate frame name: "..name)
    end
    local frame = object(name)
    frame.parent, frame.template, frame.kind = parent, template, kind
    if kind == "ItemButton" then
        frame:SetSize(37, 37)
        frame.icon = frame:CreateTexture(nil, "BORDER")
        frame:EnableMouse(true)
        function frame:SetItem(item)
            self.item = item
            self.iconTexture = item and C_Item.GetItemIconByID(tonumber(item:match("item:(%d+)"))) or nil
        end
        function frame:SetItemButtonTexture(texture)
            self.iconTexture = texture
            self.icon.texture = texture
            self.icon.atlas = nil
        end
        function frame:SetItemButtonCount(count) self.count = count end
        function frame:SetItemButtonQuality(quality, item) self.quality, self.qualityItem = quality, item end
    end
    if template == "WowScrollBoxList" then scrollBoxFixture.Initialize(frame) end
    if kind == "Button" or kind == "DropdownButton" or kind == "CheckButton" or kind == "Slider" then
        frame:EnableMouse(true)
    end
    if template == "DialogBorderTranslucentTemplate" then
        frame.Bg = object()
    end
    if template == "MinimalTabTemplate" then
        frame:SetSize(100,37)
        frame.Text=frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        frame.selected=false
        function frame:IsSelected() return self.selected end
        function frame:SetSelected(selected)
            self.selected=selected
            self.Text:SetFontObject(selected and "GameFontHighlightSmall" or "GameFontNormalSmall")
        end
    end
    -- Mirror Forever's DialogHeaderTemplate sizing and font methods.
    if template == "DialogHeaderTemplate" then
        frame:SetSize(200, 39)
        frame:SetPoint("TOP", parent, "TOP", 0, 11)
        frame.headerTextPadding = 64
        frame.Text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.Text:SetText("")
        function frame:UpdateWidth()
            self:SetWidth(self.Text:GetStringWidth() + self.headerTextPadding)
        end
        function frame:Setup(text)
            self.Text:SetText(text)
            self:UpdateWidth()
        end
        function frame:SetHeaderFont(font)
            self.Text:SetFontObject(font)
            self:UpdateWidth()
        end
    end
    if template == "UIPanelButtonTemplate" then
        frame.fontString = object()
    end
    if template == "SharedGoldRedButtonSmallTemplate" then
        frame.Left, frame.Center, frame.Right = object(), object(), object()
        frame:SetNormalFontObject("GameFontNormal")
        frame:SetHighlightFontObject("GameFontHighlight")
        frame:SetDisabledFontObject("GameFontDisable")
    end
    if template == "UIPanelSquareButton" then
        frame.icon = object()
        frame.icon:SetTexCoord(0.015625, 0.203125, 0.015625, 0.203125)
    end
    if kind == "DropdownButton" then
        frame:RegisterForMouse("LeftButtonDown", "LeftButtonUp")
        frame.nativeMouseDownCalls = 0
        frame.scripts.OnMouseDown = function(self)
            self.nativeMouseDownCalls = self.nativeMouseDownCalls + 1
            self:SetMenuOpen(not self:IsMenuOpen())
        end
    end
    if template == "SettingsCheckboxTemplate" then
        frame:SetSize(30, 29)
        function frame:Init(value, tooltip)
            self:SetChecked(value)
            self.tooltipFunc = tooltip
            self:SetScript("OnClick", function(self)
                self:TriggerEvent(SettingsCheckboxMixin.Event.OnValueChanged, self:GetChecked())
            end)
        end
    elseif template == "MinimalSliderWithSteppersTemplate" then
        frame:SetSize(250, 40)
        frame.Slider = CreateFrame("Slider", nil, frame, "MinimalSliderTemplate")
        frame.Back, frame.Forward = CreateFrame("Button", nil, frame), CreateFrame("Button", nil, frame)
        frame.RightText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        local function update(value)
            frame.RightText:SetText(frame.formatters[MinimalSliderWithSteppersMixin.Label.Right](value))
            frame.Back:SetEnabled(value > frame.Slider.minimum)
            frame.Forward:SetEnabled(value < frame.Slider.maximum)
        end
        function frame:Init(value, minimum, maximum, steps, formatters)
            self.Slider:SetMinMaxValues(minimum, maximum)
            self.Slider:SetValueStep((maximum - minimum) / steps)
            self.Slider:SetValue(value)
            self.formatters = formatters
            update(value)
            self.Slider:SetScript("OnValueChanged", function(_, value)
                update(value)
                self:TriggerEvent(MinimalSliderWithSteppersMixin.Event.OnValueChanged, value)
            end)
        end
        function frame:SetValue(value) self.Slider:SetValue(value) end
        frame.Back:SetScript("OnClick", function()
            frame.Slider:SetValue(frame.Slider:GetValue() - frame.Slider.valueStep)
        end)
        frame.Forward:SetScript("OnClick", function()
            frame.Slider:SetValue(frame.Slider:GetValue() + frame.Slider.valueStep)
        end)
    elseif template == "SettingsDropdownWithButtonsTemplate" then
        frame:SetSize(223, 38)
        frame.Dropdown = CreateFrame("DropdownButton", nil, frame)
        frame.Dropdown:SetPoint("CENTER", frame, "CENTER", 0, 0)
        frame.Dropdown.Text = frame.Dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.Dropdown.settingsSelector = frame
        frame.DecrementButton = CreateFrame("Button", nil, frame)
        frame.IncrementButton = CreateFrame("Button", nil, frame)
        frame.DecrementButton:SetSize(24, 24)
        frame.IncrementButton:SetSize(24, 24)
        frame.DecrementButton:SetPoint("RIGHT", frame.Dropdown, "LEFT", -5, 0)
        frame.IncrementButton:SetPoint("LEFT", frame.Dropdown, "RIGHT", 4, 0)
        local function step(direction)
            local items = frame.Dropdown.menuDescription.items
            for index, item in ipairs(items) do
                if item.isSelected(item.data) then
                    local nextItem = items[index + direction]
                    if nextItem then nextItem.callback(nextItem.data) end
                    return
                end
            end
        end
        frame.DecrementButton:SetScript("OnClick", function() step(-1) end)
        frame.IncrementButton:SetScript("OnClick", function() step(1) end)
    end
    frames[#frames + 1] = frame
    if name then names[name] = frame end
    return frame
end
-- Context-menu ownership and close callbacks follow Forever's MenuUtil/Menu.
MenuUtil = {}
MenuInputContext={MouseButton=1}
MenuResponse={Open=1,Refresh=2,Close=3,CloseAll=4}
function MenuUtil.CreateContextMenu(owner, generator)
    if MenuUtil.activeMenu then MenuUtil.activeMenu:Close() end
    local menu = CreateFrame("Frame", nil, UIParent)
    menu.owner, menu.description = owner, menuDescription()
    generator(owner, menu.description)
    function menu:SetClosedCallback(callback) self.closedCallback = callback end
    function menu:Close()
        if not self:IsShown() then return end
        self:Hide()
        if self.closedCallback then self.closedCallback(self) end
        if MenuUtil.activeMenu == self then MenuUtil.activeMenu = nil end
    end
    menu:SetScript("OnUpdate", function(self)
        if not owner:IsVisible() then self:Close() end
    end)
    MenuUtil.activeMenu = menu
    return menu
end
function GetTime() return now end
C_Timer = { After = function(delay, callback)
    timers[#timers + 1] = { deadline = now + delay, callback = callback }
end }
function RequestTimePlayed()
    playedRequests = playedRequests + 1
    playedRequested = true
end
READY_CHECK_READY_TEXTURE_RAID = "ready"
READY_CHECK_NOT_READY_TEXTURE_RAID = "not-ready"
READY_CHECK_WAITING_TEXTURE_RAID = "waiting"
local abbreviatedValue
function AbbreviateLargeNumbers(value)
    abbreviatedValue = value
    if value >= 1000000000000 then return "1T" end
    -- The native formatter need not abbreviate thousands on this client.
    return tostring(value)
end
function UnitXP(_unit) return xp end
function UnitXPMax(_unit) return xpMax end
function UnitLevel(_unit) return level end
function GetMaxPlayerLevel() return 60 end
-- Keep honor-level XP fixed, matching the live dump even when Honor Points increase.
function UnitHonor(_unit) return 0 end
function UnitHonorMax(_unit) return 5500 end
function UnitHonorLevel(_unit) return 1 end
function issecretvalue(value) return type(value) == "table" and value.secret == true end
DEFAULT_CHAT_FRAME = { AddMessage = function(_, message) messages[#messages + 1] = message end }
local factionChanged
local factions = {
    { name = "Alliance", factionID = 0, isHeader = true, isCollapsed = true, children = {
        { name = "Stormwind", factionID = 72, currentStanding = 0 },
        { name = "Cities", factionID = 0, isHeader = true, isCollapsed = true, children = {
            { name = "Ironforge", factionID = 47, currentStanding = 100 },
        } },
    } },
    { name = "Inactive", factionID = 0, isHeader = true, isCollapsed = true, children = {
        { name = "Timbermaw Hold", factionID = 576, currentStanding = -100 },
    } },
    { name = "Faction with reputation", factionID = 999, currentStanding = 0,
        isHeader = true, isHeaderWithRep = true, isCollapsed = true },
}
local function factionRows(all)
    local rows = {}
    local function add(nodes)
        for _, data in ipairs(nodes) do
            rows[#rows + 1] = data
            if data.children and (all or not data.isCollapsed) then add(data.children) end
        end
    end
    add(factions)
    return rows
end
C_Reputation = {
    GetWatchedFactionData = function() return watched end,
    IsMajorFaction = function() return watched and watched.isMajorFaction or false end,
    IsFactionParagon = function() return watched and watched.isParagon or false end,
    GetNumFactions = function() return #factionRows() end,
    GetFactionDataByIndex = function(index) return factionRows()[index] end,
    ExpandFactionHeader = function(index)
        factionRows()[index].isCollapsed = false
        if factionChanged then factionChanged() end
    end,
    CollapseFactionHeader = function(index)
        factionRows()[index].isCollapsed = true
        if factionChanged then factionChanged() end
    end,
    SetWatchedFactionByID = function(id)
        for _, data in ipairs(factionRows(true)) do
            if data.factionID == id then watched = data; break end
        end
        if factionChanged then factionChanged() end
    end,
    SetWatchedFactionByIndex = function(index)
        equal(index, 0, "clearing watched reputation uses index zero")
        watched = nil
        if factionChanged then factionChanged() end
    end,
}
C_GossipInfo = { GetFriendshipReputation = function()
    return { friendshipFactionID = watched and watched.friendshipFactionID or 0 }
end }
C_CurrencyInfo = { GetCurrencyInfo = function(id)
    if id == 1792 then return { name = "Honor Points", quantity = honorBalance, totalEarned = 0 } end
end }
C_ChatInfo = { SendChatMessage = function(message, channel) sent[#sent + 1] = { message, channel } end }
SlashCmdList = {}
-- Ensure saved visibility survives ADDON_LOADED.
PerHourCharacter_Settings = {
    Experience = { isShown = true, position = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 90, y = -160 } },
}

local function read(path)
    local file = assert(io.open(path, "r"))
    local contents = file:read("*a")
    file:close()
    return contents
end
local function loadSource(path)
    path = path:gsub("\\", "/")
    if path:match("%.xml$") then
        local directory = path:match("^(.*[/])") or ""
        for file in read(path):gmatch('file="([^"]+)"') do loadSource(directory..file) end
    else
        assert(loadfile(path))("per-hour", {})
    end
end
local function loadAddon()
    -- A simulated client reload recreates the embedded libraries as well.
    LibStub = nil
    Minimap.scripts = {}
    MenuUtil.activeMenu = nil
    for line in read("per-hour.toc"):gmatch("[^\r\n]+") do
        if not line:match("^#") and line:match("%S") then loadSource(line) end
    end
end
local goldFixture = assert(loadfile("tests/gold-fixture.lua"))()
loadAddon()
local function event(name, ...)
    if name == "TIME_PLAYED_MSG" then playedRequested = false end
    for _, frame in ipairs(frames) do
        if frame.events[name] then frame.scripts.OnEvent(frame, name, ...) end
    end
    if name == "PLAYER_ENTERING_WORLD" and autoPlayedReply and playedRequested then
        event("TIME_PLAYED_MSG", playedTotal, 0)
    end
end
local function changeHonor(amount)
    honorBalance = honorBalance + amount
    event("CURRENCY_DISPLAY_UPDATE", 1792, honorBalance, amount)
end
factionChanged = function() event("UPDATE_FACTION") end
local function tick(seconds)
    if PerHour.Session.InWorld then playedTotal = playedTotal + seconds end
    now = now + seconds
    for _, frame in ipairs(frames) do
        if frame:IsVisible() and frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, seconds) end
    end
    for index = #timers, 1, -1 do
        if timers[index].deadline <= now then
            local callback = table.remove(timers, index).callback
            callback()
        end
    end
end
local function click(module) module.View.ToggleStartButton.scripts.OnClick() end
-- Dispatch input through its registrations, including the mouse-down capture
-- required before a button can receive the corresponding release/click.
local function mouseClick(frame, mouseButton)
    local function accepts(registration, phase)
        for _, registered in ipairs(registration) do
            if registered:lower() == (mouseButton .. phase):lower()
                or registered:lower() == ("Any" .. phase):lower() then return true end
        end
        return false
    end
    local mouseButtons = rawget(frame, "mouseButtons") or { "AnyDown", "AnyUp" }
    local clickButtons = rawget(frame, "clickButtons") or { "LeftButtonUp" }
    local receivesDown = accepts(mouseButtons, "Down")
    if receivesDown and frame.scripts.OnMouseDown then frame.scripts.OnMouseDown(frame, mouseButton) end
    if receivesDown and accepts(mouseButtons, "Up") and frame.scripts.OnMouseUp then
        frame.scripts.OnMouseUp(frame, mouseButton)
    end
    if receivesDown and accepts(clickButtons, "Up") then frame:Click(mouseButton) end
end
-- A passive child lets input reach its parent; an enabled child captures it even
-- when it has no handler for that gesture. Direct script calls miss this boundary.
local function mouseTarget(region, motion)
    while region do
        local enabled = motion and region:IsMouseMotionEnabled() or (not motion and region:IsMouseClickEnabled())
        if region:IsVisible() and enabled then return region end
        region = rawget(region, "parent")
    end
end
local function mouseHover(region, event)
    local target = mouseTarget(region, true)
    if target and target:GetScript(event) then target:GetScript(event)(target) end
    return target
end
local function mouseDrag(region, dx, dy)
    local target = mouseTarget(region, false)
    if not target then return false end
    local registered = false
    for _, button in ipairs(rawget(target, "dragButtons") or {}) do
        if button == "LeftButton" then registered = true end
    end
    if not registered or not target:GetScript("OnDragStart") then return false end
    if target:GetScript("OnMouseDown") then target:GetScript("OnMouseDown")(target, "LeftButton") end
    target:GetScript("OnDragStart")(target, "LeftButton")
    cursorX, cursorY = cursorX + dx, cursorY + dy
    tick(0)
    target:GetScript("OnDragStop")(target)
    return true
end

local fixture = {}
function UnitName() return fixture.characterName or "Tester", fixture.characterSurname end
function GetRealmName() return fixture.realm or "Forever" end
function UnitGUID() return fixture.characterID or "Player-1-Test" end
C_Map = { GetBestMapForUnit=function() return fixture.mapID or 1 end,
    GetMapInfo=function() return {name=fixture.mapName or "Elwynn Forest"} end }
UISpecialFrames = {}
function fixture.fresh(saved, settings, history, reload)
    frames, names, timers, now, playedRequested = {}, {}, {}, 0, false
    playedTotal, autoPlayedReply = fixture.played or (saved and saved.current and saved.current.playedAtSave) or 100000, fixture.reply ~= false
    xp, xpMax, level, honorBalance = 100, 1000, 10, 100
    watched = { name="Stormwind", factionID=72, currentStanding=0,
        reaction=4,currentReactionThreshold=0,nextReactionThreshold=3000 }
    goldFixture.reset()
    PerHourRevampSession, PerHourRevampSettings, PerHourRevampHistory = saved, settings, history
    loadAddon()
    event("ADDON_LOADED", "per-hour")
    event("PLAYER_ENTERING_WORLD", not reload, reload == true)
    return PerHour
end
fixture.equal, fixture.near, fixture.tick, fixture.event = equal, near, tick, event
function fixture.reload(saved, unsaved, options)
    frames, names, timers, now, playedRequested = {}, {}, {}, 0, false
    playedTotal=(saved and saved.current and saved.current.playedAtSave or 100000)+(unsaved or 0)
    autoPlayedReply=not options or options.autoReply ~= false
    PerHourRevampSession=PerHour.Copy(saved)
    loadAddon()
    event("ADDON_LOADED","per-hour")
    event("PLAYER_ENTERING_WORLD",false,true)
end
function fixture.playedTime() return playedTotal end
-- Core capture tests explicitly confirm the current identity; UI tests exercise the dialog.
function fixture.finish()
    local current=PerHour.Session.Current
    return current and PerHour.Session:Finish(current.id) or false
end
fixture.gold, fixture.frames, fixture.sent, fixture.copy = goldFixture, function() return frames end, sent, function(value)
    return PerHour.Copy(value)
end
function fixture.progress(values)
    if values.xp ~= nil then xp=values.xp end
    if values.maximum ~= nil then xpMax=values.maximum end
    if values.level ~= nil then level=values.level end
end
function fixture.faction(data) watched=data; event("UPDATE_FACTION") end
function fixture.honor(amount) changeHonor(amount) end
function fixture.checks() return checks end
return fixture
