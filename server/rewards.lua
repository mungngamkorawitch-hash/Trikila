local ESX = exports['es_extended']:getSharedObject()
function GiveRewards(source, position)
    if not Config.Rewards[position] then return end
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    local reward = Config.Rewards[position]
    local playerName = GetPlayerName(source) or 'Unknown'
    if reward.guaranteed then
        local item = reward.guaranteed.item
        local count = reward.guaranteed.count or 1
        if xPlayer.canCarryItem(item, count) then
            xPlayer.addInventoryItem(item, count)
            TriggerClientEvent('trisport:notify', source,
                string.format(Config.Messages.rewardReceived, item, count))
            print('[Trisport] Reward: ' .. playerName .. ' received ' .. item .. ' x' .. count .. ' (position #' .. position .. ')')
        else
            TriggerClientEvent('trisport:notify', source,
                '❌ กระเป๋าเต็ม! ไม่สามารถรับ ' .. item .. ' x' .. count)
            print('[Trisport] Reward FAILED (inventory full): ' .. playerName .. ' — ' .. item .. ' x' .. count)
        end
    end
    if reward.special then
        local item = reward.special.item
        local count = reward.special.count or 1
        local chance = reward.special.chance or 0
        local roll = math.random(1, 100)
        if roll <= chance then
            if xPlayer.canCarryItem(item, count) then
                xPlayer.addInventoryItem(item, count)
                TriggerClientEvent('trisport:notify', source,
                    string.format(Config.Messages.specialReward, item, count))
                print('[Trisport] SPECIAL Reward: ' .. playerName .. ' received ' .. item .. ' x' .. count .. ' (roll: ' .. roll .. '/' .. chance .. '%)')
            else
                TriggerClientEvent('trisport:notify', source,
                    '❌ กระเป๋าเต็ม! ไม่สามารถรับของพิเศษ ' .. item .. ' x' .. count)
                print('[Trisport] SPECIAL Reward FAILED (inventory full): ' .. playerName .. ' — ' .. item .. ' x' .. count)
            end
        else
            print('[Trisport] Special reward miss: ' .. playerName .. ' (roll: ' .. roll .. '/' .. chance .. '%)')
        end
    end
end