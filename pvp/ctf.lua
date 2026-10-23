Config = Config or {}
PvpCTFState = PvpCTFState or { active = false }

local DEFAULT_FLAG_MODEL = "mp001_p_mp_flag01x"
local DEFAULT_BLIP_SPRITE = "blip_mp_flag"
local DEFAULT_CARRIER_BLIP_SPRITE = "blip_mp_playlist_capture"
local DEFAULT_TEAMMATE_BLIP_SPRITE = "blip_ambient_ped_small"
local BLIP_MP_FLAG_HASH = -1595467349
local BLIP_MP_PLAYLIST_CAPTURE_HASH = 331074463
local BLIP_AMBIENT_PED_SMALL_HASH = 692310
local COORD_BLIP_TYPE = 1664425300
local MARKER_CYLINDER = 0x94FDAE17
local MARKER_DRAW_DISTANCE = 70.0
local ACTION_RETRY_COOLDOWN = 2600
local FLAG_ACTION_RETRY_COOLDOWN = 200
local FAR_SCAN_INTERVAL = 300
local FRIENDLY_FIRE_NOTIFY_COOLDOWN = 2500
local FRIENDLY_FIRE_HEALTH_SAMPLE_INTERVAL = 50
local FLAG_MODEL_FALLBACKS = {
    "mp001_p_mp_flag01x",
    "prop_fencepost_01a",
    "prop_fencewood_06",
    "s_prop_scaffolding_02a",
    "prop_cs_deathcart_01",
}
local FLAG_PROP_COLORS = {
    [1] = { r = 230, g = 60, b = 50 },
    [2] = { r = 60, g = 145, b = 255 },
}
local worldFlagObjects = {}
local carrierFlagObjects = {}
local baseBlips = {}
local carrierBlips = {}
local carrierBlipPeds = {}
local teammateBlips = {}
local teammateBlipPeds = {}
local lastActionKey = nil
local lastInteractAt = 0
local lastCarriedWorldCleanupAt = 0
local lastFriendlyFireHealth = nil
local lastFriendlyFireCoreHealth = nil
local friendlyFireNotifyCooldowns = {}
local groundedCoordsCache = {}

local function asNumber(value, fallback)
    return tonumber(value) or fallback or 0.0
end

local function normalizeCtfNotifyIcon(icon)
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

local function sendCtfNotify(title, description, icon, duration)
    TriggerEvent("bln_notify:send", {
        title = title,
        description = description,
        icon = normalizeCtfNotifyIcon(icon),
        placement = "middle-right",
        duration = duration or 6000
    })
end

local function hashName(value, fallback)
    if type(value) == "number" then
        return value
    end

    local text = tostring(value or fallback or "")
    if text == "" then
        return nil
    end

    if text == DEFAULT_BLIP_SPRITE then
        return BLIP_MP_FLAG_HASH
    end

    if text == DEFAULT_CARRIER_BLIP_SPRITE then
        return BLIP_MP_PLAYLIST_CAPTURE_HASH
    end

    if text == DEFAULT_TEAMMATE_BLIP_SPRITE then
        return BLIP_AMBIENT_PED_SMALL_HASH
    end

    if type(GetHashKey) == "function" then
        return GetHashKey(text)
    end

    return fallback
end

local function getVec(payload)
    if type(payload) ~= "table" or not payload.x then
        return nil
    end

    return vector3(asNumber(payload.x), asNumber(payload.y), asNumber(payload.z))
end

local function serializeCoords(coords)
    if not coords then
        return nil
    end

    return {
        x = coords.x,
        y = coords.y,
        z = coords.z
    }
end

local function getGroundedCoords(coords)
    if not coords then
        return nil
    end

    local key = string.format("%.1f:%.1f", coords.x or 0.0, coords.y or 0.0)
    local now = GetGameTimer()
    local cached = groundedCoordsCache[key]
    if cached and now - cached.at < 5000 then
        return vector3(coords.x, coords.y, cached.z)
    end

    local foundGround = false
    local groundZ = nil
    local probeZ = (coords.z or 0.0) + 80.0

    if type(GetGroundZAndNormalFor_3dCoord) == "function" then
        pcall(function()
            local found, z = GetGroundZAndNormalFor_3dCoord(coords.x, coords.y, probeZ)
            foundGround = found == true
            groundZ = tonumber(z)
        end)
    end

    if (not foundGround or not groundZ) and type(GetGroundZFor_3dCoord) == "function" then
        pcall(function()
            local found, z = GetGroundZFor_3dCoord(coords.x, coords.y, probeZ, false)
            foundGround = found == true
            groundZ = tonumber(z)
        end)
    end

    if foundGround and groundZ then
        groundedCoordsCache[key] = { z = groundZ + 0.02, at = now }
        return vector3(coords.x, coords.y, groundZ + 0.02)
    end

    return coords
end

local function getDistance(first, second)
    if not first or not second then
        return 999999.0
    end

    local dx = (first.x or 0.0) - (second.x or 0.0)
    local dy = (first.y or 0.0) - (second.y or 0.0)
    local dz = (first.z or 0.0) - (second.z or 0.0)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function hideEntity(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        return true
    end

    pcall(function()
        SetEntityAsMissionEntity(entity, true, true)
    end)
    pcall(function()
        DetachEntity(entity, true, true)
    end)
    pcall(function()
        SetEntityCollision(entity, false, false)
    end)
    pcall(function()
        FreezeEntityPosition(entity, true)
    end)
    pcall(function()
        SetEntityVisible(entity, false, false)
    end)
    pcall(function()
        SetEntityAlpha(entity, 0, false)
    end)
    pcall(function()
        SetEntityCoords(entity, 0.0, 0.0, -250.0, false, false, false, false)
    end)

    return true
end

local function deleteEntity(entity)
    if not entity or entity == 0 then
        return true
    end

    if not DoesEntityExist(entity) then
        return true
    end

    hideEntity(entity)
    pcall(function()
        DeleteObject(entity)
    end)
    pcall(function()
        DeleteEntity(entity)
    end)

    if DoesEntityExist(entity) then
        pcall(function()
            DeleteObject(entity)
        end)
        pcall(function()
            DeleteEntity(entity)
        end)
    end

    return true
end

local function clearWorldFlags()
    for key, entity in pairs(worldFlagObjects) do
        if deleteEntity(entity) then
            worldFlagObjects[key] = nil
        end
    end
end

local function clearCarrierFlags()
    for key, entity in pairs(carrierFlagObjects) do
        if deleteEntity(entity) then
            carrierFlagObjects[key] = nil
        end
    end
end

local function removeBlipHandle(blip)
    if not blip then
        return
    end

    pcall(function()
        RemoveBlip(blip)
    end)
end

local function clearBlips()
    for key, blip in pairs(baseBlips) do
        removeBlipHandle(blip)
        baseBlips[key] = nil
    end
end

local function clearCarrierBlips()
    for serverId, blip in pairs(carrierBlips) do
        removeBlipHandle(blip)
        carrierBlips[serverId] = nil
        carrierBlipPeds[serverId] = nil
    end
end

local function clearTeammateBlips()
    for serverId, blip in pairs(teammateBlips) do
        removeBlipHandle(blip)
        teammateBlips[serverId] = nil
        teammateBlipPeds[serverId] = nil
    end
end

local function cleanupCtfVisuals()
    clearWorldFlags()
    clearCarrierFlags()
    clearBlips()
    clearCarrierBlips()
    clearTeammateBlips()
end

local function requestModel(modelName)
    local modelHash = hashName(modelName, DEFAULT_FLAG_MODEL)
    if type(IsModelValid) == "function" and not IsModelValid(modelHash) then
        return nil
    end

    RequestModel(modelHash)
    local timeoutAt = GetGameTimer() + 5000
    while not HasModelLoaded(modelHash) and GetGameTimer() < timeoutAt do
        Wait(0)
    end

    if not HasModelLoaded(modelHash) then
        return nil
    end

    return modelHash
end

local function getFlagModelCandidates(modelName)
    local candidates = {}
    local seen = {}

    local function addCandidate(candidate)
        candidate = tostring(candidate or "")
        if candidate ~= "" and not seen[candidate] then
            seen[candidate] = true
            candidates[#candidates + 1] = candidate
        end
    end

    addCandidate(modelName)
    addCandidate(PvpCTFState.flagModel)
    for _, fallbackModel in ipairs(FLAG_MODEL_FALLBACKS) do
        addCandidate(fallbackModel)
    end

    return candidates
end

local function tintFlagObject(entity, teamId)
    local color = FLAG_PROP_COLORS[tonumber(teamId)]
    if entity and color and type(SetEntityRgba) == "function" then
        pcall(function()
            SetEntityRgba(entity, color.r, color.g, color.b, 255)
        end)
    end
end

local function placeFlagObject(entity, coords, teamId)
    if not entity or entity == 0 or not coords or not DoesEntityExist(entity) then
        return false
    end

    SetEntityAsMissionEntity(entity, true, true)
    SetEntityCollision(entity, false, false)
    FreezeEntityPosition(entity, true)
    pcall(function()
        SetEntityVisible(entity, true, false)
    end)
    pcall(function()
        SetEntityAlpha(entity, 255, false)
    end)
    SetEntityCoords(entity, coords.x, coords.y, coords.z, false, false, false, false)
    tintFlagObject(entity, teamId)
    return true
end

local function createFlagObject(coords, modelName, teamId, useGround)
    if not coords then
        return nil
    end

    local spawnCoords = useGround == true and getGroundedCoords(coords) or coords

    for _, candidate in ipairs(getFlagModelCandidates(modelName or DEFAULT_FLAG_MODEL)) do
        local modelHash = requestModel(candidate)
        if modelHash then
            local entity = nil
            local ok = pcall(function()
                entity = CreateObject(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false)
            end)

            if ok and entity and entity ~= 0 then
                placeFlagObject(entity, spawnCoords, teamId)
                SetModelAsNoLongerNeeded(modelHash)
                return entity
            end

            SetModelAsNoLongerNeeded(modelHash)
        end
    end

    return nil
end

local function isCarrierFlagEntity(entity)
    if not entity or entity == 0 then
        return false
    end

    for _, carrierEntity in pairs(carrierFlagObjects) do
        if carrierEntity == entity then
            return true
        end
    end

    if type(IsEntityAttached) == "function" then
        local attached = false
        pcall(function()
            attached = IsEntityAttached(entity)
        end)
        if attached then
            return true
        end
    end

    return false
end

local function deleteNearbyFlagObjects(coords, modelName)
    if not coords or type(GetClosestObjectOfType) ~= "function" then
        return
    end

    for _, candidate in ipairs(getFlagModelCandidates(modelName or DEFAULT_FLAG_MODEL)) do
        local modelHash = hashName(candidate, DEFAULT_FLAG_MODEL)
        if modelHash then
            for _ = 1, 6 do
                local entity = nil
                local ok = pcall(function()
                    entity = GetClosestObjectOfType(coords.x, coords.y, coords.z, 3.0, modelHash, false, false, false)
                end)

                if not ok or not entity or entity == 0 or not DoesEntityExist(entity) then
                    break
                end

                if isCarrierFlagEntity(entity) then
                    break
                end

                deleteEntity(entity)
            end
        end
    end
end

local function getFlagWorldCoords(flag)
    if not flag then
        return nil
    end

    if flag.status == "dropped" then
        return getVec(flag.dropCoords)
    end

    return getVec(flag.base)
end

local function getFlagObjectCoords(flag)
    local coords = getGroundedCoords(getFlagWorldCoords(flag))
    if not coords then
        return nil
    end

    local offset = asNumber(flag and flag.groundOffset, 0.0)
    if offset == 0.0 then
        return coords
    end

    return vector3(coords.x, coords.y, coords.z + offset)
end

local function rebuildWorldFlagObjects()
    clearWorldFlags()

    if not PvpCTFState.active or type(PvpCTFState.flags) ~= "table" then
        return
    end

    for flagTeamId, flag in pairs(PvpCTFState.flags) do
        if flag.status ~= "carried" then
            local coords = getFlagObjectCoords(flag)
            local key = tonumber(flagTeamId) or flagTeamId
            local existing = worldFlagObjects[key]
            local entity = nil

            if existing and coords and placeFlagObject(existing, coords, flagTeamId) then
                entity = existing
            else
                entity = coords and createFlagObject(coords, flag.flagModel, flagTeamId, false) or nil
            end

            if entity then
                worldFlagObjects[key] = entity
            end
        end
    end
end

local function removeCarriedWorldFlags(force)
    if type(PvpCTFState.flags) ~= "table" then
        return
    end

    local now = GetGameTimer()
    if force ~= true and now - lastCarriedWorldCleanupAt < 1000 then
        return
    end
    lastCarriedWorldCleanupAt = now

    for flagTeamId, flag in pairs(PvpCTFState.flags) do
        if flag.status == "carried" then
            local key = tonumber(flagTeamId) or flagTeamId
            local homeCoords = getGroundedCoords(getVec(flag.base))
            if not homeCoords and PvpCTFState.bases and PvpCTFState.bases[key] then
                homeCoords = getGroundedCoords(getVec(PvpCTFState.bases[key].coords))
            end

            deleteNearbyFlagObjects(homeCoords, flag.flagModel)

            if worldFlagObjects[key] and deleteEntity(worldFlagObjects[key]) then
                worldFlagObjects[key] = nil
            end
        end
    end
end

local function applyBlipLabel(blip, label)
    if not blip then
        return
    end

    pcall(function()
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, label)
    end)

    if type(BeginTextCommandSetBlipName) == "function" then
        pcall(function()
            BeginTextCommandSetBlipName("STRING")
            if type(AddTextComponentString) == "function" then
                AddTextComponentString(label)
            end
            if type(EndTextCommandSetBlipName) == "function" then
                EndTextCommandSetBlipName(blip)
            end
        end)
    end
end

local function applyBlipStyle(blip, base, teamId)
    if not blip then
        return
    end

    local scale = asNumber(base and base.blipScale, 1.25)
    local color = tonumber(base and base.blipColor)
    local modifier = base and base.blipModifier or nil

    if type(SetBlipScale) == "function" then
        pcall(function()
            SetBlipScale(blip, scale)
        end)
    end

    if color and type(SetBlipColour) == "function" then
        pcall(function()
            SetBlipColour(blip, color)
        end)
    end

    if modifier then
        local modifierHash = hashName(modifier)
        if modifierHash then
            pcall(function()
                Citizen.InvokeNative(0x662D364ABF16DE2F, blip, modifierHash)
            end)
        end
    end
end

local function setBlipSprite(blip, spriteHash)
    if not blip or not spriteHash then
        return
    end

    if type(SetBlipSprite) == "function" then
        pcall(function()
            SetBlipSprite(blip, spriteHash, true)
        end)
        pcall(function()
            SetBlipSprite(blip, spriteHash, 1)
        end)
        pcall(function()
            SetBlipSprite(blip, spriteHash)
        end)
    end
end

local function isValidBlipHandle(blip)
    return blip ~= nil and blip ~= 0
end

local function createCoordBlip(coords, spriteHash)
    local blip = nil

    if type(BlipAddForCoords) == "function" then
        pcall(function()
            blip = BlipAddForCoords(COORD_BLIP_TYPE, coords.x, coords.y, coords.z)
        end)
        if isValidBlipHandle(blip) then
            return blip
        end
    end

    pcall(function()
        blip = Citizen.InvokeNative(0x554D9D53F696D002, COORD_BLIP_TYPE, coords.x, coords.y, coords.z)
    end)
    if isValidBlipHandle(blip) then
        return blip
    end

    pcall(function()
        blip = Citizen.InvokeNative(0x554D9D53F696D002, COORD_BLIP_TYPE, vector3(coords.x, coords.y, coords.z))
    end)
    if isValidBlipHandle(blip) then
        return blip
    end

    pcall(function()
        blip = Citizen.InvokeNative(0x554D9D53F696D002, spriteHash, coords.x, coords.y, coords.z)
    end)
    if isValidBlipHandle(blip) then
        return blip
    end

    if type(AddBlipForCoord) == "function" then
        pcall(function()
            blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        end)
    end

    return blip
end

local function createEntityBlip(entity, spriteHash)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        return nil
    end

    local blip = nil
    if type(BlipAddForEntity) == "function" then
        pcall(function()
            blip = BlipAddForEntity(COORD_BLIP_TYPE, entity)
        end)
        if isValidBlipHandle(blip) then
            return blip
        end
    end

    pcall(function()
        blip = Citizen.InvokeNative(0x23F74C2FDA6E7C61, COORD_BLIP_TYPE, entity)
    end)
    if isValidBlipHandle(blip) then
        return blip
    end

    pcall(function()
        blip = Citizen.InvokeNative(0x23F74C2FDA6E7C61, spriteHash, entity)
    end)

    return blip
end

local function createBaseBlip(teamId, base)
    if not base or not base.coords then
        return nil
    end

    local coords = getVec(base.coords)
    if not coords then
        return nil
    end

    local label = tostring(base.blipName or base.label or ("Team " .. tostring(teamId) .. " Base"))
    local spriteHash = hashName(base.blipSprite or DEFAULT_BLIP_SPRITE, BLIP_MP_FLAG_HASH)
    local blip = createCoordBlip(coords, spriteHash)

    if isValidBlipHandle(blip) then
        setBlipSprite(blip, spriteHash)
        applyBlipLabel(blip, label)
        applyBlipStyle(blip, base, teamId)
        return blip
    end

    return blip
end

local function shouldShowBaseBlip(teamId)
    if PvpCTFState.isCarrier == true then
        local carriedFlagTeamId = tonumber(PvpCTFState.carriedFlagTeamId)
        if carriedFlagTeamId and carriedFlagTeamId == tonumber(teamId) then
            return false
        end
    end

    return true
end

local function rebuildBaseBlips()
    clearBlips()

    if not PvpCTFState.active or type(PvpCTFState.bases) ~= "table" then
        return
    end

    for teamId, base in pairs(PvpCTFState.bases) do
        if shouldShowBaseBlip(teamId) then
            baseBlips[teamId] = createBaseBlip(teamId, base)
        end
    end
end

local function getMarkerColor(teamId)
    local base = PvpCTFState.bases and PvpCTFState.bases[teamId] or nil
    local marker = base and base.marker or nil
    if type(marker) == "table" and marker.r then
        return marker.r or 255, marker.g or 255, marker.b or 255
    end

    if tonumber(teamId) == 1 then
        return 230, 60, 50
    end

    return 60, 145, 255
end

local function drawCylinder(coords, radius, r, g, b, alpha)
    if not coords then
        return
    end

    local pulse = 0.78 + (0.22 * math.sin((GetGameTimer() % 1400) / 1400 * 6.28318))
    local markerAlpha = math.floor((alpha or 90) * pulse)

    Citizen.InvokeNative(
        0x2A32FAA57B937173,
        MARKER_CYLINDER,
        coords.x,
        coords.y,
        coords.z - 0.95,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        radius * 2.0,
        radius * 2.0,
        0.35,
        r,
        g,
        b,
        markerAlpha,
        false,
        false,
        2,
        false,
        nil,
        nil,
        false
    )
end

local function attachFlagToPed(serverId, modelName, flagTeamId)
    serverId = tonumber(serverId)
    if not serverId then
        return
    end

    local playerIndex = GetPlayerFromServerId(serverId)
    if not playerIndex or playerIndex == -1 then
        return
    end

    local ped = GetPlayerPed(playerIndex)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return
    end

    local existing = carrierFlagObjects[serverId]
    if existing and DoesEntityExist(existing) then
        if type(IsEntityAttachedToEntity) == "function" and IsEntityAttachedToEntity(existing, ped) then
            return
        end
        deleteEntity(existing)
        carrierFlagObjects[serverId] = nil
    end

    local coords = GetEntityCoords(ped)
    local entity = createFlagObject(coords, modelName, flagTeamId, false)
    if not entity then
        return
    end

    FreezeEntityPosition(entity, false)
    local boneIndex = GetEntityBoneIndexByName(ped, "SKEL_Spine2")
    if not boneIndex or boneIndex == -1 then
        boneIndex = 0
    end

    AttachEntityToEntity(
        entity,
        ped,
        boneIndex,
        0.11,
        -0.08,
        0.04,
        4.0,
        82.0,
        2.0,
        true,
        true,
        false,
        true,
        1,
        true
    )

    carrierFlagObjects[serverId] = entity
end

local function syncCarrierFlagObjects()
    local expected = {}
    if PvpCTFState.active and type(PvpCTFState.flags) == "table" then
        for _, flag in pairs(PvpCTFState.flags) do
            if flag.status == "carried" and flag.carrier then
                local serverId = tonumber(flag.carrier)
                if serverId then
                    expected[serverId] = true
                    attachFlagToPed(serverId, flag.flagModel, flag.teamId)
                end
            end
        end
    end

    for serverId, entity in pairs(carrierFlagObjects) do
        if not expected[serverId] then
            deleteEntity(entity)
            carrierFlagObjects[serverId] = nil
        end
    end
end

local function drawBaseMarkers(playerCoords)
    if not PvpCTFState.active or type(PvpCTFState.bases) ~= "table" then
        return false
    end

    local didDraw = false
    local captureRadius = asNumber(PvpCTFState.captureRadius, 4.0)
    for teamId, base in pairs(PvpCTFState.bases) do
        local coords = getVec(base.coords)
        if coords and (not playerCoords or getDistance(playerCoords, coords) <= MARKER_DRAW_DISTANCE) then
            local r, g, b = getMarkerColor(tonumber(teamId) or teamId)
            drawCylinder(coords, captureRadius, r, g, b, 72)
            didDraw = true
        end
    end

    return didDraw
end

local function drawFlagMarkers(playerCoords)
    if not PvpCTFState.active or type(PvpCTFState.flags) ~= "table" then
        return false
    end

    local didDraw = false
    local pickupRadius = asNumber(PvpCTFState.pickupRadius, 2.4)
    for flagTeamId, flag in pairs(PvpCTFState.flags) do
        if flag.status ~= "carried" then
            local coords = getFlagWorldCoords(flag)
            if coords and (not playerCoords or getDistance(playerCoords, coords) <= MARKER_DRAW_DISTANCE) then
                local r, g, b = getMarkerColor(tonumber(flagTeamId) or flagTeamId)
                drawCylinder(coords, pickupRadius, r, g, b, flag.status == "dropped" and 130 or 105)
                didDraw = true
            end
        end
    end

    return didDraw
end

local function getLocalTeamId()
    return tonumber(PvpCTFState.teamId or (PvpTeamArenaState and PvpTeamArenaState.teamId) or 0)
end

local function isCtfFriendlyFireProtectionActive()
    local teamId = getLocalTeamId()
    return PvpCTFState
        and PvpCTFState.active == true
        and PvpCTFState.matchActive == true
        and (teamId == 1 or teamId == 2)
end

local function getLocalPlayerServerId()
    if type(PlayerId) ~= "function" or type(GetPlayerServerId) ~= "function" then
        return nil
    end

    local serverId = nil
    pcall(function()
        serverId = tonumber(GetPlayerServerId(PlayerId()))
    end)

    return serverId
end

local function isLocalPlayerServerId(serverId)
    serverId = tonumber(serverId)
    if not serverId or serverId <= 0 then
        return false
    end

    local ownServerId = getLocalPlayerServerId()
    if ownServerId and ownServerId == serverId then
        return true
    end

    if type(PlayerId) == "function" and type(GetPlayerFromServerId) == "function" then
        local ownPlayerIndex = PlayerId()
        local playerIndex = GetPlayerFromServerId(serverId)
        if playerIndex and playerIndex ~= -1 and playerIndex == ownPlayerIndex then
            return true
        end
    end

    return false
end

local function getTeamPayloadById(teamId)
    local teams = PvpTeamArenaState and PvpTeamArenaState.teams or nil
    if type(teams) ~= "table" then
        return nil
    end

    return teams[teamId] or teams[tostring(teamId)]
end

local function isLocalCtfTeammate(serverId)
    serverId = tonumber(serverId)
    if not serverId or serverId <= 0 or isLocalPlayerServerId(serverId) then
        return false
    end

    local teamId = getLocalTeamId()
    local team = getTeamPayloadById(teamId)
    if type(team) == "table" and type(team.members) == "table" then
        for _, member in pairs(team.members) do
            if tonumber(member and member.serverId) == serverId then
                return true
            end
        end
    end

    local ctfTeamMembers = PvpCTFState and PvpCTFState.teamMembers or nil
    if type(ctfTeamMembers) == "table" then
        for _, memberId in pairs(ctfTeamMembers) do
            if tonumber(memberId) == serverId then
                return true
            end
        end
    end

    return false
end

local function getPlayerPedFromServerId(serverId)
    serverId = tonumber(serverId)
    if not serverId then
        return nil
    end

    local playerIndex = GetPlayerFromServerId(serverId)
    if not playerIndex or playerIndex == -1 then
        return nil
    end

    local ped = GetPlayerPed(playerIndex)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return nil
    end

    return ped
end

local function shouldShowCarrierBlip(flag)
    if not PvpCTFState.active or not PvpCTFState.matchActive or not flag or flag.status ~= "carried" then
        return false
    end

    if PvpCTFState.isCarrier == true then
        return false
    end

    local carrier = tonumber(flag.carrier)
    if isLocalPlayerServerId(carrier) or not isLocalCtfTeammate(carrier) then
        return false
    end

    local localTeamId = getLocalTeamId()
    local flagTeamId = tonumber(flag.teamId)
    if flagTeamId and localTeamId and flagTeamId == localTeamId then
        return false
    end

    return true
end

local function isActiveBlip(blip)
    if not isValidBlipHandle(blip) then
        return false
    end

    if type(DoesBlipExist) == "function" then
        local ok, exists = pcall(DoesBlipExist, blip)
        if ok then
            return exists == true
        end
    end

    return true
end

local function removeCarrierBlip(serverId)
    local blip = carrierBlips[serverId]
    if blip then
        removeBlipHandle(blip)
    end

    carrierBlips[serverId] = nil
    carrierBlipPeds[serverId] = nil
end

local function createCarrierBlip(serverId, flag)
    local ped = getPlayerPedFromServerId(serverId)
    if not ped then
        return nil, nil
    end

    local spriteHash = hashName(DEFAULT_CARRIER_BLIP_SPRITE, BLIP_MP_PLAYLIST_CAPTURE_HASH)
    local blip = createEntityBlip(ped, spriteHash)
    if isValidBlipHandle(blip) then
        setBlipSprite(blip, spriteHash)
        applyBlipLabel(blip, tostring(flag.carrierName or "Flag Carrier"))
        applyBlipStyle(blip, { blipScale = 1.25 }, getLocalTeamId())
        return blip, ped
    end

    return blip, ped
end

local function syncCarrierBlips()
    local expected = {}
    if PvpCTFState.active and type(PvpCTFState.flags) == "table" then
        for _, flag in pairs(PvpCTFState.flags) do
            local serverId = tonumber(flag and flag.carrier)
            if serverId and shouldShowCarrierBlip(flag) then
                expected[serverId] = true

                local ped = getPlayerPedFromServerId(serverId)
                local blip = carrierBlips[serverId]
                if not ped then
                    removeCarrierBlip(serverId)
                elseif not isActiveBlip(blip) or carrierBlipPeds[serverId] ~= ped then
                    removeCarrierBlip(serverId)
                    local newBlip, newPed = createCarrierBlip(serverId, flag)
                    if isValidBlipHandle(newBlip) then
                        carrierBlips[serverId] = newBlip
                        carrierBlipPeds[serverId] = newPed
                    end
                else
                    applyBlipLabel(blip, tostring(flag.carrierName or "Flag Carrier"))
                end
            end
        end
    end

    local stale = {}
    for serverId in pairs(carrierBlips) do
        if not expected[serverId] then
            stale[#stale + 1] = serverId
        end
    end

    for _, serverId in ipairs(stale) do
        removeCarrierBlip(serverId)
    end
end

local function isCarrierMarkedWithCaptureBlip(serverId)
    if not PvpCTFState.active or type(PvpCTFState.flags) ~= "table" then
        return false
    end

    serverId = tonumber(serverId)
    if not serverId then
        return false
    end

    for _, flag in pairs(PvpCTFState.flags) do
        if tonumber(flag and flag.carrier) == serverId and shouldShowCarrierBlip(flag) then
            return true
        end
    end

    return false
end

local function removeTeammateBlip(serverId)
    local blip = teammateBlips[serverId]
    if blip then
        removeBlipHandle(blip)
    end

    teammateBlips[serverId] = nil
    teammateBlipPeds[serverId] = nil
end

local function getTeammateBlipLabel(serverId)
    local playerIndex = GetPlayerFromServerId(tonumber(serverId) or -1)
    if playerIndex and playerIndex ~= -1 and type(GetPlayerName) == "function" then
        local name = GetPlayerName(playerIndex)
        if name and tostring(name) ~= "" then
            return tostring(name)
        end
    end

    return "Teammate"
end

local function createTeammateBlip(serverId)
    local ped = getPlayerPedFromServerId(serverId)
    if not ped then
        return nil, nil
    end

    local spriteHash = hashName(DEFAULT_TEAMMATE_BLIP_SPRITE, BLIP_AMBIENT_PED_SMALL_HASH)
    local blip = createEntityBlip(ped, spriteHash)
    if isValidBlipHandle(blip) then
        setBlipSprite(blip, spriteHash)
        applyBlipLabel(blip, getTeammateBlipLabel(serverId))
        applyBlipStyle(blip, { blipScale = 0.85 }, getLocalTeamId())
        return blip, ped
    end

    return blip, ped
end

local function syncTeammateBlips()
    local expected = {}
    if PvpCTFState.active and type(PvpCTFState.teamMembers) == "table" then
        for _, memberId in pairs(PvpCTFState.teamMembers) do
            local serverId = tonumber(memberId)
            if serverId and not isLocalPlayerServerId(serverId) and not isCarrierMarkedWithCaptureBlip(serverId) then
                expected[serverId] = true

                local ped = getPlayerPedFromServerId(serverId)
                local blip = teammateBlips[serverId]
                if not ped then
                    removeTeammateBlip(serverId)
                elseif not isActiveBlip(blip) or teammateBlipPeds[serverId] ~= ped then
                    removeTeammateBlip(serverId)
                    local newBlip, newPed = createTeammateBlip(serverId)
                    if isValidBlipHandle(newBlip) then
                        teammateBlips[serverId] = newBlip
                        teammateBlipPeds[serverId] = newPed
                    end
                else
                    applyBlipLabel(blip, getTeammateBlipLabel(serverId))
                end
            end
        end
    end

    local stale = {}
    for serverId in pairs(teammateBlips) do
        if not expected[serverId] then
            stale[#stale + 1] = serverId
        end
    end

    for _, serverId in ipairs(stale) do
        removeTeammateBlip(serverId)
    end
end

local function resolveCtfDamageEntity(value)
    local numericValue = tonumber(value)
    if not numericValue or numericValue == 0 then
        return nil
    end

    if DoesEntityExist(numericValue) then
        return numericValue
    end

    if type(NetworkGetEntityFromNetworkId) == "function" then
        local ok, entity = pcall(NetworkGetEntityFromNetworkId, numericValue)
        if ok and entity and entity ~= 0 and DoesEntityExist(entity) then
            return entity
        end
    end

    return nil
end

local function getServerIdFromDamageEntity(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        return nil
    end

    if type(IsEntityAPed) == "function" and not IsEntityAPed(entity) then
        return nil
    end

    local playerIndex = NetworkGetPlayerIndexFromPed(entity)
    if not playerIndex or playerIndex == -1 then
        return nil
    end

    local serverId = GetPlayerServerId(playerIndex)
    return serverId and serverId > 0 and serverId or nil
end

local function getCtfPedCoreHealth(ped)
    if not ped or ped == 0 then
        return nil
    end

    local coreHealth = nil
    pcall(function()
        coreHealth = Citizen.InvokeNative(0x36731AC041289BB1, ped, 0, 0, Citizen.ResultAsFloat())
    end)

    return tonumber(coreHealth)
end

local function setCtfPedCoreHealth(ped, value)
    value = tonumber(value)
    if not ped or ped == 0 or not value then
        return
    end

    pcall(function()
        Citizen.InvokeNative(0xC6258F41D86676E0, ped, 0, math.min(value, 1000.0))
    end)
end

local function updateCtfFriendlyFireHealthBaseline(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return
    end

    lastFriendlyFireHealth = GetEntityHealth(ped)
    lastFriendlyFireCoreHealth = getCtfPedCoreHealth(ped)
end

local function resetCtfFriendlyFireProtectionState()
    lastFriendlyFireHealth = nil
    lastFriendlyFireCoreHealth = nil
    friendlyFireNotifyCooldowns = {}
end

local function getFriendlyFireAttackerServerId(args, victimPed)
    if type(args) ~= "table" then
        return nil
    end

    local directAttacker = resolveCtfDamageEntity(args[2])
    local directServerId = getServerIdFromDamageEntity(directAttacker)
    if directServerId then
        return directServerId
    end

    for _, value in pairs(args) do
        local entity = resolveCtfDamageEntity(value)
        if entity and entity ~= victimPed then
            local serverId = getServerIdFromDamageEntity(entity)
            if serverId then
                return serverId
            end
        end
    end

    return nil
end

local function restoreCtfFriendlyFireDamage(ped)
    local currentHealth = GetEntityHealth(ped)
    local targetHealth = tonumber(lastFriendlyFireHealth) or currentHealth
    targetHealth = math.max(targetHealth, currentHealth)

    if targetHealth > currentHealth then
        SetEntityHealth(ped, targetHealth)
    end

    local currentCoreHealth = getCtfPedCoreHealth(ped)
    local targetCoreHealth = tonumber(lastFriendlyFireCoreHealth)
    if currentCoreHealth and targetCoreHealth and targetCoreHealth > currentCoreHealth then
        setCtfPedCoreHealth(ped, targetCoreHealth)
    end

    pcall(function()
        ClearEntityLastDamageEntity(ped)
    end)
    pcall(function()
        ClearPedLastDamageBone(ped)
    end)

    updateCtfFriendlyFireHealthBaseline(ped)
end

local function notifyCtfFriendlyFireBlocked(attackerServerId)
    attackerServerId = tonumber(attackerServerId)
    if not attackerServerId then
        return
    end

    local now = GetGameTimer()
    local lastNotifyAt = friendlyFireNotifyCooldowns[attackerServerId] or 0
    if now - lastNotifyAt < FRIENDLY_FIRE_NOTIFY_COOLDOWN then
        return
    end

    friendlyFireNotifyCooldowns[attackerServerId] = now
    TriggerServerEvent("pvp:ctfFriendlyFireBlocked", attackerServerId)
end

local function findNearbyAction(playerCoords)
    if not PvpCTFState.active or not PvpCTFState.matchActive then
        return nil
    end

    local teamId = getLocalTeamId()
    if teamId ~= 1 and teamId ~= 2 then
        return nil
    end

    local coords = playerCoords
    if not coords then
        local ped = PlayerPedId()
        if not ped or ped == 0 then
            return nil
        end

        coords = GetEntityCoords(ped)
    end

    if PvpCTFState.isCarrier then
        local ownBase = PvpCTFState.bases and PvpCTFState.bases[teamId] or nil
        local baseCoords = ownBase and getVec(ownBase.coords) or nil
        if baseCoords and getDistance(coords, baseCoords) <= asNumber(PvpCTFState.captureRadius, 4.0) then
            local ownFlag = PvpCTFState.flags and PvpCTFState.flags[teamId] or nil
            return {
                key = "capture:" .. tostring(teamId) .. ":" .. tostring(PvpCTFState.carriedFlagTeamId) .. ":" .. tostring(ownFlag and ownFlag.status or "none"),
                serverAction = "capture",
                cooldown = FLAG_ACTION_RETRY_COOLDOWN
            }
        end
        return nil
    end

    local ownFlag = PvpCTFState.flags and PvpCTFState.flags[teamId] or nil
    if ownFlag and ownFlag.status == "dropped" then
        local dropCoords = getVec(ownFlag.dropCoords)
        if dropCoords and getDistance(coords, dropCoords) <= asNumber(PvpCTFState.returnRadius, 2.8) then
            return {
                key = "return:" .. tostring(teamId) .. ":" .. tostring(ownFlag.returnAt or "manual"),
                serverAction = "return",
                cooldown = FLAG_ACTION_RETRY_COOLDOWN
            }
        end
    end

    local enemyTeamId = teamId == 1 and 2 or 1
    local enemyFlag = PvpCTFState.flags and PvpCTFState.flags[enemyTeamId] or nil
    if enemyFlag and enemyFlag.status ~= "carried" then
        local targetCoords = getFlagWorldCoords(enemyFlag)
        if targetCoords and getDistance(coords, targetCoords) <= asNumber(PvpCTFState.pickupRadius, 2.4) then
            return {
                key = "pickup:" .. tostring(enemyTeamId) .. ":" .. tostring(enemyFlag.status) .. ":" .. tostring(enemyFlag.returnAt or "home"),
                serverAction = "pickup",
                cooldown = FLAG_ACTION_RETRY_COOLDOWN
            }
        end
    end

    return nil
end

local function findNearbyContextAction(playerCoords)
    if not PvpCTFState.active or not PvpCTFState.matchActive then
        return nil
    end

    local teamId = getLocalTeamId()
    if teamId ~= 1 and teamId ~= 2 then
        return nil
    end

    local coords = playerCoords
    if not coords then
        local ped = PlayerPedId()
        if not ped or ped == 0 then
            return nil
        end

        coords = GetEntityCoords(ped)
    end

    local captureRadius = asNumber(PvpCTFState.captureRadius, 4.0) + 0.75
    local pickupRadius = asNumber(PvpCTFState.pickupRadius, 2.4) + 0.75
    local returnRadius = asNumber(PvpCTFState.returnRadius, 2.8) + 0.75
    local maxBaseRadius = math.max(captureRadius, pickupRadius, returnRadius)

    if type(PvpCTFState.bases) == "table" then
        for baseTeamId, base in pairs(PvpCTFState.bases) do
            local baseCoords = getVec(base.coords)
            if baseCoords and getDistance(coords, baseCoords) <= maxBaseRadius then
                return {
                    key = "context:base:" .. tostring(baseTeamId) .. ":" .. tostring(PvpCTFState.isCarrier) .. ":" .. tostring(PvpCTFState.carriedFlagTeamId or "none"),
                    serverAction = "context",
                    cooldown = FLAG_ACTION_RETRY_COOLDOWN
                }
            end
        end
    end

    if type(PvpCTFState.flags) == "table" then
        for flagTeamId, flag in pairs(PvpCTFState.flags) do
            if flag.status ~= "carried" then
                local flagCoords = getFlagWorldCoords(flag)
                if flagCoords and getDistance(coords, flagCoords) <= math.max(pickupRadius, returnRadius) then
                    return {
                        key = "context:flag:" .. tostring(flagTeamId) .. ":" .. tostring(flag.status or "home") .. ":" .. tostring(flag.returnAt or "none"),
                        serverAction = "context",
                        cooldown = FLAG_ACTION_RETRY_COOLDOWN
                    }
                end
            end
        end
    end

    return nil
end

AddEventHandler("gameEventTriggered", function(eventName, args)
    if eventName ~= "CEventNetworkEntityDamage" or not isCtfFriendlyFireProtectionActive() then
        return
    end

    local ped = PlayerPedId()
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return
    end

    local victimEntity = resolveCtfDamageEntity(args and args[1] or nil)
    if victimEntity ~= ped then
        return
    end

    local attackerServerId = getFriendlyFireAttackerServerId(args, ped)
    if not attackerServerId or not isLocalCtfTeammate(attackerServerId) then
        updateCtfFriendlyFireHealthBaseline(ped)
        return
    end

    restoreCtfFriendlyFireDamage(ped)
    notifyCtfFriendlyFireBlocked(attackerServerId)
end)

RegisterNetEvent("pvp:ctfState")
AddEventHandler("pvp:ctfState", function(payload)
    PvpCTFState = payload or { active = false }
    lastActionKey = nil
    if not PvpCTFState.active then
        resetCtfFriendlyFireProtectionState()
        cleanupCtfVisuals()
        return
    end

    local ped = PlayerPedId()
    if ped and ped ~= 0 and DoesEntityExist(ped) then
        updateCtfFriendlyFireHealthBaseline(ped)
    end

    rebuildBaseBlips()
    rebuildWorldFlagObjects()
    removeCarriedWorldFlags(true)
    syncCarrierFlagObjects()
    syncCarrierBlips()
    syncTeammateBlips()
end)

RegisterNetEvent("pvp:clearClientLobby")
AddEventHandler("pvp:clearClientLobby", function()
    PvpCTFState = { active = false }
    lastActionKey = nil
    resetCtfFriendlyFireProtectionState()
    cleanupCtfVisuals()
end)

RegisterCommand("ctfcoords", function()
    local ped = PlayerPedId()
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        sendCtfNotify("CTF Coords", "Could not read your current position.", "cross", 6000)
        return
    end

    local coords = GetEntityCoords(ped)
    local text = string.format("vector3(%.2f, %.2f, %.2f)", coords.x, coords.y, coords.z)

    if Citizen and Citizen.Trace then
        Citizen.Trace("[PvP CTF] " .. text .. "\n")
    end

    TriggerEvent("chat:addMessage", {
        color = { 60, 145, 255 },
        multiline = true,
        args = { "CTF", text }
    })
    sendCtfNotify("CTF Coords", text, "tick", 10000)
end)

CreateThread(function()
    while true do
        if isCtfFriendlyFireProtectionActive() then
            local ped = PlayerPedId()
            if ped and ped ~= 0 and DoesEntityExist(ped) and not IsEntityDead(ped) and not IsPedFatallyInjured(ped) then
                updateCtfFriendlyFireHealthBaseline(ped)
            end
            Wait(FRIENDLY_FIRE_HEALTH_SAMPLE_INTERVAL)
        else
            resetCtfFriendlyFireProtectionState()
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        if not PvpCTFState.active then
            Wait(1000)
        else
            removeCarriedWorldFlags()

            local ped = PlayerPedId()
            local coords = ped and ped ~= 0 and GetEntityCoords(ped) or nil
            local drewBase = drawBaseMarkers(coords)
            local drewFlag = drawFlagMarkers(coords)
            local action = findNearbyAction(coords) or findNearbyContextAction(coords)

            if action then
                local now = GetGameTimer()
                if action.key ~= lastActionKey or now - lastInteractAt > (action.cooldown or ACTION_RETRY_COOLDOWN) then
                    lastActionKey = action.key
                    lastInteractAt = GetGameTimer()
                    TriggerServerEvent("pvp:ctfInteract", action.serverAction or "context", serializeCoords(coords))
                end
                Wait(0)
            elseif drewBase or drewFlag then
                lastActionKey = nil
                Wait(0)
            else
                lastActionKey = nil
                Wait(FAR_SCAN_INTERVAL)
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(PvpCTFState.active and 1000 or 2500)
        syncCarrierFlagObjects()
        syncCarrierBlips()
        syncTeammateBlips()
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    cleanupCtfVisuals()
end)
