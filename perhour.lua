perhour_history = {}

perhour_time_since_last_update = 0
perhour_update_interval = 1.0

perhour_start_time = 0
perhour_honor_per_min = 0

perhour_is_started = false
perhour_has_paused = false

perhour_total_played_time = 0
perhour_total_honor_received = 0

function perhour_onLoad()

    perhour_mainframe:SetScript("OnUpdate", perhour_onUpdate)

    perhour_mainframe:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")
    perhour_mainframe:RegisterEvent("TIME_PLAYED_MSG")

    perhour_button_reset_onClick()

end

function perhour_onMouseDown()
    perhour_mainframe:StartMoving()
end

function perhour_onMouseUp()
    perhour_mainframe:StopMovingOrSizing()
end

function perhour_button_start_onClick()

    -- if not started
    if not perhour_is_started then

        perhour_start_time = GetTime()

        perhour_is_started = true

        perhour_mainframe_value_per_minute:SetTextColor(1,1,1,1)
        perhour_mainframe_value_per_hour:SetTextColor(1,1,1,1)
        
        DEFAULT_CHAT_FRAME:AddMessage("PerHour started.")
    end
end

function perhour_button_stop_onClick()

    if perhour_is_started then

        perhour_total_played_time = perhour_total_played_time + (GetTime() - perhour_start_time)
        local playedTimeHours = floor(perhour_total_played_time / 3600)
        local playedTimeMinutes = floor((perhour_total_played_time - (playedTimeHours * 3600)) / 60)
        local playedTimeSeconds = perhour_total_played_time - (playedTimeHours * 3600) -  (playedTimeMinutes * 60)

        DEFAULT_CHAT_FRAME:AddMessage("You played: " .. playedTimeHours .. " h "
                                                     .. playedTimeMinutes .. " min "
                                                     .. playedTimeSeconds .. " sec")
        DEFAULT_CHAT_FRAME:AddMessage("You gained: " .. perhour_total_honor_received .. " Honor")

        perhour_is_started = false

        perhour_mainframe_value_per_minute:SetTextColor(1,1,1,1)
        perhour_mainframe_value_per_hour:SetTextColor(1,1,1,1)

        perhour_has_paused = true
        DEFAULT_CHAT_FRAME:AddMessage("XP-Monitor stoped")

    end

end

function perhour_button_reset_onClick()

    perhour_start_time = 0

    perhour_is_started = false
    perhour_has_paused = false

    perhour_total_played_time = 0
    perhour_total_honor_received = 0

    DEFAULT_CHAT_FRAME:AddMessage("Data reseted!")

    -- experience per minute
    perhour_mainframe_value_per_minute:SetText("None")
    perhour_mainframe_value_per_minute:SetTextColor(1,1,1,0.3)

    -- estimated minutes to next level up
    perhour_mainframe_value_per_hour:SetText("None")
    perhour_mainframe_value_per_hour:SetTextColor(1,1,1,0.3)

end

function perhour_onEvent(self, event, ...)

    if event == "TIME_PLAYED_MSG" then
        -- nothing
    elseif event == "CHAT_MSG_COMBAT_HONOR_GAIN" then

        if (perhour_is_started) then

            local arg = {...}
            s, e, honor_points = string.find(arg[1], "(%d+)")
    
            perhour_total_honor_received = perhour_total_honor_received + tonumber(honor_points, 10)
            
        end
    
    end
end

function perhour_onUpdate(self, elapsed)

    if perhour_is_started then

        perhour_time_since_last_update = perhour_time_since_last_update + elapsed

        if (perhour_time_since_last_update > perhour_update_interval) then

            if not (perhour_has_paused) then
                perhour_honor_per_min = perhour_total_honor_received / ((GetTime() - perhour_start_time) / 60)
            else
                perhour_honor_per_min = perhour_total_honor_received / (((GetTime() - perhour_start_time) + perhour_total_played_time) / 60)
            end
    
            honor_per_min = round_value(perhour_honor_per_min, 2)
            honor_per_hour = round_value(perhour_honor_per_min * 60, 2)
            
            -- update values
            perhour_mainframe_value_per_minute:SetText(honor_per_min)
            perhour_mainframe_value_per_hour:SetText(honor_per_hour)
            perhour_mainframe_value_total:SetText(perhour_total_honor_received)
    
            perhour_time_since_last_update = 0

        end

    end

end

function round_value(num, numDecimals)
    local mult = 10^(numDecimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

function isINF(value)
    return value == math.huge or value == -math.huge
end