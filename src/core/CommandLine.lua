SLASH_PERHOUR1 = "/perhour"
SlashCmdList["PERHOUR"] = function(message)
    local command = (message or ""):match("^%s*(.-)%s*$"):lower()
    GameTooltip:Hide()
    if command == "" then PerHour.SettingsPanel:Show()
    elseif command == "xp" or command == "gold" or command == "honor" or command == "rep" then
        PerHour.Dashboard:Show()
    elseif command == "help" then
        Utils:AddonMessage("/perhour: open Settings. Left-click minimap: show/hide Per Hour; right-click: Settings.")
        Utils:AddonMessage("/perhour xp|gold|honor|rep: show the shared panel without changing the session.")
        Utils:AddonMessage("Use Start / Pause / Resume and Sessions > Finish and Reset. Hiding keeps capture running.")
    else Utils:AddonMessage("Unknown command. Use /perhour help for available commands.") end
end
