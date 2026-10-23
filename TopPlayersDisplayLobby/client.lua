local currentLobbyId = nil
local statsMenuVisible = false
local pendingStatsMenuOpen = false
local top3HudEnabled = true
local demoLobbyStatsCommandEnabled = true
local f6Control = 0x3C0A40F2
local lastStatsPayload = nil
local statsMenuFocusWarmed = false
local setCurrentLobby
local blockedMenuControls = {
    0xA987235F, -- Look left/right
    0xD2047988  -- Look up/down
}
local demoStatsPlayers = {}
local top3HudEditorMode = false
local top3HudPosition = nil
local top3HudPositionKvp = "funcker_topplayers_top3_position_v1"

for index = 1, 20 do
    demoStatsPlayers[index] = {
        id = index,
        name = ("await exploit() [%d]"):format(index),
        kills = 21 - index,
        deaths = index - 1,
        duelRequestsEnabled = true
    }
end
local function safeToNumber(value)
    local number = tonumber(value)
    if not number or number ~= number then
        return nil
    end

    return number
end

local function buildDemoStatsPayload()
    return {
        inLobby = true,
        lobbyId = "DEMO",
        totalPlayers = #demoStatsPlayers,
        players = demoStatsPlayers,
        viewerDuelPending = false,
        viewerPendingDuelTargetId = nil
    }
end

local function normalizeTop3HudPosition(position)
    if type(position) ~= "table" then
        return nil
    end

    local x = safeToNumber(position.x or position.left)
    local y = safeToNumber(position.y or position.top)

    if not x or not y then
        return nil
    end

    return {
        x = math.max(0, math.min(100, x)),
        y = math.max(0, math.min(100, y))
    }
end

local function loadTop3HudPosition()
    if type(GetResourceKvpString) ~= "function" or type(json) ~= "table" or type(json.decode) ~= "function" then
        return nil
    end

    local raw = GetResourceKvpString(top3HudPositionKvp)
    if not raw or raw == "" then
        return nil
    end

    local ok, decoded = pcall(json.decode, raw)
    if not ok then
        return nil
    end

    return normalizeTop3HudPosition(decoded)
end

local function saveTop3HudPosition()
    if top3HudPosition then
        if type(SetResourceKvp) == "function" and type(json) == "table" and type(json.encode) == "function" then
            SetResourceKvp(top3HudPositionKvp, json.encode(top3HudPosition))
        end

        return
    end

    if type(DeleteResourceKvp) == "function" then
        DeleteResourceKvp(top3HudPositionKvp)
    elseif type(SetResourceKvp) == "function" then
        SetResourceKvp(top3HudPositionKvp, "")
    end
end

local function sendTop3HudPositionToNui()
    SendNUIMessage({
        action = "setTop3HudPosition",
        position = top3HudPosition
    })
end

top3HudPosition = loadTop3HudPosition()

local function normalizeLobbyId(lobbyId)
    if type(lobbyId) == "string" then
        lobbyId = lobbyId:gsub("^%s+", ""):gsub("%s+$", "")
        if lobbyId == "" or lobbyId:lower() == "safezone" then
            return nil
        end
    end

    local numericLobbyId = safeToNumber(lobbyId)
    if numericLobbyId then
        numericLobbyId = math.floor(numericLobbyId)
        if numericLobbyId > 0 then
            return numericLobbyId
        end

        return nil
    end

    return lobbyId
end

local function getMyServerId()
    local ok, serverId = pcall(function()
        return GetPlayerServerId(PlayerId())
    end)

    if ok then
        return tonumber(serverId)
    end

    return nil
end

local function notifySpectator(title, description, iconName)
    TriggerEvent("bln_notify:send", {
        title = title or "Spectator",
        description = description or "Action unavailable.",
        icon = iconName or "cross",
        placement = "middle-right",
        duration = 4500
    })
end

local function getCurrentLobbyNumber(lobbyId)
    local resolvedLobbyId = normalizeLobbyId(lobbyId or currentLobbyId)

    if resolvedLobbyId == nil then
        local okLobby, exportedLobbyId = pcall(function()
            return exports.pvp:GetPlayerLobby()
        end)

        if okLobby then
            resolvedLobbyId = normalizeLobbyId(exportedLobbyId)
        end
    end

    local lobbyNumber = math.floor(safeToNumber(resolvedLobbyId) or 0)
    if lobbyNumber <= 0 then
        return nil
    end

    return lobbyNumber
end

local function getPvpConfig()
    local okConfig, pvpConfig = pcall(function()
        return exports.pvp:GetConfig()
    end)

    if okConfig and type(pvpConfig) == "table" then
        return pvpConfig
    end

    return {}
end

local function isTeamBattleLobby(lobbyId)
    local lobbyNumber = getCurrentLobbyNumber(lobbyId)
    if not lobbyNumber then
        return false
    end

    local cfg = getPvpConfig()
    local teamArenaIds = cfg.TeamArenaIds
    if type(teamArenaIds) == "table" then
        for key, value in pairs(teamArenaIds) do
            local candidate = math.floor(safeToNumber(value) or safeToNumber(key) or 0)
            if candidate > 0 and candidate == lobbyNumber then
                return true
            end
        end
    end

    if type(cfg.Lobbies) == "table" then
        for _, lobbyData in pairs(cfg.Lobbies) do
            if type(lobbyData) == "table" and math.floor(safeToNumber(lobbyData.id) or 0) == lobbyNumber then
                local category = type(lobbyData.category) == "string" and lobbyData.category:lower() or ""
                local description = type(lobbyData.description) == "string" and lobbyData.description:lower() or ""

                if category == "team" or description:find("team battle", 1, true) then
                    return true
                end

                break
            end
        end
    end

    return false
end

local function canSpectateLobbyPlayers()
    local lobbyNumber = getCurrentLobbyNumber()
    if not lobbyNumber then
        return false
    end

    return not isTeamBattleLobby(lobbyNumber)
end

local function requestStatsForCurrentLobby(force)
    if force or statsMenuVisible or pendingStatsMenuOpen then
        TriggerServerEvent("topplayers:requestLobbyStatsMenu")
    end
end

local function buildInitialStatsPayload(lobbyId)
    lobbyId = normalizeLobbyId(lobbyId)

    return {
        inLobby = lobbyId ~= nil,
        lobbyId = lobbyId,
        totalPlayers = 0,
        players = {}
    }
end

local function isStatsPayloadForLobby(payload, lobbyId)
    if not payload or payload.inLobby == false then
        return false
    end

    lobbyId = normalizeLobbyId(lobbyId)
    return lobbyId ~= nil and normalizeLobbyId(payload.lobbyId) == lobbyId
end

local function cacheStatsPayload(payload)
    if payload and payload.inLobby and payload.lobbyId then
        currentLobbyId = normalizeLobbyId(payload.lobbyId)
        lastStatsPayload = payload
    elseif payload and payload.inLobby == false then
        currentLobbyId = nil
        lastStatsPayload = payload
    elseif payload then
        lastStatsPayload = payload
    end
end

local function sendTop3Hud(payload, isDemo)
    if not top3HudEnabled and not top3HudEditorMode then
        SendNUIMessage({ action = "hideTopKills" })
        return
    end

    local players = payload and type(payload.players) == "table" and payload.players or {}

    if payload and payload.inLobby ~= false and #players > 0 then
        SendNUIMessage({
            action = "showTop3Hud",
            stats = payload,
            demo = isDemo and true or false,
            position = top3HudPosition,
            editor = top3HudEditorMode
        })
        return
    end

    if top3HudEditorMode then
        SendNUIMessage({
            action = "showTop3Hud",
            stats = buildDemoStatsPayload(),
            demo = true,
            position = top3HudPosition,
            editor = true
        })
        return
    end

    SendNUIMessage({ action = "hideTopKills" })
end

local function hideTop3Hud()
    if top3HudEditorMode then
        sendTop3Hud(lastStatsPayload or buildDemoStatsPayload(), lastStatsPayload == nil)
        return
    end

    SendNUIMessage({ action = "hideTopKills" })
end

local function setTop3HudEnabled(enabled)
    top3HudEnabled = enabled and true or false

    if not top3HudEnabled and not top3HudEditorMode then
        SendNUIMessage({ action = "hideTopKills" })
        return
    end

    if lastStatsPayload then
        sendTop3Hud(lastStatsPayload, false)
    else
        requestStatsForCurrentLobby(false)
    end
end

local function setStatsMenuFocus(enabled)
    local hasFocus = enabled and true or false
    SetNuiFocus(hasFocus, hasFocus)

    if type(SetNuiFocusKeepInput) == "function" then
        SetNuiFocusKeepInput(false)
    end

    TriggerEvent("respawnsys:externalNuiFocusChanged", hasFocus)
end

local function warmStatsMenuFocus()
    if statsMenuFocusWarmed or statsMenuVisible or pendingStatsMenuOpen then
        return
    end

    statsMenuFocusWarmed = true
    SetNuiFocus(true, true)

    if type(SetNuiFocusKeepInput) == "function" then
        SetNuiFocusKeepInput(false)
    end

    Citizen.Wait(75)

    if not statsMenuVisible and not pendingStatsMenuOpen then
        SetNuiFocus(false, false)

        if type(SetNuiFocusKeepInput) == "function" then
            SetNuiFocusKeepInput(false)
        end

        TriggerEvent("respawnsys:externalNuiFocusChanged", false)
    end
end

local function disableStatsMenuGameControls()
    DisableAllControlActions(0)
    DisableAllControlActions(1)
    DisableAllControlActions(2)

    for _, control in ipairs(blockedMenuControls) do
        DisableControlAction(0, control, true)
        DisableControlAction(1, control, true)
        DisableControlAction(2, control, true)
    end
end

local function closeStatsMenu()
    local shouldNotifyServer = statsMenuVisible or pendingStatsMenuOpen
    pendingStatsMenuOpen = false

    if shouldNotifyServer then
        TriggerServerEvent("topplayers:closeLobbyStatsMenu")
    end

    if not statsMenuVisible then
        return
    end

    statsMenuVisible = false
    setStatsMenuFocus(false)
    SendNUIMessage({ action = "closeLobbyStatsMenu" })
end

local function showStatsMenu(payload, options)
    pendingStatsMenuOpen = false
    statsMenuVisible = true
    setStatsMenuFocus(true)

    options = options or {}
    local currentServerIdOverride = options.currentServerId
    if currentServerIdOverride == nil then
        currentServerIdOverride = getMyServerId()
    end

    local canSpectatePlayersOverride = options.canSpectatePlayers
    if canSpectatePlayersOverride == nil then
        canSpectatePlayersOverride = canSpectateLobbyPlayers()
    end

    SendNUIMessage({
        action = "openLobbyStatsMenu",
        lobbyId = currentLobbyId,
        stats = payload,
        currentServerId = currentServerIdOverride,
        canSpectatePlayers = canSpectatePlayersOverride
    })
end

Citizen.CreateThread(function()
    while true do
        if statsMenuVisible then
            Citizen.Wait(0)
            disableStatsMenuGameControls()

            if type(SetNuiFocusKeepInput) == "function" then
                SetNuiFocusKeepInput(false)
            end
        else
            Citizen.Wait(250)
        end
    end
end)

local function openStatsMenu()
    local exportedLobbyId = getCurrentLobbyNumber()
    if exportedLobbyId and exportedLobbyId ~= currentLobbyId then
        setCurrentLobby(exportedLobbyId)
    end

    local lobbyId = exportedLobbyId or currentLobbyId
    local payload = isStatsPayloadForLobby(lastStatsPayload, lobbyId) and lastStatsPayload or buildInitialStatsPayload(lobbyId)

    showStatsMenu(payload)
    requestStatsForCurrentLobby(true)
end

local function openDemoStatsMenu()
    showStatsMenu(buildDemoStatsPayload(), {
        currentServerId = -1,
        canSpectatePlayers = false
    })
end

local function showDemoTop3Hud()
    sendTop3Hud(buildDemoStatsPayload(), true)
end

local function publishTop3HudPositionToEditor()
    TriggerEvent("funcker_hud:externalHudPosition", {
        key = "topplayers",
        position = top3HudPosition
    })
end

local function setTop3HudEditorMode(enabled)
    top3HudEditorMode = enabled and true or false

    SendNUIMessage({
        action = "setTop3HudEditorMode",
        enabled = top3HudEditorMode,
        position = top3HudPosition
    })

    if top3HudEditorMode then
        publishTop3HudPositionToEditor()
        sendTop3Hud(lastStatsPayload or buildDemoStatsPayload(), lastStatsPayload == nil)
        return
    end

    if top3HudEnabled and lastStatsPayload then
        sendTop3Hud(lastStatsPayload, false)
    else
        hideTop3Hud()
    end
end

local function setTop3HudPosition(position, shouldPersist, shouldPublish)
    top3HudPosition = normalizeTop3HudPosition(position)

    if shouldPersist ~= false then
        saveTop3HudPosition()
    end

    sendTop3HudPositionToNui()

    if shouldPublish then
        publishTop3HudPositionToEditor()
    end
end

local function resetTop3HudPosition()
    top3HudPosition = nil
    saveTop3HudPosition()
    sendTop3HudPositionToNui()
    publishTop3HudPositionToEditor()
end

local function toggleStatsMenu()
    if statsMenuVisible or pendingStatsMenuOpen then
        closeStatsMenu()
        return
    end

    openStatsMenu()
end

local function isF6Pressed()
    return IsControlJustPressed(0, f6Control) or IsDisabledControlJustPressed(0, f6Control)
end

setCurrentLobby = function(lobbyId)
    lobbyId = normalizeLobbyId(lobbyId)
    local lobbyChanged = currentLobbyId ~= lobbyId

    if lobbyChanged then
        lastStatsPayload = nil
    end

    currentLobbyId = lobbyId

    if lobbyId then
        if lobbyChanged then
            TriggerServerEvent("topplayers:onLobbyJoin", lobbyId)
        end

        Citizen.SetTimeout(500, function()
            requestStatsForCurrentLobby(false)
        end)
    else
        closeStatsMenu()
        hideTop3Hud()
    end
end

Citizen.CreateThread(function()
    Citizen.Wait(250)
    sendTop3HudPositionToNui()
    SendNUIMessage({ action = "warmupLobbyStatsMenu" })
    Citizen.Wait(750)
    warmStatsMenuFocus()

    for attempt = 1, 20 do
        Citizen.Wait(attempt == 1 and 250 or 500)

        if currentLobbyId then
            return
        end

        local lobbyId = getCurrentLobbyNumber()
        if lobbyId then
            setCurrentLobby(lobbyId)
            return
        end
    end
end)

Citizen.CreateThread(function()
    while not NetworkIsSessionStarted() do
        Citizen.Wait(100)
    end

    Citizen.Wait(1000)

    if type(GetResourceState) ~= "function" or GetResourceState("funcker_settings_ui_custom") == "started" then
        TriggerServerEvent("funcker:loadSettings")
    end
end)

RegisterCommand("lobbystats", function()
    toggleStatsMenu()
end, false)

RegisterCommand("demolobbystats", function()
    if not demoLobbyStatsCommandEnabled then
        return
    end

    openDemoStatsMenu()
end, false)


RegisterNetEvent("funcker_topplayers:editorModeChanged")
AddEventHandler("funcker_topplayers:editorModeChanged", function(enabled)
    setTop3HudEditorMode(enabled)
end)

RegisterNetEvent("funcker_topplayers:setHudPosition")
AddEventHandler("funcker_topplayers:setHudPosition", function(position, shouldPersist)
    setTop3HudPosition(position, shouldPersist)
end)

RegisterNetEvent("funcker_topplayers:resetHudPosition")
AddEventHandler("funcker_topplayers:resetHudPosition", function()
    resetTop3HudPosition()
end)

RegisterNetEvent("funcker_topplayers:requestHudPosition")
AddEventHandler("funcker_topplayers:requestHudPosition", function()
    publishTop3HudPositionToEditor()
    sendTop3HudPositionToNui()
end)

if type(RegisterKeyMapping) == "function" then
    RegisterKeyMapping("lobbystats", "Open lobby stats", "keyboard", "F6")
else
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)

            if isF6Pressed() then
                toggleStatsMenu()
                Citizen.Wait(350)
            end
        end
    end)
end

RegisterNUICallback("closeLobbyStats", function(_, cb)
    closeStatsMenu()
    cb("ok")
end)

RegisterNUICallback("spectateLobbyPlayer", function(data, cb)
    local targetId = tonumber(data and data.targetId)
    if not targetId or targetId <= 0 then
        notifySpectator("Spectator unavailable", "Invalid player selected.", "cross")
        cb("error")
        return
    end

    local myServerId = getMyServerId()
    if myServerId and targetId == myServerId then
        notifySpectator("Spectator unavailable", "You cannot spectate yourself.", "cross")
        cb("error")
        return
    end

    if not canSpectateLobbyPlayers() then
        notifySpectator("Spectator unavailable", "Spectator is disabled in Team Battle arenas.", "cross")
        cb("error")
        return
    end

    TriggerServerEvent("topplayers:spectateLobbyPlayer", targetId)
    cb("ok")
end)

RegisterNUICallback("duelLobbyPlayer", function(data, cb)
    local targetId = tonumber(data and data.targetId)
    if not targetId or targetId <= 0 then
        notifySpectator("Duel unavailable", "Invalid player selected.", "cross")
        cb("error")
        return
    end

    local myServerId = getMyServerId()
    if myServerId and targetId == myServerId then
        notifySpectator("Duel unavailable", "You cannot duel yourself.", "cross")
        cb("error")
        return
    end

    TriggerServerEvent("topplayers:duelLobbyPlayer", targetId)
    cb("ok")
end)
RegisterNetEvent("funcker_topplayers:enable")
AddEventHandler("funcker_topplayers:enable", function()
    setTop3HudEnabled(true)

    if statsMenuVisible or pendingStatsMenuOpen then
        requestStatsForCurrentLobby()
    end
end)

RegisterNetEvent("funcker_topplayers:disable")
AddEventHandler("funcker_topplayers:disable", function()
    setTop3HudEnabled(false)
    closeStatsMenu()
end)

RegisterNetEvent("funcker:applySettings")
AddEventHandler("funcker:applySettings", function(data)
    if type(data) ~= "table" then
        return
    end

    local topPlayersSetting = nil
    if data.topplayers ~= nil then
        topPlayersSetting = data.topplayers
    elseif data.topPlayers ~= nil then
        topPlayersSetting = data.topPlayers
    elseif data.TopPlayers ~= nil then
        topPlayersSetting = data.TopPlayers
    elseif data.TOPPLAYERS ~= nil then
        topPlayersSetting = data.TOPPLAYERS
    end

    if topPlayersSetting == nil then
        return
    end

    setTop3HudEnabled(tonumber(topPlayersSetting) == 1 or topPlayersSetting == true)
end)

RegisterNetEvent("funcker_topplayers:updateLobbyStats")
AddEventHandler("funcker_topplayers:updateLobbyStats", function(payload)
    cacheStatsPayload(payload)
    sendTop3Hud(payload, false)

    if not statsMenuVisible and not pendingStatsMenuOpen then
        return
    end

    if pendingStatsMenuOpen then
        showStatsMenu(lastStatsPayload or payload)
        return
    end

    SendNUIMessage({
        action = "updateLobbyStats",
        stats = payload,
        currentServerId = getMyServerId(),
        canSpectatePlayers = canSpectateLobbyPlayers()
    })
end)

RegisterNetEvent("topplayers:spectateDenied")
AddEventHandler("topplayers:spectateDenied", function(reason)
    notifySpectator("Spectator unavailable", reason or "You cannot spectate this player.", "cross")
end)

RegisterNetEvent("pvp:updateTopKills")
AddEventHandler("pvp:updateTopKills", function(payload)
    if type(payload) == "table" then
        cacheStatsPayload(payload)
        sendTop3Hud(payload, false)
    elseif lastStatsPayload then
        sendTop3Hud(lastStatsPayload, false)
    else
        hideTop3Hud()
    end
end)

RegisterNetEvent("pvp:hideTopKills")
AddEventHandler("pvp:hideTopKills", function()
    if top3HudEditorMode then
        sendTop3Hud(lastStatsPayload or buildDemoStatsPayload(), lastStatsPayload == nil)
        return
    end

    hideTop3Hud()
end)

RegisterNetEvent("respawnsys:spectatorStopped")
AddEventHandler("respawnsys:spectatorStopped", function()
    if statsMenuVisible or pendingStatsMenuOpen then
        requestStatsForCurrentLobby()
    end
end)

RegisterNetEvent("pvp:teamArenaState")
AddEventHandler("pvp:teamArenaState", function()
    if statsMenuVisible then
        SendNUIMessage({
            action = "updateLobbyStats",
            stats = lastStatsPayload,
            currentServerId = getMyServerId(),
            canSpectatePlayers = canSpectateLobbyPlayers()
        })
    end
end)

RegisterNetEvent("pvp:joinedLobby")
AddEventHandler("pvp:joinedLobby", function(newLobbyId)
    setCurrentLobby(newLobbyId)
end)

RegisterNetEvent("pvp:leftLobby")
AddEventHandler("pvp:leftLobby", function()
    if currentLobbyId then
        TriggerServerEvent("topplayers:onLobbyLeave", currentLobbyId)
        currentLobbyId = nil
    end

    lastStatsPayload = nil
    closeStatsMenu()
    hideTop3Hud()
end)

RegisterNetEvent("pvp:updateLobby")
AddEventHandler("pvp:updateLobby", function(newLobbyId)
    newLobbyId = normalizeLobbyId(newLobbyId)

    if currentLobbyId == newLobbyId then
        if newLobbyId then
            requestStatsForCurrentLobby()
        end
        return
    end

    local oldLobbyId = currentLobbyId

    if oldLobbyId then
        TriggerServerEvent("topplayers:onLobbyLeave", oldLobbyId)
    end

    if newLobbyId then
        setCurrentLobby(newLobbyId)
        if statsMenuVisible then
            Citizen.SetTimeout(500, requestStatsForCurrentLobby)
        end
    else
        currentLobbyId = nil
        lastStatsPayload = nil
        closeStatsMenu()
        hideTop3Hud()
    end
end)
