local VorpCore = {}
TriggerEvent("getCore", function(core) VorpCore = core end)

local inSafeZone = false

RegisterNetEvent("safezone:forceSpawn")
AddEventHandler("safezone:forceSpawn", function(x, y, z)
    local playerPed = PlayerPedId()

    -- ✅ Înghețăm poziția pentru a preveni glitch-uri
    FreezeEntityPosition(playerPed, true)

    -- ✅ Setăm coordonatele instant
    SetEntityCoords(playerPed, x, y, z, false, false, false, true)
    
    -- ✅ Dezghețăm jucătorul după teleport
    Citizen.Wait(100) -- Mic delay pentru siguranță
    FreezeEntityPosition(playerPed, false)

   --- print("✔ Te-ai teleportat instant la Safezone: ", x, y, z)
end)




------------------ MARK CUSTOM WEAPONS 2 ( AFARA ) ------------------
local markers = {
    {
        coords = vector3(-1300.9960, 412.0528, 95.3839),
        color = { r = 97, g = 255, b = 97, a = 180 }
    },
    {
        coords = vector3(-1303.4698, 394.5351, 95.4293),
        color = { r = 97, g = 255, b = 97, a = 180 }
    }
}


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        for _, marker in pairs(markers) do
            local c = marker.coords
            local clr = marker.color

            DrawMarker(
                0x94FDAE17,
                c.x, c.y, c.z - 1.0,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                0.5, 0.5, 0.5,
                clr.r, clr.g, clr.b, clr.a,
                false, true, 2,
                false, false
            )
        end
    end
end)

------------------ MARK CUSTOM WEAPONS 2 ( AFARA ) ------------------

Citizen.CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if IsPedOnMount(ped) then
            local horse = GetMount(ped)
            if horse ~= 0 then
                -- Core Stamina
                Citizen.InvokeNative(0xC6258F41D86676E0, horse, 1.0)
                -- Rezervă stamina
                Citizen.InvokeNative(0xB68CFAF83A02768D, horse, 1.0)
                -- Core vizual stamina
                Citizen.InvokeNative(0xF6A7C08DF2E28B28, horse, 1.0)
                -- Core health
                Citizen.InvokeNative(0xE7DD1F5DFEEE61AC, horse, 1.0)
                -- Restabilire stamina internă
                RestorePedStamina(horse, 100.0)
                -- Setare HP maxim
                SetEntityHealth(horse, GetEntityMaxHealth(horse))
                -- Ignorare scădere stamina
                Citizen.InvokeNative(0xB90C94B328CCAB00, horse, true)

                -- ✅ Adăugat: sincronizare atribut pentru stamina
                Citizen.InvokeNative(0x497A6539BB0E8787, horse, 1, true) -- force core override
                Citizen.InvokeNative(0x4AF5A4C7B9157D14, horse, 1, 1.0) -- ATTRIBUTE_STAMINA = 1

                -- ✅ Actualizare vizuală bară (fulger)
                Citizen.InvokeNative(0xB8EF261DAA984F49, horse, 1.0)

                Wait(250)
            else
                Wait(1000)
            end
        else
            Wait(1000)
        end
    end
end)

