local ESX = exports['es_extended']:getSharedObject()
rooms = {}
playerRooms = {}
finishCounters = {}
local TOTAL_CHECKPOINTS = #Config.Checkpoints
local function initRooms()
    for i = 1, Config.MaxRooms do
        rooms[i] = {
            state       = 'closed',   
            players     = {},         
            playerCount = 0,
            raceStartTime = 0,
            gen         = 0,
        }
        finishCounters[i] = 0
    end
    print('[Trisport] Initialized ' .. Config.MaxRooms .. ' rooms')
end
initRooms()
---@param roomId number
---@return number
local function getBucket(roomId)
    return Config.RoutingBucketOffset + roomId
end
---@param playerIndex number (0-based)
---@return vector4 position+heading
local function getSpawnPosition(playerIndex)
    local origin = Config.SpawnOrigin
    local cols   = Config.SpawnColumns
    local space  = Config.SpawnSpacing
    local col = playerIndex % cols
    local row = math.floor(playerIndex / cols)
    local headingRad = math.rad(origin.w)
    local cosH = math.cos(headingRad)
    local sinH = math.sin(headingRad)
    local rightOffset = (col - (cols - 1) / 2) * space
    local backOffset  = -row * space  
    local offsetX = rightOffset * cosH - backOffset * sinH
    local offsetY = rightOffset * sinH + backOffset * cosH
    return vector4(
        origin.x + offsetX,
        origin.y + offsetY,
        origin.z,
        origin.w
    )
end
---@param source number server ID
---@param msg string
local function notify(source, msg)
    TriggerClientEvent('trisport:notify', source, msg)
end
---@param roomId number
---@param msg string
local function notifyRoom(roomId, msg)
    local room = rooms[roomId]
    if not room then return end
    for serverId, _ in pairs(room.players) do
        notify(serverId, msg)
    end
end
---@param msg string
local function notifyAll(msg)
    if not Config.AnnounceGlobally then return end
    TriggerClientEvent('trisport:notify', -1, msg)
end
---@param ms number
---@return string
local function formatTime(ms)
    local totalSeconds = ms / 1000
    local mins = math.floor(totalSeconds / 60)
    local secs = math.floor(totalSeconds % 60)
    local cents = math.floor((ms % 1000) / 10)
    return string.format('%02d:%02d.%02d', mins, secs, cents)
end
---@param roomId number
---@return table sorted list of {serverId, checkpoint, time, name}
local function calculatePositions(roomId)
    local room = rooms[roomId]
    if not room then return {} end
    local positions = {}
    for serverId, data in pairs(room.players) do
        positions[#positions + 1] = {
            serverId   = serverId,
            checkpoint = data.checkpoint or 0,
            time       = data.checkpointTime or 0,
            name       = data.name,
            finished   = data.finished or false,
        }
    end
    table.sort(positions, function(a, b)
        if a.finished and not b.finished then return true end
        if not a.finished and b.finished then return false end
        if a.finished and b.finished then return a.time < b.time end
        if a.checkpoint ~= b.checkpoint then return a.checkpoint > b.checkpoint end
        return a.time < b.time
    end)
    return positions
end
---@param roomId number
local function broadcastPositions(roomId)
    local room = rooms[roomId]
    if not room or room.state ~= 'racing' then return end
    local positions = calculatePositions(roomId)
    local totalPlayers = room.playerCount
    local topN = math.min(Config.ShowLeaderboardTop, #positions)
    local sigParts = {}
    local leaderboardObj = {}
    for i = 1, topN do
        local p = positions[i]
        local timeStr = formatTime(p.time)
        leaderboardObj[i] = {
            pos  = i,
            name = p.name,
            cp   = p.checkpoint,
            time = timeStr,
        }
        sigParts[i] = p.serverId .. ':' .. p.checkpoint .. ':' .. timeStr
    end
    local sig = table.concat(sigParts, '|')
    local lbChanged = sig ~= room.lastLbSig
    room.lastLbSig = sig
    local leaderboardPayload = lbChanged and leaderboardObj or nil
    for rank, p in ipairs(positions) do
        TriggerClientEvent('trisport:updatePosition', p.serverId, {
            position    = rank,
            total       = totalPlayers,
            checkpoint  = p.checkpoint,
            totalCp     = TOTAL_CHECKPOINTS,
            leaderboard = leaderboardPayload,
            raceTime    = formatTime(GetGameTimer() - room.raceStartTime),
        })
    end
end
---@param roomId number
---@return boolean success
function OpenRoom(roomId)
    local room = rooms[roomId]
    if not room then return false end
    if room.state ~= 'closed' and room.state ~= 'finished' then return false end
    room.state          = 'open'
    room.players        = {}
    room.playerCount    = 0
    room.raceStartTime  = 0
    room.lastLbSig      = nil
    room.gen            = (room.gen or 0) + 1
    finishCounters[roomId] = 0
    print('[Trisport] Room ' .. roomId .. ' opened')
    return true
end
---@param roomId number
function CloseRoom(roomId)
    local room = rooms[roomId]
    if not room then return end
    local playersToRemove = {}
    for serverId, _ in pairs(room.players) do
        playersToRemove[#playersToRemove + 1] = serverId
    end
    room.state       = 'closed'
    room.players     = {}
    room.playerCount = 0
    finishCounters[roomId] = 0
    Citizen.CreateThread(function()
        for i, serverId in ipairs(playersToRemove) do
            RemovePlayerFromRoom(serverId)  
            if i % 10 == 0 then
                Citizen.Wait(50) 
            end
        end
    end)
    print('[Trisport] Room ' .. roomId .. ' closed')
end
---@param source number server ID
---@param roomId number
---@return boolean success
function AddPlayerToRoom(source, roomId)
    local room = rooms[roomId]
    if not room then
        notify(source, string.format(Config.Messages.roomNotExist, Config.MaxRooms))
        return false
    end
    if room.state ~= 'open' then
        notify(source, string.format(Config.Messages.roomClosed, roomId))
        return false
    end
    if playerRooms[source] then
        notify(source, Config.Messages.alreadyInRoom)
        return false
    end
    if room.playerCount >= Config.MaxPlayersPerRoom then
        notify(source, string.format(Config.Messages.roomFull, roomId))
        return false
    end
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local originalBucket = GetPlayerRoutingBucket(source)
    playerRooms[source] = {
        roomId         = roomId,
        originalCoords = coords,
        originalBucket = originalBucket,
    }
    local usedSlots = {}
    for _, d in pairs(room.players) do
        if d.spawnIndex then usedSlots[d.spawnIndex] = true end
    end
    local spawnIndex = 0
    while usedSlots[spawnIndex] do spawnIndex = spawnIndex + 1 end
    local spawnPos = getSpawnPosition(spawnIndex)
    room.players[source] = {
        spawnIndex     = spawnIndex,
        checkpoint     = 0,
        checkpointTime = 0,
        startTime      = 0,
        finished       = false,
        spawnPos       = spawnPos,
        name           = GetPlayerName(source) or 'Unknown',
        respawnCooldown = 0,
    }
    room.playerCount = room.playerCount + 1
    SetPlayerRoutingBucket(source, getBucket(roomId))
    TriggerClientEvent('trisport:joinRoom', source, {
        roomId     = roomId,
        spawnPos   = { x = spawnPos.x, y = spawnPos.y, z = spawnPos.z, w = spawnPos.w },
    })
    notify(source, string.format(Config.Messages.joined, roomId))
    print('[Trisport] Player ' .. GetPlayerName(source) .. ' joined room ' .. roomId .. ' (' .. room.playerCount .. '/' .. Config.MaxPlayersPerRoom .. ')')
    return true
end
---@param source number server ID
function RemovePlayerFromRoom(source)
    local playerData = playerRooms[source]
    if not playerData then return end
    local roomId = playerData.roomId
    local room = rooms[roomId]
    if room then
        room.players[source] = nil
        room.playerCount = math.max(0, room.playerCount - 1)
    end
    SetPlayerRoutingBucket(source, playerData.originalBucket or 0)
    TriggerClientEvent('trisport:leaveRoom', source, {
        coords = { x = playerData.originalCoords.x, y = playerData.originalCoords.y, z = playerData.originalCoords.z },
    })
    playerRooms[source] = nil
end
---@param roomId number
function StartRace(roomId)
    local room = rooms[roomId]
    if not room or room.state ~= 'open' then return end
    if room.playerCount == 0 then return end
    room.state = 'countdown'
    notifyRoom(roomId, string.format(Config.Messages.raceStartingSoon, Config.CountdownSeconds))
    for serverId, _ in pairs(room.players) do
        TriggerClientEvent('trisport:countdown', serverId, Config.CountdownSeconds)
    end
    local myGen = room.gen
    SetTimeout(Config.CountdownSeconds * 1000, function()
        if room.state ~= 'countdown' or room.gen ~= myGen then return end
        room.state = 'racing'
        room.raceStartTime = GetGameTimer()
        local startTime = room.raceStartTime
        for serverId, data in pairs(room.players) do
            data.startTime      = startTime
            data.checkpoint     = 0
            data.checkpointTime = 0
            data.finished       = false
            TriggerClientEvent('trisport:raceStart', serverId)
        end
        notifyRoom(roomId, Config.Messages.raceStarted)
        print('[Trisport] Race started in room ' .. roomId .. ' with ' .. room.playerCount .. ' players')
        StartPositionBroadcast(roomId)
        SetTimeout(Config.RaceDurationSeconds * 1000, function()
            if room.state == 'racing' and room.gen == myGen then
                EndRace(roomId)
            end
        end)
    end)
end
---@param roomId number
function EndRace(roomId)
    local room = rooms[roomId]
    if not room then return end
    if room.state ~= 'racing' and room.state ~= 'countdown' then return end
    room.state = 'finished'
    notifyRoom(roomId, Config.Messages.raceTimeout)
    local playersToRemove = {}
    for serverId, data in pairs(room.players) do
        if not data.finished then
            playersToRemove[#playersToRemove + 1] = serverId
        end
    end
    Citizen.CreateThread(function()
        for i, serverId in ipairs(playersToRemove) do
            RemovePlayerFromRoom(serverId)
            if i % 10 == 0 then
                Citizen.Wait(50)
            end
        end
    end)
    notifyAll(Config.Messages.eventEnded)
    print('[Trisport] Race ended in room ' .. roomId)
    local myGen = room.gen
    SetTimeout(Config.AutoCloseAfterFinish * 1000, function()
        if room.state == 'finished' and room.gen == myGen then
            CloseRoom(roomId)
        end
    end)
end
---@param roomId number
function StartPositionBroadcast(roomId)
    local room = rooms[roomId]
    local function tick()
        if not room or room.state ~= 'racing' then return end
        broadcastPositions(roomId)
        SetTimeout(Config.UIUpdateInterval, tick)
    end
    SetTimeout(Config.UIUpdateInterval, tick)
end
RegisterNetEvent('trisport:checkpointHit')
AddEventHandler('trisport:checkpointHit', function(checkpointIndex)
    local source = source
    local playerData = playerRooms[source]
    if not playerData then return end
    local roomId = playerData.roomId
    local room = rooms[roomId]
    if not room or room.state ~= 'racing' then return end
    local raceData = room.players[source]
    if not raceData then return end
    if raceData.finished then return end
    if type(checkpointIndex) ~= 'number' then return end
    local nowMs = GetGameTimer()
    if nowMs - (raceData.lastCpAttempt or 0) < 250 then return end
    raceData.lastCpAttempt = nowMs
    local expectedCp = (raceData.checkpoint or 0) + 1
    if checkpointIndex ~= expectedCp then return end
    if checkpointIndex < 1 or checkpointIndex > TOTAL_CHECKPOINTS then return end
    local cpData    = Config.Checkpoints[checkpointIndex]
    local playerPos = GetEntityCoords(GetPlayerPed(source))
    local dist      = #(playerPos - cpData.coords)
    if dist > (cpData.radius * 1.5) then
        print('[Trisport] CHEAT DETECTED: ' .. GetPlayerName(source) .. ' fake checkpoint ' .. checkpointIndex .. ' (dist: ' .. dist .. ')')
        return
    end
    raceData.checkpoint     = checkpointIndex
    raceData.checkpointTime = nowMs - raceData.startTime
    notify(source, string.format(Config.Messages.checkpointHit, checkpointIndex, TOTAL_CHECKPOINTS))
    if checkpointIndex == TOTAL_CHECKPOINTS then
        raceData.finished = true
        finishCounters[roomId] = finishCounters[roomId] + 1
        local finishPos = finishCounters[roomId]
        local timeStr = formatTime(raceData.checkpointTime)
        notify(source, string.format(Config.Messages.finished, finishPos, timeStr))
        GiveRewards(source, finishPos)
        TriggerClientEvent('trisport:raceFinished', source, {
            position = finishPos,
            time     = timeStr,
        })
        SetTimeout(3000, function()
            RemovePlayerFromRoom(source)  
        end)
        print('[Trisport] Player ' .. GetPlayerName(source) .. ' finished #' .. finishPos .. ' in room ' .. roomId .. ' (time: ' .. timeStr .. ')')
        local allFinished = true
        for _, data in pairs(room.players) do
            if not data.finished then
                allFinished = false
                break
            end
        end
        if allFinished then
            EndRace(roomId)
        end
    end
end)
RegisterNetEvent('trisport:requestRespawn')
AddEventHandler('trisport:requestRespawn', function()
    local source = source
    local playerData = playerRooms[source]
    if not playerData then return end
    local roomId = playerData.roomId
    local room = rooms[roomId]
    if not room or room.state ~= 'racing' then return end
    local raceData = room.players[source]
    if not raceData or raceData.finished then return end
    local now = GetGameTimer()
    if now - (raceData.respawnCooldown or 0) < 2000 then return end
    raceData.respawnCooldown = now
    local cpIndex = raceData.checkpoint or 0
    local respawnCoords
    if cpIndex > 0 and cpIndex <= TOTAL_CHECKPOINTS then
        respawnCoords = Config.Checkpoints[cpIndex].coords
    else
        local spawnPos = raceData.spawnPos
        respawnCoords = vector3(spawnPos.x, spawnPos.y, spawnPos.z)
    end
    TriggerClientEvent('trisport:respawn', source, {
        coords  = { x = respawnCoords.x, y = respawnCoords.y, z = respawnCoords.z },
        heading = Config.SpawnOrigin.w,
    })
    notify(source, string.format(Config.Messages.respawned, math.max(cpIndex, 1)))
end)
AddEventHandler('playerDropped', function(reason)
    local source = source
    if playerRooms[source] then
        local roomId = playerRooms[source].roomId
        local room = rooms[roomId]
        if room then
            room.players[source] = nil
            room.playerCount = math.max(0, room.playerCount - 1)
            if room.state == 'racing' and room.playerCount == 0 then
                print('[Trisport] Room ' .. roomId .. ' is empty mid-race, ending immediately')
                EndRace(roomId)
            end
        end
        playerRooms[source] = nil
        print('[Trisport] Player ' .. source .. ' disconnected from room ' .. roomId .. ' (' .. reason .. ')')
    end
end)
if Config.AutoStartEnabled then
    local autoStartTriggered = false
    local lastCheckMinute = -1
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(30000)  
            local currentTime = os.date('%H:%M')
            local currentMinute = os.date('%M')
            if currentMinute ~= lastCheckMinute then
                if autoStartTriggered and currentTime ~= Config.AutoStartTime then
                    autoStartTriggered = false
                end
                lastCheckMinute = currentMinute
            end
            if currentTime == Config.AutoStartTime and not autoStartTriggered then
                autoStartTriggered = true
                print('[Trisport] Auto-start triggered at ' .. currentTime)
                for i = 1, Config.MaxRooms do
                    OpenRoom(i)
                end
                notifyAll(string.format(Config.Messages.eventOpening, Config.MaxPlayersPerRoom))
                SetTimeout(Config.JoinWindowSeconds * 1000, function()
                    for i = 1, Config.MaxRooms do
                        if rooms[i].state == 'open' and rooms[i].playerCount > 0 then
                            StartRace(i)
                        elseif rooms[i].state == 'open' and rooms[i].playerCount == 0 then
                            CloseRoom(i)
                            print('[Trisport] Room ' .. i .. ' closed (no players)')
                        end
                    end
                end)
            end
        end
    end)
    print('[Trisport] Auto-start enabled — scheduled at ' .. Config.AutoStartTime)
end
exports('openRoom', OpenRoom)
exports('closeRoom', CloseRoom)
exports('startRace', StartRace)
exports('endRace', EndRace)
exports('getRoomState', function(roomId)
    local room = rooms[roomId]
    if not room then return nil end
    return {
        state = room.state,
        playerCount = room.playerCount,
        maxPlayers = Config.MaxPlayersPerRoom,
    }
end)
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    print('[Trisport] Resource stopping — restoring all players...')
    local count = 0
    for source, data in pairs(playerRooms) do
        SetPlayerRoutingBucket(source, data.originalBucket or 0)
        local ped = GetPlayerPed(source)
        if ped and ped ~= 0 then
            local c = data.originalCoords
            SetEntityCoords(ped, c.x, c.y, c.z, false, false, false, true)
        end
        count = count + 1
    end
    playerRooms    = {}
    rooms          = {}
    finishCounters = {}
    print('[Trisport] Restored ' .. count .. ' players to original positions. Safe to restart.')
end)
print('[Trisport] Server loaded successfully')