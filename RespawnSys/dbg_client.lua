
-- Dezactivare forțată a tuturor mesajelor `print()`
_G.print = function(...) end

-- Blochează evenimentele interne care trimit mesaje în consolă
AddEventHandler("__cfx_internal:serverPrint", function(msg)
    CancelEvent()
end)

-- Blochează orice mesaje de debug venite de la resursele personalizate
RegisterNetEvent("debug_message")
AddEventHandler("debug_message", function(msg)
    CancelEvent()
end)

print("^2[DEBUG DISABLE] Debugging messages have been globally blocked.^7")

-- Dezactivare forțată a tuturor mesajelor `print()`