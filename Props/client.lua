Citizen.CreateThread(function()
    for _, obj in ipairs(objects) do
        RequestModel(obj.model)
        while not HasModelLoaded(obj.model) do
            Wait(100)
        end

        local created = CreateObject(obj.model, obj.coords.x, obj.coords.y, obj.coords.z, false, false, true)
        SetEntityRotation(created, obj.rotation.x, obj.rotation.y, obj.rotation.z, 2, true)
        FreezeEntityPosition(created, true)
    end
end)
