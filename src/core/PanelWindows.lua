local Components = PerHour.Components
local windows = {}
local CASCADE_OFFSET, SCREEN_MARGIN = 32, 16

local function FitScale(frame)
    local scale = math.min(1,(UIParent:GetWidth()-2*SCREEN_MARGIN)/frame:GetWidth(),
        (UIParent:GetHeight()-60)/frame:GetHeight())
    if frame:GetScale() ~= scale then frame:SetScale(scale) end
end

local function PlaceFirstShow(frame)
    if frame.WindowPlaced then return end
    frame.WindowPlaced = true
    for index=#windows,1,-1 do
        local previous = windows[index]
        if previous ~= frame and previous:IsVisible() and previous:GetFrameStrata() == frame:GetFrameStrata() then
            local parentScale = UIParent:GetEffectiveScale()
            local previousScale = previous:GetEffectiveScale()/parentScale
            local scale = frame:GetEffectiveScale()/parentScale
            local width,height = frame:GetWidth()*scale,frame:GetHeight()*scale
            local left = previous:GetLeft()*previousScale+CASCADE_OFFSET
            local top = previous:GetTop()*previousScale-CASCADE_OFFSET
            left = math.max(SCREEN_MARGIN,math.min(left,UIParent:GetWidth()-width-SCREEN_MARGIN))
            top = math.max(height+SCREEN_MARGIN,math.min(top,UIParent:GetHeight()-SCREEN_MARGIN))
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left/scale,top/scale)
            break
        end
    end
end

-- Standard windows share initial placement and screen fitting. Their frame
-- strata and native toplevel behavior own stacking; no custom z-index counter.
function Components:SetupPanelWindow(frame)
    frame.WindowPlaced = false
    frame:SetClampedToScreen(true)
    frame:HookScript("OnShow",function(self)
        FitScale(self)
        PlaceFirstShow(self)
        for index=#windows,1,-1 do
            if windows[index] == self then table.remove(windows,index); break end
        end
        windows[#windows+1] = self
    end)
    frame:HookScript("OnSizeChanged",function(self)
        if self:IsVisible() then FitScale(self) end
    end)
    -- Build controls while hidden, then place only once the final size is known.
    frame:Hide()
end
