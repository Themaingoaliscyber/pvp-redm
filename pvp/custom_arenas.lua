PvpCustomArenaState = PvpCustomArenaState or { active = false }

local function normalizeClientNotifyIcon(icon)
    local normalized = tostring(icon or "tick"):lower()
    if normalized == "cross"
        or normalized == "x"
        or normalized == "error"
        or normalized == "danger"
        or normalized == "blocked"
        or normalized == "cancel"
        or normalized == "warning" then
        return "cross"
    end

    return "tick"
end

local function sendClientCustomArenaNotify(title, description, icon, duration)
    TriggerEvent("bln_notify:send", {
        title = title,
        description = description,
        icon = normalizeClientNotifyIcon(icon),
        placement = "middle-right",
        duration = duration or 6000
    })
end

local function getActiveCustomArenaLobbyId()
    if PvpCustomArenaState and PvpCustomArenaState.active and PvpCustomArenaState.lobbyId then
        return tonumber(PvpCustomArenaState.lobbyId)
    end

    return nil
end

local function canManageActiveCustomArena()
    return PvpCustomArenaState
        and PvpCustomArenaState.active
        and (PvpCustomArenaState.isOwner or PvpCustomArenaState.isLeader)
end

local RANDOM_SPAWN_COUNT_MIN = 1
local RANDOM_SPAWN_COUNT_MAX = 32
local RANDOM_SPAWN_DISTANCE_MIN = 8.0
local RANDOM_SPAWN_DISTANCE_MAX = 150.0
local RANDOM_SPAWN_ATTEMPTS_PER_POINT = 140
local RANDOM_SPAWN_GROUND_RAY_FLAGS = 1
local RANDOM_SPAWN_FALLBACK_GROUND_RAY_FLAGS = 27
local RANDOM_SPAWN_CLEARANCE_RAY_FLAGS = 17

local function clampNumber(value, minimumValue, maximumValue)
    value = tonumber(value)
    if not value then
        return minimumValue
    end

    return math.min(math.max(value, minimumValue), maximumValue)
end

local function sanitizeRandomSpawnCount(value)
    return math.floor(clampNumber(value, RANDOM_SPAWN_COUNT_MIN, RANDOM_SPAWN_COUNT_MAX))
end

local function sanitizeRandomSpawnDistance(value)
    local distance = clampNumber(value, RANDOM_SPAWN_DISTANCE_MIN, RANDOM_SPAWN_DISTANCE_MAX)
    return math.floor((distance * 10.0) + 0.5) / 10.0
end

local function getCustomArenaSpawnDistance(firstCoords, secondCoords)
    local dx = (firstCoords.x or 0.0) - (secondCoords.x or 0.0)
    local dy = (firstCoords.y or 0.0) - (secondCoords.y or 0.0)
    local dz = (firstCoords.z or 0.0) - (secondCoords.z or 0.0)
    return math.sqrt((dx * dx) + (dy * dy) + (dz * dz))
end

local function getCurrentCustomArenaSpawnPoints()
    local spawnPoints = PvpCustomArenaState and PvpCustomArenaState.spawnPoints or nil
    if type(spawnPoints) ~= "table" then
        return {}
    end

    local points = {}
    for _, spawnPoint in ipairs(spawnPoints) do
        if type(spawnPoint) == "table" and spawnPoint.x and spawnPoint.y and spawnPoint.z then
            points[#points + 1] = {
                x = tonumber(spawnPoint.x) or 0.0,
                y = tonumber(spawnPoint.y) or 0.0,
                z = tonumber(spawnPoint.z) or 0.0
            }
        end
    end

    return points
end

local function isFarEnoughFromSpawnPoints(coords, spawnPoints, minDistance)
    for _, spawnPoint in ipairs(spawnPoints or {}) do
        if getCustomArenaSpawnDistance(coords, spawnPoint) < minDistance then
            return false
        end
    end

    return true
end

local function readShapeTestResult(handle)
    if not handle or handle == 0 or type(GetShapeTestResult) ~= "function" then
        return false, nil, nil, 0
    end

    local status, hit, endCoords, surfaceNormal, entityHit
    for _ = 1, 6 do
        status, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(handle)
        if status ~= 1 then
            break
        end

        Wait(0)
    end

    return hit == true or hit == 1, endCoords, surfaceNormal, entityHit or 0
end

local function raycastToGround(x, y, centerZ, ignoredEntity)
    RequestCollisionAtCoord(x, y, centerZ)
    Wait(0)

    if type(StartShapeTestRay) == "function" then
        local rayFlags = { RANDOM_SPAWN_GROUND_RAY_FLAGS, RANDOM_SPAWN_FALLBACK_GROUND_RAY_FLAGS }
        for _, flags in ipairs(rayFlags) do
            local rayHandle = StartShapeTestRay(
                x, y, centerZ + 150.0,
                x, y, centerZ - 150.0,
                flags,
                ignoredEntity or 0,
                0
            )
            local hit, endCoords, surfaceNormal, entityHit = readShapeTestResult(rayHandle)
            if hit and endCoords then
                return endCoords, surfaceNormal, entityHit
            end
        end
    end

    if type(GetGroundZAndNormalFor_3dCoord) == "function" then
        local foundGround, groundZ, surfaceNormal = GetGroundZAndNormalFor_3dCoord(x, y, centerZ + 80.0)
        if foundGround and groundZ then
            return vector3(x, y, groundZ + 0.0), surfaceNormal or vector3(0.0, 0.0, 1.0), 0
        end
    end

    if type(GetGroundZFor_3dCoord) == "function" then
        local foundGround, groundZ = GetGroundZFor_3dCoord(x, y, centerZ + 80.0, false)
        if foundGround and groundZ then
            return vector3(x, y, groundZ + 0.0), vector3(0.0, 0.0, 1.0), 0
        end
    end

    return nil, nil, 0
end

local function isPointInsideInterior(x, y, z)
    if type(GetInteriorAtCoords) ~= "function" then
        return false
    end

    local interiorId = GetInteriorAtCoords(x, y, z + 1.0)
    return interiorId and interiorId ~= 0
end

local function isPointNearWater(x, y, z)
    if type(GetWaterHeight) ~= "function" then
        return false
    end

    local ok, hasWater, waterZ = pcall(GetWaterHeight, x, y, z + 1.5)
    return ok and hasWater and waterZ and math.abs((waterZ + 0.0) - z) < 1.75
end

local function hasSpawnClearance(x, y, z, ignoredEntity)
    if type(StartShapeTestRay) ~= "function" then
        return true
    end

    local rayHandle = StartShapeTestRay(
        x, y, z + 0.35,
        x, y, z + 2.25,
        RANDOM_SPAWN_CLEARANCE_RAY_FLAGS,
        ignoredEntity or 0,
        0
    )
    local hit = readShapeTestResult(rayHandle)
    if hit then
        return false
    end

    return true
end

local function buildSafeRandomSpawnCandidate(rawX, rawY, centerZ, existingPoints, minDistance, ignoredEntity)
    local groundCoords, surfaceNormal = raycastToGround(rawX, rawY, centerZ, ignoredEntity)
    if not groundCoords then
        return nil
    end

    local x = groundCoords.x + 0.0
    local y = groundCoords.y + 0.0
    local z = groundCoords.z + 0.0
    if z < -80.0 then
        return nil
    end

    if surfaceNormal and surfaceNormal.z and surfaceNormal.z < 0.72 then
        return nil
    end

    if isPointInsideInterior(x, y, z) or isPointNearWater(x, y, z) then
        return nil
    end

    local coords = { x = x, y = y, z = z + 0.15 }
    if not isFarEnoughFromSpawnPoints(coords, existingPoints, minDistance) then
        return nil
    end

    if not hasSpawnClearance(x, y, z, ignoredEntity) then
        return nil
    end

    return coords
end

local function generateSafeRandomCustomArenaSpawns(count, minDistance)
    local ped = PlayerPedId()
    local center = GetEntityCoords(ped)
    local existingPoints = getCurrentCustomArenaSpawnPoints()
    local accepted = {}
    local attempts = count * RANDOM_SPAWN_ATTEMPTS_PER_POINT
    local baseRadius = math.max(minDistance * 2.0, minDistance * math.sqrt(count) * 1.85)

    math.randomseed((GetGameTimer() or 0) + math.floor(math.abs(center.x) * 10.0) + math.floor(math.abs(center.y) * 10.0))

    for attempt = 1, attempts do
        if #accepted >= count then
            break
        end

        local expansion = 1.0 + (math.floor(attempt / math.max(count * 28, 1)) * 0.35)
        local angle = math.random() * math.pi * 2.0
        local radius = minDistance + (math.sqrt(math.random()) * baseRadius * expansion)
        local rawX = center.x + (math.cos(angle) * radius)
        local rawY = center.y + (math.sin(angle) * radius)
        local candidate = buildSafeRandomSpawnCandidate(rawX, rawY, center.z, existingPoints, minDistance, ped)

        if candidate then
            accepted[#accepted + 1] = candidate
            existingPoints[#existingPoints + 1] = candidate
        end

        if attempt % 12 == 0 then
            Wait(0)
        end
    end

    return accepted
end

RegisterNetEvent("pvp:customArenaState")
AddEventHandler("pvp:customArenaState", function(data)
    PvpCustomArenaState = data or { active = false }
    SendNUIMessage({
        action = "updateCustomArenaState",
        payload = PvpCustomArenaState
    })
end)

RegisterNetEvent("pvp:savedCustomArenas")
AddEventHandler("pvp:savedCustomArenas", function(payload)
    SendNUIMessage({
        action = "savedCustomArenasData",
        payload = payload or {}
    })
end)

CreateThread(function()
    Wait(2500)
    TriggerServerEvent("pvp:requestSavedCustomArenas", false)
end)

RegisterNUICallback("requestSavedCustomArenas", function(_, cb)
    TriggerServerEvent("pvp:requestSavedCustomArenas", false)
    cb("ok")
end)

RegisterNUICallback("saveCustomArenaSlot", function(data, cb)
    local slot = data and tonumber(data.slot) or nil
    if not slot then
        cb("invalid")
        return
    end

    TriggerServerEvent("pvp:saveCustomArenaSlot", slot)
    cb("ok")
end)

RegisterNUICallback("restoreCustomArenaSlot", function(data, cb)
    local slot = data and tonumber(data.slot) or nil
    if not slot then
        cb("invalid")
        return
    end

    TriggerServerEvent("pvp:restoreCustomArenaSlot", slot)
    cb("ok")
end)

RegisterNUICallback("deleteSavedCustomArena", function(data, cb)
    local slot = data and tonumber(data.slot) or nil
    if not slot then
        cb("invalid")
        return
    end

    TriggerServerEvent("pvp:deleteSavedCustomArena", slot)
    cb("ok")
end)

RegisterNUICallback("createCustomArena", function(data, cb)
    local arenaName = data and tostring(data.name or "") or ""
    local maxPlayers = data and tonumber(data.maxPlayers) or nil
    local accessType = data and tostring(data.accessType or "private") or "private"

    TriggerServerEvent("pvp:createCustomArena", {
        name = arenaName,
        maxPlayers = maxPlayers,
        accessType = accessType
    })

    cb("ok")
end)

RegisterNUICallback("updateCustomArenaSettings", function(data, cb)
    local lobbyId = getActiveCustomArenaLobbyId()
    if not lobbyId then
        cb("inactive")
        return
    end

    TriggerServerEvent("pvp:updateCustomArenaSettings", {
        lobbyId = lobbyId,
        name = data and tostring(data.name or "") or "",
        maxPlayers = data and tonumber(data.maxPlayers) or nil,
        accessType = data and tostring(data.accessType or "private") or "private"
    })

    cb("ok")
end)

RegisterNUICallback("addCustomArenaSpawn", function(_, cb)
    local lobbyId = getActiveCustomArenaLobbyId()
    if not lobbyId then
        cb("inactive")
        return
    end

    local ped = PlayerPedId()
    if IsEntityDead(ped) or IsPedFatallyInjured(ped) then
        sendClientCustomArenaNotify("Invalid Spawn Point", "You must be alive to save a new spawn point.", "cross", 7000)
        cb("invalid")
        return
    end

    TriggerServerEvent("pvp:addCustomArenaSpawn", {
        lobbyId = lobbyId
    })

    cb("ok")
end)

RegisterCommand("addspawn", function()
    local lobbyId = getActiveCustomArenaLobbyId()
    if not lobbyId then
        sendClientCustomArenaNotify("Custom Spawn Point", "Join your custom arena before adding a spawn point.", "cross", 7000)
        return
    end

    local ped = PlayerPedId()
    if IsEntityDead(ped) or IsPedFatallyInjured(ped) then
        sendClientCustomArenaNotify("Invalid Spawn Point", "You must be alive to save a new spawn point.", "cross", 7000)
        return
    end

    TriggerServerEvent("pvp:addCustomArenaSpawn", {
        lobbyId = lobbyId
    })
end, false)
RegisterNUICallback("addRandomCustomArenaSpawns", function(data, cb)
    local lobbyId = getActiveCustomArenaLobbyId()
    if not lobbyId then
        cb("inactive")
        return
    end

    if not canManageActiveCustomArena() then
        cb("denied")
        return
    end

    local ped = PlayerPedId()
    if IsEntityDead(ped) or IsPedFatallyInjured(ped) then
        sendClientCustomArenaNotify("Invalid Spawn Points", "You must be alive to add random spawn points.", "cross", 7000)
        cb("invalid")
        return
    end

    local count = sanitizeRandomSpawnCount(data and data.count)
    local minDistance = sanitizeRandomSpawnDistance(data and data.minDistance)

    cb("ok")

    CreateThread(function()
        sendClientCustomArenaNotify("Random Spawn Points", "Searching for safe ground spawn points...", "tick", 5000)

        local spawnPoints = generateSafeRandomCustomArenaSpawns(count, minDistance)
        if #spawnPoints == 0 then
            sendClientCustomArenaNotify("Random Spawn Points", "No safe spawn points were found. Try a smaller distance or move to a more open area.", "cross", 9000)
            return
        end

        TriggerServerEvent("pvp:addRandomCustomArenaSpawns", {
            lobbyId = lobbyId,
            spawnPoints = spawnPoints,
            minDistance = minDistance
        })
    end)
end)

RegisterNUICallback("teleportCustomArenaSpawn", function(data, cb)
    if not canManageActiveCustomArena() then
        cb("denied")
        return
    end

    local spawnIndex = data and tonumber(data.index) or nil
    local spawnPoints = PvpCustomArenaState and PvpCustomArenaState.spawnPoints or nil
    local spawnPoint = spawnIndex and type(spawnPoints) == "table" and spawnPoints[spawnIndex] or nil
    if not spawnPoint then
        cb("invalid")
        return
    end

    local ped = PlayerPedId()
    if IsEntityDead(ped) or IsPedFatallyInjured(ped) then
        sendClientCustomArenaNotify("Teleport Blocked", "You must be alive to teleport to a spawn point.", "cross", 7000)
        cb("invalid")
        return
    end

    local x = tonumber(spawnPoint.x) or 0.0
    local y = tonumber(spawnPoint.y) or 0.0
    local z = tonumber(spawnPoint.z) or 0.0
    RequestCollisionAtCoord(x, y, z)
    SetEntityCoords(ped, x, y, z + 0.25, false, false, false, false)
    sendClientCustomArenaNotify("Spawn Point", "Teleported to spawn point " .. tostring(spawnIndex) .. ".", "tick", 5000)

    cb("ok")
end)

RegisterNUICallback("updateCustomArenaSpawn", function(data, cb)
    if not canManageActiveCustomArena() then
        cb("denied")
        return
    end

    local lobbyId = getActiveCustomArenaLobbyId()
    if not lobbyId then
        cb("inactive")
        return
    end

    local ped = PlayerPedId()
    if IsEntityDead(ped) or IsPedFatallyInjured(ped) then
        sendClientCustomArenaNotify("Invalid Spawn Point", "You must be alive to update a spawn point.", "cross", 7000)
        cb("invalid")
        return
    end

    TriggerServerEvent("pvp:updateCustomArenaSpawn", {
        lobbyId = lobbyId,
        index = data and tonumber(data.index) or nil
    })

    cb("ok")
end)

RegisterNUICallback("deleteCustomArenaSpawn", function(data, cb)
    if not canManageActiveCustomArena() then
        cb("denied")
        return
    end

    local lobbyId = getActiveCustomArenaLobbyId()
    if not lobbyId then
        cb("inactive")
        return
    end

    TriggerServerEvent("pvp:deleteCustomArenaSpawn", {
        lobbyId = lobbyId,
        index = data and tonumber(data.index) or nil
    })

    cb("ok")
end)

RegisterNUICallback("deleteCustomArena", function(data, cb)
    local lobbyId = data and tonumber(data.lobbyId) or (PvpCustomArenaState and tonumber(PvpCustomArenaState.lobbyId)) or nil
    if not lobbyId then
        cb("inactive")
        return
    end

    TriggerServerEvent("pvp:deleteCustomArena", {
        lobbyId = lobbyId
    })

    cb("ok")
end)

RegisterNUICallback("resetCustomArenaSpawns", function(_, cb)
    local lobbyId = getActiveCustomArenaLobbyId()
    if not lobbyId then
        cb("inactive")
        return
    end

    local ped = PlayerPedId()
    if IsEntityDead(ped) or IsPedFatallyInjured(ped) then
        sendClientCustomArenaNotify("Invalid Spawn Point", "You must be alive to reset the spawn points.", "cross", 7000)
        cb("invalid")
        return
    end

    TriggerServerEvent("pvp:resetCustomArenaSpawns", {
        lobbyId = lobbyId
    })

    cb("ok")
end)
