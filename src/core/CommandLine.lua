local TRACKERS = {
    { "xp", "Experience" },
    { "gold", "Gold" },
    { "honor", "Honor" },
    { "rep", "Reputation" },
}

local function DismissMenus()
    PerHour.ToggleMenu:Close()
    PerHour.MinimapButton.Tooltip:Hide()
    GameTooltip:Hide()
end

SLASH_PERHOUR1 = "/perhour"
SlashCmdList["PERHOUR"] = function(message)
    local command = (message or ""):match("^%s*(.-)%s*$"):lower()
    if command == "" then
        DismissMenus()
        PerHour.SettingsPanel:Show()
    elseif command == "help" then
        Utils:AddonMessage("/perhour: open Settings.")
        for _, tracker in ipairs(TRACKERS) do
            Utils:AddonMessage("/perhour " .. tracker[1] .. ": show the " .. tracker[2] .. " tracker.")
        end
        Utils:AddonMessage("/perhour help: show available commands.")
    else
        for _, tracker in ipairs(TRACKERS) do
            if command == tracker[1] then
                DismissMenus()
                local module = PerHour.Modules[tracker[2]]
                module.Settings:Set("isShown", true)
                module.View.Frame:Show()
                module.View.Frame:Raise()
                return
            end
        end
        Utils:AddonMessage("Unknown command. Use /perhour help for available commands.")
    end
end
