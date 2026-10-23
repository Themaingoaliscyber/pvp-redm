KeyZone = nil
EnCoords = nil
DisBetewewn = nil
ZoneName = nil
Citizen.CreateThread(function()
  while true do
    for k,v in pairs(AFU.Config) do
      EnCoords = GetEntityCoords(PlayerPedId())
      for _,_v in pairs(v) do
        DisBetewewn = GetDistanceBetweenCoords(EnCoords,_v.x,_v.y,_v.z,false)  < _v.radius+1.5 
        while DisBetewewn do
          local ped = PlayerPedId()
          EnCoords = GetEntityCoords(ped)
          DisBetewewn = GetDistanceBetweenCoords(EnCoords,_v.x,_v.y,_v.z,false) < _v.radius+1.5
          SetEntityInvincible(ped, AFU.IsGodModeInSafeZone)
          if Citizen.InvokeNative(0x2311F15D971AA680 , PlayerPedId()) > -1 or Citizen.InvokeNative(0x0E99E3BF11BB6367 , PlayerPedId()) or Citizen.InvokeNative(0x3BDFCF25B58B0415, PlayerPedId()) then
              exports['LRP_Notify']:DisplayLeftNotification(
                k,
                "~COLOR_RED~NO FIGHTING IN THIS ZONE",
                'INVENTORY_ITEMS',
                'ammo_throwing_knives_trail',
                3000
              )
              Citizen.InvokeNative(0xAAA34F8A7CB32098,PlayerPedId(),false,false)

          end
          DisableControlAction(0,  0x60c81cde,  true)
          DisableControlAction(0,  0xc904196d,  true)
          DisableControlAction(0,  0xD0C1FEFF,  true)
          DisableControlAction(0,  0xADEAF48C,  true)
          DisableControlAction(0,  0x018C47CF,  true)
          DisableControlAction(0,  0x91C9A817,  true)
          DisableControlAction(0,  0xBE1F4699,  true)
          DisableControlAction(0,  0x67ED272E,  true)
          DisableControlAction(0,  0x78ed2132,  true)
          DisableControlAction(0,  0x162afeb8,  true)
          DisableControlAction(0,  0x0283c582,  true)
          DisableControlAction(0,  0x07ce1e61,  true)
          DisableControlAction(0,  0xb2f377e8,  true)
          KeyZone = _v
          ZoneName = k
          
          Citizen.Wait(0)
        end
        
        ZoneName = nil
        KeyZone = nil
      end
    end
    Citizen.Wait(7)
  end
end)



Citizen.CreateThread(function()
  if AFU.DebugMode then
    while true do
      while DisBetewewn do
        Citizen.InvokeNative(0x2A32FAA57B937173,-1795314153 , KeyZone.x ,KeyZone.y, KeyZone.z-1.1, 0.0, 0.0, 0.0,0.0, 0.0, 0.0, KeyZone.radius*2,KeyZone.radius*2,20.0, 100, 1, 1, 150, false, false, 0, false, false)
        Citizen.Wait(7)
      end
      Citizen.Wait(200)
    end
  else
    while true do
      if KeyZone ~= nil then
        ShowUiZone()
        while DisBetewewn do
          Citizen.Wait(0)
        end
        HideUiZone()
      end

      Citizen.Wait(250)
    end
  end
end)

ShowUiZone = function() 
  SendNUIMessage({
    action = 'show',
    key = ZoneName
  })
end

HideUiZone = function()
  SendNUIMessage({
    action = 'hide'
  })

end

function DrawText(x, y, text)
  SetTextScale(0.45, 0.45)
  SetTextDropshadow( 5, 0, 0, 0,255)
  SetTextFontForCurrentCommand(1)
  local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
  SetTextCentre(1)
  DisplayText(str,x,y)
  local factor = (string.len(text)) / 150
  DrawSprite("generic_textures", "hud_menu_4a", x, y+0.018,0.0009+ factor, 0.05, 0.1, 0, 0, 0, 150, 0)
  DrawSprite("menu_textures", "medal_gold", x, y-0.005 ,0.042*1.5, 0.07*1.5, 0.1, 255, 255, 255, 255, 0)

end

