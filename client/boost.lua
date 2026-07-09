local isRacing          = false
local boostCharges      = 0
local boostActive       = false
local boostEndTime      = 0
local boostCooldown     = 0
local boostMarkers      = {}
local collectedBoosts   = {}
local boostThreadsActive= false  
RegisterNetEvent('trisport:raceStart')
AddEventHandler('trisport:raceStart', function()
    if not Config.BoostEnabled then return end
    isRacing        = true
    boostMarkers    = Config.BoostMarkers or {}
    boostCharges    = 0
    boostActive     = false
    boostEndTime    = 0
    boostCooldown   = 0
    collectedBoosts = {}
    if #boostMarkers > 0 and not boostThreadsActive then
        boostThreadsActive = true
        StartBoostCollection()
        StartBoostActivation()
        StartBoostMarkerRendering()
    end
end)
RegisterNetEvent('trisport:leaveRoom')
AddEventHandler('trisport:leaveRoom', function()
    isRacing            = false
    boostThreadsActive  = false
    boostCharges        = 0
    boostActive         = false
    boostEndTime        = 0
    boostCooldown       = 0
    boostMarkers        = {}
    collectedBoosts     = {}
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh and veh ~= 0 then
        SetVehicleEnginePowerMultiplier(veh, 1.0)
        SetVehicleEngineTorqueMultiplier(veh, 1.0)
    end
end)
RegisterNetEvent('trisport:raceFinished')
AddEventHandler('trisport:raceFinished', function()
    isRacing           = false
    boostThreadsActive = false
    boostActive        = false
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh and veh ~= 0 then
        SetVehicleEnginePowerMultiplier(veh, 1.0)
        SetVehicleEngineTorqueMultiplier(veh, 1.0)
    end
end)
function StartBoostCollection()
    Citizen.CreateThread(function()
        while isRacing and Config.BoostEnabled do
            local ped = PlayerPedId()
            local playerPos = GetEntityCoords(ped)
            local now = GetGameTimer() / 1000.0
            if now < boostCooldown then
                Citizen.Wait(200)
                goto continue
            end
            local closestDist = 999.0
            for i, marker in ipairs(boostMarkers) do
                if not collectedBoosts[i] then
                    local dist = #(playerPos - marker.coords)
                    if dist < closestDist then
                        closestDist = dist
                    end
                    if dist < (marker.radius or 4.0) then
                        if boostCharges < Config.BoostMaxCharges then
                            boostCharges = boostCharges + 1
                            collectedBoosts[i] = true
                            boostCooldown = now + Config.BoostCooldown
                            BeginTextCommandThefeedPost('STRING')
                            AddTextComponentSubstringPlayerName(Config.Messages.boostCollected)
                            EndTextCommandThefeedPostTicker(false, false)
                            PlaySoundFrontend(-1, 'PICK_UP_COLLECTIBLE', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
                            SendNUIMessage({
                                action  = 'updateBoost',
                                charges = boostCharges,
                                max     = Config.BoostMaxCharges,
                                active  = boostActive,
                            })
                            break
                        end
                    end
                end
            end
            if closestDist > 100.0 then
                Citizen.Wait(500)
            elseif closestDist > 30.0 then
                Citizen.Wait(200)
            else
                Citizen.Wait(50)
            end
            ::continue::
        end
    end)
end
function StartBoostActivation()
    Citizen.CreateThread(function()
        while isRacing and Config.BoostEnabled do
            if IsControlJustPressed(0, Config.BoostKeyCode) then
                if boostCharges > 0 and not boostActive then
                    boostCharges = boostCharges - 1
                    boostActive = true
                    boostEndTime = GetGameTimer() / 1000.0 + Config.BoostDuration
                    local ped = PlayerPedId()
                    local veh = GetVehiclePedIsIn(ped, false)
                    if veh and veh ~= 0 then
                        SetVehicleEnginePowerMultiplier(veh, Config.BoostPowerMultiplier * 10.0)
                        SetVehicleEngineTorqueMultiplier(veh, Config.BoostPowerMultiplier)
                        AnimpostfxPlay('RaceTurbo', 0, false)
                        ShakeGameplayCam('ROAD_VIBRATION_SHAKE', 0.3)
                        PlaySoundFrontend(-1, 'NITRO_BOOST', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
                        BeginTextCommandThefeedPost('STRING')
                        AddTextComponentSubstringPlayerName(Config.Messages.boostUsed)
                        EndTextCommandThefeedPostTicker(false, false)
                        SendNUIMessage({
                            action  = 'updateBoost',
                            charges = boostCharges,
                            max     = Config.BoostMaxCharges,
                            active  = true,
                        })
                        SetTimeout(math.floor(Config.BoostDuration * 1000), function()
                            boostActive = false
                            if veh and DoesEntityExist(veh) then
                                SetVehicleEnginePowerMultiplier(veh, 1.0)
                                SetVehicleEngineTorqueMultiplier(veh, 1.0)
                            end
                            AnimpostfxStop('RaceTurbo')
                            StopGameplayCamShaking(true)
                            SendNUIMessage({
                                action  = 'updateBoost',
                                charges = boostCharges,
                                max     = Config.BoostMaxCharges,
                                active  = false,
                            })
                        end)
                    end
                elseif boostCharges <= 0 then
                    BeginTextCommandThefeedPost('STRING')
                    AddTextComponentSubstringPlayerName(Config.Messages.boostEmpty)
                    EndTextCommandThefeedPostTicker(false, false)
                end
            end
            Citizen.Wait(100)
        end
    end)
end
function StartBoostMarkerRendering()
    Citizen.CreateThread(function()
        while isRacing and Config.BoostEnabled do
            local ped = PlayerPedId()
            local playerPos = GetEntityCoords(ped)
            local rendered = false
            for i, marker in ipairs(boostMarkers) do
                if not collectedBoosts[i] then
                    local dist = #(playerPos - marker.coords)
                    if dist < 80.0 then
                        rendered = true
                        local color = Config.BoostMarkerColor
                        DrawMarker(
                            6,
                            marker.coords.x,
                            marker.coords.y,
                            marker.coords.z + 0.5,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            2.0, 2.0, 2.0,
                            color.r, color.g, color.b, color.a,
                            true,
                            false,
                            2,
                            true,
                            nil, nil, false
                        )
                        DrawMarker(
                            27,
                            marker.coords.x,
                            marker.coords.y,
                            marker.coords.z + 1.0,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            0.5, 0.5, 8.0,
                            color.r, color.g, color.b, math.floor(color.a * 0.4),
                            false, false, 2, false,
                            nil, nil, false
                        )
                    end
                end
            end
            if rendered then
                Citizen.Wait(0)
            else
                Citizen.Wait(300)
            end
        end
    end)
end