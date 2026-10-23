local VISIBILITY_KVP_KEY = "quickcommands_visible"

local commandsVisible = true
local inLobby = false -- tracks whether the player is in a lobby
local lobbyStatusRetryCount = 0
local MAX_LOBBY_STATUS_RETRIES = 5

local function loadVisibilityPreference()
    local savedState = GetResourceKvpString(VISIBILITY_KVP_KEY)

    if savedState == nil then
        return true
    end

    return savedState == "true"
end

local function saveVisibilityPreference(state)
    SetResourceKvp(VISIBILITY_KVP_KEY, state and "true" or "false")
end

local function normalizeVisibilityState(state)
    if type(state) == "boolean" then
        return state
    end

    if type(state) == "number" then
        return state ~= 0
    end

    if type(state) == "string" then
        local normalized = string.lower(state)
        return normalized == "true" or normalized == "1" or normalized == "on"
    end

    return false
end

function updateLobbyCommands()
    if commandsVisible and not inLobby then
        SendNUIMessage({ action = "showLobbyCommands" })
    else
        SendNUIMessage({ action = "hideLobbyCommands" })
    end
end

-- On startup, restore the saved preference and then ask the server for lobby state.
Citizen.CreateThread(function()
    Citizen.Wait(3000) -- wait for the UI/player state to be ready
    commandsVisible = loadVisibilityPreference()

    if not commandsVisible then
        SendNUIMessage({ action = "hideLobbyCommands" })
    end

    TriggerServerEvent("pvp:checkLobbyStatus")
end)

RegisterNetEvent("funcker_commands:setVisible")
AddEventHandler("funcker_commands:setVisible", function(state)
    commandsVisible = normalizeVisibilityState(state)
    saveVisibilityPreference(commandsVisible)
    lobbyStatusRetryCount = 0
    updateLobbyCommands()

    if commandsVisible then
        TriggerServerEvent("pvp:checkLobbyStatus")
    end
end)

RegisterNetEvent("funcker_commands:lobbyStatus")
AddEventHandler("funcker_commands:lobbyStatus", function(isInLobby)
    inLobby = isInLobby
    updateLobbyCommands()

    if isInLobby then
        lobbyStatusRetryCount = 0
        return
    end

    -- Retry only during startup/state propagation; outside-lobby is otherwise a stable state.
    if commandsVisible and lobbyStatusRetryCount < MAX_LOBBY_STATUS_RETRIES then
        lobbyStatusRetryCount = lobbyStatusRetryCount + 1
        Citizen.SetTimeout(2000, function()
            if inLobby then
                return
            end

            TriggerServerEvent("pvp:checkLobbyStatus")
        end)
    end
end)

RegisterNetEvent("funcker_lobbycommands:show")
AddEventHandler("funcker_lobbycommands:show", function()
    commandsVisible = true
    lobbyStatusRetryCount = 0
    saveVisibilityPreference(commandsVisible)
    updateLobbyCommands()
    TriggerServerEvent("pvp:checkLobbyStatus")
end)

RegisterNetEvent("funcker_lobbycommands:hide")
AddEventHandler("funcker_lobbycommands:hide", function()
    commandsVisible = false
    lobbyStatusRetryCount = 0
    saveVisibilityPreference(commandsVisible)
    updateLobbyCommands()
end)

RegisterCommand("testcomenzi", function()
    SendNUIMessage({ action = "showLobbyCommands" })
end, false)
