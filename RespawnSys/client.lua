local VorpCore = {}
TriggerEvent("getCore", function(core) VorpCore = core end)

local respawnKey = 0xCEFD9220 -- E
local spectateKey = 0x760A9C6F -- G
local chatOpenControl = `INPUT_MP_TEXT_CHAT_ALL`
local lookLeftRightControl = 0xA987235F
local lookUpDownControl = 0xD2047988
local spectatorExitKeys = {
    0x156F7119, -- ESC / Frontend pause
    0x4AF4D473  -- Frontend pause alternate
}
local spectatorSwitchKey = 0xD9D0E1C0 -- SPACE / INPUT_JUMP
local deathNuiZIndex = 0
local deathNuiChatZIndex = 0
local spectatorNuiZIndex = 2147483000
local deathActive = false
local isRespawning = false
local respawnRequestSent = false
local respawnAttemptId = 0
local lastDeathInfo = nil
local deathNuiFocused = false
local deathChatInputActive = false
local pendingServerDeathInfo = nil
local pendingServerDeathInfoAt = 0
local serverDeathInfoTTL = 12000
local spectateActive = false
local spectateTargetServerId = nil
local spectateTargetPed = 0
local spectateTargetName = nil
local spectateMode = nil
local spectateTeamRetargetRequestAt = 0
local spectateSwitchDebounceAt = 0
local spectateReturnCoords = nil
local spectateLobbyId = nil
local spectateLostTargetTicks = 0
local spectateHudRefreshAt = 0
local spectateExitDebounceAt = 0
local spectatePauseSuppressUntil = 0
local spectateExitRequestAt = 0
local spectateExitUnlockAt = 0
local spectateExitLockNoticeDebounceAt = 0
local spectateCamHandle = 0
local spectateCamYaw = 0.0
local spectateCamPitch = -8.0
local spectateCamDistance = 4.8
local spectateCamHeight = 1.05
local spectateSmoothedTargetX = nil
local spectateSmoothedTargetY = nil
local spectateSmoothedTargetZ = nil
local spectatorHudSuppressed = false
local spectatorUiTestActive = false
local spectatorNuiFocusActive = false
local spectatorChatInputActive = false
local spectatorChatFocusGraceUntil = 0
local externalNuiFocusActive = false
local disablePauseOpenControls = nil
local setDeathScreenVisible = nil

local UNKNOWN_LABEL = "Unknown"
local SPECTATE_LOST_TARGET_TICKS_MAX = 12
local SPECTATE_EXIT_LOCK_MS = 10000

local weaponNamesByHash = {}
local weaponNamesByCode = {}

local function registerWeaponLabel(code, label)
    if not code or code == "" then
        return
    end

    local normalizedCode = tostring(code):upper()
    weaponNamesByCode[normalizedCode] = label
    weaponNamesByHash[GetHashKey(normalizedCode)] = label
end

registerWeaponLabel("WEAPON_UNARMED", "Unarmed")
registerWeaponLabel("WEAPON_MELEE_KNIFE", "Knife")
registerWeaponLabel("WEAPON_MELEE_KNIFE_JAWBONE", "Jawbone Knife")
registerWeaponLabel("WEAPON_MELEE_HATCHET", "Hatchet")
registerWeaponLabel("WEAPON_MELEE_MACHETE", "Machete")
registerWeaponLabel("WEAPON_REVOLVER_CATTLEMAN", "Cattleman Revolver")
registerWeaponLabel("WEAPON_REVOLVER_DOUBLEACTION", "Double-Action Revolver")
registerWeaponLabel("WEAPON_REVOLVER_LEMAT", "LeMat Revolver")
registerWeaponLabel("WEAPON_REVOLVER_NAVY", "Navy Revolver")
registerWeaponLabel("WEAPON_REVOLVER_SCHOFIELD", "Schofield Revolver")
registerWeaponLabel("WEAPON_PISTOL_M1899", "M1899 Pistol")
registerWeaponLabel("WEAPON_PISTOL_MAUSER", "Mauser Pistol")
registerWeaponLabel("WEAPON_PISTOL_SEMIAUTO", "Semi-Auto Pistol")
registerWeaponLabel("WEAPON_REPEATER_CARBINE", "Carbine Repeater")
registerWeaponLabel("WEAPON_REPEATER_EVANS", "Evans Repeater")
registerWeaponLabel("WEAPON_REPEATER_HENRY", "Litchfield Repeater")
registerWeaponLabel("WEAPON_REPEATER_WINCHESTER", "Lancaster Repeater")
registerWeaponLabel("WEAPON_RIFLE_BOLTACTION", "Bolt-Action Rifle")
registerWeaponLabel("WEAPON_RIFLE_SPRINGFIELD", "Springfield Rifle")
registerWeaponLabel("WEAPON_RIFLE_VARMINT", "Varmint Rifle")
registerWeaponLabel("WEAPON_SNIPERRIFLE_CARCANO", "Carcano Rifle")
registerWeaponLabel("WEAPON_SNIPERRIFLE_ROLLINGBLOCK", "Rolling Block Rifle")
registerWeaponLabel("WEAPON_SHOTGUN_DOUBLEBARREL", "Double-Barrel Shotgun")
registerWeaponLabel("WEAPON_SHOTGUN_PUMP", "Pump-Action Shotgun")
registerWeaponLabel("WEAPON_SHOTGUN_REPEATING", "Repeating Shotgun")
registerWeaponLabel("WEAPON_SHOTGUN_SEMIAUTO", "Semi-Auto Shotgun")
registerWeaponLabel("WEAPON_BOW", "Bow")
registerWeaponLabel("WEAPON_THROWN_DYNAMITE", "Dynamite")
registerWeaponLabel("WEAPON_THROWN_MOLOTOV", "Molotov")
registerWeaponLabel("WEAPON_THROWN_TOMAHAWK", "Tomahawk")

local function formatUnsignedHashHex(value)
    local numericValue = tonumber(value)
    if not numericValue then
        return "00000000"
    end

    if numericValue < 0 then
        numericValue = numericValue + 4294967296
    end

    return ("%08X"):format(numericValue)
end

local function prettifyWeaponCode(weaponCode)
    local normalized = tostring(weaponCode):upper()
    local mapped = weaponNamesByCode[normalized]
    if mapped then
        return mapped
    end

    if normalized:sub(1, 7) ~= "WEAPON_" then
        return tostring(weaponCode)
    end

    local pretty = normalized
        :gsub("^WEAPON_", "")
        :gsub("_", " ")
        :lower()
        :gsub("(%a)([%w']*)", function(first, rest)
            return first:upper() .. rest
        end)
        :gsub(" Of ", " of ")

    return pretty
end

local function getPrettyWeaponName(weaponValue)
    if weaponValue == nil then
        return UNKNOWN_LABEL
    end

    if type(weaponValue) == "string" then
        local trimmedValue = weaponValue:gsub("^%s+", ""):gsub("%s+$", "")
        if trimmedValue == "" then
            return UNKNOWN_LABEL
        end

        local mappedByCode = weaponNamesByCode[trimmedValue:upper()]
        if mappedByCode then
            return mappedByCode
        end

        local asNumber = tonumber(trimmedValue)
        if asNumber then
            return getPrettyWeaponName(asNumber)
        end

        return prettifyWeaponCode(trimmedValue)
    end

    local weaponHash = tonumber(weaponValue)
    if not weaponHash or weaponHash == 0 then
        return UNKNOWN_LABEL
    end

    local mappedByHash = weaponNamesByHash[weaponHash]
    if mappedByHash then
        return mappedByHash
    end

    return ("Hash 0x%s"):format(formatUnsignedHashHex(weaponHash))
end

local function safeToNumber(value)
    local numberValue = tonumber(value)
    if not numberValue or numberValue ~= numberValue then
        return nil
    end

    return numberValue
end

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function readControlAxis(controlHash)
    local disabledValue = safeToNumber(GetDisabledControlNormal(0, controlHash)) or 0.0
    if math.abs(disabledValue) > 0.0001 then
        return disabledValue
    end

    return safeToNumber(GetControlNormal(0, controlHash)) or 0.0
end

local function readCoordComponent(rawCoords, fieldName, numericIndex)
    if rawCoords == nil then
        return nil
    end

    local fieldValue = nil
    local okField, resultField = pcall(function()
        return rawCoords[fieldName]
    end)
    if okField then
        fieldValue = resultField
    end

    if fieldValue == nil and numericIndex ~= nil then
        local okIndex, resultIndex = pcall(function()
            return rawCoords[numericIndex]
        end)
        if okIndex then
            fieldValue = resultIndex
        end
    end

    return safeToNumber(fieldValue)
end

local function normalizeCoords(rawCoords)
    if rawCoords == nil then
        return nil
    end

    local rawType = type(rawCoords)
    if rawType ~= "table" and rawType ~= "userdata" and rawType ~= "vector3" then
        return nil
    end

    local x = readCoordComponent(rawCoords, "x", 1)
    local y = readCoordComponent(rawCoords, "y", 2)
    local z = readCoordComponent(rawCoords, "z", 3)
    if not x or not y or not z then
        return nil
    end

    return {
        x = x,
        y = y,
        z = z
    }
end

local function notifySpectator(title, description, iconName)
    TriggerEvent("bln_notify:send", {
        title = title or "Spectator",
        description = description or "Action unavailable.",
        icon = iconName or "teleport",
        placement = "middle-right",
        duration = 4500
    })
end

local function setCinematicBarsEnabled(enabled)
    local state = enabled and true or false

    -- RDR2 / RedM CAM::SET_CINEMATIC_MODE_ACTIVE
    pcall(function()
        Citizen.InvokeNative(0xCE7A90B160F75046, state)
    end)

    -- Fallback hashes used by some runtime mappings/builds.
    pcall(function()
        Citizen.InvokeNative(0xDCF0754AC3D6FD4E, state)
    end)
    pcall(function()
        Citizen.InvokeNative(0x69D65E89FFD72313, state, state)
    end)
end

local function forceClosePauseMenu()
    disablePauseOpenControls()

    if type(IsPauseMenuActive) == "function" and IsPauseMenuActive() and type(SetPauseMenuActive) == "function" then
        pcall(SetPauseMenuActive, false)
    end
end

local function disableSpectatorExitControls()
    for _, key in ipairs(spectatorExitKeys) do
        DisableControlAction(0, key, true)
        DisableControlAction(1, key, true)
        DisableControlAction(2, key, true)
    end
end

local spectatorPauseBlockKeys = {
    0x156F7119, -- BACKSPACE / Frontend pause mapping on some layouts
    0x4AF4D473, -- DEL / Frontend pause alternate
    0x308588E6, -- Frontend cancel/back
    0xD82E0BD2  -- P (can open pause/map in some keymaps)
}

disablePauseOpenControls = function()
    for _, key in ipairs(spectatorPauseBlockKeys) do
        DisableControlAction(0, key, true)
        DisableControlAction(1, key, true)
        DisableControlAction(2, key, true)
    end
end

local spectatorCombatKeys = {
    0x07CE1E61, -- INPUT_ATTACK
    0xF84FA74F, -- INPUT_AIM
    0xB2F377E8, -- INPUT_ATTACK2
    0xCEE12B50, -- INPUT_MELEE_ATTACK
    0xD9D0E1C0  -- INPUT_RELOAD
}

local function disableSpectatorCombatControls()
    DisablePlayerFiring(PlayerId(), true)

    for _, key in ipairs(spectatorCombatKeys) do
        DisableControlAction(0, key, true)
        DisableControlAction(1, key, true)
        DisableControlAction(2, key, true)
    end
end

local function disableSpectatorGeneralControls(allowLookInput)
    -- Spectator mode should not leak gameplay/keymap inputs (e.g. leave-lobby binds on ESC).
    DisableAllControlActions(0)
    DisableAllControlActions(1)
    DisableAllControlActions(2)

    if allowLookInput ~= false then
        -- Keep camera look controls active for spectating.
        EnableControlAction(0, lookLeftRightControl, true)
        EnableControlAction(1, lookLeftRightControl, true)
        EnableControlAction(2, lookLeftRightControl, true)
        EnableControlAction(0, lookUpDownControl, true)
        EnableControlAction(1, lookUpDownControl, true)
        EnableControlAction(2, lookUpDownControl, true)
    end

    -- Keep chat available while spectating.
    EnableControlAction(0, chatOpenControl, true)
    EnableControlAction(1, chatOpenControl, true)
    EnableControlAction(2, chatOpenControl, true)
end

local function isChatControlJustPressed()
    return (
        IsControlJustPressed(0, chatOpenControl) or
        IsDisabledControlJustPressed(0, chatOpenControl) or
        IsControlJustPressed(1, chatOpenControl) or
        IsDisabledControlJustPressed(1, chatOpenControl) or
        IsControlJustPressed(2, chatOpenControl) or
        IsDisabledControlJustPressed(2, chatOpenControl)
    )
end

local function getDeathNuiTargetZIndex()
    if deathChatInputActive then
        return deathNuiChatZIndex
    end

    return deathNuiZIndex
end

local function setDeathNuiFocusState(enabled, keepInput)
    local shouldEnable = enabled and true or false
    local shouldKeepInput = shouldEnable and keepInput and true or false

    if type(SetNuiFocus) == "function" then
        -- Keep death overlay focused without forcing mouse cursor.
        pcall(SetNuiFocus, shouldEnable, false)
    end

    if type(SetNuiFocusKeepInput) == "function" then
        pcall(SetNuiFocusKeepInput, shouldKeepInput)
    end

    deathNuiFocused = shouldEnable
end

local function releaseDeathNuiFocusForChat()
    if not deathActive or spectateActive or deathChatInputActive then
        return
    end

    deathChatInputActive = true

    if type(SetNuiZIndex) == "function" then
        SetNuiZIndex(getDeathNuiTargetZIndex())
    end

    setDeathNuiFocusState(false, false)
end

local function isNuiFocusActive()
    if type(IsNuiFocused) ~= "function" then
        return false
    end

    local okFocused, isFocused = pcall(IsNuiFocused)
    return okFocused and isFocused or false
end

local function restoreDeathNuiFocusAfterChat()
    if not deathActive or spectateActive or not deathChatInputActive then
        return
    end

    if isNuiFocusActive() then
        return
    end

    deathChatInputActive = false

    if type(SetNuiZIndex) == "function" then
        SetNuiZIndex(getDeathNuiTargetZIndex())
    end

    setDeathNuiFocusState(false, false)
end

local function suppressPauseMenuFor(milliseconds)
    local durationMs = math.floor(safeToNumber(milliseconds) or 0)
    if durationMs <= 0 then
        return
    end

    local now = GetGameTimer()
    local untilTick = now + durationMs
    if untilTick > spectatePauseSuppressUntil then
        spectatePauseSuppressUntil = untilTick
    end
end

local function getCurrentLobbyId(lobbyId)
    local resolvedLobbyId = lobbyId
    if resolvedLobbyId == nil then
        local okLobby, currentLobbyId = pcall(function()
            return exports.pvp:GetPlayerLobby()
        end)

        if not okLobby then
            return nil
        end

        resolvedLobbyId = currentLobbyId
    end

    if type(resolvedLobbyId) == "string" then
        local trimmed = resolvedLobbyId:gsub("^%s+", ""):gsub("%s+$", "")
        if trimmed == "" or trimmed:lower() == "safezone" then
            return nil
        end

        resolvedLobbyId = trimmed
    end

    local lobbyNumber = math.floor(safeToNumber(resolvedLobbyId) or 0)
    if lobbyNumber <= 0 then
        return nil
    end

    return lobbyNumber
end

local function resolveLobbyLabelFromId(lobbyId)
    local resolvedLobbyId = lobbyId
    if resolvedLobbyId == nil then
        local okLobby, currentLobbyId = pcall(function()
            return exports.pvp:GetPlayerLobby()
        end)

        if not okLobby then
            return nil
        end

        resolvedLobbyId = currentLobbyId
    end

    if type(resolvedLobbyId) == "string" then
        local trimmed = resolvedLobbyId:gsub("^%s+", ""):gsub("%s+$", "")
        if trimmed == "" or trimmed:lower() == "safezone" then
            return nil
        end

        local normalizedLobbyId = getCurrentLobbyId(trimmed)
        if not normalizedLobbyId then
            return trimmed
        end

        resolvedLobbyId = normalizedLobbyId
    end

    local lobbyNumber = getCurrentLobbyId(resolvedLobbyId)
    if not lobbyNumber then
        return nil
    end

    local okConfig, pvpConfig = pcall(function()
        return exports.pvp:GetConfig()
    end)

    if okConfig and type(pvpConfig) == "table" and type(pvpConfig.Lobbies) == "table" then
        for _, lobbyData in ipairs(pvpConfig.Lobbies) do
            if tonumber(lobbyData.id) == lobbyNumber then
                if type(lobbyData.name) == "string" and lobbyData.name ~= "" then
                    return lobbyData.name
                end
                break
            end
        end
    end

    return ("Lobby %d"):format(lobbyNumber)
end

local function normalizeDeathInfo(info)
    local normalized = {
        killer = UNKNOWN_LABEL,
        killerServerId = nil,
        weapon = UNKNOWN_LABEL,
        distance = UNKNOWN_LABEL,
        lobby = nil
    }

    if type(info) ~= "table" then
        return normalized
    end

    if type(info.killer) == "string" and info.killer ~= "" then
        normalized.killer = info.killer
    end

    if info.killerServerId ~= nil then
        local killerServerId = math.floor(safeToNumber(info.killerServerId) or 0)
        if killerServerId > 0 then
            normalized.killerServerId = killerServerId
        end
    end

    if normalized.killer == "Yourself" then
        normalized.killer = "Suicide"
        normalized.killerServerId = nil
    end

    if info.weapon ~= nil then
        normalized.weapon = getPrettyWeaponName(info.weapon)
    end

    if type(info.distance) == "number" and info.distance >= 0 then
        normalized.distance = ("%.1fm"):format(info.distance)
    elseif type(info.distance) == "string" and info.distance ~= "" then
        normalized.distance = info.distance
    end

    if info.lobby ~= nil then
        if type(info.lobby) == "string" then
            local trimmedLobby = info.lobby:gsub("^%s+", ""):gsub("%s+$", "")
            if trimmedLobby ~= "" and trimmedLobby:lower() ~= "safezone" then
                normalized.lobby = trimmedLobby
            end
        elseif type(info.lobby) == "number" then
            normalized.lobby = resolveLobbyLabelFromId(info.lobby)
        end
    end

    return normalized
end

local function isUnknownField(value)
    if type(value) ~= "string" then
        return true
    end

    local cleaned = value:gsub("^%s+", ""):gsub("%s+$", "")
    if cleaned == "" then
        return true
    end

    local lowered = cleaned:lower()
    return lowered == "unknown"
        or lowered == "player"
        or lowered == "npc"
        or lowered:sub(1, 7) == "hash 0x"
end

local function mergeDeathInfo(primaryInfo, fallbackInfo)
    local primary = normalizeDeathInfo(primaryInfo)
    local fallback = normalizeDeathInfo(fallbackInfo)

    local merged = {
        killer = primary.killer,
        killerServerId = primary.killerServerId,
        weapon = primary.weapon,
        distance = primary.distance,
        lobby = primary.lobby
    }

    if merged.killer == "Suicide" or fallback.killer == "Suicide" then
        merged.killer = "Suicide"
        merged.killerServerId = nil
        merged.distance = "0.0m"
    else
        if isUnknownField(merged.killer) and not isUnknownField(fallback.killer) then
            merged.killer = fallback.killer
        end

        if isUnknownField(merged.distance) and not isUnknownField(fallback.distance) then
            merged.distance = fallback.distance
        end

        if (not merged.killerServerId or merged.killerServerId <= 0) and fallback.killerServerId and fallback.killerServerId > 0 then
            merged.killerServerId = fallback.killerServerId
        end
    end

    if isUnknownField(merged.weapon) and not isUnknownField(fallback.weapon) then
        merged.weapon = fallback.weapon
    end

    if (not merged.lobby or merged.lobby == "") and fallback.lobby and fallback.lobby ~= "" then
        merged.lobby = fallback.lobby
    end

    return normalizeDeathInfo(merged)
end

local function buildDeathInfo()
    local playerPed = PlayerPedId()
    if not DoesEntityExist(playerPed) then
        return normalizeDeathInfo(nil)
    end

    local killer = UNKNOWN_LABEL
    local killerServerId = nil
    local distance = UNKNOWN_LABEL
    local weapon = getPrettyWeaponName(GetPedCauseOfDeath(playerPed))
    local lobby = resolveLobbyLabelFromId()
    local killerEntity = GetPedSourceOfDeath(playerPed)

    if killerEntity and killerEntity ~= 0 and DoesEntityExist(killerEntity) then
        if killerEntity == playerPed then
            killer = "Suicide"
            distance = "0.0m"
        elseif IsPedAPlayer(killerEntity) then
            local killerPlayer = NetworkGetPlayerIndexFromPed(killerEntity)
            if killerPlayer and killerPlayer ~= -1 then
                local killerName = GetPlayerName(killerPlayer)
                if killerName and killerName ~= "" then
                    killer = killerName
                else
                    killer = "Player"
                end
                local killerId = GetPlayerServerId(killerPlayer)
                if killerId and killerId > 0 then
                    killerServerId = killerId
                end
            else
                killer = "Player"
            end
        else
            killer = "NPC"
        end

        if isUnknownField(weapon) then
            local okWeapon, firstResult, secondResult = pcall(GetCurrentPedWeapon, killerEntity, true, 0, false)
            if okWeapon then
                local killerWeaponHash = nil
                if type(secondResult) == "number" then
                    killerWeaponHash = secondResult
                elseif type(firstResult) == "number" then
                    killerWeaponHash = firstResult
                end

                if killerWeaponHash and killerWeaponHash ~= 0 then
                    local killerWeaponName = getPrettyWeaponName(killerWeaponHash)
                    if not isUnknownField(killerWeaponName) then
                        weapon = killerWeaponName
                    end
                end
            end
        end

        if killerEntity ~= playerPed then
            local victimCoords = GetEntityCoords(playerPed)
            local killerCoords = GetEntityCoords(killerEntity)
            local distanceValue = #(victimCoords - killerCoords)
            if distanceValue and distanceValue >= 0 then
                distance = ("%.1fm"):format(distanceValue)
            end
        end

    end

    return normalizeDeathInfo({
        killer = killer,
        killerServerId = killerServerId,
        weapon = weapon,
        distance = distance,
        lobby = lobby
    })
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

local function isTeamBattleLobby(lobbyId, pvpConfig)
    local lobbyNumber = math.floor(safeToNumber(lobbyId) or 0)
    if lobbyNumber <= 0 then
        return false
    end

    local cfg = pvpConfig or getPvpConfig()
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
        for _, lobbyData in ipairs(cfg.Lobbies) do
            if math.floor(safeToNumber(lobbyData.id) or 0) == lobbyNumber then
                local description = type(lobbyData.description) == "string" and lobbyData.description:lower() or ""
                if description:find("team battle", 1, true) then
                    return true
                end
                break
            end
        end
    end

    return false
end

local function isCtfLobby(lobbyId, pvpConfig)
    local lobbyNumber = math.floor(safeToNumber(lobbyId) or 0)
    if lobbyNumber <= 0 then
        return false
    end

    local cfg = pvpConfig or getPvpConfig()
    local modeConfig = cfg.TeamArenaModes and cfg.TeamArenaModes[lobbyNumber] or nil
    local mode = type(modeConfig) == "table" and modeConfig.mode or modeConfig
    if type(mode) == "string" and mode:lower() == "ctf" then
        return true
    end

    if type(cfg.CTFArenas) == "table" and cfg.CTFArenas[lobbyNumber] then
        return true
    end

    if type(cfg.Lobbies) == "table" then
        for _, lobbyData in ipairs(cfg.Lobbies) do
            if math.floor(safeToNumber(lobbyData.id) or 0) == lobbyNumber then
                local description = type(lobbyData.description) == "string" and lobbyData.description:lower() or ""
                return description:find("capture the flag", 1, true) ~= nil
            end
        end
    end

    return false
end

local function isTeamSpectatorLobby(lobbyId, pvpConfig)
    local cfg = pvpConfig or getPvpConfig()
    return isTeamBattleLobby(lobbyId, cfg) and not isCtfLobby(lobbyId, cfg)
end

local function buildDeathSpectateContext()
    local lobbyId = getCurrentLobbyId()
    local cfg = getPvpConfig()

    if lobbyId and isTeamSpectatorLobby(lobbyId, cfg) then
        return {
            label = "Spectate Team",
            note = "Spectator mode follows a living teammate until your team respawns."
        }
    end

    return {
        label = "Spectate Killer",
        note = "Spectator mode is available in Public and Private arenas."
    }
end

local function canUseSpectatorInCurrentLobby()
    local lobbyId = getCurrentLobbyId()
    if not lobbyId then
        return false, nil, "Spectator works only inside PvP arenas."
    end

    local okDuel, isInDuel = pcall(function()
        return exports.pvp:IsPlayerInDuel()
    end)
    if okDuel and isInDuel then
        return false, lobbyId, "Spectator is disabled during duels."
    end

    local cfg = getPvpConfig()
    if isTeamBattleLobby(lobbyId, cfg) and isCtfLobby(lobbyId, cfg) then
        return false, lobbyId, "Spectator is disabled in CTF arenas."
    end

    return true, lobbyId, nil
end

local function getArenaReturnCoords(lobbyId)
    local okRespawnLocation, respawnLocation = pcall(function()
        return exports.pvp:GetPlayerRespawnLocation()
    end)
    if okRespawnLocation then
        local normalizedRespawn = normalizeCoords(respawnLocation)
        if normalizedRespawn then
            return normalizedRespawn
        end
    end

    local okRandomSpawn, randomSpawn = pcall(function()
        return exports.pvp:GetRandomLobbySpawn()
    end)
    if okRandomSpawn then
        local normalizedRandomSpawn = normalizeCoords(randomSpawn)
        if normalizedRandomSpawn then
            return normalizedRandomSpawn
        end
    end

    local cfg = getPvpConfig()
    local lobbySpawns = cfg and cfg.LobbySpawns and cfg.LobbySpawns[lobbyId] or nil
    if type(lobbySpawns) == "table" and #lobbySpawns > 0 then
        local randomIndex = math.random(1, #lobbySpawns)
        local normalizedLobbySpawn = normalizeCoords(lobbySpawns[randomIndex])
        if normalizedLobbySpawn then
            return normalizedLobbySpawn
        end
    end

    local playerPed = PlayerPedId()
    if DoesEntityExist(playerPed) then
        local coords = GetEntityCoords(playerPed)
        return normalizeCoords(coords)
    end

    return nil
end

local function healPlayerFully(playerPed)
    if not DoesEntityExist(playerPed) then
        return
    end

    local maxHealth = GetEntityMaxHealth(playerPed)
    if maxHealth and maxHealth > 0 then
        SetEntityHealth(playerPed, maxHealth)
    end

    Citizen.InvokeNative(0xC6258F41D86676E0, playerPed, 0, 1000.0)
end

local function reloadCharacter()
    local playerPed = PlayerPedId()
    if DoesEntityExist(playerPed) then
        ExecuteCommand("rc")
    end
end

local function revivePlayerAt(coords)
    local normalizedCoords = normalizeCoords(coords)
    if not normalizedCoords then
        return false
    end

    local playerPed = PlayerPedId()
    if not DoesEntityExist(playerPed) then
        return false
    end

    local x = normalizedCoords.x
    local y = normalizedCoords.y
    local z = normalizedCoords.z

    if IsEntityDead(playerPed) or IsPedFatallyInjured(playerPed) then
        NetworkResurrectLocalPlayer(x, y, z + 0.2, 0.0, true, false)
        Citizen.Wait(200)
    end

    SetEntityCoords(playerPed, x, y, z, false, false, false, false)
    healPlayerFully(playerPed)

    return true
end

local function setSpectatorNuiFocus(enabled)
    local shouldEnable = enabled and true or false

    if shouldEnable then
        if deathNuiFocused then
            setDeathNuiFocusState(false, false)
        end

        if type(SetNuiFocus) == "function" then
            pcall(SetNuiFocus, true, false)
            spectatorNuiFocusActive = true
        end
        if type(SetNuiFocusKeepInput) == "function" then
            pcall(SetNuiFocusKeepInput, true)
        end
    else
        if spectatorNuiFocusActive and type(SetNuiFocus) == "function" then
            pcall(SetNuiFocus, false, false)
        end
        if type(SetNuiFocusKeepInput) == "function" then
            pcall(SetNuiFocusKeepInput, false)
        end
        spectatorNuiFocusActive = false
    end
end

local function releaseSpectatorNuiFocusForChat()
    if not spectateActive or spectatorChatInputActive then
        return
    end

    spectatorChatInputActive = true
    -- Avoid restoring spectator NUI too early while chat is still transitioning to focus.
    spectatorChatFocusGraceUntil = GetGameTimer() + 900
    setSpectatorNuiFocus(false)
end

local function restoreSpectatorNuiFocusAfterChat()
    if not spectateActive or not spectatorChatInputActive or externalNuiFocusActive then
        return
    end

    if GetGameTimer() < spectatorChatFocusGraceUntil then
        return
    end

    if IsControlPressed(0, chatOpenControl) or IsDisabledControlPressed(0, chatOpenControl)
        or IsControlPressed(1, chatOpenControl) or IsDisabledControlPressed(1, chatOpenControl)
        or IsControlPressed(2, chatOpenControl) or IsDisabledControlPressed(2, chatOpenControl) then
        return
    end

    if isNuiFocusActive() then
        return
    end

    spectatorChatInputActive = false
    spectatorChatFocusGraceUntil = 0
    setSpectatorNuiFocus(true)
end

local function setSpectatorHudVisible(visible, targetName)
    if visible and type(SetNuiZIndex) == "function" then
        SetNuiZIndex(spectatorNuiZIndex)
    end

    -- Spectator overlay is passive; keep game input unlocked for camera controls.
    if visible and deathNuiFocused and not deathActive then
        setDeathNuiFocusState(false, false)
    elseif not visible and deathNuiFocused and not deathActive then
        setDeathNuiFocusState(false, false)
    end

    SendNUIMessage({
        action = visible and "showSpectatorHud" or "hideSpectatorHud",
        targetName = targetName,
        mode = spectateMode,
        canSwitchTarget = spectateMode == "team"
    })
end

local function setSpectatorHudSuppressed(enabled)
    local hideHud = enabled and true or false
    if spectatorHudSuppressed == hideHud then
        return
    end

    spectatorHudSuppressed = hideHud

    if hideHud then
        if type(DisplayHud) == "function" then
            pcall(DisplayHud, false)
        end
        if type(DisplayRadar) == "function" then
            pcall(DisplayRadar, false)
        end

        TriggerEvent("funcker_hud:setVisible", false)
        TriggerEvent("funcker_rank:setVisible", false)
        TriggerEvent("funcker_topplayers:disable")
    else
        if type(DisplayHud) == "function" then
            pcall(DisplayHud, true)
        end
        if type(DisplayRadar) == "function" then
            pcall(DisplayRadar, true)
        end

        TriggerEvent("funcker_hud:setVisible", true)
        TriggerEvent("funcker_rank:setVisible", true)
        TriggerEvent("funcker_topplayers:enable")
    end
end

local function applySpectatorHudSuppressionFrame()
    if not spectatorHudSuppressed then
        return
    end

    if type(HideHudAndRadarThisFrame) == "function" then
        pcall(HideHudAndRadarThisFrame)
    end
    if type(DisplayHud) == "function" then
        pcall(DisplayHud, false)
    end
    if type(DisplayRadar) == "function" then
        pcall(DisplayRadar, false)
    end
end

local function setLocalSpectatorState(enabled)
    local playerPed = PlayerPedId()
    if not DoesEntityExist(playerPed) then
        return
    end

    if enabled then
        if type(NetworkSetEntityInvisibleToNetwork) == "function" then
            pcall(NetworkSetEntityInvisibleToNetwork, playerPed, true)
        end
        SetEntityVisible(playerPed, false, false)
        SetEntityCollision(playerPed, false, false)
        FreezeEntityPosition(playerPed, true)
        SetEntityInvincible(playerPed, true)
    else
        if type(NetworkSetEntityInvisibleToNetwork) == "function" then
            pcall(NetworkSetEntityInvisibleToNetwork, playerPed, false)
        end
        FreezeEntityPosition(playerPed, false)
        SetEntityCollision(playerPed, true, true)
        SetEntityVisible(playerPed, true, false)
        SetEntityInvincible(playerPed, false)
    end
end

local function setNetworkSpectatorMode(enabled, targetPed)
    if type(NetworkSetInSpectatorMode) ~= "function" then
        return false
    end

    local pedTarget = targetPed
    if not pedTarget or pedTarget == 0 then
        pedTarget = PlayerPedId()
    end

    local ok = pcall(NetworkSetInSpectatorMode, enabled, pedTarget)
    return ok
end

local function destroySpectateCamera()
    if spectateCamHandle and spectateCamHandle ~= 0 then
        if type(DoesCamExist) == "function" and DoesCamExist(spectateCamHandle) then
            pcall(RenderScriptCams, false, false, 0, true, true)
            pcall(DestroyCam, spectateCamHandle, false)
        end
        spectateCamHandle = 0
    end

    if type(ClearFocus) == "function" then
        pcall(ClearFocus)
    end
end

local function seedSpectateTargetSmoothing(targetPed)
    if not targetPed or targetPed == 0 or not DoesEntityExist(targetPed) then
        spectateSmoothedTargetX = nil
        spectateSmoothedTargetY = nil
        spectateSmoothedTargetZ = nil
        return
    end

    local coords = GetEntityCoords(targetPed)
    spectateSmoothedTargetX = coords.x
    spectateSmoothedTargetY = coords.y
    spectateSmoothedTargetZ = coords.z
end

local function resetSpectateCameraRig(targetPed)
    local heading = safeToNumber(GetEntityHeading(targetPed)) or 0.0
    spectateCamYaw = heading + 180.0
    spectateCamPitch = -10.0
    spectateCamDistance = 5.0
    spectateCamHeight = 1.05
    seedSpectateTargetSmoothing(targetPed)
end

local function updateSpectateCamera(targetPed, allowInput, hardSnap)
    if not targetPed or targetPed == 0 or not DoesEntityExist(targetPed) then
        return false
    end
    if not spectateCamHandle or spectateCamHandle == 0 then
        return false
    end
    if type(DoesCamExist) == "function" and not DoesCamExist(spectateCamHandle) then
        return false
    end

    local frameSeconds = safeToNumber(GetFrameTime()) or 0.016666
    frameSeconds = clamp(frameSeconds, 0.001, 0.1)

    if allowInput then
        local lookX = readControlAxis(lookLeftRightControl)
        local lookY = readControlAxis(lookUpDownControl)
        local yawSpeed = 410.0
        local pitchSpeed = 285.0

        if math.abs(lookX) > 0.0001 then
            spectateCamYaw = spectateCamYaw - (lookX * yawSpeed * frameSeconds)
        end
        if math.abs(lookY) > 0.0001 then
            spectateCamPitch = clamp(spectateCamPitch + (lookY * pitchSpeed * frameSeconds), -58.0, 25.0)
        end
    end

    local targetCoords = GetEntityCoords(targetPed)
    if hardSnap or spectateSmoothedTargetX == nil or spectateSmoothedTargetY == nil or spectateSmoothedTargetZ == nil then
        spectateSmoothedTargetX = targetCoords.x
        spectateSmoothedTargetY = targetCoords.y
        spectateSmoothedTargetZ = targetCoords.z
    else
        local targetBlend = 1.0 - math.exp(-14.0 * frameSeconds)
        spectateSmoothedTargetX = spectateSmoothedTargetX + ((targetCoords.x - spectateSmoothedTargetX) * targetBlend)
        spectateSmoothedTargetY = spectateSmoothedTargetY + ((targetCoords.y - spectateSmoothedTargetY) * targetBlend)
        spectateSmoothedTargetZ = spectateSmoothedTargetZ + ((targetCoords.z - spectateSmoothedTargetZ) * targetBlend)
    end

    local followX = spectateSmoothedTargetX
    local followY = spectateSmoothedTargetY
    local followZ = spectateSmoothedTargetZ
    local yawRadians = math.rad(spectateCamYaw)
    local pitchRadians = math.rad(spectateCamPitch)
    local distance = spectateCamDistance
    local cosPitch = math.cos(pitchRadians)

    local desiredX = followX + (math.sin(yawRadians) * distance * cosPitch)
    local desiredY = followY - (math.cos(yawRadians) * distance * cosPitch)
    local desiredZ = followZ + spectateCamHeight + (math.sin(pitchRadians) * distance)

    if hardSnap then
        SetCamCoord(spectateCamHandle, desiredX, desiredY, desiredZ)
    else
        local currentCoords = GetCamCoord(spectateCamHandle)
        local camBlend = 1.0 - math.exp(-10.0 * frameSeconds)
        local newX = currentCoords.x + ((desiredX - currentCoords.x) * camBlend)
        local newY = currentCoords.y + ((desiredY - currentCoords.y) * camBlend)
        local newZ = currentCoords.z + ((desiredZ - currentCoords.z) * camBlend)
        SetCamCoord(spectateCamHandle, newX, newY, newZ)
    end

    PointCamAtCoord(spectateCamHandle, followX, followY, followZ + 0.95)

    if type(SetFocusEntity) == "function" then
        pcall(SetFocusEntity, targetPed)
    end

    return true
end

local function createSpectateCamera(targetPed)
    destroySpectateCamera()

    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    if not cam or cam == 0 then
        return false
    end

    spectateCamHandle = cam

    local cameraFov = safeToNumber(GetGameplayCamFov()) or 55.0
    cameraFov = math.max(45.0, math.min(75.0, cameraFov))
    SetCamFov(cam, cameraFov)

    resetSpectateCameraRig(targetPed)
    updateSpectateCamera(targetPed, false, true)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, true)

    return true
end

local function clearSpectatorState()
    spectateActive = false
    spectateTargetServerId = nil
    spectateTargetPed = 0
    spectateTargetName = nil
    spectateMode = nil
    spectateTeamRetargetRequestAt = 0
    spectateSwitchDebounceAt = 0
    spectateReturnCoords = nil
    spectateLobbyId = nil
    spectateLostTargetTicks = 0
    spectateHudRefreshAt = 0
    spectateExitDebounceAt = 0
    spectateExitRequestAt = 0
    spectateExitUnlockAt = 0
    spectateExitLockNoticeDebounceAt = 0
    spectateCamHandle = 0
    spectateCamYaw = 0.0
    spectateCamPitch = -8.0
    spectateCamDistance = 4.8
    spectateCamHeight = 1.05
    spectateSmoothedTargetX = nil
    spectateSmoothedTargetY = nil
    spectateSmoothedTargetZ = nil
    spectatorChatInputActive = false
    spectatorChatFocusGraceUntil = 0
end

local function hideSpectatorUiTest(withNotify)
    if not spectatorUiTestActive then
        return false
    end

    spectatorUiTestActive = false
    setSpectatorHudVisible(false)

    if withNotify then
        notifySpectator("Spectator UI Test", "Preview hidden.", "teleport")
    end

    return true
end

local function showSpectatorUiTest(targetName)
    if spectateActive or deathActive or isRespawning then
        notifySpectator("Spectator UI Test", "Cannot show preview while death/spectator flow is active.", "cross")
        return false
    end

    spectatorUiTestActive = true
    setSpectatorHudVisible(true, targetName or "Killer")
    notifySpectator("Spectator UI Test", "Preview shown. Use /testspectateui off to hide.", "teleport")
    return true
end

local function stopSpectatorMode(withNotify)
    if not spectateActive then
        return false
    end

    local lobbyToRestore = math.floor(safeToNumber(spectateLobbyId) or 0)
    spectateExitRequestAt = 0
    suppressPauseMenuFor(1600)
    setSpectatorHudSuppressed(false)
    setNetworkSpectatorMode(false, spectateTargetPed)
    destroySpectateCamera()
    setLocalSpectatorState(false)
    setSpectatorNuiFocus(false)
    setCinematicBarsEnabled(false)
    forceClosePauseMenu()
    setSpectatorHudVisible(false)

    local returnCoords = normalizeCoords(spectateReturnCoords) or getArenaReturnCoords(spectateLobbyId or getCurrentLobbyId())
    if returnCoords then
        revivePlayerAt(returnCoords)
    end

    if lobbyToRestore > 0 then
        local currentLobbyId = getCurrentLobbyId() or 0
        if currentLobbyId > 0 and currentLobbyId ~= lobbyToRestore then
            TriggerServerEvent("pvp:setPlayerLobby", lobbyToRestore)
        elseif currentLobbyId <= 0 then
            local expectedLobbyId = lobbyToRestore
            Citizen.SetTimeout(500, function()
                if spectateActive then
                    return
                end

                local latestLobbyId = getCurrentLobbyId() or 0
                if latestLobbyId ~= expectedLobbyId then
                    TriggerServerEvent("pvp:setPlayerLobby", expectedLobbyId)
                end
            end)
        end
    end

    TriggerServerEvent("respawnsys:spectatorStopped")

    deathActive = false
    isRespawning = false
    respawnRequestSent = false
    lastDeathInfo = nil
    pendingServerDeathInfo = nil
    pendingServerDeathInfoAt = 0

    clearSpectatorState()

    Citizen.SetTimeout(100, function()
        if not spectateActive then
            reloadCharacter()
        end
    end)

    if withNotify then
        notifySpectator("Spectator", "You returned to your arena.", "teleport")
    end

    return true
end

local function requestTeamSpectatorSwitch()
    if not spectateActive or spectateMode ~= "team" then
        return false
    end

    local now = GetGameTimer()
    if now < spectateSwitchDebounceAt then
        return false
    end

    spectateSwitchDebounceAt = now + 350
    local excludedTarget = math.floor(safeToNumber(spectateTargetServerId) or 0)
    if excludedTarget > 0 then
        TriggerServerEvent("pvp:requestTeamSpectateTarget", excludedTarget)
    else
        TriggerServerEvent("pvp:requestTeamSpectateTarget")
    end

    return true
end

local function tryManualSpectatorExit(withNotify)
    if not spectateActive then
        return false
    end

    if spectateMode == "team" then
        notifySpectator("Spectator", "You will respawn automatically when the round ends.", "cross")
        return false
    end

    local now = GetGameTimer()
    local remainingMs = spectateExitUnlockAt - now
    if remainingMs > 0 then
        local remainingSeconds = math.max(1, math.ceil(remainingMs / 1000.0))
        if now >= spectateExitLockNoticeDebounceAt then
            spectateExitLockNoticeDebounceAt = now + 180
            local secondsLabel = remainingSeconds == 1 and "second" or "seconds"
            notifySpectator("Spectator", ("You can leave spectator mode in %d %s."):format(remainingSeconds, secondsLabel), "cross")
        end
        return false
    end

    return stopSpectatorMode(withNotify)
end

local function startSpectatorMode(targetInfo)
    if spectateActive then
        notifySpectator("Spectator unavailable", "You are already spectating.", "cross")
        return false
    end

    if spectatorUiTestActive then
        hideSpectatorUiTest(false)
    end

    local requestedTarget = nil
    local requestedMode = nil
    if type(targetInfo) == "table" then
        local rawMode = targetInfo.spectateMode or targetInfo.mode
        if type(rawMode) == "string" and rawMode ~= "" then
            requestedMode = rawMode:lower()
        end

        local requestedId = math.floor(safeToNumber(targetInfo.targetServerId or targetInfo.serverId or targetInfo.id or targetInfo.killerServerId) or 0)
        if requestedId > 0 then
            requestedTarget = {
                serverId = requestedId,
                name = targetInfo.targetName or targetInfo.name or targetInfo.killer,
                coords = normalizeCoords(targetInfo.targetCoords or targetInfo.coords)
            }
        end
    elseif targetInfo ~= nil then
        local requestedId = math.floor(safeToNumber(targetInfo) or 0)
        if requestedId > 0 then
            requestedTarget = {
                serverId = requestedId,
                name = nil
            }
        end
    end

    if isRespawning then
        notifySpectator("Spectator unavailable", "Wait until your respawn finishes, then try again.", "cross")
        return false
    end

    if not requestedTarget and not deathActive then
        notifySpectator("Spectator unavailable", "No player target was received.", "cross")
        return false
    end

    local allowed, lobbyId, deniedReason = canUseSpectatorInCurrentLobby()
    if not allowed then
        notifySpectator("Spectator unavailable", deniedReason or "You cannot spectate here.", "cross")
        return false
    end

    local cfg = getPvpConfig()
    local teamSpectateLobby = isTeamSpectatorLobby(lobbyId, cfg)
    if teamSpectateLobby and not requestedTarget then
        TriggerServerEvent("pvp:requestTeamSpectateTarget")
        return true
    end

    if requestedTarget and teamSpectateLobby and not requestedMode then
        requestedMode = "team"
    end

    if requestedMode == "team" and not teamSpectateLobby then
        notifySpectator("Spectator unavailable", "Team spectator is available only in Team Battle arenas.", "cross")
        return false
    end

    local info = nil
    if requestedTarget then
        info = normalizeDeathInfo({
            killer = requestedTarget.name or (requestedMode == "team" and "Teammate" or "Player"),
            killerServerId = requestedTarget.serverId
        })
    else
        info = normalizeDeathInfo(lastDeathInfo or buildDeathInfo())
    end

    local killerServerId = math.floor(safeToNumber(info.killerServerId) or 0)
    local myServerId = GetPlayerServerId(PlayerId())
    if killerServerId <= 0 or killerServerId == myServerId then
        local targetLabel = requestedMode == "team" and "living teammate" or "killer player"
        notifySpectator("Spectator unavailable", "No valid " .. targetLabel .. " found for spectating.", "cross")
        return false
    end

    local returnCoords = nil
    if requestedMode == "team" then
        local playerPed = PlayerPedId()
        if DoesEntityExist(playerPed) then
            returnCoords = normalizeCoords(GetEntityCoords(playerPed))
        end
    end
    returnCoords = returnCoords or getArenaReturnCoords(lobbyId)

    if not returnCoords then
        notifySpectator("Spectator unavailable", "Could not resolve your arena return point.", "cross")
        return false
    end

    local killerPlayer = -1
    local targetPed = 0
    local function resolveTargetPed()
        killerPlayer = GetPlayerFromServerId(killerServerId)
        if not killerPlayer or killerPlayer == -1 then
            return false
        end

        targetPed = GetPlayerPed(killerPlayer)
        return targetPed and targetPed ~= 0 and DoesEntityExist(targetPed)
    end

    if requestedTarget and requestedTarget.coords and requestedMode ~= "team" then
        if not revivePlayerAt(requestedTarget.coords) then
            notifySpectator("Spectator unavailable", "Could not move close enough to spectate this player.", "cross")
            return false
        end

        if type(RequestCollisionAtCoord) == "function" then
            pcall(RequestCollisionAtCoord, requestedTarget.coords.x, requestedTarget.coords.y, requestedTarget.coords.z)
        end

        local streamUntil = GetGameTimer() + 1600
        while not resolveTargetPed() and GetGameTimer() < streamUntil do
            Citizen.Wait(50)
        end
    else
        resolveTargetPed()

        if not revivePlayerAt(returnCoords) then
            notifySpectator("Spectator unavailable", "Could not prepare your player for spectating.", "cross")
            return false
        end
    end

    if not targetPed or targetPed == 0 or not DoesEntityExist(targetPed) then
        if requestedTarget and requestedTarget.coords and requestedMode ~= "team" then
            revivePlayerAt(returnCoords)
        end

        notifySpectator("Spectator unavailable", "Player is too far away or not streamed yet. Try again in a moment.", "cross")
        return false
    end

    setLocalSpectatorState(true)
    destroySpectateCamera()
    forceClosePauseMenu()
    if not setNetworkSpectatorMode(true, targetPed) then
        setLocalSpectatorState(false)
        if requestedTarget and requestedTarget.coords and requestedMode ~= "team" then
            revivePlayerAt(returnCoords)
        end
        notifySpectator("Spectator unavailable", "Spectator mode is not supported on this build.", "cross")
        return false
    end

    spectateActive = true
    spectateMode = requestedMode == "team" and "team" or "killer"
    spectateTargetServerId = killerServerId
    spectateTargetPed = targetPed
    spectateTargetName = (type(info.killer) == "string" and info.killer ~= "" and info.killer) or (GetPlayerName(killerPlayer) or (spectateMode == "team" and "Teammate" or "Killer"))
    spectateReturnCoords = returnCoords
    spectateLobbyId = lobbyId
    spectateLostTargetTicks = 0
    spectateTeamRetargetRequestAt = 0
    spectateSwitchDebounceAt = 0
    spectateExitUnlockAt = GetGameTimer() + SPECTATE_EXIT_LOCK_MS
    spectateExitLockNoticeDebounceAt = 0

    deathActive = false
    isRespawning = false
    respawnRequestSent = false

    setCinematicBarsEnabled(false)
    setSpectatorHudSuppressed(true)
    setDeathScreenVisible(false)
    setSpectatorHudVisible(true, spectateTargetName or (spectateMode == "team" and "Teammate" or "Killer"))
    setSpectatorNuiFocus(true)
    TriggerServerEvent("respawnsys:spectatorStarted", killerServerId, { mode = spectateMode, lobbyId = lobbyId })
    notifySpectator("Spectator", "Now watching " .. spectateTargetName .. ".", "teleport")

    return true
end

local function switchSpectatorTarget(targetInfo)
    if not spectateActive then
        return startSpectatorMode(targetInfo)
    end

    if type(targetInfo) ~= "table" then
        targetInfo = { targetServerId = targetInfo }
    end

    local targetServerId = math.floor(safeToNumber(targetInfo.targetServerId or targetInfo.serverId or targetInfo.id or targetInfo.killerServerId) or 0)
    local myServerId = GetPlayerServerId(PlayerId())
    if targetServerId <= 0 or targetServerId == myServerId then
        return false
    end

    if spectateTargetServerId == targetServerId then
        return true
    end

    local targetPlayer = GetPlayerFromServerId(targetServerId)
    if not targetPlayer or targetPlayer == -1 then
        return false
    end

    local targetPed = GetPlayerPed(targetPlayer)
    if not targetPed or targetPed == 0 or not DoesEntityExist(targetPed) then
        return false
    end

    if not setNetworkSpectatorMode(true, targetPed) then
        return false
    end

    local rawMode = targetInfo.spectateMode or targetInfo.mode or spectateMode
    if type(rawMode) == "string" and rawMode:lower() == "team" then
        spectateMode = "team"
    end

    spectateTargetServerId = targetServerId
    spectateTargetPed = targetPed
    spectateTargetName = targetInfo.targetName or targetInfo.name or GetPlayerName(targetPlayer) or (spectateMode == "team" and "Teammate" or "Player")
    spectateLostTargetTicks = 0
    spectateTeamRetargetRequestAt = 0
    spectateSwitchDebounceAt = 0
    setSpectatorHudVisible(true, spectateTargetName)
    TriggerServerEvent("respawnsys:spectatorStarted", targetServerId, { mode = spectateMode or "killer", lobbyId = spectateLobbyId or getCurrentLobbyId() })
    notifySpectator("Spectator", "Now watching " .. spectateTargetName .. ".", "teleport")
    return true
end
RegisterNetEvent("respawnsys:switchSpectateTarget")
AddEventHandler("respawnsys:switchSpectateTarget", function(targetInfo)
    switchSpectatorTarget(targetInfo)
end)
RegisterNetEvent("respawnsys:startSpectateTarget")
AddEventHandler("respawnsys:startSpectateTarget", function(targetInfo)
    if type(targetInfo) ~= "table" then
        targetInfo = { targetServerId = targetInfo }
    end

    startSpectatorMode(targetInfo)
end)

RegisterNetEvent("respawnsys:spectatorTargetStatus")
AddEventHandler("respawnsys:spectatorTargetStatus", function(reason, lobbyLabel)
    if not spectateActive then
        return
    end

    local description = "The player is no longer available. You were returned to your arena."
    if reason == "disconnect" then
        description = "The player disconnected. You were returned to your arena."
    elseif reason == "left_arena" then
        description = "The player left the arena. You were returned to your arena."
    elseif reason == "team_no_target" then
        description = "No living teammate is available right now. You will respawn when the round ends."
    elseif reason == "switched_arena" then
        if type(lobbyLabel) == "string" and lobbyLabel ~= "" then
            description = ("The player switched to %s. You were returned to your arena."):format(lobbyLabel)
        else
            description = "The player switched arena. You were returned to your arena."
        end
    end

    if reason == "team_no_target" and spectateMode == "team" then
        notifySpectator("Spectator", description, "cross")
        setSpectatorHudVisible(true, "Waiting for teammate")
        return
    end

    notifySpectator("Spectator ended", description, "cross")
    stopSpectatorMode(false)
end)

RegisterNetEvent("respawnsys:joinLobbyRequest")
AddEventHandler("respawnsys:joinLobbyRequest", function(lobbyId)
    local lobbyNumber = math.floor(safeToNumber(lobbyId) or 0)
    if lobbyNumber > 0 then
        TriggerServerEvent("pvp:joinLobby", lobbyNumber)
    end
end)

setDeathScreenVisible = function(visible)
    if visible then
        deathChatInputActive = false
        if type(SetNuiZIndex) == "function" then
            SetNuiZIndex(getDeathNuiTargetZIndex())
        end
        if deathNuiFocused then
            setDeathNuiFocusState(false, false)
        end
    else
        deathChatInputActive = false
        if deathNuiFocused then
            setDeathNuiFocusState(false, false)
        end
    end

    SendNUIMessage({
        action = visible and "showDeathScreen" or "hideDeathScreen",
        deathInfo = visible and (lastDeathInfo or normalizeDeathInfo(nil)) or nil,
        spectateContext = visible and buildDeathSpectateContext() or nil
    })
end

local function startRespawnAttempt()
    if spectateActive or not deathActive or isRespawning then
        return false
    end

    isRespawning = true
    respawnRequestSent = true
    respawnAttemptId = respawnAttemptId + 1
    local activeAttempt = respawnAttemptId

    TriggerServerEvent("pvp:requestRespawn")

    Citizen.SetTimeout(12000, function()
        if isRespawning and activeAttempt == respawnAttemptId then
            isRespawning = false
            respawnRequestSent = false
            deathActive = true

            TriggerEvent("bln_notify:send", {
                title = "Respawn Delay",
                description = "Respawn is taking too long. Please press E again.",
                icon = "alert",
                placement = "middle-right",
                duration = 4000
            })

            setDeathScreenVisible(true)
        end
    end)

    return true
end

local function getRecentServerDeathInfo()
    if not pendingServerDeathInfo then
        return nil
    end

    if (GetGameTimer() - (pendingServerDeathInfoAt or 0)) > serverDeathInfoTTL then
        pendingServerDeathInfo = nil
        pendingServerDeathInfoAt = 0
        return nil
    end

    return pendingServerDeathInfo
end

RegisterNetEvent("respawnsys:deathInfo")
AddEventHandler("respawnsys:deathInfo", function(info)
    pendingServerDeathInfo = normalizeDeathInfo(info)
    pendingServerDeathInfoAt = GetGameTimer()

    if deathActive then
        lastDeathInfo = mergeDeathInfo(lastDeathInfo, pendingServerDeathInfo)
        SendNUIMessage({
            action = "updateDeathInfo",
            deathInfo = lastDeathInfo
        })
    end
end)

RegisterNetEvent("pvp:playerDied")
AddEventHandler("pvp:playerDied", function(deathInfo)
    if spectatorUiTestActive then
        hideSpectatorUiTest(false)
    end

    if spectateActive then
        stopSpectatorMode(false)
    end

    if isRespawning then return end

    deathActive = true
    local fallbackInfo = buildDeathInfo()
    local mergedInfo = fallbackInfo

    if type(deathInfo) == "table" then
        mergedInfo = mergeDeathInfo(normalizeDeathInfo(deathInfo), mergedInfo)
    end

    local recentServerInfo = getRecentServerDeathInfo()
    if recentServerInfo then
        mergedInfo = mergeDeathInfo(mergedInfo, recentServerInfo)
    end

    lastDeathInfo = normalizeDeathInfo(mergedInfo)
    TriggerServerEvent("respawnsys:requestDeathInfo")
    setDeathScreenVisible(true)
end)

Citizen.CreateThread(function()
    if type(SetNuiZIndex) == "function" then
        SetNuiZIndex(getDeathNuiTargetZIndex())
    end

    while true do
        Citizen.Wait(200)
        local playerPed = PlayerPedId()

        if deathActive and type(SetNuiZIndex) == "function" then
            -- Keep this NUI layer on top while death screen is active.
            SetNuiZIndex(getDeathNuiTargetZIndex())
        end

        if spectateActive and type(SetNuiZIndex) == "function" then
            -- Keep spectator HUD above other UIs while spectating.
            SetNuiZIndex(spectatorNuiZIndex)
        end

        if deathActive and not spectateActive and deathNuiFocused then
            -- Keep death overlay passive so chat can always own focus/input.
            setDeathNuiFocusState(false, false)
        end

        if spectateActive then
            restoreSpectatorNuiFocusAfterChat()

            if deathNuiFocused then
                setDeathNuiFocusState(false, false)
            end
        end

        if DoesEntityExist(playerPed) then
            if IsEntityDead(playerPed) and not deathActive and not spectateActive then
                TriggerEvent("pvp:playerDied")
            elseif not IsEntityDead(playerPed) and deathActive and not isRespawning and not spectateActive then
                deathActive = false
                setDeathScreenVisible(false)
                lastDeathInfo = nil
                pendingServerDeathInfo = nil
                pendingServerDeathInfoAt = 0
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        local controlsActive = deathActive or spectateActive or isRespawning
        Citizen.Wait(controlsActive and 0 or 250)

        if controlsActive then

            if deathActive and not spectateActive then
                if isChatControlJustPressed() then
                    releaseDeathNuiFocusForChat()
                end

                -- Keep death-screen keys isolated to NUI so gameplay keybinds (e.g. leave arena on G) do not fire.
                DisableAllControlActions(0)
                DisableAllControlActions(1)
                DisableAllControlActions(2)
                EnableControlAction(0, chatOpenControl, true)
                EnableControlAction(1, chatOpenControl, true)
                EnableControlAction(2, chatOpenControl, true)
                EnableControlAction(0, spectateKey, true)
                EnableControlAction(1, spectateKey, true)
                EnableControlAction(2, spectateKey, true)
                forceClosePauseMenu()
            end

            local respawnPressed =
                IsControlJustReleased(0, respawnKey) or
                IsDisabledControlJustReleased(0, respawnKey) or
                IsControlJustReleased(1, respawnKey) or
                IsDisabledControlJustReleased(1, respawnKey) or
                IsControlJustReleased(2, respawnKey) or
                IsDisabledControlJustReleased(2, respawnKey)

            local spectatePressed =
                IsControlJustReleased(0, spectateKey) or
                IsDisabledControlJustReleased(0, spectateKey) or
                IsControlJustReleased(1, spectateKey) or
                IsDisabledControlJustReleased(1, spectateKey) or
                IsControlJustReleased(2, spectateKey) or
                IsDisabledControlJustReleased(2, spectateKey)

            if deathActive and respawnPressed then
                startRespawnAttempt()
            end

            if deathActive and spectatePressed and not spectateActive and not isRespawning then
                startSpectatorMode()
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        local now = GetGameTimer()
        local shouldSuppressPause = now < spectatePauseSuppressUntil

        if not spectateActive and not shouldSuppressPause then
            Citizen.Wait(220)
        else
            Citizen.Wait(0)

            if spectateActive then
                local escPressed = false
                local switchPressed = false
                local chatCursorOpen = externalNuiFocusActive or spectatorChatInputActive or (isNuiFocusActive() and not spectatorNuiFocusActive)

                if isChatControlJustPressed() then
                    releaseSpectatorNuiFocusForChat()
                    chatCursorOpen = true
                end

                setCinematicBarsEnabled(false)
                applySpectatorHudSuppressionFrame()
                -- While chat cursor/NUI focus is open, keep spectator camera fully locked.
                disableSpectatorGeneralControls(not chatCursorOpen)
                disableSpectatorExitControls()
                disableSpectatorCombatControls()
                disablePauseOpenControls()
                
                if not spectatorNuiFocusActive and not chatCursorOpen then
                    for _, key in ipairs(spectatorExitKeys) do
                        if IsControlJustPressed(0, key) or IsDisabledControlJustPressed(0, key)
                            or IsControlJustPressed(1, key) or IsDisabledControlJustPressed(1, key)
                            or IsControlJustPressed(2, key) or IsDisabledControlJustPressed(2, key)
                            or IsControlJustReleased(0, key) or IsDisabledControlJustReleased(0, key)
                            or IsControlJustReleased(1, key) or IsDisabledControlJustReleased(1, key)
                            or IsControlJustReleased(2, key) or IsDisabledControlJustReleased(2, key) then
                            escPressed = true
                        end
                    end
                end

                if spectateMode == "team" and not spectatorNuiFocusActive and not chatCursorOpen then
                    if IsControlJustPressed(0, spectatorSwitchKey) or IsDisabledControlJustPressed(0, spectatorSwitchKey)
                        or IsControlJustPressed(1, spectatorSwitchKey) or IsDisabledControlJustPressed(1, spectatorSwitchKey)
                        or IsControlJustPressed(2, spectatorSwitchKey) or IsDisabledControlJustPressed(2, spectatorSwitchKey)
                        or IsControlJustReleased(0, spectatorSwitchKey) or IsDisabledControlJustReleased(0, spectatorSwitchKey)
                        or IsControlJustReleased(1, spectatorSwitchKey) or IsDisabledControlJustReleased(1, spectatorSwitchKey)
                        or IsControlJustReleased(2, spectatorSwitchKey) or IsDisabledControlJustReleased(2, spectatorSwitchKey) then
                        switchPressed = true
                    end
                end

                forceClosePauseMenu()

                if switchPressed then
                    requestTeamSpectatorSwitch()
                end

                if escPressed then
                    local tickNow = GetGameTimer()
                    if tickNow >= spectateExitDebounceAt and spectateExitRequestAt == 0 then
                        spectateExitDebounceAt = tickNow + 260
                        spectateExitRequestAt = tickNow + 120
                        suppressPauseMenuFor(1600)
                    end
                end

                if spectateExitRequestAt ~= 0 then
                    local tickNow = GetGameTimer()
                    if tickNow >= spectateExitRequestAt then
                        spectateExitRequestAt = 0
                        suppressPauseMenuFor(1600)
                        tryManualSpectatorExit(true)
                    end
                end
            elseif shouldSuppressPause then
                disablePauseOpenControls()
                forceClosePauseMenu()
            end
        end
    end
end)

RegisterNetEvent("respawnsys:externalNuiFocusChanged")
AddEventHandler("respawnsys:externalNuiFocusChanged", function(isFocused)
    externalNuiFocusActive = isFocused == true

    if spectateActive and not externalNuiFocusActive and not spectatorChatInputActive then
        setSpectatorNuiFocus(true)
    end
end)

RegisterNUICallback("deathRespawnPressed", function(_, cb)
    startRespawnAttempt()
    cb("ok")
end)

RegisterNUICallback("deathSpectatePressed", function(_, cb)
    startSpectatorMode()
    cb("ok")
end)

RegisterNUICallback("spectatorExitPressed", function(_, cb)
    if spectateActive then
        tryManualSpectatorExit(true)
    elseif spectatorUiTestActive then
        hideSpectatorUiTest(true)
    end
    cb("ok")
end)

RegisterNUICallback("spectatorSwitchPressed", function(_, cb)
    requestTeamSpectatorSwitch()
    cb("ok")
end)

RegisterCommand("testspectateui", function(_, args)
    local firstArg = args and args[1] and tostring(args[1]):lower() or "show"
    if firstArg == "off" or firstArg == "hide" or firstArg == "0" then
        hideSpectatorUiTest(true)
        return
    end

    local targetNameStartIndex = 1
    if firstArg == "on" or firstArg == "show" or firstArg == "1" then
        targetNameStartIndex = 2
    end

    local targetNameParts = {}
    for index = targetNameStartIndex, #(args or {}) do
        local piece = tostring(args[index] or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if piece ~= "" then
            targetNameParts[#targetNameParts + 1] = piece
        end
    end

    local targetName = (#targetNameParts > 0) and table.concat(targetNameParts, " ") or "Killer"
    showSpectatorUiTest(targetName)
end, false)

Citizen.CreateThread(function()
    while true do
        if not spectateActive then
            Citizen.Wait(650)
        else
            Citizen.Wait(350)

            local targetPlayer = spectateTargetServerId and GetPlayerFromServerId(spectateTargetServerId) or -1
            if targetPlayer and targetPlayer ~= -1 then
                local targetPed = GetPlayerPed(targetPlayer)
                if targetPed and targetPed ~= 0 and DoesEntityExist(targetPed) then
                    if targetPed ~= spectateTargetPed then
                        spectateTargetPed = targetPed
                        setNetworkSpectatorMode(true, targetPed)
                    end

                    if spectateMode == "team" and (IsEntityDead(targetPed) or IsPedFatallyInjured(targetPed)) then
                        local now = GetGameTimer()
                        if now >= spectateTeamRetargetRequestAt then
                            spectateTeamRetargetRequestAt = now + 2500
                            TriggerServerEvent("pvp:requestTeamSpectateTarget", spectateTargetServerId)
                        end
                    end

                    spectateLostTargetTicks = 0
                else
                    spectateLostTargetTicks = spectateLostTargetTicks + 1
                end
            else
                spectateLostTargetTicks = spectateLostTargetTicks + 1
            end

            if spectateLostTargetTicks >= SPECTATE_LOST_TARGET_TICKS_MAX then
                if spectateMode == "team" then
                    local now = GetGameTimer()
                    if now >= spectateTeamRetargetRequestAt then
                        spectateTeamRetargetRequestAt = now + 2500
                        TriggerServerEvent("pvp:requestTeamSpectateTarget", spectateTargetServerId)
                    end
                    spectateLostTargetTicks = 0
                    setSpectatorHudVisible(true, "Waiting for teammate")
                else
                    notifySpectator("Spectator ended", "The player is unavailable. You were returned to your arena.", "cross")
                    stopSpectatorMode(false)
                end
            end
        end
    end
end)

RegisterNetEvent("pvp:forceCloseDeathScreen")
AddEventHandler("pvp:forceCloseDeathScreen", function()
    if spectateActive then
        stopSpectatorMode(false)
        return
    end

    if spectatorUiTestActive then
        hideSpectatorUiTest(false)
    end

    respawnAttemptId = respawnAttemptId + 1
    deathActive = false
    isRespawning = false
    respawnRequestSent = false
    lastDeathInfo = nil
    pendingServerDeathInfo = nil
    pendingServerDeathInfoAt = 0
    setSpectatorHudSuppressed(false)
    setSpectatorHudVisible(false)
    setSpectatorNuiFocus(false)
    destroySpectateCamera()
    clearSpectatorState()
    setCinematicBarsEnabled(false)
    forceClosePauseMenu()
    setDeathScreenVisible(false)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    if spectateActive then
        TriggerServerEvent("respawnsys:spectatorStopped")
        setNetworkSpectatorMode(false, spectateTargetPed)
        destroySpectateCamera()
        setLocalSpectatorState(false)
        setSpectatorHudVisible(false)
        setSpectatorNuiFocus(false)
        clearSpectatorState()
    end

    destroySpectateCamera()

    setSpectatorHudSuppressed(false)
    setCinematicBarsEnabled(false)
    forceClosePauseMenu()

    if spectatorUiTestActive then
        hideSpectatorUiTest(false)
    end

    if deathNuiFocused then
        setDeathNuiFocusState(false, false)
    end
    setSpectatorNuiFocus(false)
end)

RegisterNetEvent("pvp:respawnApproved")
AddEventHandler("pvp:respawnApproved", function()
    if spectateActive then
        stopSpectatorMode(false)
    end

    if not isRespawning then return end

    respawnRequestSent = false
    deathActive = false
    setDeathScreenVisible(false)
end)

RegisterNetEvent("pvp:respawnDenied")
AddEventHandler("pvp:respawnDenied", function()
    if spectateActive then
        stopSpectatorMode(false)
    end

    respawnAttemptId = respawnAttemptId + 1
    isRespawning = false
    respawnRequestSent = false
    deathActive = true
    setDeathScreenVisible(true)
end)

RegisterNetEvent("pvp:teleportPlayer")
AddEventHandler("pvp:teleportPlayer", function(coords)
    if spectateActive then
        stopSpectatorMode(false)
    end

    if not isRespawning then return end

    local x = coords and tonumber(coords.x) or nil
    local y = coords and tonumber(coords.y) or nil
    local z = coords and tonumber(coords.z) or nil
    if not x or not y or not z then
        isRespawning = false
        deathActive = true
        setDeathScreenVisible(true)
        return
    end

    respawnAttemptId = respawnAttemptId + 1
    respawnRequestSent = false

    local playerPed = PlayerPedId()
    if not DoesEntityExist(playerPed) then
        isRespawning = false
        deathActive = true
        setDeathScreenVisible(true)
        return
    end

    NetworkResurrectLocalPlayer(x, y, z + 0.2, 0.0, true, false)
    Citizen.Wait(500)

    TriggerServerEvent("pvp:syncPlayerAfterRespawn")

    Citizen.Wait(100)
    reloadCharacter()

    isRespawning = false
    deathActive = false
    lastDeathInfo = nil
    pendingServerDeathInfo = nil
    pendingServerDeathInfoAt = 0
end)
