local nuiOpen = false

RegisterNetEvent('crosshair:openUI', function()
    SetNuiFocus(true, true)
    nuiOpen = true

    SendNUIMessage({
        action = "openUI"
    })

    -- Thread care ascultă ESC/Back
    Citizen.CreateThread(function()
        while nuiOpen do
            Citizen.Wait(0)
            if IsControlJustPressed(0, 322) or IsControlJustPressed(0, 200) then -- ESC sau BACK
                SetNuiFocus(false, false)
                SendNUIMessage({ action = "forceClose" })
                nuiOpen = false
            end
        end
    end)
end)

RegisterNUICallback("close", function(data, cb)
    SetNuiFocus(false, false)
    nuiOpen = false
    cb({})
end)

RegisterCommand('crosshair', function()
    TriggerEvent('crosshair:openUI')
end)

local alreadyRegistered = false

if not alreadyRegistered then
    RegisterNUICallback("notify_save", function(_, cb)
        TriggerEvent("bln_notify:send", {
            title = "🎯 Crosshair",
            description = "Settings have been successfully saved!",
            icon = "crosshair",
            placement = "middle-right",
            duration = 5000
        })
        cb({})
    end)

    RegisterNUICallback("notify_reset", function(_, cb)
        TriggerEvent("bln_notify:send", {
            title = "🎯 Crosshair",
            description = "Settings have been reset to default values!",
            icon = "crosshair-reset",
            placement = "middle-right",
            duration = 5000
        })
        cb({})
    end)

    alreadyRegistered = true
end

