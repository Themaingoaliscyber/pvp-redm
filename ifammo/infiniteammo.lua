
local limitaMunitie = 200
local pragReincarcare = 50

local armeCuMunitieStandard = {
    [GetHashKey("WEAPON_SNIPERRIFLE_CARCANO")] = true,
    [GetHashKey("WEAPON_SNIPERRIFLE_ROLLINGBLOCK")] = true,
    [GetHashKey("WEAPON_RIFLE_BOLTACTION")] = true,
    [GetHashKey("WEAPON_RIFLE_SPRINGFIELD")] = true
}

local armeCuSagetiInfinite = {
    [GetHashKey("WEAPON_BOW")] = true,
    [GetHashKey("WEAPON_BOW_IMPROVED")] = true
}

local tipuriHV = {
    [GetHashKey("AMMO_REVOLVER")] = GetHashKey("AMMO_REVOLVER_HIGH_VELOCITY"),
    [GetHashKey("AMMO_PISTOL")] = GetHashKey("AMMO_PISTOL_HIGH_VELOCITY"),
    [GetHashKey("AMMO_REPEATER")] = GetHashKey("AMMO_REPEATER_HIGH_VELOCITY"),
    [GetHashKey("AMMO_RIFLE")] = GetHashKey("AMMO_RIFLE_HIGH_VELOCITY"),
    [GetHashKey("AMMO_22")] = GetHashKey("AMMO_22_HIGH_VELOCITY"),
    [GetHashKey("AMMO_SHOTGUN")] = GetHashKey("AMMO_SHOTGUN"),

}

local ultimaArma = nil

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300)
        local ped = PlayerPedId()
        if DoesEntityExist(ped) then
            local _, arma = GetCurrentPedWeapon(ped, true)
            if arma ~= ultimaArma and arma ~= GetHashKey("WEAPON_UNARMED") then
                ultimaArma = arma
                AtribuieMunitie(ped, arma)
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()
        if DoesEntityExist(ped) then
            local _, arma = GetCurrentPedWeapon(ped, true)
            if arma and arma ~= GetHashKey("WEAPON_UNARMED") then
                ReincarcaDacaESub(ped, arma)
            end
        end
    end
end)

function ReincarcaDacaESub(ped, arma)
    local tipAmmo = GetPedAmmoTypeFromWeapon(ped, arma)
    local ammoCurenta = GetAmmoInPedWeapon(ped, arma)

    if armeCuSagetiInfinite[arma] then
        if ammoCurenta < pragReincarcare then
            SetPedAmmoByType(ped, GetHashKey("AMMO_ARROW"), limitaMunitie)
        end
        return
    end

    if armeCuMunitieStandard[arma] then
        if ammoCurenta < pragReincarcare then
            SetPedAmmoByType(ped, tipAmmo, limitaMunitie)
        end
        return
    end

    local hvAmmo = tipuriHV[tipAmmo]
    if hvAmmo and ammoCurenta < pragReincarcare then
        SetPedAmmoByType(ped, hvAmmo, limitaMunitie)
    elseif ammoCurenta < pragReincarcare then
        SetPedAmmoByType(ped, tipAmmo, limitaMunitie)
    end
end

function AtribuieMunitie(ped, arma)
    if armeCuSagetiInfinite[arma] then
        SetPedAmmoByType(ped, GetHashKey("AMMO_ARROW"), limitaMunitie)
        return
    end

    if armeCuMunitieStandard[arma] then
        local tipAmmo = GetPedAmmoTypeFromWeapon(ped, arma)
        SetPedAmmoByType(ped, tipAmmo, limitaMunitie)
        return
    end

    local tipAmmo = GetPedAmmoTypeFromWeapon(ped, arma)
    local hvAmmo = tipuriHV[tipAmmo]
    if hvAmmo then
        SetPedAmmoByType(ped, hvAmmo, limitaMunitie)
        SetPedAmmoByType(ped, tipAmmo, 0)
    else
        SetPedAmmoByType(ped, tipAmmo, limitaMunitie)
    end
end

Citizen.CreateThread(function()
    while not NetworkIsSessionStarted() do
        Citizen.Wait(500)
    end
    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()
        if ped ~= -1 then
            RestorePlayerStamina(PlayerId(), 1.0)
        end
    end
end)


