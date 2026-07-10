local inRoom           = false
local inRace           = false
local roomId           = 0
local raceVehicle      = nil
local checkpoints      = {}
local currentCp        = 0
local totalCp          = 0
local checkpointBlip   = nil
local finishBlip       = nil
local cachedPed        = 0
local cpDetectionActive = false
local function refreshPed()
    cachedPed = PlayerPedId()
    return cachedPed
end
local function deleteVehicle(veh)
    if veh and DoesEntityExist(veh) then
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)
    end
end
local function removeBlip(blip)
    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
    end
end
local function spawnVehicle(model, pos, color, cb)
    local hash = GetHashKey(model)
    RequestModel(hash)
    local timeout = 50
    while not HasModelLoaded(hash) and timeout > 0 do
        Citizen.Wait(100)
        timeout = timeout - 1
    end
    if not HasModelLoaded(hash) then
        print('[Trisport] ERROR: Failed to load model: ' .. model)
        return
    end
    local ped = refreshPed()
    local veh = CreateVehicle(hash, pos.x, pos.y, pos.z, pos.w or 0.0, true, false)
    if DoesEntityExist(veh) then
        SetEntityAsMissionEntity(veh, true, true)
        SetVehicleOnGroundProperly(veh)
        SetPedIntoVehicle(ped, veh, -1)
        if color then
            SetVehicleCustomPrimaryColour(veh, color.r, color.g, color.b)
            SetVehicleCustomSecondaryColour(veh, color.r, color.g, color.b)
        end
        SetVehicleModKit(veh, 0)
        for modType, modIndex in pairs(Config.VehicleMods) do
            SetVehicleMod(veh, modType, modIndex, false)
        end
        SetVehicleEngineOn(veh, true, true, false)
        SetVehicleDirtLevel(veh, 0.0)
        SetModelAsNoLongerNeeded(hash)
        if cb then cb(veh) end
    end
end
local function updateCheckpointBlip(cpIndex)
    removeBlip(checkpointBlip)
    removeBlip(finishBlip)
    if cpIndex > 0 and cpIndex <= totalCp then
        local cp = checkpoints[cpIndex]
        local isFinish = (cpIndex == totalCp)
        if isFinish then
            finishBlip = AddBlipForCoord(cp.coords.x, cp.coords.y, cp.coords.z)
            SetBlipSprite(finishBlip, 38)
            SetBlipColour(finishBlip, 2)
            SetBlipScale(finishBlip, 1.2)
            SetBlipRoute(finishBlip, true)
            SetBlipRouteColour(finishBlip, 2)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName('Finish Line')
            EndTextCommandSetBlipName(finishBlip)
        else
            checkpointBlip = AddBlipForCoord(cp.coords.x, cp.coords.y, cp.coords.z)
            SetBlipSprite(checkpointBlip, 1)
            SetBlipColour(checkpointBlip, 17)
            SetBlipScale(checkpointBlip, 0.9)
            SetBlipRoute(checkpointBlip, true)
            SetBlipRouteColour(checkpointBlip, 17)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName('Checkpoint ' .. cpIndex)
            EndTextCommandSetBlipName(checkpointBlip)
        end
    end
end
local function fullCleanup()
    inRoom             = false
    inRace             = false
    cpDetectionActive  = false
    currentCp          = 0
    checkpoints        = {}
    totalCp            = 0
    deleteVehicle(raceVehicle)
    raceVehicle        = nil
    removeBlip(checkpointBlip)
    removeBlip(finishBlip)
    checkpointBlip     = nil
    finishBlip         = nil
    SendNUIMessage({ action = 'hide' })
end
RegisterNetEvent('trisport:joinRoom')
AddEventHandler('trisport:joinRoom', function(data)
    fullCleanup()
    inRoom = true
    roomId = data.roomId
    spawnVehicle(Config.RaceVehicle, data.spawnPos, Config.VehicleColor, function(veh)
        raceVehicle = veh
        FreezeEntityPosition(veh, true)
        SetEntityInvincible(veh, true)
        SetEntityCanBeDamaged(veh, false)
    end)
    SendNUIMessage({
        action = 'show',
        state  = 'waiting',
        roomId = roomId,
    })
end)
RegisterNetEvent('trisport:leaveRoom')
AddEventHandler('trisport:leaveRoom', function(data)
    fullCleanup()
    if data and data.coords then
        local ped = refreshPed()
        SetEntityCoords(ped, data.coords.x, data.coords.y, data.coords.z, false, false, false, true)
    end
end)
RegisterNetEvent('trisport:countdown')
AddEventHandler('trisport:countdown', function(seconds)
    SendNUIMessage({
        action  = 'countdown',
        seconds = seconds,
    })
    if Config.UseCustomSounds then
        SendNUIMessage({ action = 'playSound', sound = 'countdown' })
    end
end)
RegisterNetEvent('trisport:raceStart')
AddEventHandler('trisport:raceStart', function()
    checkpoints = Config.Checkpoints
    totalCp     = #checkpoints
    currentCp   = 0
    inRace      = true
    if raceVehicle and DoesEntityExist(raceVehicle) then
        FreezeEntityPosition(raceVehicle, false)
        SetEntityInvincible(raceVehicle, false)
        SetEntityCanBeDamaged(raceVehicle, true)
    end
    updateCheckpointBlip(1)
    SendNUIMessage({
        action = 'show',
        state  = 'racing',
    })
    if not cpDetectionActive then
        cpDetectionActive = true
        StartCheckpointDetection()
    end
end)
RegisterNetEvent('trisport:updatePosition')
AddEventHandler('trisport:updatePosition', function(data)
    if not inRace then return end
    SendNUIMessage({
        action      = 'updatePosition',
        position    = data.position,
        total       = data.total,
        checkpoint  = data.checkpoint,
        totalCp     = data.totalCp,
        leaderboard = data.leaderboard,
        raceTime    = data.raceTime,
    })
end)
RegisterNetEvent('trisport:raceFinished')
AddEventHandler('trisport:raceFinished', function(data)
    inRace = false
    if Config.UseCustomSounds then
        SendNUIMessage({ action = 'playSound', sound = 'finish' })
    else
        PlaySoundFrontend(-1, 'RACE_PLACED', 'HUD_AWARDS', false)
    end
    SendNUIMessage({
        action   = 'finished',
        position = data.position,
        time     = data.time,
    })
end)
RegisterNetEvent('trisport:respawn')
AddEventHandler('trisport:respawn', function(data)
    if not raceVehicle or not DoesEntityExist(raceVehicle) then return end
    local ped = refreshPed()
    SetEntityCoords(raceVehicle, data.coords.x, data.coords.y, data.coords.z, false, false, false, true)
    SetEntityHeading(raceVehicle, data.heading or 0.0)
    SetVehicleOnGroundProperly(raceVehicle)
    SetVehicleFixed(raceVehicle)
    SetVehicleEngineOn(raceVehicle, true, true, false)
    SetEntityVelocity(raceVehicle, 0.0, 0.0, 0.0)
    if not IsPedInVehicle(ped, raceVehicle, false) then
        SetPedIntoVehicle(ped, raceVehicle, -1)
    end
end)
RegisterNetEvent('trisport:notify')
AddEventHandler('trisport:notify', function(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, false)
end)
function StartCheckpointDetection()
    Citizen.CreateThread(function()
        while inRace do
            local nextCp = currentCp + 1
            if nextCp > totalCp then
                Citizen.Wait(1000)
                goto continue
            end
            local ped    = refreshPed()
            local pos    = GetEntityCoords(ped)
            local cpData = checkpoints[nextCp]
            local dist   = #(pos - cpData.coords)
            if dist < cpData.radius then
                currentCp = nextCp
                TriggerServerEvent('trisport:checkpointHit', currentCp)
                if Config.UseCustomSounds then
                    SendNUIMessage({ action = 'playSound', sound = 'checkpoint' })
                else
                    PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', false)
                end
                if currentCp < totalCp then
                    updateCheckpointBlip(currentCp + 1)
                else
                    removeBlip(checkpointBlip)
                    removeBlip(finishBlip)
                end
                Citizen.Wait(500)
            end
            if dist > 150.0 then
                Citizen.Wait(500)
            elseif dist > 80.0 then
                Citizen.Wait(200)
            elseif dist > 30.0 then
                Citizen.Wait(100)
            else
                Citizen.Wait(50)
            end
            ::continue::
        end
        cpDetectionActive = false
    end)
end
Citizen.CreateThread(function()
    while true do
        if inRace and currentCp < totalCp then
            local nextCp = currentCp + 1
            local cpData = checkpoints[nextCp]
            if cpData then
                local ped = refreshPed()
                local playerPos = GetEntityCoords(ped)
                local dist = #(playerPos - cpData.coords)
                if dist < 100.0 then
                    local isFinish = (nextCp == totalCp)
                    local color = isFinish and Config.FinishLineColor or Config.CheckpointColor
                    local scale = Config.CheckpointScale
                    DrawMarker(
                        1,                          
                        cpData.coords.x,
                        cpData.coords.y,
                        cpData.coords.z - 1.0,      
                        0.0, 0.0, 0.0,              
                        0.0, 0.0, 0.0,              
                        scale.x * cpData.radius * 0.5,
                        scale.y * cpData.radius * 0.5,
                        scale.z,
                        color.r, color.g, color.b, color.a,
                        false,                       
                        false,                       
                        2,                           
                        false,                       
                        nil, nil,                    
                        false                        
                    )
                    DrawMarker(
                        27,                          
                        cpData.coords.x,
                        cpData.coords.y,
                        cpData.coords.z + 2.0,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        1.0, 1.0, 15.0,             
                        color.r, color.g, color.b, math.floor(color.a * 0.5),
                        false, false, 2, false,
                        nil, nil, false
                    )
                    Citizen.Wait(0)  
                else
                    Citizen.Wait(200)  
                end
            else
                Citizen.Wait(500)
            end
        else
            Citizen.Wait(500)  
        end
    end
end)
Citizen.CreateThread(function()
    while true do
        if inRoom or inRace then
            DisableControlAction(0, 75, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 37, true)
            Citizen.Wait(0)
        else
            Citizen.Wait(500)
        end
    end
end)
Citizen.CreateThread(function()
    while true do
        if inRace then
            if IsControlJustPressed(0, 47) then
                TriggerServerEvent('trisport:requestRespawn')
                Citizen.Wait(2000)
            else
                Citizen.Wait(100)
            end
        else
            Citizen.Wait(1000)
        end
    end
end)
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    fullCleanup()
end)
print('[Trisport] Client loaded')