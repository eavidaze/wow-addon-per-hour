local Components,Theme = PerHour.Components,PerHour.Theme
-- Motion follows MUI CircularProgress (MIT); see src/licenses/MaterialUI.txt.
local Style = {
    Size=12,Period=1.4,Radius=4.5,Stroke=1.25,EdgeCoverage=0.8,
    Texture="SessionSpinnerAtlas.tga",Rows=8,Columns=16,Frames=84,FrameSize=64,
    ReferenceSize=44,ReferenceStroke=3.6,DashMin=1,DashMax=100,OffsetMiddle=-15,OffsetEnd=-126,
}
Components.SessionIndicatorStyle = Style

function Components:CreateSessionIndicator(parent)
    local frame = CreateFrame("Frame",nil,parent)
    frame:SetSize(Style.Size,Style.Size)
    frame:EnableMouse(false)
    frame.Spinner = frame:CreateTexture(nil,"ARTWORK")
    frame.Spinner:SetSize(Style.Size,Style.Size)
    frame.Spinner:SetPoint("CENTER",frame,"CENTER",0,0)
    frame.Spinner:SetTexture("Interface\\AddOns\\"..PerHour.AddonName.."\\src\\textures\\"..Style.Texture,
        "CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE","LINEAR")
    frame.Spinner:SetVertexColor(unpack(Theme.gold.subtleText))
    frame.Spinner:SetAlpha(0.9)
    frame.Spinner:SetSnapToPixelGrid(false)
    frame.Spinner:SetTexelSnappingBias(0)
    frame.PauseBars = {}
    for index=1,2 do
        local bar = frame:CreateTexture(nil,"ARTWORK")
        bar:SetSize(2,8)
        bar:SetPoint("CENTER",frame,"CENTER",index == 1 and -2 or 2,0)
        bar:SetColorTexture(unpack(Theme.gold.subtleText))
        bar:SetAlpha(0.9)
        frame.PauseBars[index] = bar
    end
    frame.Animation = frame.Spinner:CreateAnimationGroup()
    frame.Animation:SetLooping("REPEAT")
    local flipbook = frame.Animation:CreateAnimation("FlipBook")
    flipbook:SetOrder(1)
    flipbook:SetDuration(Style.Period)
    flipbook:SetFlipBookRows(Style.Rows)
    flipbook:SetFlipBookColumns(Style.Columns)
    flipbook:SetFlipBookFrames(Style.Frames)
    flipbook:SetFlipBookFrameWidth(0)
    flipbook:SetFlipBookFrameHeight(0)

    function frame:RefreshAnimation()
        local active = self.Running and self:IsVisible()
        if active and not self.Animation:IsPlaying() then self.Animation:Play()
        elseif not active and self.Animation:IsPlaying() then self.Animation:Stop() end
    end
    function frame:SetRunning(running)
        self.Running = running == true
        self.Spinner:SetShown(self.Running)
        for _,bar in ipairs(self.PauseBars) do bar:SetShown(not self.Running) end
        self:RefreshAnimation()
    end
    frame:SetScript("OnShow",function(self) self:RefreshAnimation() end)
    frame:SetScript("OnHide",function(self) self.Animation:Stop() end)
    frame:SetRunning(false)
    return frame
end
