return function(t,fresh)
    fresh()
    local equal,near=t.equal,t.near
    local gauge=PerHour.Components:CreateSpeedometerDisplay(UIParent)
    gauge:SetRate(25000,50000)
    gauge:SetDisplayWidth(160)
    local radius,artworkWidth=gauge.Radius,gauge.Dial:GetWidth()
    gauge:SetDisplayWidth(100)
    equal(gauge:GetScale(),1,"resizing gauge geometry does not scale its frame")
    for _,label in ipairs(gauge.Labels) do
        equal(select(2,label:GetFont()),10,"gauge labels retain a readable fixed font")
    end
    equal(gauge.Radius < radius and gauge.Dial:GetWidth() < artworkWidth,true,"smaller gauge width recalculates arc geometry")
    for _,width in ipairs({100,160}) do
        gauge:SetDisplayWidth(width)
        for _,label in ipairs(gauge.Labels) do
            local anchor,_,_,x,y=label:GetPoint()
            local w,h=label:GetStringWidth(),label:GetHeight()
            local left=anchor:find("LEFT") and x or anchor:find("RIGHT") and x-w or x-w/2
            local bottom=anchor:find("BOTTOM") and y or y-h/2
            local right,top=left+w,bottom+h
            local closestX=math.max(left,math.min(0,right))
            local closestY=math.max(bottom,math.min(gauge.CenterY,top))
            local separation=math.sqrt(closestX^2+(closestY-gauge.CenterY)^2)-gauge.Radius
            equal(separation >= PerHour.Components.SpeedometerGeometry.LabelGap-0.000001
                and left >= -width/2 and right <= width/2
                and bottom >= -gauge:GetHeight()/2 and top <= gauge:GetHeight()/2,
                true,"label bounds remain outside the arc and inside the resized gauge")
        end
    end
    near(gauge.Needle.rotation,math.pi/2,"resizing preserves the current needle angle")
    equal(gauge.Dial.filterMode,"LINEAR","dial uses linear texture sampling")
    equal(gauge.Needle.filterMode,"LINEAR","needle uses linear texture sampling")
    gauge:SetRate(0,50000)
    near(gauge.Needle.rotation,math.pi,"zero rate points to the left end")
    gauge:SetRate(60000,50000)
    near(gauge.Needle.rotation,0,"overload keeps the needle at the right end")
    equal(gauge.OverloadAnimation:IsPlaying(),true,"overload uses a native animation group")
    gauge:Hide()
    equal(gauge.OverloadAnimation:IsPlaying(),false,"hiding stops overload animation")
    equal(gauge:GetScript("OnUpdate"),nil,"gauge geometry has no per-frame Lua work")
end
