local killfeedEnabled = true
local inPvpLobby = false
local killedAlready = false
local lastKillFeed = { killer = "", victim = "", time = 0 }

RegisterNetEvent("pvp:joinedLobby")
AddEventHandler("pvp:joinedLobby", function()
    inPvpLobby = true
end)

RegisterNetEvent("pvp:leftLobby")
AddEventHandler("pvp:leftLobby", function()
    inPvpLobby = false
    killedAlready = false
end)

RegisterNetEvent("pvp:updateLobby")
AddEventHandler("pvp:updateLobby", function(lobbyId)
    inPvpLobby = lobbyId ~= nil
    if not inPvpLobby then
        killedAlready = false
    end
end)

RegisterNetEvent("pvp:setClientLobby")
AddEventHandler("pvp:setClientLobby", function(lobbyId)
    inPvpLobby = lobbyId ~= nil
end)

RegisterNetEvent("pvp:clearClientLobby")
AddEventHandler("pvp:clearClientLobby", function()
    inPvpLobby = false
    killedAlready = false
end)

CreateThread(function()
    Wait(1500)

    local ok, isInLobby = pcall(function()
        return exports["pvp"]:IsInLobby()
    end)

    inPvpLobby = ok and isInLobby == true
end)

RegisterNetEvent("funcker_killfeed:enable")
AddEventHandler("funcker_killfeed:enable", function()
    killfeedEnabled = true
end)

RegisterNetEvent("funcker_killfeed:disable")
AddEventHandler("funcker_killfeed:disable", function()
    killfeedEnabled = false
end)

RegisterNetEvent("killfeed:add")
AddEventHandler("killfeed:add", function(killer, victim, distance)
    if not killfeedEnabled then return end

    local now = GetGameTimer()
    if lastKillFeed.killer == killer and lastKillFeed.victim == victim and now - lastKillFeed.time < 500 then
        return
    end

    lastKillFeed = { killer = killer, victim = victim, time = now }

    SendNUIMessage({
        action = "addKill",
        killer = killer,
        victim = victim,
        distance = distance or "-"
    })
end)

CreateThread(function()
    while true do
        Wait(inPvpLobby and 500 or 2000)

        if inPvpLobby then
            local playerPed = PlayerPedId()
            if DoesEntityExist(playerPed) then
                if IsEntityDead(playerPed) and not killedAlready then
                    killedAlready = true

                    local killerPed = GetPedSourceOfDeath(playerPed)
                    local victim = GetPlayerName(PlayerId())
                    local victimCoords = GetEntityCoords(playerPed)

                    if killerPed and killerPed ~= 0 then
                        if IsPedAPlayer(killerPed) then
                            local killerPlayer = NetworkGetPlayerIndexFromPed(killerPed)
                            local killerServerId = GetPlayerServerId(killerPlayer)
                            local killerCoords = GetEntityCoords(killerPed)

                            if killerServerId then
                                local killerName = GetPlayerName(killerPlayer)
                                TriggerServerEvent("killfeed:playerKilled", killerName, victim, killerCoords, victimCoords)
                            end
                        else
                            TriggerServerEvent("killfeed:playerKilled", "Unknown", victim, victimCoords, victimCoords)
                        end
                    else
                        TriggerServerEvent("killfeed:playerKilled", "Suicide", victim, victimCoords, victimCoords)
                    end
                elseif not IsEntityDead(playerPed) and killedAlready then
                    killedAlready = false
                end
            end
        else
            killedAlready = false
        end
    end
end)

RegisterCommand("testkill", function()
    Citizen.CreateThread(function()
        local kills = {
            { killer = "TEST KILLER", victim = "VICTIM 1", distance = "5M" },
            { killer = "TEST KILLER", victim = "VICTIM 2", distance = "20M" },
            { killer = "TEST KILLER", victim = "VICTIM 3", distance = "40M" },
            { killer = "TEST KILLER", victim = "VICTIM 4", distance = "80M" }
        }

        for _, data in ipairs(kills) do
            TriggerEvent("killfeed:add", data.killer, data.victim, data.distance)
            Wait(450)
        end
    end)
end)
