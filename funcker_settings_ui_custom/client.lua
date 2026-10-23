local hudVisible = true
local notifyEnabled = true
local killfeedEnabled = true
local topPlayersVisible = true
local commandsVisible = true

local settingsLoaded = false

local function sendSettingsToUI(messageType)
    SendNUIMessage({
        type = messageType,
        hud = hudVisible,
        notify = notifyEnabled,
        killfeed = killfeedEnabled,
        topplayers = topPlayersVisible,
        lobbycommands = commandsVisible
    })
end

RegisterNetEvent("funcker:applySettings")
AddEventHandler("funcker:applySettings", function(data)
    local normalized = {}

    for key, value in pairs(data) do
        normalized[string.lower(key)] = value
    end

    hudVisible = tonumber(normalized["hud"] or 1) == 1
    notifyEnabled = tonumber(normalized["notify"] or 1) == 1
    killfeedEnabled = tonumber(normalized["killfeed"] or 1) == 1
    topPlayersVisible = tonumber(normalized["topplayers"] or 1) == 1
    commandsVisible = tonumber(normalized["commands"] or 1) == 1
    settingsLoaded = true

    sendSettingsToUI("statusUpdate")

    if not commandsVisible then
        TriggerEvent("funcker_lobbycommands:hide")
    end
end)

Citizen.CreateThread(function()
    while not NetworkIsSessionStarted() do
        Citizen.Wait(100)
    end

    Citizen.Wait(500)
    TriggerServerEvent("funcker:loadSettings")
end)

local function saveToServer()
    if not settingsLoaded then
        return
    end

    TriggerServerEvent("funcker:saveSettings", {
        hud = hudVisible,
        notify = notifyEnabled,
        killfeed = killfeedEnabled,
        topplayers = topPlayersVisible,
        commands = commandsVisible
    })
end

local function openSettingsUI()
    if not settingsLoaded then
        TriggerEvent("bln_notify:send", {
            title = "Loading Settings",
            description = "Please wait, settings are still loading from server.",
            icon = "wait",
            placement = "middle-right",
            duration = 3000
        })
        return
    end

    SetNuiFocus(true, true)
    sendSettingsToUI("open")
end

RegisterCommand("settings", openSettingsUI, false)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, 0x4AF4D473) then
            openSettingsUI()
        end
    end
end)

RegisterNUICallback("toggleOption", function(data, cb)
    local option = data.option

    if option == "hud" then
        hudVisible = not hudVisible
        TriggerEvent("funcker_hud:setVisible", hudVisible)
        TriggerEvent("funcker_rank:setVisible", hudVisible)

        TriggerEvent("bln_notify:send", {
            title = hudVisible and "HUD Enabled" or "HUD Disabled",
            description = hudVisible and "The HUD interface has been enabled." or "The HUD interface has been disabled.",
            icon = hudVisible and "hudon" or "hudoff",
            placement = "middle-right",
            duration = 4000
        })

    elseif option == "killfeed" then
        killfeedEnabled = not killfeedEnabled
        TriggerEvent(killfeedEnabled and "funcker_killfeed:enable" or "funcker_killfeed:disable")

        TriggerEvent("bln_notify:send", {
            title = killfeedEnabled and "Killfeed Enabled" or "Killfeed Disabled",
            description = killfeedEnabled and "Killfeed is now visible." or "Killfeed is now hidden.",
            icon = killfeedEnabled and "killfeedON" or "killfeedOFF",
            placement = "middle-right",
            duration = 4000
        })

    elseif option == "notify" then
        notifyEnabled = not notifyEnabled

        if not notifyEnabled then
            TriggerEvent("bln_notify:send", {
                title = "Notifications Disabled",
                description = "Notifications are now off.",
                icon = "notifyoff",
                placement = "middle-right",
                duration = 4000
            })

            Citizen.SetTimeout(100, function()
                TriggerEvent("bln_notify:setEnabled", false)
            end)
        else
            TriggerEvent("bln_notify:setEnabled", true)
            TriggerEvent("bln_notify:send", {
                title = "Notifications Enabled",
                description = "Notifications are back on.",
                icon = "notifyon",
                placement = "middle-right",
                duration = 4000
            })
        end

    elseif option == "topplayers" then
        topPlayersVisible = not topPlayersVisible
        TriggerEvent(topPlayersVisible and "funcker_topplayers:enable" or "funcker_topplayers:disable")

        TriggerEvent("bln_notify:send", {
            title = topPlayersVisible and "Lobby Top 3 Enabled" or "Lobby Top 3 Hidden",
            description = topPlayersVisible and "The lobby top 3 players panel is now visible." or "The lobby top 3 players panel is now hidden.",
            icon = topPlayersVisible and "TopPlayersOn" or "TopPlayersOFF",
            placement = "middle-right",
            duration = 4000
        })

    elseif option == "lobbycommands" then
        commandsVisible = not commandsVisible
        TriggerEvent("funcker_commands:setVisible", commandsVisible)
        TriggerEvent(commandsVisible and "funcker_lobbycommands:show" or "funcker_lobbycommands:hide")

        TriggerEvent("bln_notify:send", {
            title = commandsVisible and "Commands Shown" or "Commands Hidden",
            description = commandsVisible and "Lobby commands are visible." or "Lobby commands are hidden.",
            icon = commandsVisible and "helpon" or "helpoff",
            placement = "middle-right",
            duration = 4000
        })
    end

    saveToServer()
    sendSettingsToUI("statusUpdate")

    cb("ok")
end)

RegisterNUICallback("disableAll", function(_, cb)
    local notifyWasEnabled = notifyEnabled

    hudVisible = false
    notifyEnabled = false
    killfeedEnabled = false
    topPlayersVisible = false
    commandsVisible = false

    TriggerEvent("funcker_hud:setVisible", false)
    TriggerEvent("funcker_rank:setVisible", false)
    TriggerEvent("funcker_killfeed:disable")
    TriggerEvent("funcker_topplayers:disable")
    TriggerEvent("funcker_commands:setVisible", false)
    TriggerEvent("funcker_lobbycommands:hide")

    if notifyWasEnabled then
        TriggerEvent("bln_notify:send", {
            title = "All Elements Disabled",
            description = "All interface elements have been turned off.",
            icon = "notifyoff",
            placement = "middle-right",
            duration = 4000
        })

        Citizen.SetTimeout(100, function()
            TriggerEvent("bln_notify:setEnabled", false)
        end)
    else
        TriggerEvent("bln_notify:setEnabled", false)
    end

    saveToServer()
    sendSettingsToUI("statusUpdate")

    cb("ok")
end)

RegisterNUICallback("enableAll", function(_, cb)
    hudVisible = true
    notifyEnabled = true
    killfeedEnabled = true
    topPlayersVisible = true
    commandsVisible = true

    TriggerEvent("funcker_hud:setVisible", true)
    TriggerEvent("funcker_rank:setVisible", true)
    TriggerEvent("funcker_killfeed:enable")
    TriggerEvent("funcker_topplayers:enable")
    TriggerEvent("funcker_commands:setVisible", true)
    TriggerEvent("funcker_lobbycommands:show")
    TriggerEvent("bln_notify:setEnabled", true)
    TriggerEvent("bln_notify:send", {
        title = "All Elements Enabled",
        description = "All interface elements have been turned on.",
        icon = "notifyon",
        placement = "middle-right",
        duration = 4000
    })

    saveToServer()
    sendSettingsToUI("statusUpdate")

    cb("ok")
end)

RegisterNUICallback("close", function(_, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)
