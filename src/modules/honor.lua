-- import
local Utils = Utils

-- class


-- statics
local STATIC_UPDATE_INTERVAL = 1.0
local STATIC_RED = 0.999
local STATIC_GREEN = 0.912
local STATIC_BLUE = 0
local STATIC_ALPHA = 1

-- variables
local HAS_STARTED = false
local HAS_PAUSED = false

local STARTED_AT = 0
local PAUSED_AT = 0
local PAUSED_DURATION = 0

local TOTAL_OF_HONOR_RECEIVED = 0
local TIME_SINCE_LAST_UPDATE = 0



-- XML events
function HonorPerHour_OnLoad()

    HonorPerHourMainFrame:SetScript("OnUpdate", HonorPerHour_OnUpdate)

    HonorPerHourMainFrame:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")
    HonorPerHourMainFrame:RegisterEvent("TIME_PLAYED_MSG")

    PerHourButtonClear_OnClick()

end

function HonorPerHour_OnMouseDown()
    HonorPerHourMainFrame:StartMoving()
end

function HonorPerHour_OnMouseUp()
    HonorPerHourMainFrame:StopMovingOrSizing()
end

function PerHourButtonStart_OnClick()

    -- if not started or was paused
    if not HAS_STARTED or HAS_PAUSED then

        -- if not was paused, have to set the new start time
        if not HAS_STARTED then
            STARTED_AT = GetTime()
            DEFAULT_CHAT_FRAME:AddMessage("Per Hour™ started.")
        else -- else I just have to calc the time paused
            PAUSED_DURATION = PAUSED_DURATION + GetTime() - PAUSED_AT
            DEFAULT_CHAT_FRAME:AddMessage("Per Hour™ was unpaused.")
        end

        HAS_STARTED = true
        HAS_PAUSED = false

        HonorPerHourMainFrameValueHonorTimer:SetTextColor(STATIC_RED,STATIC_GREEN,STATIC_BLUE,1)
        HonorPerHourMainFrameValueHonorPerMinute:SetTextColor(1,1,1,1)
        HonorPerHourMainFrameValueHonorPerHour:SetTextColor(1,1,1,1)
        HonorPerHourMainFrameValueHonorTotalHonor:SetTextColor(STATIC_RED,STATIC_GREEN,STATIC_BLUE,1)
        
    else
        DEFAULT_CHAT_FRAME:AddMessage("Per Hour™ has already started.")
    end
end

function PerHourButtonPause_OnClick()

    if not HAS_PAUSED then

        HAS_PAUSED = true
        PAUSED_AT = GetTime()

        -- set color
        HonorPerHourMainFrameValueHonorTimer:SetTextColor(STATIC_RED,STATIC_GREEN,STATIC_BLUE,0.7)
        HonorPerHourMainFrameValueHonorPerMinute:SetTextColor(1,1,1,0.7)
        HonorPerHourMainFrameValueHonorPerHour:SetTextColor(1,1,1,0.7)
        HonorPerHourMainFrameValueHonorTotalHonor:SetTextColor(STATIC_RED,STATIC_GREEN,STATIC_BLUE,0.7)
        
        DEFAULT_CHAT_FRAME:AddMessage("Per Hour™ has paused.")

    else
        DEFAULT_CHAT_FRAME:AddMessage("Per Hour™ has already been paused.")
    end

end

function PerHourButtonClear_OnClick()

    STARTED_AT = GetTime()
    PAUSED_AT = 0
    PAUSED_DURATION = 0
    TOTAL_OF_HONOR_RECEIVED = 0

    if HAS_STARTED and HAS_PAUSED then
        HAS_STARTED = false
    end

    HonorPerHourMainFrameValueHonorTimer:SetText("None")
    HonorPerHourMainFrameValueHonorPerMinute:SetText("None")
    HonorPerHourMainFrameValueHonorPerHour:SetText("None")
    HonorPerHourMainFrameValueHonorTotalHonor:SetText("None")
    
    if not HAS_STARTED then
        
        HonorPerHourMainFrameValueHonorTimer:SetTextColor(1,1,1,0.3)
        HonorPerHourMainFrameValueHonorPerMinute:SetTextColor(1,1,1,0.3)
        HonorPerHourMainFrameValueHonorPerHour:SetTextColor(1,1,1,0.3)
        HonorPerHourMainFrameValueHonorTotalHonor:SetTextColor(1,1,1,0.3)
        
    end

    DEFAULT_CHAT_FRAME:AddMessage("Per Hour™ is clear.")
end

function HonorPerHour_OnEvent(self, event, ...)

    if (HAS_STARTED) then
        
        if event == "CHAT_MSG_COMBAT_HONOR_GAIN" then

            local arg = {...}

            -- have to be better tested
            s, e, honor_points = string.find(arg[1], "(%d+)")
            
            TOTAL_OF_HONOR_RECEIVED = TOTAL_OF_HONOR_RECEIVED + tonumber(honor_points, 10)
        
        elseif event == "TIME_PLAYED_MSG" then
            -- nothing
        end
    end
end

function HonorPerHour_OnUpdate(self, elapsed)
    
    if HAS_STARTED and not HAS_PAUSED then

        TIME_SINCE_LAST_UPDATE = TIME_SINCE_LAST_UPDATE + elapsed

        if (TIME_SINCE_LAST_UPDATE > STATIC_UPDATE_INTERVAL) then

            timed = GetTime() - STARTED_AT - PAUSED_DURATION;

            honorPerMinute = TOTAL_OF_HONOR_RECEIVED / (timed / 60)
            
            honorPerMinuteRounded = Utils:RoundValue(honorPerMinute, 2)
            honorPerHourRounded = Utils:RoundValue(honorPerMinute * 60, 2)
            
            -- update values
            HonorPerHourMainFrameValueHonorTimer:SetText(Utils:DisplayTimer(timed))
            HonorPerHourMainFrameValueHonorPerMinute:SetText(honorPerMinuteRounded)
            HonorPerHourMainFrameValueHonorPerHour:SetText(honorPerHourRounded)
            HonorPerHourMainFrameValueHonorTotalHonor:SetText(TOTAL_OF_HONOR_RECEIVED)
    
            TIME_SINCE_LAST_UPDATE = 0

        end

    end

end
