local currentTime = nil
local dynamicTime = nil
local syncEnabled = true
local timeMode = "synced"

local DYNAMIC_SECONDS_PER_GAME_MINUTE = 2

local function applyLocalTime(hour, minute, second, transition)
    Citizen.InvokeNative(0x669E223E64B1903C, hour, minute, second or 0, transition or 1000, true)
end

local function getDynamicClock()
    local elapsedSeconds = math.floor((GetGameTimer() - dynamicTime.startedAt) / 1000)
    local elapsedGameMinutes = math.floor(elapsedSeconds / DYNAMIC_SECONDS_PER_GAME_MINUTE)
    local totalMinutes = (dynamicTime.baseMinutes + elapsedGameMinutes) % 1440

    return math.floor(totalMinutes / 60), totalMinutes % 60
end

RegisterNetEvent("weathersync:setMyTime")
AddEventHandler("weathersync:setMyTime", function(h, m, s, t, lockTime)
    if lockTime == nil then
        lockTime = true
    end

    syncEnabled = false

    if lockTime then
        timeMode = "locked"
        currentTime = {hour = h, minute = m}
        dynamicTime = nil
        applyLocalTime(h, m, s or 0, t or 1000)
    else
        timeMode = "dynamic"
        currentTime = nil
        dynamicTime = {
            baseMinutes = ((h * 60) + m) % 1440,
            startedAt = GetGameTimer()
        }
        applyLocalTime(h, m, s or 0, t or 1000)
    end
end)

RegisterNetEvent("weathersync:setSyncEnabled")
AddEventHandler("weathersync:setSyncEnabled", function(enable)
    syncEnabled = enable

    if enable then
        timeMode = "synced"
        currentTime = nil
        dynamicTime = nil
    end
end)

-- Keep the personal time override active while server sync is disabled.
Citizen.CreateThread(function()
    while true do
        if not syncEnabled then
            if timeMode == "locked" and currentTime then
                applyLocalTime(currentTime.hour, currentTime.minute, 0, 1000)
            elseif timeMode == "dynamic" and dynamicTime then
                local hour, minute = getDynamicClock()
                applyLocalTime(hour, minute, 0, 1000)
            end
        end

        Wait(500)
    end
end)
