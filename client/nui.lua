RegisterNUICallback('close', function(data, cb)
    TriggerServerEvent('trisport:requestLeave')
    cb('ok')
end)
RegisterNUICallback('ready', function(data, cb)
    cb('ok')
end)
RegisterNetEvent('trisport:playSound')
AddEventHandler('trisport:playSound', function(soundName)
    if Config.UseCustomSounds then
        SendNUIMessage({
            action = 'playSound',
            sound  = soundName,
        })
    end
end)