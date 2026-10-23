local function requestRank()
    TriggerServerEvent("pvp:requestRank")
end

RegisterNetEvent("pvp:updateRank")
AddEventHandler("pvp:updateRank", function(rank, xp, nextXP, ranks, isInLobby)
    HudClient.SendUiMessage({
        action = "updateRank",
        rank = rank,
        xp = xp,
        nextXP = nextXP,
        ranks = ranks,
        inLobby = isInLobby
    })
end)

AddEventHandler("playerSpawned", requestRank)

AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    CreateThread(function()
        Wait(250)
        requestRank()
    end)
end)

RegisterNetEvent("vorp:playerLoaded")
AddEventHandler("vorp:playerLoaded", requestRank)

RegisterNetEvent("vorp:SelectedCharacter")
AddEventHandler("vorp:SelectedCharacter", requestRank)

CreateThread(function()
    Wait(750)
    requestRank()
end)

RegisterNetEvent("funcker_rank:setVisible")
AddEventHandler("funcker_rank:setVisible", function(state)
    HudClient.SetRankVisible(state)

    if HudClient.State.rankVisible then
        requestRank()
    end
end)
