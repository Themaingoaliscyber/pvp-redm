HudClient = HudClient or {}
HudClient.Config = Config or {}
HudClient.State = HudClient.State or {
    hudVisible = Config.DefaultHUDVisible ~= false,
    rankVisible = Config.DefaultRankHUDVisible ~= false,
    editMode = false
}

function HudClient.Debug(message, ...)
    if not HudClient.Config.DebugMode then
        return
    end

    print(("[hud] " .. tostring(message)):format(...))
end

function HudClient.SendUiMessage(payload)
    SendNUIMessage(payload)
end

function HudClient.SetEditMode(state)
    HudClient.State.editMode = state == true

    SetNuiFocus(HudClient.State.editMode, HudClient.State.editMode)

    HudClient.SendUiMessage({
        action = "setEditMode",
        enabled = HudClient.State.editMode
    })

    TriggerEvent("funcker_topplayers:editorModeChanged", HudClient.State.editMode)

    if HudClient.State.editMode then
        TriggerEvent("funcker_topplayers:requestHudPosition")
    end
end

function HudClient.SetHudVisible(state)
    HudClient.State.hudVisible = state ~= false
    HudClient.SendUiMessage({
        action = "toggleHUD",
        visible = HudClient.State.hudVisible
    })
end

function HudClient.SetRankVisible(state)
    HudClient.State.rankVisible = state ~= false
    HudClient.SendUiMessage({
        action = "toggleRankHUD",
        visible = HudClient.State.rankVisible
    })
end

CreateThread(function()
    Wait(1000)
    HudClient.SetHudVisible(HudClient.State.hudVisible)
    HudClient.SetRankVisible(HudClient.State.rankVisible)
end)

RegisterCommand("edithud", function()
    HudClient.SetEditMode(not HudClient.State.editMode)
end, false)

RegisterNUICallback("closeHudEditor", function(_, cb)
    HudClient.SetEditMode(false)
    cb({ ok = true })
end)

RegisterNUICallback("setExternalHudPosition", function(data, cb)
    if type(data) == "table" and data.key == "topplayers" then
        TriggerEvent("funcker_topplayers:setHudPosition", data.position, data.persist == true)
    end

    cb({ ok = true })
end)

RegisterNUICallback("resetExternalHudLayout", function(data, cb)
    if type(data) ~= "table" or data.key == nil or data.key == "topplayers" then
        TriggerEvent("funcker_topplayers:resetHudPosition")
    end

    cb({ ok = true })
end)

RegisterNetEvent("funcker_hud:externalHudPosition")
AddEventHandler("funcker_hud:externalHudPosition", function(payload)
    if type(payload) ~= "table" or payload.key ~= "topplayers" then
        return
    end

    HudClient.SendUiMessage({
        action = "setExternalHudPosition",
        key = payload.key,
        position = payload.position
    })
end)

AddEventHandler("onClientResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    TriggerEvent("funcker_topplayers:editorModeChanged", false)
    SetNuiFocus(false, false)
end)
