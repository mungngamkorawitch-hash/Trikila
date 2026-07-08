RegisterCommand('tri', function(source, args, rawCommand)
    local roomId = tonumber(args[1])
    if not roomId then
        TriggerClientEvent('trisport:notify', source, 'ใช้: /tri [1-' .. Config.MaxRooms .. ']')
        return
    end
    if roomId < 1 or roomId > Config.MaxRooms then
        TriggerClientEvent('trisport:notify', source,
            string.format(Config.Messages.roomNotExist, Config.MaxRooms))
        return
    end
    AddPlayerToRoom(source, roomId)
end, false)
RegisterCommand('triout', function(source, args, rawCommand)
    if not playerRooms[source] then
        TriggerClientEvent('trisport:notify', source, Config.Messages.notInRoom)
        return
    end
    RemovePlayerFromRoom(source, false)
    TriggerClientEvent('trisport:notify', source, Config.Messages.leftRoom)
end, false)
RegisterCommand('tristart', function(source, args, rawCommand)
    if source > 0 and not IsPlayerAceAllowed(source, Config.AdminPermission) then
        TriggerClientEvent('trisport:notify', source, Config.Messages.noPermission)
        return
    end
    local roomId = tonumber(args[1])
    if not roomId or roomId < 1 or roomId > Config.MaxRooms then
        if source > 0 then
            TriggerClientEvent('trisport:notify', source, 'ใช้: /tristart [1-' .. Config.MaxRooms .. ']')
        else
            print('[Trisport] Usage: tristart [1-' .. Config.MaxRooms .. ']')
        end
        return
    end
    local room = rooms[roomId]
    if not room then return end
    if room.state == 'closed' or room.state == 'finished' then
        OpenRoom(roomId)
        if source > 0 then
            TriggerClientEvent('trisport:notify', source, string.format(Config.Messages.adminOpened, roomId))
        end
        if Config.AnnounceGlobally then
            TriggerClientEvent('trisport:notify', -1, string.format(Config.Messages.eventOpening, Config.MaxPlayersPerRoom))
        end
        SetTimeout(Config.JoinWindowSeconds * 1000, function()
            if rooms[roomId].state == 'open' and rooms[roomId].playerCount > 0 then
                StartRace(roomId)
            end
        end)
    elseif room.state == 'open' then
        if room.playerCount > 0 then
            StartRace(roomId)
            if source > 0 then
                TriggerClientEvent('trisport:notify', source, string.format(Config.Messages.adminStarted, roomId))
            end
        else
            if source > 0 then
                TriggerClientEvent('trisport:notify', source, '❌ ห้อง ' .. roomId .. ' ไม่มีผู้เล่น!')
            end
        end
    else
        if source > 0 then
            TriggerClientEvent('trisport:notify', source, '❌ ห้อง ' .. roomId .. ' กำลังแข่งอยู่!')
        end
    end
end, false)
RegisterCommand('tristop', function(source, args, rawCommand)
    if source > 0 and not IsPlayerAceAllowed(source, Config.AdminPermission) then
        TriggerClientEvent('trisport:notify', source, Config.Messages.noPermission)
        return
    end
    local roomId = tonumber(args[1])
    if not roomId or roomId < 1 or roomId > Config.MaxRooms then
        if source > 0 then
            TriggerClientEvent('trisport:notify', source, 'ใช้: /tristop [1-' .. Config.MaxRooms .. ']')
        else
            print('[Trisport] Usage: tristop [1-' .. Config.MaxRooms .. ']')
        end
        return
    end
    EndRace(roomId)
    CloseRoom(roomId)
    if source > 0 then
        TriggerClientEvent('trisport:notify', source, string.format(Config.Messages.adminStopped, roomId))
    end
    print('[Trisport] Admin force-stopped room ' .. roomId)
end, false)
RegisterCommand('triopen', function(source, args, rawCommand)
    if source > 0 and not IsPlayerAceAllowed(source, Config.AdminPermission) then
        TriggerClientEvent('trisport:notify', source, Config.Messages.noPermission)
        return
    end
    for i = 1, Config.MaxRooms do
        OpenRoom(i)
    end
    if Config.AnnounceGlobally then
        TriggerClientEvent('trisport:notify', -1, string.format(Config.Messages.eventOpening, Config.MaxPlayersPerRoom))
    end
    if source > 0 then
        TriggerClientEvent('trisport:notify', source, '✅ เปิดทุกห้องแล้ว')
    end
    print('[Trisport] Admin opened all rooms')
end, false)
RegisterCommand('trievent', function(source, args, rawCommand)
    if source > 0 and not IsPlayerAceAllowed(source, Config.AdminPermission) then
        TriggerClientEvent('trisport:notify', source, Config.Messages.noPermission)
        return
    end
    for i = 1, Config.MaxRooms do
        OpenRoom(i)
    end
    if Config.AnnounceGlobally then
        TriggerClientEvent('trisport:notify', -1, string.format(Config.Messages.eventOpening, Config.MaxPlayersPerRoom))
    end
    if source > 0 then
        TriggerClientEvent('trisport:notify', source, '✅ เปิดรับผู้เล่นเข้ากิจกรรมแล้ว (รอ ' .. Config.JoinWindowSeconds .. ' วินาที)')
    end
    print('[Trisport] Admin manually triggered the event flow')
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
end, false)
RegisterCommand('trihost', function(source, args, rawCommand)
    for i = 1, Config.MaxRooms do
        OpenRoom(i)
    end
    if Config.AnnounceGlobally then
        TriggerClientEvent('trisport:notify', -1, string.format(Config.Messages.eventOpening, Config.MaxPlayersPerRoom))
    end
    if source > 0 then
        TriggerClientEvent('trisport:notify', source, '✅ คุณได้เริ่มกิจกรรมแล้ว (รอ ' .. Config.JoinWindowSeconds .. ' วินาที)')
    end
    print('[Trisport] Player ' .. source .. ' hosted the event flow')
    SetTimeout(Config.JoinWindowSeconds * 1000, function()
        for i = 1, Config.MaxRooms do
            if rooms[i].state == 'open' and rooms[i].playerCount > 0 then
                StartRace(i)
            elseif rooms[i].state == 'open' and rooms[i].playerCount == 0 then
                CloseRoom(i)
            end
        end
    end)
end, false)
RegisterCommand('tristartall', function(source, args, rawCommand)
    if source > 0 and not IsPlayerAceAllowed(source, Config.AdminPermission) then
        TriggerClientEvent('trisport:notify', source, Config.Messages.noPermission)
        return
    end
    local started = 0
    for i = 1, Config.MaxRooms do
        if rooms[i].state == 'open' and rooms[i].playerCount > 0 then
            StartRace(i)
            started = started + 1
        elseif rooms[i].state == 'open' and rooms[i].playerCount == 0 then
            CloseRoom(i)
        end
    end
    if source > 0 then
        TriggerClientEvent('trisport:notify', source, '✅ บังคับเริ่มแข่ง ' .. started .. ' ห้องทันที')
    end
    print('[Trisport] Admin force-started all open rooms (' .. started .. ' rooms)')
end, false)
RegisterCommand('triclose', function(source, args, rawCommand)
    if source > 0 and not IsPlayerAceAllowed(source, Config.AdminPermission) then
        TriggerClientEvent('trisport:notify', source, Config.Messages.noPermission)
        return
    end
    for i = 1, Config.MaxRooms do
        CloseRoom(i)
    end
    if source > 0 then
        TriggerClientEvent('trisport:notify', source, '✅ ปิดทุกห้องแล้ว')
    end
    print('[Trisport] Admin closed all rooms')
end, false)
RegisterCommand('tristatus', function(source, args, rawCommand)
    if source > 0 and not IsPlayerAceAllowed(source, Config.AdminPermission) then
        TriggerClientEvent('trisport:notify', source, Config.Messages.noPermission)
        return
    end
    for i = 1, Config.MaxRooms do
        local room = rooms[i]
        local status = string.format(
            '[Room %d] State: %s | Players: %d/%d',
            i, room.state, room.playerCount, Config.MaxPlayersPerRoom
        )
        if source > 0 then
            TriggerClientEvent('trisport:notify', source, status)
        end
        print('[Trisport] ' .. status)
    end
end, false)
RegisterNetEvent('trisport:requestLeave')
AddEventHandler('trisport:requestLeave', function()
    local source = source
    if not playerRooms[source] then
        TriggerClientEvent('trisport:notify', source, Config.Messages.notInRoom)
        return
    end
    RemovePlayerFromRoom(source, false)
    TriggerClientEvent('trisport:notify', source, Config.Messages.leftRoom)
end)