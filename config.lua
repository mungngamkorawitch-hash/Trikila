Config = {}
Config.MaxRooms              = 3          
Config.MaxPlayersPerRoom     = 60         
Config.RoutingBucketOffset   = 100        
Config.AutoStartEnabled      = true       
Config.AutoStartTime         = "20:00"    
Config.JoinWindowSeconds     = 300        
Config.RaceDurationSeconds   = 600        
Config.CountdownSeconds      = 10         
Config.AutoCloseAfterFinish  = 60         
Config.AnnounceGlobally      = false      
Config.RaceVehicle           = 'sultan'   
Config.VehicleColor          = {r = 255, g = 69, b = 0}  
Config.VehicleMods           = {}         
Config.SpawnOrigin           = vector4(-1042.49, -2966.70, 13.95, 330.0)  
Config.SpawnSpacing          = 6.0        
Config.SpawnColumns          = 6          
Config.SpawnStaggerMs        = 50         
Config.Checkpoints = {
    { coords = vector3(-1025.12, -2994.56, 13.95), radius = 12.0 },
    { coords = vector3(-987.34,  -3042.78, 13.95), radius = 12.0 },
    { coords = vector3(-932.56,  -3078.12, 13.95), radius = 12.0 },
    { coords = vector3(-878.45,  -3112.67, 13.95), radius = 12.0 },
    { coords = vector3(-823.78,  -3089.34, 13.95), radius = 12.0 },
    { coords = vector3(-769.12,  -3045.56, 13.95), radius = 12.0 },
    { coords = vector3(-734.56,  -2989.78, 13.95), radius = 12.0 },
    { coords = vector3(-712.34,  -2934.12, 13.95), radius = 12.0 },
    { coords = vector3(-745.67,  -2878.45, 13.95), radius = 12.0 },
    { coords = vector3(-798.12,  -2834.78, 13.95), radius = 12.0 },
    { coords = vector3(-856.45,  -2812.34, 13.95), radius = 12.0 },
    { coords = vector3(-912.78,  -2834.56, 13.95), radius = 12.0 },
    { coords = vector3(-967.34,  -2878.12, 13.95), radius = 12.0 },
    { coords = vector3(-1012.56, -2923.67, 13.95), radius = 12.0 },
    { coords = vector3(-1042.49, -2966.70, 13.95), radius = 15.0 },  
}
Config.CheckpointColor       = {r = 255, g = 165, b = 0, a = 120}    
Config.FinishLineColor       = {r = 0,   g = 255, b = 100, a = 150}  
Config.CheckpointScale       = vector3(3.0, 3.0, 2.0)                
Config.Rewards = {
    [1]  = { guaranteed = { item = 'reward_gold', count = 3 }, special = { item = 'reward_diamond', count = 1, chance = 25 } },
    [2]  = { guaranteed = { item = 'reward_gold', count = 2 }, special = { item = 'reward_diamond', count = 1, chance = 15 } },
    [3]  = { guaranteed = { item = 'reward_gold', count = 1 }, special = { item = 'reward_diamond', count = 1, chance = 10 } },
    [4]  = { guaranteed = { item = 'reward_silver', count = 3 }, special = { item = 'reward_gold', count = 1, chance = 20 } },
    [5]  = { guaranteed = { item = 'reward_silver', count = 3 }, special = { item = 'reward_gold', count = 1, chance = 15 } },
    [6]  = { guaranteed = { item = 'reward_silver', count = 2 }, special = { item = 'reward_gold', count = 1, chance = 10 } },
    [7]  = { guaranteed = { item = 'reward_silver', count = 2 }, special = { item = 'reward_gold', count = 1, chance = 10 } },
    [8]  = { guaranteed = { item = 'reward_silver', count = 1 }, special = { item = 'reward_gold', count = 1, chance = 5 } },
    [9]  = { guaranteed = { item = 'reward_silver', count = 1 }, special = { item = 'reward_gold', count = 1, chance = 5 } },
    [10] = { guaranteed = { item = 'reward_bronze', count = 3 }, special = { item = 'reward_silver', count = 1, chance = 15 } },
    [11] = { guaranteed = { item = 'reward_bronze', count = 3 }, special = { item = 'reward_silver', count = 1, chance = 10 } },
    [12] = { guaranteed = { item = 'reward_bronze', count = 2 }, special = { item = 'reward_silver', count = 1, chance = 10 } },
    [13] = { guaranteed = { item = 'reward_bronze', count = 2 }, special = { item = 'reward_silver', count = 1, chance = 5 } },
    [14] = { guaranteed = { item = 'reward_bronze', count = 1 }, special = { item = 'reward_silver', count = 1, chance = 5 } },
    [15] = { guaranteed = { item = 'reward_bronze', count = 1 }, special = { item = 'reward_silver', count = 1, chance = 3 } },
}
Config.BoostEnabled          = true       
Config.BoostDuration         = 3.0        
Config.BoostPowerMultiplier  = 3.0        
Config.BoostMaxCharges       = 1          
Config.BoostCooldown         = 5.0        
Config.BoostKeyCode          = 38         
Config.BoostMarkerColor      = {r = 0, g = 191, b = 255, a = 150}  
Config.BoostMarkers = {
    { coords = vector3(-960.00, -3060.00, 13.95), radius = 4.0 },
    { coords = vector3(-850.00, -3100.00, 13.95), radius = 4.0 },
    { coords = vector3(-750.00, -3020.00, 13.95), radius = 4.0 },
    { coords = vector3(-720.00, -2910.00, 13.95), radius = 4.0 },
    { coords = vector3(-830.00, -2820.00, 13.95), radius = 4.0 },
    { coords = vector3(-940.00, -2850.00, 13.95), radius = 4.0 },
}
Config.ShowLeaderboardTop    = 5          
Config.UIUpdateInterval      = 1000       
Config.UseCustomSounds       = false      
Config.AdminPermission       = 'trisport.admin'  
Config.Messages = {
    joined           = '🏁 เข้าร่วมห้องแข่ง %d แล้ว! รอกิจกรรมเริ่ม...',
    roomFull         = '❌ ห้อง %d เต็มแล้ว!',
    roomClosed       = '❌ ห้อง %d ยังไม่เปิด!',
    roomNotExist     = '❌ ห้องนี้ไม่มีอยู่! ใช้ 1-%d',
    alreadyInRoom    = '❌ คุณอยู่ในห้องแข่งแล้ว!',
    notInRoom        = '❌ คุณไม่ได้อยู่ในห้องแข่ง!',
    leftRoom         = '🚪 ออกจากห้องแข่งแล้ว',
    raceStartingSoon = '🏁 กิจกรรมแข่งรถกำลังจะเริ่มใน %d วินาที!',
    raceStarted      = '🟢 GO! GO! GO!',
    checkpointHit    = '✅ Checkpoint %d/%d',
    finished         = '🏆 เข้าเส้นชัย! อันดับที่ %d — เวลา %s',
    rewardReceived   = '🎁 ได้รับ %s x%d!',
    specialReward    = '🌟 ได้รับของพิเศษ %s x%d!',
    respawned        = '🔄 Respawn ที่ Checkpoint %d',
    boostCollected   = '🚀 เก็บ Boost ได้! กด E เพื่อใช้',
    boostUsed        = '💨 NITROUS ACTIVATED!',
    boostEmpty       = '❌ ไม่มี Boost!',
    raceTimeout      = '⏰ หมดเวลาแข่ง!',
    adminOpened      = '✅ เปิดห้อง %d แล้ว',
    adminClosed      = '✅ ปิดห้อง %d แล้ว',
    adminStarted     = '✅ เริ่มกิจกรรมห้อง %d แล้ว',
    adminStopped     = '✅ หยุดกิจกรรมห้อง %d แล้ว',
    noPermission     = '❌ คุณไม่มีสิทธิ์ใช้คำสั่งนี้',
    eventOpening     = '🏁 [TRISPORT] กิจกรรมแข่งรถเปิดแล้ว! ใช้ /tri 1-3 เพื่อเข้าร่วม (%d ที่ว่างต่อห้อง)',
    eventStarting    = '🏁 [TRISPORT] กิจกรรมกำลังจะเริ่มใน %d วินาที!',
    eventEnded       = '🏁 [TRISPORT] กิจกรรมแข่งรถจบแล้ว!',
}