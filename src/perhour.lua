-- const
perhour_history = {}

perhour_has_started = false
perhour_has_paused = false

perhour_update_interval = 1.0
perhour_time_since_last_update = 0

perhour_started_in = 0
perhour_paused_in = 0

perhour_time_paused = 0

perhour_honor_per_min = 0

perhour_total_honor_received = 0

default_color_r = 0.999
default_color_g = 0.912
default_color_b = 0
default_color_alpha = 1

function perhour_onLoad()

    perhour_mainframe:SetScript("OnUpdate", perhour_onUpdate)

    perhour_mainframe:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")
    perhour_mainframe:RegisterEvent("TIME_PLAYED_MSG")

    perhour_button_clear_onClick()

end

function perhour_onMouseDown()
    perhour_mainframe:StartMoving()
end

function perhour_onMouseUp()
    perhour_mainframe:StopMovingOrSizing()
end

function perhour_button_start_onClick()

    -- if not started or was paused
    if not perhour_has_started or perhour_has_paused then

        -- if not was paused, have to set the new start time
        if not perhour_has_started then
            perhour_started_in = GetTime()
            DEFAULT_CHAT_FRAME:AddMessage("Per Hour™ started.")
        else -- else I just have to calc the time paused
            perhour_time_paused = perhour_time_paused + GetTime() - perhour_paused_in
            DEFAULT_CHAT_FRAME:AddMessage("Per Hour™ was unpaused.")
        end

        perhour_has_started = true
        perhour_has_paused = false

        perhour_mainframe_value_timer:SetTextColor(default_color_r,default_color_g,default_color_b,1)
        perhour_mainframe_value_per_minute:SetTextColor(1,1,1,1)
        perhour_mainframe_value_per_hour:SetTextColor(1,1,1,1)
        perhour_mainframe_value_total_honor:SetTextColor(default_color_r,default_color_g,default_color_b,1)
        
    else
        DEFAULT_CHAT_FRAME:AddMessage("Per Hour™ has already started.")
    end
end

function perhour_button_pause_onClick()

    if not perhour_has_paused then

        perhour_has_paused = true
        perhour_paused_in = GetTime()

        -- set color
        perhour_mainframe_value_timer:SetTextColor(default_color_r,default_color_g,default_color_b,0.7)
        perhour_mainframe_value_per_minute:SetTextColor(1,1,1,0.7)
        perhour_mainframe_value_per_hour:SetTextColor(1,1,1,0.7)
        perhour_mainframe_value_total_honor:SetTextColor(default_color_r,default_color_g,default_color_b,0.7)
        
        DEFAULT_CHAT_FRAME:AddMessage("Per Hour™ has paused.")

    else
        DEFAULT_CHAT_FRAME:AddMessage("Per Hour™ has already been paused.")
    end

end

function perhour_button_clear_onClick()

    perhour_started_in = GetTime()
    perhour_paused_in = 0
    perhour_time_paused = 0
    perhour_total_honor_received = 0

    if perhour_has_started and perhour_has_paused then
        perhour_has_started = false
    end

    perhour_mainframe_value_timer:SetText("None")
    perhour_mainframe_value_per_minute:SetText("None")
    perhour_mainframe_value_per_hour:SetText("None")
    perhour_mainframe_value_total_honor:SetText("None")
    
    if not perhour_has_started then
        
        perhour_mainframe_value_timer:SetTextColor(1,1,1,0.3)
        perhour_mainframe_value_per_minute:SetTextColor(1,1,1,0.3)
        perhour_mainframe_value_per_hour:SetTextColor(1,1,1,0.3)
        perhour_mainframe_value_total_honor:SetTextColor(1,1,1,0.3)
        
    end

    DEFAULT_CHAT_FRAME:AddMessage("Per Hour™ is clear.")
end

function perhour_onEvent(self, event, ...)

    if (perhour_has_started) then
        
        if event == "CHAT_MSG_COMBAT_HONOR_GAIN" then

            local arg = {...}

            -- have to be better tested
            s, e, honor_points = string.find(arg[1], "(%d+)")
            
            perhour_total_honor_received = perhour_total_honor_received + tonumber(honor_points, 10)
        
        elseif event == "TIME_PLAYED_MSG" then
            -- nothing
        end
    end
end

function perhour_onUpdate(self, elapsed)
    
    if perhour_has_started and not perhour_has_paused then

        perhour_time_since_last_update = perhour_time_since_last_update + elapsed

        if (perhour_time_since_last_update > perhour_update_interval) then

            timed = GetTime() - perhour_started_in - perhour_time_paused;

            perhour_honor_per_min = perhour_total_honor_received / (timed / 60)
    
            honor_per_min = round_value(perhour_honor_per_min, 2)
            honor_per_hour = round_value(perhour_honor_per_min * 60, 2)
            
            -- update values

            -- timer
            perhour_mainframe_value_timer:SetText(display_time(timed))

            -- honor per minute
            perhour_mainframe_value_per_minute:SetText(honor_per_min)

            -- honor per hour
            perhour_mainframe_value_per_hour:SetText(honor_per_hour)

            -- total honor
            perhour_mainframe_value_total_honor:SetText(perhour_total_honor_received)
    
            perhour_time_since_last_update = 0

        end

    end

end

--------
-- utils
--------

function display_time(time)

    local hours = floor(mod(time, 86400)/3600)
    local minutes = floor(mod(time,3600)/60)
    local seconds = floor(mod(time,60))

    local time_formated = ""

    -- if the time has hours
    if hours >= 1 then
        time_formated = format("%02dh ",hours)
    end
    
    -- if the time has minutes
    if minutes >= 1 or hours >= 1 then
        time_formated = time_formated .. format("%02dm ",minutes)
    end
    
    -- doest metter if have hours or minutes, I just concat seconds
    time_formated = time_formated .. format("%02ds",seconds)

    return time_formated
    
end

function round_value(num, numDecimals)
    local mult = 10^(numDecimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

function isINF(value)
    return value == math.huge or value == -math.huge
end