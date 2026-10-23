-- in-memory spawnpoint array for this script execution instance
local spawnPoints = {}
local autoSpawnEnabled = false
local autoSpawnCallback

-- Suport pentru mapmanager maps
AddEventHandler('getMapDirectives', function(add)
    add('spawnpoint', function(state, model)
        return function(opts)
            local x, y, z, heading

            local s, e = pcall(function()
                if opts.x then
                    x = opts.x
                    y = opts.y
                    z = opts.z
                else
                    x = opts[1]
                    y = opts[2]
                    z = opts[3]
                end

                x = x + 0.0001
                y = y + 0.0001
                z = z + 0.0001

                heading = opts.heading and (opts.heading + 0.01) or 0

                addSpawnPoint({
                    x = x, y = y, z = z,
                    heading = heading,
                    model = model
                })

                if not tonumber(model) then
                    model = GetHashKey(model, _r)
                end

                state.add('xyz', { x, y, z })
                state.add('model', model)
            end)

            if not s then
                Citizen.Trace(e .. "\n")
            end
        end
    end, function(state, arg)
        for i, sp in ipairs(spawnPoints) do
            if sp.x == state.xyz[1] and sp.y == state.xyz[2] and sp.z == state.xyz[3] and sp.model == state.model then
                table.remove(spawnPoints, i)
                return
            end
        end
    end)
end)

-- Încarcă locații de spawn dintr-un JSON
function loadSpawns(spawnString)
    local data = json.decode(spawnString)
    if not data.spawns then
        error("no 'spawns' in JSON data")
    end

    for i, spawn in ipairs(data.spawns) do
        addSpawnPoint(spawn)
    end
end

local spawnNum = 1

function addSpawnPoint(spawn)
    if not tonumber(spawn.x) or not tonumber(spawn.y) or not tonumber(spawn.z) then
        error("Invalid spawn position")
    end

    if not tonumber(spawn.heading) then
        error("Invalid spawn heading")
    end

    local model = spawn.model
    if not tonumber(spawn.model) then
        model = GetHashKey(spawn.model)
    end

    if not IsModelInCdimage(model) then
        error("Invalid spawn model")
    end

    spawn.model = model
    spawn.idx = spawnNum
    spawnNum = spawnNum + 1
    table.insert(spawnPoints, spawn)
end

function removeSpawnPoint(spawn)
    for i = 1, #spawnPoints do
        if spawnPoints[i].idx == spawn then
            table.remove(spawnPoints, i)
            return
        end
    end
end

function setAutoSpawn(enabled)
    autoSpawnEnabled = false
   --- print("[SpawnManager] Auto-spawn complet dezactivat!")
end

function setAutoSpawnCallback(cb)
    autoSpawnCallback = nil
    autoSpawnEnabled = false
   --- print("[SpawnManager] Callback auto-spawn blocat! Doar respawn manual este permis.")
end

-- Funcție care îngheață/dezgheață jucătorul
local function freezePlayer(id, freeze)
    local player = id
    SetPlayerControl(player, not freeze, false)
    local ped = GetPlayerPed(player)

    if not freeze then
        if not IsEntityVisible(ped) then
            SetEntityVisible(ped, true)
        end

        if not IsPedInAnyVehicle(ped) then
            SetEntityCollision(ped, true)
        end

        FreezeEntityPosition(ped, false)
        SetPlayerInvincible(player, false)
    else
        if IsEntityVisible(ped) then
            SetEntityVisible(ped, false)
        end

        SetEntityCollision(ped, false)
        FreezeEntityPosition(ped, true)
        SetPlayerInvincible(player, true)
        ClearPedTasksImmediately(ped)
    end
end

function loadScene(x, y, z)
	if not NewLoadSceneStart then
		return
	end

    NewLoadSceneStart(x, y, z, 0.0, 0.0, 0.0, 20.0, 0)

    while IsNewLoadSceneActive() do
        networkTimer = GetNetworkTimer()

        NetworkUpdateLoadScene()
    end
end


-- Spawn manual la conectare
RegisterNetEvent("spawnmanager:firstSpawn")
AddEventHandler("spawnmanager:firstSpawn", function()
    print("[SpawnManager] Executăm primul spawn al jucătorului...")

    Citizen.CreateThread(function()
        local timeout = 10
        while #spawnPoints == 0 and timeout > 0 do
           --- print("[SpawnManager] Așteptăm spawn points... (" .. timeout .. "s rămas)")
            Citizen.Wait(1000)
            timeout = timeout - 1
        end

        if #spawnPoints > 0 then
            exports.spawnmanager:spawnPlayer()
        else
           --- print("[SpawnManager] Eroare: Nu există locații de spawn disponibile!")
        end
    end)
end)

-- Spawn manual la respawn
RegisterNetEvent("spawnmanager:manualRespawn")
AddEventHandler("spawnmanager:manualRespawn", function()
    print("[SpawnManager] Respawn manual cerut...")
    exports.spawnmanager:spawnPlayer()
end)

-- Spawn player doar când este cerut manual
function spawnPlayer(spawnIdx, cb)
    if #spawnPoints == 0 then
       --- print("[SpawnManager] Eroare: Niciun spawn point definit!")
        return
    end

    if not spawnIdx then
        spawnIdx = GetRandomIntInRange(1, #spawnPoints + 1)
    end

    local spawn = spawnPoints[spawnIdx]
    if not spawn then
        print("[SpawnManager] Eroare: Spawn index invalid!")
        return
    end

   --- print(string.format("[SpawnManager] Spawn la: x = %.2f, y = %.2f, z = %.2f", spawn.x, spawn.y, spawn.z))

    local ped = PlayerPedId()
    freezePlayer(PlayerId(), true)
    RequestCollisionAtCoord(spawn.x, spawn.y, spawn.z)
    SetEntityCoordsNoOffset(ped, spawn.x, spawn.y, spawn.z, false, false, false, true)
    NetworkResurrectLocalPlayer(spawn.x, spawn.y, spawn.z, spawn.heading, true, true, false)
    ClearPedTasksImmediately(ped)
    RemoveAllPedWeapons(ped)
    ClearPlayerWantedLevel(PlayerId())

    DoScreenFadeIn(500)
    freezePlayer(PlayerId(), false)
    TriggerEvent('playerSpawned', spawn)

    if cb then cb(spawn) end
end

-- Monitorizează moartea și NU permite auto-respawn
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(50)
        local playerPed = PlayerPedId()

        if playerPed and playerPed ~= -1 then
            if IsEntityDead(playerPed) then
               --- print("[SpawnManager] Jucătorul a murit, dar auto-respawn este dezactivat.")
            end
        end
    end
end)

function forceRespawn()
   --- print("[SpawnManager] Respawn forțat cerut...")
    TriggerEvent("spawnmanager:manualRespawn") -- Redirecționăm către respawn manual
end

exports('forceRespawn', forceRespawn)


exports('spawnPlayer', spawnPlayer)
exports('addSpawnPoint', addSpawnPoint)
exports('removeSpawnPoint', removeSpawnPoint)
exports('setAutoSpawn', setAutoSpawn)
exports('setAutoSpawnCallback', setAutoSpawnCallback)
