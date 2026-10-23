local lastStats = {
    kills = nil,
    deaths = nil,
    kd = nil
}

local requestCooldown = false

local function requestStats(forceRefresh)
    if requestCooldown and not forceRefresh then
        return
    end

    requestCooldown = not forceRefresh
    TriggerServerEvent("hud:getPlayerStats", forceRefresh == true)

    if not forceRefresh then
        Citizen.SetTimeout(Config.HudRequestCooldown or 1000, function()
            requestCooldown = false
        end)
    end
end

local function requestPlayerCount()
    TriggerServerEvent("hud:getPlayerCount")
end

function HudClient.RequestHudData(forceRefresh)
    if not HudClient.State.hudVisible then
        return
    end

    requestStats(forceRefresh == true)
    requestPlayerCount()
end

CreateThread(function()
    Wait(1500)
    HudClient.RequestHudData(true)

    while true do
        Wait(Config.HudFallbackRefreshInterval or Config.HudRefreshInterval or 30000)
        HudClient.RequestHudData()
    end
end)

RegisterNetEvent("hud:updateStats")
AddEventHandler("hud:updateStats", function(kills, deaths, kd)
    if kills == nil or deaths == nil then
        requestStats(true)
        return
    end

    local normalizedKills = tonumber(kills) or 0
    local normalizedDeaths = tonumber(deaths) or 0
    local normalizedKd = tonumber(kd) or 0.0

    if lastStats.kills == normalizedKills and lastStats.deaths == normalizedDeaths and lastStats.kd == normalizedKd then
        return
    end

    lastStats.kills = normalizedKills
    lastStats.deaths = normalizedDeaths
    lastStats.kd = normalizedKd

    HudClient.SendUiMessage({
        action = "updateHUD",
        kills = normalizedKills,
        deaths = normalizedDeaths,
        kd = normalizedKd
    })
end)

RegisterNetEvent("hud:updatePlayerCount")
AddEventHandler("hud:updatePlayerCount", function(count, myId)
    HudClient.SendUiMessage({
        action = "updatePlayerCount",
        count = count,
        id = myId
    })
end)

RegisterNetEvent("funcker_hud:setVisible")
AddEventHandler("funcker_hud:setVisible", function(state)
    HudClient.SetHudVisible(state)

    if HudClient.State.hudVisible then
        HudClient.RequestHudData(true)
    end
end)

RegisterNetEvent("vorp:SelectedCharacter")
AddEventHandler("vorp:SelectedCharacter", function()
    HudClient.RequestHudData(true)
end)
