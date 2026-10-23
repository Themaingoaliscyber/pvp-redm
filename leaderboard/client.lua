local leaderboardOpen = false
local lastLeaderboardPayload = nil
local pendingRequestId = 0
local lastRequestAt = 0
local lastManualRefreshAt = 0
local openWhenPayloadReady = false
local warmupStarted = false
local warmupPayloadSent = false
local quickWarmupStarted = false
local nuiReady = false

local ACTIVE_REFRESH_INTERVAL_MS = 3000
local VISUAL_TOP_LIMIT = 100
local REQUEST_COOLDOWN_MS = 250
local MANUAL_REFRESH_COOLDOWN_MS = 3000
local POST_CONNECT_WARMUP_DELAY_MS = 2500
local QUICK_CACHE_WARMUP_DELAY_MS = 650
local FALLBACK_WARMUP_DELAY_MS = 10000
local blockedControls = {
    0xA987235F, -- Look left/right
    0xD2047988, -- Look up/down
    0x07CE1E61, -- Attack
    0xB2F377E8  -- Melee attack
}

local function getNowMilliseconds()
    if type(GetGameTimer) == "function" then
        return GetGameTimer()
    end

    return math.floor((os.clock() or 0) * 1000)
end

local function nextRequestId()
    pendingRequestId = pendingRequestId + 1

    if pendingRequestId > 999999 then
        pendingRequestId = 1
    end

    return pendingRequestId
end

local function hasDisplayablePayload(payload)
    return type(payload) == "table" and payload.loading ~= true
end

local function buildLoadingPayload()
    local payload = {
        loading = true,
        totalPlayers = 0,
        topPlayers = {},
        viewer = {
            name = "Steam Player",
            message = "Leaderboard cache is waking up."
        }
    }

    if type(lastLeaderboardPayload) == "table" then
        payload.totalPlayers = tonumber(lastLeaderboardPayload.totalPlayers) or 0
        payload.topPlayers = type(lastLeaderboardPayload.topPlayers) == "table" and lastLeaderboardPayload.topPlayers or {}
        payload.viewer = type(lastLeaderboardPayload.viewer) == "table" and lastLeaderboardPayload.viewer or payload.viewer
    end

    return payload
end

local function getStableTopPlayers(incomingTopPlayers, totalPlayers)
    if type(incomingTopPlayers) ~= "table" then
        return type(lastLeaderboardPayload) == "table" and type(lastLeaderboardPayload.topPlayers) == "table" and lastLeaderboardPayload.topPlayers or {}
    end

    local previousTopPlayers = type(lastLeaderboardPayload) == "table" and type(lastLeaderboardPayload.topPlayers) == "table" and lastLeaderboardPayload.topPlayers or nil
    if not previousTopPlayers then
        return incomingTopPlayers
    end

    local expectedTopSize = math.min(VISUAL_TOP_LIMIT, math.max(tonumber(totalPlayers) or 0, #previousTopPlayers))
    if #previousTopPlayers >= VISUAL_TOP_LIMIT and expectedTopSize >= VISUAL_TOP_LIMIT and #incomingTopPlayers < expectedTopSize then
        return previousTopPlayers
    end

    return incomingTopPlayers
end

local function applyPayload(payload)
    if not hasDisplayablePayload(payload) then
        return false
    end

    payload.topPlayers = getStableTopPlayers(payload.topPlayers, payload.totalPlayers)
    lastLeaderboardPayload = payload
    return true
end

local function setLeaderboardFocus(hasFocus)
    hasFocus = hasFocus == true
    SetNuiFocus(hasFocus, hasFocus)

    if type(SetNuiFocusKeepInput) == "function" then
        SetNuiFocusKeepInput(false)
    end
end

local function sendOpen(payload, stale, pending)
    if type(payload) ~= "table" then
        payload = buildLoadingPayload()
    end

    SendNUIMessage({
        action = "openLeaderboard",
        payload = payload,
        stale = stale == true,
        pending = pending == true
    })

    return true
end

local function mergeTopOnlyPayload(payload)
    if type(payload) ~= "table" then
        return false
    end

    if type(lastLeaderboardPayload) ~= "table" then
        lastLeaderboardPayload = payload
    else
        lastLeaderboardPayload.generatedAt = payload.generatedAt or lastLeaderboardPayload.generatedAt
        lastLeaderboardPayload.cacheTtlMs = payload.cacheTtlMs or lastLeaderboardPayload.cacheTtlMs
        lastLeaderboardPayload.totalPlayers = tonumber(payload.totalPlayers) or tonumber(lastLeaderboardPayload.totalPlayers) or 0
        lastLeaderboardPayload.loading = payload.loading == true
        lastLeaderboardPayload.topPlayers = getStableTopPlayers(payload.topPlayers, lastLeaderboardPayload.totalPlayers)
    end

    return hasDisplayablePayload(lastLeaderboardPayload)
end

local function mergeTopPlayerPatch(patch)
    if type(patch) ~= "table" or type(patch.players) ~= "table" then
        return false
    end

    if type(lastLeaderboardPayload) ~= "table" or type(lastLeaderboardPayload.topPlayers) ~= "table" then
        return false
    end

    local players = lastLeaderboardPayload.topPlayers

    for _, changedPlayer in ipairs(patch.players) do
        local changedKey = tostring(changedPlayer.key or "")
        local changedRank = tonumber(changedPlayer.rank) or 0

        for index, currentPlayer in ipairs(players) do
            if tostring(currentPlayer.key or "") == changedKey or (changedRank > 0 and tonumber(currentPlayer.rank) == changedRank) then
                players[index] = changedPlayer
                break
            end
        end
    end

    lastLeaderboardPayload.generatedAt = patch.generatedAt or lastLeaderboardPayload.generatedAt
    lastLeaderboardPayload.cacheTtlMs = patch.cacheTtlMs or lastLeaderboardPayload.cacheTtlMs
    lastLeaderboardPayload.totalPlayers = tonumber(patch.totalPlayers) or tonumber(lastLeaderboardPayload.totalPlayers) or 0
    lastLeaderboardPayload.loading = false

    return hasDisplayablePayload(lastLeaderboardPayload)
end
local function sendUpdate(payload)
    if not hasDisplayablePayload(payload) then
        return false
    end

    SendNUIMessage({
        action = "updateLeaderboard",
        payload = payload
    })

    return true
end

local function sendTopUpdate(payload)
    if type(payload) ~= "table" then
        return false
    end

    SendNUIMessage({
        action = "updateLeaderboardTop",
        payload = payload
    })

    return true
end

local function sendPlayerPatch(patch)
    if type(patch) ~= "table" then
        return false
    end

    SendNUIMessage({
        action = "patchLeaderboardPlayers",
        payload = patch
    })

    return true
end
local function sendWarmup(payload)
    if leaderboardOpen or not hasDisplayablePayload(payload) then
        return false
    end

    warmupPayloadSent = true
    SendNUIMessage({
        action = "warmupLeaderboard",
        payload = payload
    })

    return true
end

local function requestLeaderboard(options)
    options = options or {}

    if options.throttled == true then
        local now = getNowMilliseconds()
        if lastRequestAt > 0 and (now - lastRequestAt) < REQUEST_COOLDOWN_MS then
            return nil
        end
        lastRequestAt = now
    end

    local requestId = nextRequestId()
    TriggerServerEvent("leaderboard:request", {
        requestId = requestId,
        forceRefresh = options.forceRefresh == true,
        silent = options.silent == true,
        prefetch = options.prefetch == true,
        cacheOnly = options.cacheOnly == true
    })

    return requestId
end

local function showLeaderboard(payload, options)
    options = options or {}

    if type(payload) == "table" then
        applyPayload(payload)
    end

    if not hasDisplayablePayload(lastLeaderboardPayload) then
        return false
    end

    openWhenPayloadReady = false
    leaderboardOpen = true
    setLeaderboardFocus(true)
    sendOpen(lastLeaderboardPayload, false)

    if options.refreshAfterOpen ~= false then
        requestLeaderboard({
            forceRefresh = false,
            silent = true,
            throttled = true
        })
    end

    return true
end

local function openLeaderboard(payload)
    if showLeaderboard(payload) then
        return
    end

    openWhenPayloadReady = true
    leaderboardOpen = true
    setLeaderboardFocus(true)
    sendOpen(lastLeaderboardPayload or buildLoadingPayload(), true, true)
    requestLeaderboard({
        forceRefresh = false,
        throttled = true
    })
end

local function closeLeaderboard()
    if not leaderboardOpen then
        openWhenPayloadReady = false
        return
    end

    leaderboardOpen = false
    openWhenPayloadReady = false
    TriggerServerEvent("leaderboard:close")
    setLeaderboardFocus(false)
    SendNUIMessage({ action = "closeLeaderboard" })
end

local function isReadyForPostConnectWarmup()
    if type(PlayerId) == "function" and type(NetworkIsPlayerActive) == "function" then
        local ok, isActive = pcall(NetworkIsPlayerActive, PlayerId())
        if ok and isActive ~= true then
            return false
        end
    end

    if type(PlayerPedId) == "function" then
        local ok, ped = pcall(PlayerPedId)
        if not ok or not ped or ped == 0 then
            return false
        end

        if type(DoesEntityExist) == "function" then
            local existsOk, exists = pcall(DoesEntityExist, ped)
            if existsOk and exists ~= true then
                return false
            end
        end
    end

    if type(IsScreenFadedIn) == "function" then
        local ok, fadedIn = pcall(IsScreenFadedIn)
        if ok and fadedIn ~= true then
            return false
        end
    elseif type(IsScreenFadedOut) == "function" then
        local ok, fadedOut = pcall(IsScreenFadedOut)
        if ok and fadedOut == true then
            return false
        end
    end

    return true
end

local function startQuickCacheWarmup()
    if quickWarmupStarted then
        return
    end

    quickWarmupStarted = true

    CreateThread(function()
        Wait(QUICK_CACHE_WARMUP_DELAY_MS)
        SendNUIMessage({ action = "warmupLeaderboard" })
        requestLeaderboard({
            prefetch = true,
            cacheOnly = true,
            silent = true
        })
    end)
end

local function startPostConnectWarmup(delayMs)
    if warmupStarted then
        return
    end

    warmupStarted = true

    CreateThread(function()
        Wait(tonumber(delayMs) or POST_CONNECT_WARMUP_DELAY_MS)

        while not isReadyForPostConnectWarmup() do
            Wait(1000)
        end

        SendNUIMessage({ action = "warmupLeaderboard" })
        requestLeaderboard({
            forceRefresh = false,
            prefetch = true
        })
    end)
end

RegisterNetEvent("leaderboard:open", function(payload)
    openLeaderboard(payload)
end)

RegisterNetEvent("leaderboard:showCached", function()
    openLeaderboard(lastLeaderboardPayload)
end)

RegisterNetEvent("leaderboard:openFromCommand", function()
    openLeaderboard()
end)

RegisterCommand("top", function()
    openLeaderboard()
end, false)

RegisterCommand("leaderboard", function()
    openLeaderboard()
end, false)

RegisterNetEvent("leaderboard:update", function(payload)
    if not applyPayload(payload) then
        return
    end

    if openWhenPayloadReady and hasDisplayablePayload(payload) then
        showLeaderboard(payload, { refreshAfterOpen = false })
        return
    end

    if leaderboardOpen then
        sendUpdate(payload)
    elseif warmupStarted and not warmupPayloadSent and nuiReady then
        sendWarmup(payload)
    end
end)

RegisterNetEvent("leaderboard:updateTop", function(payload)
    if not mergeTopOnlyPayload(payload) then
        return
    end

    if leaderboardOpen then
        sendTopUpdate(lastLeaderboardPayload)
    elseif warmupStarted and not warmupPayloadSent and nuiReady then
        sendWarmup(lastLeaderboardPayload)
    end
end)

RegisterNetEvent("leaderboard:updatePlayers", function(patch)
    if not mergeTopPlayerPatch(patch) then
        return
    end

    if leaderboardOpen then
        sendPlayerPatch(patch)
    elseif warmupStarted and not warmupPayloadSent and nuiReady then
        sendWarmup(lastLeaderboardPayload)
    end
end)
RegisterNetEvent("leaderboard:invalidate", function()
    lastLeaderboardPayload = nil

    if leaderboardOpen then
        requestLeaderboard({ forceRefresh = true })
    end
end)

RegisterNUICallback("closeLeaderboard", function(_, cb)
    closeLeaderboard()
    cb({ ok = true })
end)

RegisterNUICallback("refreshLeaderboard", function(_, cb)
    local now = getNowMilliseconds()
    local elapsed = now - lastManualRefreshAt

    if lastManualRefreshAt > 0 and elapsed < MANUAL_REFRESH_COOLDOWN_MS then
        cb({ ok = false, cooldown = true, retryAfterMs = MANUAL_REFRESH_COOLDOWN_MS - elapsed })
        return
    end

    lastManualRefreshAt = now
    requestLeaderboard({ forceRefresh = true })
    cb({ ok = true, cooldownMs = MANUAL_REFRESH_COOLDOWN_MS })
end)

RegisterNUICallback("leaderboardReady", function(_, cb)
    nuiReady = true
    startQuickCacheWarmup()

    if leaderboardOpen and hasDisplayablePayload(lastLeaderboardPayload) then
        sendOpen(lastLeaderboardPayload, false)
    elseif warmupStarted and not warmupPayloadSent and hasDisplayablePayload(lastLeaderboardPayload) then
        sendWarmup(lastLeaderboardPayload)
    end

    cb({ ok = true })
end)

AddEventHandler("playerSpawned", function()
    startPostConnectWarmup(POST_CONNECT_WARMUP_DELAY_MS)
end)

CreateThread(function()
    Wait(1500)
    startQuickCacheWarmup()
end)

CreateThread(function()
    Wait(FALLBACK_WARMUP_DELAY_MS)
    startPostConnectWarmup(0)
end)

CreateThread(function()
    while true do
        if leaderboardOpen then
            Wait(ACTIVE_REFRESH_INTERVAL_MS)

            if leaderboardOpen then
                requestLeaderboard({
                    silent = true,
                    throttled = true
                })
            end
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        if leaderboardOpen then
            for _, control in ipairs(blockedControls) do
                DisableControlAction(0, control, true)
            end

            Wait(0)
        else
            Wait(250)
        end
    end
end)

AddEventHandler("onClientResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    if leaderboardOpen then
        setLeaderboardFocus(false)
    end
end)