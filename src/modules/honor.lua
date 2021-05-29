-- import
local Utils = Utils

-- statics
local STATIC_UPDATE_INTERVAL = 1.0
local STATIC_RED = 0.999
local STATIC_GREEN = 0.912
local STATIC_BLUE = 0
local STATIC_ALPHA = 1

-- class
Honor = {}

-- private variables
local HAS_STARTED = false
local HAS_PAUSED = false

local STARTED_AT = 0
local PAUSED_AT = 0
local PAUSED_DURATION = 0

local TOTAL_OF_HONOR_RECEIVED = 0
local TIME_SINCE_LAST_UPDATE = 0

-- public functions
function Honor:Toggle()
	if (HonorPerHourMainFrame:IsShown()) then
		HonorPerHourMainFrame:Hide()
        DEFAULT_CHAT_FRAME:AddMessage("Honor Per Hour™ Hide.")
	else
		HonorPerHourMainFrame:Show()
        DEFAULT_CHAT_FRAME:AddMessage("Honor Per Hour™ Show.")
	end
end

function Honor:SetValuesAlpha(alphaValue)
    HonorPerHourMainFrameValueHonorTimer:SetTextColor(STATIC_RED,STATIC_GREEN,STATIC_BLUE,alphaValue)
    HonorPerHourMainFrameValueHonorPerMinute:SetTextColor(1,1,1,alphaValue)
    HonorPerHourMainFrameValueHonorPerHour:SetTextColor(1,1,1,alphaValue)
    HonorPerHourMainFrameValueHonorTotalHonor:SetTextColor(STATIC_RED,STATIC_GREEN,STATIC_BLUE,alphaValue)
end

function Honor:SetValues(timer,perMinute,perHour,totalHonor)
    HonorPerHourMainFrameValueHonorTimer:SetText(timer)
    HonorPerHourMainFrameValueHonorPerMinute:SetText(perMinute)
    HonorPerHourMainFrameValueHonorPerHour:SetText(perHour)
    HonorPerHourMainFrameValueHonorTotalHonor:SetText(totalHonor)
end

function Honor:SetAllValues(sharedValue)
    Honor:SetValues(sharedValue,sharedValue,sharedValue,sharedValue)
end

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
            DEFAULT_CHAT_FRAME:AddMessage("Honor Per Hour™ started.")
        else -- else I just have to calc the time paused
            PAUSED_DURATION = PAUSED_DURATION + GetTime() - PAUSED_AT
            DEFAULT_CHAT_FRAME:AddMessage("Honor Per Hour™ was unpaused.")
        end

        HAS_STARTED = true
        HAS_PAUSED = false
        
        Honor:SetValuesAlpha(1)
    else
        DEFAULT_CHAT_FRAME:AddMessage("Honor Per Hour™ has already started.")
    end
end

function PerHourButtonPause_OnClick()

    if not HAS_PAUSED then
        HAS_PAUSED = true
        PAUSED_AT = GetTime()
        -- set color
        Honor:SetValuesAlpha(0.5)
        DEFAULT_CHAT_FRAME:AddMessage("Honor Per Hour™ has paused.")
    else
        DEFAULT_CHAT_FRAME:AddMessage("Honor Per Hour™ has already been paused.")
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

    Honor:SetAllValues("None")
    
    if not HAS_STARTED then
        Honor:SetValuesAlpha(0.5)
    end

    DEFAULT_CHAT_FRAME:AddMessage("Honor Per Hour™ is clear.")
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
            
            displayedTime = Utils:DisplayTimer(timed)
            honorPerMinute = TOTAL_OF_HONOR_RECEIVED / (timed / 60)
            honorPerMinuteRounded = Utils:RoundValue(honorPerMinute, 2)
            honorPerHourRounded = Utils:RoundValue(honorPerMinute * 60, 2)
            
            Honor:SetValues(displayedTime,honorPerMinuteRounded,honorPerHourRounded,TOTAL_OF_HONOR_RECEIVED)

            TIME_SINCE_LAST_UPDATE = 0
        end
    end
end
