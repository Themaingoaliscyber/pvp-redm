local currentLobbyId = nil

-- 🎬 JOIN / LEAVE / SWITCH banners din server
RegisterNetEvent("pvp:showJoinMessage")
AddEventHandler("pvp:showJoinMessage", function(name)
    SendNUIMessage({
        action = "showJoinBanner",
        name = name,
        messageType = "join"
    })
end)

RegisterNetEvent("pvp:showLeaveMessage")
AddEventHandler("pvp:showLeaveMessage", function(name)
    SendNUIMessage({
        action = "showJoinBanner",
        name = name,
        messageType = "leave"
    })
end)

RegisterNetEvent("pvp:showSwitchMessage")
AddEventHandler("pvp:showSwitchMessage", function(name, newLobby)
    SendNUIMessage({
        action = "showJoinBanner",
        name = name,
        messageType = "switch",
        lobby = tostring(newLobby or "?")
    })
end)

-- 🧠 Detectăm când playerul schimbă lobby
RegisterNetEvent("pvp:updateLobby")
AddEventHandler("pvp:updateLobby", function(newLobbyId)
    local switching = currentLobbyId and newLobbyId and currentLobbyId ~= newLobbyId
    local leaving = currentLobbyId and not newLobbyId
    local joining = not currentLobbyId and newLobbyId

    if switching then
        TriggerServerEvent("pvp:onLobbyLeave", currentLobbyId)
        currentLobbyId = newLobbyId
        TriggerServerEvent("pvp:onLobbyJoin")
        return
    end

    if leaving then
        TriggerServerEvent("pvp:onLobbyLeave", currentLobbyId)
        currentLobbyId = nil
        return
    end

    if joining then
        currentLobbyId = newLobbyId
        TriggerServerEvent("pvp:onLobbyJoin")
    end
end)

-- 🧪 Comenzi de test pentru bannere
RegisterCommand("simularejoin", function(_, args)
    local nume = table.concat(args, " ") or "Necunoscut"
    SendNUIMessage({
        action = "showJoinBanner",
        name = nume,
        messageType = "join"
    })
end)

RegisterCommand("simulareleave", function(_, args)
    local nume = table.concat(args, " ") or "Necunoscut"
    SendNUIMessage({
        action = "showJoinBanner",
        name = nume,
        messageType = "leave"
    })
end)

RegisterCommand("simulareswitch", function(_, args)
    local nume = table.concat(args, " ") or "Necunoscut"
    SendNUIMessage({
        action = "showJoinBanner",
        name = nume,
        messageType = "switch",
        lobby = "2"
    })
end)
