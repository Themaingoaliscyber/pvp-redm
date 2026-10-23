Config = {}

Config.DebugMode = false

-- setează pe true ca să vezi print-urile când ai nevoie
Config.DebugMode = false
Config.LobbyOpenDebug = false

-- ✅ Activează/dezactivează suportul pentru Virtual World
Config.UseVirtualWorld = true

Config.EnableLockedArenas = true -- setează pe false pentru a dezactiva sistemul de blocare a arenelor

-- 📌 Definim SafeZone unde sunt trimiși jucătorii după ce ies din lobby
Config.SafeZoneSpawn = vector3(-1308.02, 400.81, 95.38) -- Poți schimba coordonatele aici

-- 📌 Definim lobby-urile
Config.Lobbies = {
    { id = 1, name = "Arena 1", max_players = 18, image = "arena1.webp", description = "WEAPONS UNRESTRICTED", routingBucket = 10 },
    { id = 2, name = "Arena 2", max_players = 18, image = "arena2.webp", description = "WEAPONS UNRESTRICTED", routingBucket = 20 },
    { id = 3, name = "Arena 3", max_players = 18, image = "arena3.webp", description = "WEAPONS UNRESTRICTED", routingBucket = 30 },
    { id = 4, name = "Arena 4", max_players = 18, image = "arena4.webp", description = "WEAPONS RESTRICTED", routingBucket = 40 },
    { id = 5, name = "Arena 5", max_players = 20, image = "arena5.webp", description = "WEAPONS UNRESTRICTED", routingBucket = 50 },
    { id = 6, name = "Arena 6", max_players = 20, image = "arena6.webp", description = "ARENA FOR CHALLENGES", routingBucket = 60 },
    { id = 7, name = "Arena 7", max_players = 20, image = "arena7.webp", description = "ARENA FOR CHALLENGES", routingBucket = 70 },
    { id = 8, name = "Arena 8", max_players = 20, image = "arena8.webp", description = "ARENA FOR CHALLENGES", routingBucket = 80 },
    { id = 9, name = "Arena 9", max_players = 12, image = "arena9.webp", description = "WEAPONS RESTRICTED", routingBucket = 90 },
    { id = 10, name = "Arena 10", max_players = 20, image = "arena10.webp", description = "ARENA FOR CHALLENGES", routingBucket = 100 },
    { id = 11, name = "Arena 11", max_players = 18, image = "arena11.webp", description = "WEAPONS RESTRICTED", routingBucket = 110 },
    { id = 12, name = "Arena 12", max_players = 20, image = "arena12.webp", description = "ARENA FOR CHALLENGES", routingBucket = 120 },
    { id = 13, name = "Arena 13", max_players = 20, image = "arena13.webp", description = "ARENA FOR CHALLENGES", routingBucket = 130 },
    { id = 14, name = "Arena 14", max_players = 20, image = "arena14.webp", description = "ARENA FOR CHALLENGES", routingBucket = 140 },
    { id = 15, name = "Arena 15", max_players = 20, image = "arena15.webp", description = "ARENA FOR CHALLENGES", routingBucket = 150 },
    { id = 16, name = "Arena 16", max_players = 12, image = "arena16.webp", description = "WEAPONS RESTRICTED", routingBucket = 160 },
    { id = 17, name = "Arena 17", max_players = 30, image = "arena17.webp", description = "TEAM BATTLE", routingBucket = 170 },
    { id = 18, name = "Arena 18", max_players = 30, image = "arena18.webp", description = "TEAM BATTLE", routingBucket = 180 },
    { id = 19, name = "Arena 19", max_players = 30, image = "arena19.webp", description = "TEAM BATTLE", routingBucket = 190 },
    { id = 20, name = "Arena 20", max_players = 30, image = "arena20.webp", description = "TEAM BATTLE", routingBucket = 200 },
    { id = 21, name = "Arena 21", max_players = 30, image = "arena21.webp", description = "TEAM BATTLE", routingBucket = 210 },
    { id = 22, name = "Arena 22", max_players = 30, image = "arena22.webp", description = "TEAM BATTLE", routingBucket = 220 },
    { id = 23, name = "Arena 23", max_players = 30, image = "ctf23.webp", description = "CAPTURE THE FLAG", routingBucket = 230 },
    { id = 24, name = "Arena 24", max_players = 30, image = "ctf24.webp", description = "CAPTURE THE FLAG", routingBucket = 240 },
    { id = 25, name = "Arena 25", max_players = 30, image = "ctf25.webp", description = "CAPTURE THE FLAG", routingBucket = 250 },

}

Config.PrivateArenas = {6, 7, 8, 10, 12, 13, 14, 15}
Config.TeamArenaIds = {17, 18, 19, 20, 21, 22, 23, 24, 25}

Config.PrivateArenaTemplateExclude = {}
Config.DynamicPrivateArena = {
    idStart = 1000,
    bucketStart = 5000,
    bucketCount = 256,
    maxPlayers = 30,
    namePrefix = "Private",
    image = "customarena.webp"
}

Config.DynamicCustomArena = {
    idStart = 2000,
    bucketStart = 8000,
    bucketCount = 256,
    maxPlayers = 32,
    spawnMinDistance = 7.5,
    emptyGraceMinutes = 10,
    namePrefix = "Custom Arena",
    image = "customarena.webp",
    publicImage = "customarenapublic.webp",
    privateImage = "customarenaprivate.webp",
    publicDescription = "PUBLIC CUSTOM ARENA",
    privateDescription = "PRIVATE CUSTOM ARENA"
}

Config.LeaderLockedArenas = Config.LeaderLockedArenas or {}
for _, arenaId in ipairs(Config.PrivateArenas) do
    Config.LeaderLockedArenas[arenaId] = true
end

Config.TeamArenaSettings = {
    scoreToWin = 16,
    maxTeams = 2,
    maxPlayersPerTeam = 0, -- 0 = no limit
    allowFriendlyFireScore = false,
    roundResetDelay = 6,
    roundResolutionDelayMs = 400,
}

Config.TeamArenaModes = {
    [23] = { mode = "ctf" },
    [24] = { mode = "ctf" },
    [25] = { mode = "ctf" },
}

-- Add more CTF arenas by adding a Config.Lobbies row and a matching Config.CTFArenas[id] block.
-- TeamArenaIds and TeamArenaModes are filled automatically from Config.CTFArenas below.
Config.CTFArenas = {
    [23] = {
        name = "Arena 23 (CTF)",
        scoreToWin = 3,
        pickupRadius = 2.4,
        captureRadius = 4.0,
        returnRadius = 2.8,
        autoReturnSeconds = 30,
        respawnDelay = 6,
        publicTeamSelect = true, -- Public CTF: players choose RED/BLUE from the lobby UI.
        selectionCountdownSeconds = 20,
        minPlayersToStart = 2,
        enableTestCommands = false, -- Set false to disable /ctftest and the CTF /killme test bypass.
        enableCtfBot = false, -- Set false to disable /ctfbot.
        flagGroundOffset = -0.95,
        flagModel = "mp001_p_mp_flag01x",
        flagModels = {
            [1] = "mp001_p_mp_flag01x",
            [2] = "mp001_p_mp_flag01x",
        },
        blipSprite = "blip_mp_flag",
        blipScale = 1.25,
        teams = {
            [1] = {
                label = "RED TEAM",
                baseBlip = "RED BASE",
                spawn = vector3(1187.8822, -181.6542, 100.2838),
                base = vector3(1187.8822, -181.6542, 100.2838),
                marker = { r = 230, g = 60, b = 50 },
            },
            [2] = {
                label = "BLUE TEAM",
                baseBlip = "BLUE BASE",
                spawn = vector3(1281.9802, -412.6572, 96.6387),
                base = vector3(1281.9802, -412.6572, 96.6387),
                marker = { r = 60, g = 145, b = 255 },
            }
        },
    },
    [24] = {
        name = "Arena 24 (CTF)",
        scoreToWin = 3,
        pickupRadius = 2.4,
        captureRadius = 4.0,
        returnRadius = 2.8,
        autoReturnSeconds = 30,
        respawnDelay = 6,
        publicTeamSelect = false, -- Private CTF: keep /allowteam access.
        enableTestCommands = false, -- Set false to disable /ctftest and the CTF /killme test bypass.
        enableCtfBot = false, -- Set false to disable /ctfbot.
        flagGroundOffset = -0.95,
        flagModel = "mp001_p_mp_flag01x",
        flagModels = {
            [1] = "mp001_p_mp_flag01x",
            [2] = "mp001_p_mp_flag01x",
        },
        blipSprite = "blip_mp_flag",
        blipScale = 1.25,
        teams = {
            [1] = {
                label = "RED TEAM",
                baseBlip = "RED BASE",
                spawn = vector3(1187.8822, -181.6542, 100.2838),
                base = vector3(1187.8822, -181.6542, 100.2838),
                marker = { r = 230, g = 60, b = 50 },
            },
            [2] = {
                label = "BLUE TEAM",
                baseBlip = "BLUE BASE",
                spawn = vector3(1281.9802, -412.6572, 96.6387),
                base = vector3(1281.9802, -412.6572, 96.6387),
                marker = { r = 60, g = 145, b = 255 },
            }
        },
    },
    [25] = {
        name = "Arena 25 (CTF)",
        scoreToWin = 3,
        pickupRadius = 2.4,
        captureRadius = 4.0,
        returnRadius = 2.8,
        autoReturnSeconds = 30,
        respawnDelay = 6,
        publicTeamSelect = false, -- Private CTF: keep /allowteam access.
        enableTestCommands = false, -- Set false to disable /ctftest and the CTF /killme test bypass.
        enableCtfBot = false, -- Set false to disable /ctfbot.
        flagGroundOffset = -0.95,
        flagModel = "mp001_p_mp_flag01x",
        flagModels = {
            [1] = "mp001_p_mp_flag01x",
            [2] = "mp001_p_mp_flag01x",
        },
        blipSprite = "blip_mp_flag",
        blipScale = 1.25,
        teams = {
            [1] = {
                label = "RED TEAM",
                baseBlip = "RED BASE",
                spawn = vector3(1187.8822, -181.6542, 100.2838),
                base = vector3(1187.8822, -181.6542, 100.2838),
                marker = { r = 230, g = 60, b = 50 },
            },
            [2] = {
                label = "BLUE TEAM",
                baseBlip = "BLUE BASE",
                spawn = vector3(1281.9802, -412.6572, 96.6387),
                base = vector3(1281.9802, -412.6572, 96.6387),
                marker = { r = 60, g = 145, b = 255 },
            }
        },
    }
}

local function normalizeTeamArenaIds()
    local normalized = {}
    local seen = {}

    for key, value in pairs(Config.TeamArenaIds or {}) do
        local arenaId = tonumber(value)
        if type(value) == "boolean" then
            arenaId = tonumber(key)
        end

        if arenaId and not seen[arenaId] then
            normalized[#normalized + 1] = arenaId
            seen[arenaId] = true
        end
    end

    for arenaId in pairs(Config.CTFArenas or {}) do
        arenaId = tonumber(arenaId)
        if arenaId and not seen[arenaId] then
            normalized[#normalized + 1] = arenaId
            seen[arenaId] = true
        end
    end

    table.sort(normalized)
    Config.TeamArenaIds = normalized
end

normalizeTeamArenaIds()

Config.TeamArenaModes = Config.TeamArenaModes or {}
for arenaId in pairs(Config.CTFArenas or {}) do
    arenaId = tonumber(arenaId)
    if arenaId then
        Config.TeamArenaModes[arenaId] = { mode = "ctf" }
    end
end

Config.Duels = {
    enabled = true,
    arenaName = "Duel Arena",
    scoreToWin = 16,
    inviteExpireSeconds = 30,
    roundResetDelay = 5,
    roundResolutionDelayMs = 400,
    finishCleanupDelayMs = 9000,
    forfeitCleanupDelayMs = 3000,

    -- Duelurile nu apar in /lobby. Acest ID este doar intern, pentru kill tracking.
    virtualLobbyIdStart = 900000,

    -- Fiecare duel primeste un VW separat din intervalul acesta.
    routingBucketStart = 30000,
    routingBucketCount = 1024,

    -- Fallback vechi: ramane valid daca nu configurezi lista `arenas`.
    spawn1 = vector3(-2168.1716, 709.2181, 122.3011),
    spawn2 = vector3(-2233.1567, 727.9977, 123.0137),

    -- Adauga cate arene de duel vrei aici. Butonul CHANGE ARENA le parcurge automat.
    arenas = {
        {
            name = "Duel Arena",
            spawn1 = vector3(-2168.1716, 709.2181, 122.3011),
            spawn2 = vector3(-2233.1567, 727.9977, 123.0137),
        },
        {
            name = "Duel Arena 2",
            spawn1 = vector3(-2596.8879, 425.8994, 147.9868),
            spawn2 = vector3(-2548.8821, 336.8833, 150.8711),
        },
        {
            name = "Duel Arena 3",
            spawn1 = vector3(-4849.4805, -2661.7363, -12.4172),
            spawn2 = vector3(-4764.8740, -2736.9680, -14.1740),
        },
        {
            name = "Duel Arena 4",
            spawn1 = vector3(2973.7432, 486.2497, 45.1703),
            spawn2 = vector3(2979.7971, 585.7496, 44.2328),
        },
        {
            name = "Duel Arena 5",
            spawn1 = vector3(-377.7165, 895.7663, 115.5330),
            spawn2 = vector3(-376.9977, 946.3322, 120.5256),
        },
     {
            name = "Duel Arena 6",
            spawn1 = vector3(-1659.4058, -1377.8080, 83.9962),
            spawn2 = vector3(-1575.2997, -1395.7540, 81.0447),
        },
    },
}

Config.TeamWeaponMenu = {
    categories = {
        {
            id = "revolvers",
            label = "Revolvers",
            weapons = {
                { code = "WEAPON_REVOLVER_NAVY_CROSSOVER", label = "Navy Crossover" },
                { code = "WEAPON_REVOLVER_NAVY", label = "Navy" },
                { code = "WEAPON_REVOLVER_CATTLEMAN_MEXICAN", label = "Cattleman Mexican" },
                { code = "WEAPON_REVOLVER_CATTLEMAN", label = "Cattleman" },
                { code = "WEAPON_REVOLVER_DOUBLEACTION_GAMBLER", label = "Double Action Gambler" },
                { code = "WEAPON_REVOLVER_DOUBLEACTION", label = "Double Action" },
                { code = "WEAPON_REVOLVER_LEMAT", label = "Lemat" },
                { code = "WEAPON_REVOLVER_SCHOFIELD", label = "Schofield" },
            }
        },
        {
            id = "pistols",
            label = "Pistols",
            weapons = {
                { code = "WEAPON_PISTOL_MAUSER", label = "Mauser" },
                { code = "WEAPON_PISTOL_SEMIAUTO", label = "Semi Auto" },
                { code = "WEAPON_PISTOL_M1899", label = "M1899" },
                { code = "WEAPON_PISTOL_VOLCANIC", label = "Volcanic" },
            }
        },
        {
            id = "repeaters",
            label = "Repeaters",
            weapons = {
                { code = "WEAPON_REPEATER_WINCHESTER", label = "Winchester" },
                { code = "WEAPON_REPEATER_HENRY", label = "Henry" },
                { code = "WEAPON_REPEATER_EVANS", label = "Evans" },
                { code = "WEAPON_REPEATER_CARBINE", label = "Carbine" },
            }
        },
        {
            id = "rifles",
            label = "Rifles",
            weapons = {
                { code = "WEAPON_RIFLE_SPRINGFIELD", label = "Springfield" },
                { code = "WEAPON_RIFLE_BOLTACTION", label = "Bolt Action" },
            }
        },
        {
            id = "snipers",
            label = "Snipers",
            weapons = {
                { code = "WEAPON_SNIPERRIFLE_ROLLINGBLOCK", label = "Rolling Block" },
                { code = "WEAPON_SNIPERRIFLE_CARCANO", label = "Carcano" },
            }
        },
        {
            id = "shotguns",
            label = "Shotguns",
            weapons = {
                { code = "WEAPON_SHOTGUN_SEMIAUTO", label = "Semi Auto Shotgun" },
                { code = "WEAPON_SHOTGUN_SAWEDOFF", label = "Sawed Off Shotgun" },
                { code = "WEAPON_SHOTGUN_REPEATING", label = "Repeating Shotgun" },
                { code = "WEAPON_SHOTGUN_PUMP", label = "Pump Shotgun" },
                { code = "WEAPON_SHOTGUN_DOUBLEBARREL", label = "Double Barrel Shotgun" },
                { code = "WEAPON_SHOTGUN_DOUBLEBARREL_EXOTIC", label = "Double Barrel Exotic" },
            }
        },
        {
            id = "bows",
            label = "Bows",
            weapons = {
                { code = "WEAPON_BOW", label = "Bow" },
                { code = "WEAPON_BOW_IMPROVED", label = "Improved Bow" },
            }
        },
    },
    presets = {
        {
            id = "free_weapons",
            label = "Free Weapons",
            mode = "restrict",
            weapons = {}
        },
        {
            id = "no_snipers",
            label = "No Snipers",
            mode = "restrict",
            weapons = {
                "WEAPON_SNIPERRIFLE_ROLLINGBLOCK",
                "WEAPON_SNIPERRIFLE_CARCANO"
            }
        },
        {
            id = "no_shotguns",
            label = "No Shotguns",
            mode = "restrict",
            weapons = {
                "WEAPON_SHOTGUN_SEMIAUTO",
                "WEAPON_SHOTGUN_SAWEDOFF",
                "WEAPON_SHOTGUN_REPEATING",
                "WEAPON_SHOTGUN_PUMP",
                "WEAPON_SHOTGUN_DOUBLEBARREL",
                "WEAPON_SHOTGUN_DOUBLEBARREL_EXOTIC"
            }
        },
        {
            id = "repeaters_only",
            label = "Repeaters Only",
            mode = "allow_only",
            weapons = {
                "WEAPON_REPEATER_WINCHESTER",
                "WEAPON_REPEATER_HENRY",
                "WEAPON_REPEATER_EVANS",
                "WEAPON_REPEATER_CARBINE"
            }
        },
        {
            id = "sidearms_only",
            label = "Sidearms Only",
            mode = "allow_only",
            weapons = {
                "WEAPON_REVOLVER_NAVY_CROSSOVER",
                "WEAPON_REVOLVER_NAVY",
                "WEAPON_REVOLVER_CATTLEMAN_MEXICAN",
                "WEAPON_REVOLVER_CATTLEMAN",
                "WEAPON_REVOLVER_DOUBLEACTION_GAMBLER",
                "WEAPON_REVOLVER_DOUBLEACTION",
                "WEAPON_REVOLVER_LEMAT",
                "WEAPON_REVOLVER_SCHOFIELD",
                "WEAPON_PISTOL_MAUSER",
                "WEAPON_PISTOL_SEMIAUTO",
                "WEAPON_PISTOL_M1899",
                "WEAPON_PISTOL_VOLCANIC"
            }
        },
    }
}

Config.TeamArenaMeta = {
    [17] = {
        team1Label = "Team 1",
        team2Label = "Team 2",
    },
    [18] = {
        team1Label = "Team 1",
        team2Label = "Team 2",
    },
    [19] = {
        team1Label = "Team 1",
        team2Label = "Team 2",
    },
    [20] = {
        team1Label = "Team 1",
        team2Label = "Team 2",
    },
     [21] = {
        team1Label = "Team 1",
        team2Label = "Team 2",
    },
    [22] = {
        team1Label = "Team 1",
        team2Label = "Team 2",
    },
    [23] = {
        team1Label = "RED TEAM",
        team2Label = "BLUE TEAM",
    },
    [24] = {
        team1Label = "RED TEAM",
        team2Label = "BLUE TEAM",
    },
    [25] = {
        team1Label = "RED TEAM",
        team2Label = "BLUE TEAM",
    },
}

-- ✅ Arenele unde este activ modul Only Headshot
Config.OnlyHeadshotArenas = {
    [16] = true,
}

-- 📌 Definim armele interzise în fiecare lobby
Config.WeaponRestrictions = {
    [1] = { 
  ---      "WEAPON_SNIPERRIFLE_ROLLINGBLOCK",
  ---      "WEAPON_SNIPERRIFLE_CARCANO"
    },
    [2] = {}, 
    [3] = {}, 
    [4] = {
        "WEAPON_SNIPERRIFLE_ROLLINGBLOCK",
        "WEAPON_SNIPERRIFLE_CARCANO"
    },
    [5] = {},
    [6] = {}, 
    [7] = {},
    [8] = {}, 
    [9] = {
        "WEAPON_SNIPERRIFLE_ROLLINGBLOCK",
        "WEAPON_SNIPERRIFLE_CARCANO",
        "WEAPON_RIFLE_SPRINGFIELD",
        "WEAPON_RIFLE_BOLTACTION",
    },
    [10] = {

    },
    [11] = {
        "WEAPON_RIFLE_BOLTACTION",
        "WEAPON_RIFLE_SPRINGFIELD",
        "WEAPON_SNIPERRIFLE_CARCANO",
        "WEAPON_SNIPERRIFLE_ROLLINGBLOCK",
        "WEAPON_REVOLVER_NAVY_CROSSOVER",
        "WEAPON_REVOLVER_NAVY",
        "WEAPON_REVOLVER_CATTLEMAN_MEXICAN",
        "WEAPON_REVOLVER_CATTLEMAN",
        "WEAPON_REVOLVER_DOUBLEACTION_GAMBLER",
        "WEAPON_REVOLVER_DOUBLEACTION",
        "WEAPON_REVOLVER_LEMAT",
        "WEAPON_REVOLVER_SCHOFIELD",
        "WEAPON_PISTOL_MAUSER",
        "WEAPON_PISTOL_SEMIAUTO",
        "WEAPON_PISTOL_M1899",
        "WEAPON_PISTOL_VOLCANIC",
    },
    [12] = {},
    [13] = {
    },
    [15] = {},
    [16] = {
        "WEAPON_PISTOL_VOLCANIC",
        "WEAPON_PISTOL_M1899",
        "WEAPON_PISTOL_SEMIAUTO",
        "WEAPON_PISTOL_MAUSER",
        "WEAPON_REVOLVER_SCHOFIELD",
        "WEAPON_REVOLVER_LEMAT",
        "WEAPON_REVOLVER_DOUBLEACTION",
        "WEAPON_REVOLVER_CATTLEMAN",
        "WEAPON_REVOLVER_CATTLEMAN_MEXICAN",
        "WEAPON_REVOLVER_NAVY",
        "WEAPON_REVOLVER_NAVY_CROSSOVER",
        "WEAPON_SHOTGUN_SEMIAUTO",
        "WEAPON_SHOTGUN_SAWEDOFF",
        "WEAPON_SHOTGUN_REPEATING",
        "WEAPON_SHOTGUN_PUMP",
        "WEAPON_SHOTGUN_DOUBLEBARREL",
        "WEAPON_SHOTGUN_DOUBLEBARREL_EXOTIC",
        "WEAPON_BOW",
        "WEAPON_BOW_IMPROVED",

    },
    [17] = {},
    [18] = {},
    [23] = {},
    [24] = {},
    [25] = {},
}




-- 📌 Spawn points pentru fiecare lobby
Config.LobbySpawns = {
    [1] = {
        vector3(-597.4831, -402.9717, 80.3282),
        vector3(-645.8791, -403.8574, 80.0775),
        vector3(-497.5076, -379.1237, 82.9945),
        vector3(-537.7238, -305.2396, 57.1054),
        vector3(-457.3007, -436.7799, 84.5747),
        vector3(-395.6597, -414.9434, 83.5411),
        vector3(-356.8493, -330.3594, 88.3518),
        vector3(-349.1898, -254.3286, 90.0990),
        vector3(-488.1299, -305.8838, 71.9057),
        vector3(-573.7874, -458.4825, 80.4249),
        vector3(-335.7736, -450.8650, 75.3444),
        vector3(-411.8621, -360.5174, 87.6145),
        vector3(-284.8282, -291.1898, 93.17299),
        vector3(-258.2915, -366.7706, 88.3602),
        vector3(-296.6539, -326.3462, 88.9485),
        vector3(-346.5110, -343.8784, 88.1262),
        vector3(-316.7697, -481.4515, 69.2174),
        vector3(-448.3804, -485.2802, 65.2782),
        vector3(-586.9458, -449.3916, 82.4656),
        vector3(-651.9001, -409.3702, 79.9888),
        vector3(-170.02, -409.71, 66.27),
        vector3(-141.7, -360.4, 76.28),
        vector3(-172.98, -322.59, 87.21),
        vector3(-205.23, -276.41, 89.94),
        vector3(-225.48, -248.09, 88.78),
        vector3(-266.25, -235.8, 90.04),
        vector3(-312.98, -242.51, 91.04),
        vector3(-392.24, -258.02, 80.78),
        vector3(-404.66, -230.72, 65.86)
    },
    [2] = {
        vector3(-1174.31, -444.31, 108.17),
        vector3(-1149.58, -404.09, 107.58),
        vector3(-1117.81, -383.89, 102.1),
        vector3(-1083.08, -429.94, 86.27),
        vector3(-1063.42, -406.2, 83.55),
        vector3(-1025.38, -370.52, 74.68),
        vector3(-1000.25, -369.17, 67.39),
        vector3(-982.23, -352.83, 62.32),
        vector3(-953.41, -396.59, 65.53),
        vector3(-967.55, -422.44, 71.53),
        vector3(-951.98, -449.44, 77.63),
        vector3(-948.82, -469.81, 76.55),
        vector3(-952.88, -496.03, 78.21),
        vector3(-934.3, -522.46, 78.65),
        vector3(-917.27, -546.13, 75.27),
        vector3(-939.49, -550.82, 87.1),
        vector3(-953.35, -565.63, 91.91),
        vector3(-947.52, -586.65, 87.11),
        vector3(-962.52, -605.7, 85.92),
        vector3(-988.3, -605.53, 84.32),
        vector3(-1010.67, -556.68, 99.06),
        vector3(-1011.6, -529.25, 99.57),
        vector3(-1025.42, -492.43, 102.46),
        vector3(-1006.72, -476.6, 99.6),
        vector3(-1005.46, -454.36, 94.77),
        vector3(-1130.36, -546.4, 84.85),
        vector3(-1182.38, -534.73, 89.71),
        vector3(-1236.45, -519.1, 98.21),
        vector3(-1252.37, -494.83, 100.87),
        vector3(-1289.25, -501.33, 114.53),
        vector3(-1306.31, -476.53, 118.53),
        vector3(-1299.91, -451.64, 115.38),
        vector3(-1314.49, -446.24, 108.42),
        vector3(-1274.49, -395.65, 98.9),
        vector3(-1238.18, -376.85, 102.36),
        vector3(-1200.79, -379.87, 102.22),
        vector3(-1164.34, -374.36, 98.74),
        vector3(-1118.9, -362.93, 98.2),
        vector3(-1095.89, -361.84, 98.18),
        vector3(-1073.7, -349.41, 88.56),
        vector3(-1083.13, -321.89, 86.46)
    },
    [3] = {
        vector3(-3687.1328, -2579.7290, -13.7319),
        vector3(-3595.8369, -2578.0056, -14.0120),
        vector3(-3696.2029, -2730.1838, -12.9827),
        vector3(-3715.7812, -2668.1641, -12.6270),
        vector3(-3719.7263, -2577.8894, -13.8806),
        vector3(-3743.2703, -2601.4507, -13.2383),
        vector3(-3685.4868, -2505.1980, -13.9197),
        vector3(-3731.7734, -2524.1316, -13.5103),
        vector3(-3684.9646, -2611.5190, -14.1047),
        vector3(-3643.9165, -2612.3577, -13.8294),
        vector3(-3646.4741, -2662.4036, -14.1172),
        vector3(-3689.6028, -2641.3582, -13.8075),
        vector3(-3659.9753, -2548.8850, -14.0372),
        vector3(-3585.0066, -2519.8857, -14.0699),
        vector3(-3641.9924, -2474.7432, -14.1213),
        vector3(-3725.3794, -2596.3591, -13.4139),
        vector3(-3665.11, -2426.12, -13.65),
        vector3(-3603.17, -2451.34, -14.05),
        vector3(-3563.73, -2492.8, -14.07),
        vector3(-3561.35, -2542.6, -13.56),
        vector3(-3512.8, -2591.91, -13.49),
        vector3(-3500.65, -2645.4, -12.95),
        vector3(-3601.87, -2712.43, -10.11),
        vector3(-3650.53, -2734.69, -9.64),
        vector3(-3681.68, -2744.51, -13.71),
        vector3(-3711.26, -2736.21, -12.72),
        vector3(-3765.9, -2724.64, -14.92),
        vector3(-3807.62, -2683.07, -14.32),
        vector3(-3803.75, -2647.21, -13.93),
        vector3(-3802.65, -2607.2, -14.07),
        vector3(-3793.65, -2563.83, -13.49),
        vector3(-3788.68, -2497.31, -12.2),
        vector3(-3757.05, -2434.37, -11.32),
        vector3(-3703.45, -2393.14, -12.61),
        vector3(-3685.95, -2436.39, -13.6),
        vector3(-3667.01, -2474.97, -13.62),
        vector3(-3697.31, -2604.75, -10.33),
        vector3(-3706.03, -2594.61, -13.33), --- new
        vector3(-3824.8, -2500.41, -12.34)
        },
    [4] = {
        vector3(-528.78, 757.65, 109.48),
        vector3(-442.97, 809.13, 113.06),
        vector3(-392.97, 736.83, 115.06),
        vector3(-349.25, 682.04, 116.43),
        vector3(-356.34, 634.13, 110.65),
        vector3(-388.02, 615.24, 109.27),
        vector3(-423.77, 623.73, 109.9),
        vector3(-473.56, 604.39, 106.73),
        vector3(-509.63, 650.17, 104.02),
        vector3(-511.22, 702.79, 107.21),
        vector3(-512.85, 735.04, 112.41),
        vector3(-471.92, 856.6, 126.59),
        vector3(-546.92, 780.9, 106.49),
        vector3(-531.28, 716.12, 108.05),
        vector3(-501.81, 657.07, 106.46),
        vector3(-518.87, 576.31, 103.56),
        vector3(-441.48, 542.69, 101.76),
        vector3(-420.05, 485.72, 97.91),
        vector3(-363.68, 545.36, 100.82),
        vector3(-333.64, 605.49, 105.79),
        vector3(-324.86, 659.04, 115.69)
        },
    [5] = {
        vector3(-4640.12, -3775.78, 15.01),
        vector3(-4702.04, -3731.41, 12.6),
        vector3(-4784.01, -3801.97, 6.43),
        vector3(-4819.15, -3757.9, 7.5),
        vector3(-4779.5, -3709.96, 9.03),
        vector3(-4747.33, -3677.94, 9.64),
        vector3(-4682.58, -3635.6, 12.02),
        vector3(-4621.59, -3637.81, 14.34),
        vector3(-4558.38, -3657.3, 17.23),
        vector3(-4532.99, -3739.57, 17.28),
        vector3(-4562.75, -3797.48, 13.66),
        vector3(-4603.94, -3829.34, 8.84),
        vector3(-4697.24, -3786.06, 12.02),
        vector3(-4706.71, -3745.54, 12.46),
        vector3(-4708.23, -3688.42, 11.4)
    },
    [6] = {
        vector3(-1123.77, -2185.5, 57.87),
        vector3(-1107.89, -2220.39, 60.37),
        vector3(-1127.43, -2263.68, 58.57),
        vector3(-1166.47, -2257.42, 56.75),
        vector3(-1153.03, -2306.73, 58.77),
        vector3(-1116.65, -2321.0, 58.74),
        vector3(-1073.36, -2285.83, 55.68),
        vector3(-1036.37, -2224.34, 52.84)
    },
    [7] = {
        vector3(-2206.98, 721.83, 122.6),
        vector3(-2217.83, 732.6, 123.15),
        vector3(-2234.71, 721.36, 122.7),
        vector3(-2225.94, 731.91, 127.04),
        vector3(-2210.16, 737.79, 126.8),
        vector3(-2189.52, 726.61, 122.45),
        vector3(-2168.53, 719.9, 122.31),
        vector3(-2172.13, 695.26, 121.11),
        vector3(-2158.62, 692.52, 120.88),
        vector3(-2192.39, 678.8, 120.45),
        vector3(-2219.84, 670.48, 119.33),
        vector3(-2253.76, 705.27, 122.24)
    },
    [8] = {
        vector3(442.67, 1101.63, 196.68),
        vector3(513.79, 1081.48, 195.29),
        vector3(474.01, 1130.84, 190.5),
        vector3(412.55, 1076.46, 192.05),
        vector3(378.91, 1107.29, 193.69)
    },
    [9] = {
        vector3(-2580.29, 387.96, 149.39),
        vector3(-2550.6, 399.58, 148.29),
        vector3(-2548.63, 415.68, 148.51),
        vector3(-2512.76, 365.88, 152.78),
        vector3(-2530.27, 324.87, 153.12),
        vector3(-2581.72, 328.59, 150.36),
        vector3(-2593.76, 340.76, 149.97),
        vector3(-2600.77, 416.22, 148.83),
        vector3(-2601.98, 442.43, 147.54),
        vector3(-2596.93, 465.42, 146.52)
    },
    [10] = {
        vector3(-4208.38, -3440.28, 37.07),
        vector3(-4203.31, -3451.48, 37.09),
        vector3(-4196.31, -3433.76, 37.09)

    },
    [11] = {
        vector3(-1662.12, -1369.07, 83.99),
        vector3(-1646.29, -1281.93, 84.7),
        vector3(-1701.56, -1309.72, 93.12),
        vector3(-1715.28, -1364.02, 95.2),
        vector3(-1715.1, -1386.12, 87.77),
        vector3(-1700.12, -1454.17, 86.45),
        vector3(-1626.64, -1471.76, 84.03),
        vector3(-1582.96, -1422.18, 81.41),
        vector3(-1600.33, -1413.22, 81.95),
        vector3(-1577.12, -1385.67, 80.87),
        vector3(-1596.83, -1343.14, 81.48),
        vector3(-1578.37, -1260.54, 75.25),
        vector3(-1641.04, -1358.3, 89.83),
        vector3(-1640.62, -1373.51, 84.47),
        vector3(-1626.44, -1369.46, 83.23)
    },
    [12] = {
        vector3(1813.93, -1396.35, 43.82),
        vector3(1798.76, -1355.79, 43.8),
        vector3(1761.74, -1393.36, 44.34),
        vector3(1732.6, -1403.27, 44.85),
        vector3(1781.18, -1317.76, 43.98),
        vector3(1849.04, -1318.09, 42.05),
        vector3(1876.01, -1359.74, 42.51),
        vector3(1878.74, -1403.44, 42.26),
        vector3(1859.01, -1353.56, 42.29),
        vector3(1845.82, -1271.4, 43.15),
        vector3(1763.76, -1277.14, 42.78),
    },
    [13] = {
        vector3(-3687.1328, -2579.7290, -13.7319),
        vector3(-3595.8369, -2578.0056, -14.0120),
        vector3(-3696.2029, -2730.1838, -12.9827),
        vector3(-3715.7812, -2668.1641, -12.6270),
        vector3(-3719.7263, -2577.8894, -13.8806),
        vector3(-3743.2703, -2601.4507, -13.2383),
        vector3(-3685.4868, -2505.1980, -13.9197),
        vector3(-3731.7734, -2524.1316, -13.5103),
        vector3(-3684.9646, -2611.5190, -14.1047),
        vector3(-3643.9165, -2612.3577, -13.8294),
        vector3(-3646.4741, -2662.4036, -14.1172),
        vector3(-3689.6028, -2641.3582, -13.8075),
        vector3(-3659.9753, -2548.8850, -14.0372),
        vector3(-3585.0066, -2519.8857, -14.0699),
        vector3(-3641.9924, -2474.7432, -14.1213),
        vector3(-3725.3794, -2596.3591, -13.4139),
        vector3(-3665.11, -2426.12, -13.65),
        vector3(-3603.17, -2451.34, -14.05),
        vector3(-3563.73, -2492.8, -14.07),
        vector3(-3561.35, -2542.6, -13.56),
        vector3(-3512.8, -2591.91, -13.49),
        vector3(-3500.65, -2645.4, -12.95),
        vector3(-3601.87, -2712.43, -10.11),
        vector3(-3650.53, -2734.69, -9.64),
        vector3(-3681.68, -2744.51, -13.71),
        vector3(-3711.26, -2736.21, -12.72),
        vector3(-3765.9, -2724.64, -14.92),
        vector3(-3807.62, -2683.07, -14.32),
        vector3(-3803.75, -2647.21, -13.93),
        vector3(-3802.65, -2607.2, -14.07),
        vector3(-3793.65, -2563.83, -13.49),
        vector3(-3788.68, -2497.31, -12.2),
        vector3(-3757.05, -2434.37, -11.32),
        vector3(-3703.45, -2393.14, -12.61),
        vector3(-3685.95, -2436.39, -13.6),
        vector3(-3667.01, -2474.97, -13.62),
        vector3(-3697.31, -2604.75, -10.33),
        vector3(-3706.03, -2594.61, -13.33), --- new
        vector3(-3824.8, -2500.41, -12.34)
        },
        [14] = {
        vector3(-597.4831, -402.9717, 80.3282),
        vector3(-645.8791, -403.8574, 80.0775),
        vector3(-497.5076, -379.1237, 82.9945),
        vector3(-537.7238, -305.2396, 57.1054),
        vector3(-457.3007, -436.7799, 84.5747),
        vector3(-395.6597, -414.9434, 83.5411),
        vector3(-356.8493, -330.3594, 88.3518),
        vector3(-349.1898, -254.3286, 90.0990),
        vector3(-488.1299, -305.8838, 71.9057),
        vector3(-573.7874, -458.4825, 80.4249),
        vector3(-335.7736, -450.8650, 75.3444),
        vector3(-411.8621, -360.5174, 87.6145),
        vector3(-284.8282, -291.1898, 93.17299),
        vector3(-258.2915, -366.7706, 88.3602),
        vector3(-296.6539, -326.3462, 88.9485),
        vector3(-346.5110, -343.8784, 88.1262),
        vector3(-316.7697, -481.4515, 69.2174),
        vector3(-448.3804, -485.2802, 65.2782),
        vector3(-586.9458, -449.3916, 82.4656),
        vector3(-651.9001, -409.3702, 79.9888),
        vector3(-170.02, -409.71, 66.27),
        vector3(-141.7, -360.4, 76.28),
        vector3(-172.98, -322.59, 87.21),
        vector3(-205.23, -276.41, 89.94),
        vector3(-225.48, -248.09, 88.78),
        vector3(-266.25, -235.8, 90.04),
        vector3(-312.98, -242.51, 91.04),
        vector3(-392.24, -258.02, 80.78),
        vector3(-404.66, -230.72, 65.86)
    },
    [15] = {
        vector3(-969.63, -1420.6, 52.43),
        vector3(-831.68, -1403.79, 43.36),
        vector3(-861.59, -1324.29, 43.4),
        vector3(-870.43, -1298.36, 43.16),
        vector3(-853.91, -1246.99, 43.34),
        vector3(-746.9, -1288.6, 43.17),
        vector3(-775.52, -1304.59, 43.8),
        vector3(-799.68, -1305.8, 43.55),
        vector3(-816.42, -1267.86, 51.0),
        vector3(-814.49, -1293.26, 56.1),
        vector3(-737.48, -1405.54, 47.88),
        vector3(-907.44, -1362.47, 44.64),
    },
    [16] = {
        vector3(-803.91, -1240.01, 43.33),
        vector3(-820.6, -1166.14, 43.25),
        vector3(-763.19, -1205.17, 43.22),
        vector3(-748.22, -1293.92, 43.12),
        vector3(-799.84, -1278.63, 43.59),
        vector3(-849.16, -1283.81, 43.27),
        vector3(-824.84, -1291.87, 53.57),
        vector3(-886.43, -1298.63, 43.24),
        vector3(-825.96, -1336.4, 43.42),
        vector3(-729.96, -1240.81, 44.76),
        vector3(-763.06, -1283.08, 48.68),
        vector3(-785.03, -1312.94, 52.18),
        vector3(-788.43, -1325.92, 51.85),
        vector3(-805.11, -1193.87, 51.81),
    },
    [17] = {
        vector3(-458.1620, -381.1772, 85.7970),
    }, --- team 1
    [18] = {
        vector3(-782.0536, -1233.6655, 43.5384),
    }, --- team 2
    [19] = {
        vector3(1758.7914, -1690.8246, 49.8496),
    }, ---- team 3
    [20] = {
        vector3(-2573.7083, 389.6200, 149.3951),
    }, ---- team 4
     [21] = {
        vector3(707.7937, 58.1174, 151.6426),
    }, ---- team 5
    [22] = {
        vector3(-5981.8252, -3258.9426, -21.7526),
    }, ---- team 6
    [23] = {
        vector3(-6032.0, -3302.0, -21.5),
        vector3(-5932.0, -3216.0, -21.5),
    }, ---- capture the flag
    [24] = {
        vector3(-6032.0, -3302.0, -21.5),
        vector3(-5932.0, -3216.0, -21.5),
    }, ---- capture the flag
    [25] = {
        vector3(-6032.0, -3302.0, -21.5),
        vector3(-5932.0, -3216.0, -21.5),
    }, ---- capture the flag
}

Config.AdminRoles = {
    [1343252230194597897] = true, -- DEVELOPER
    [1366125678193278976] = true, -- OWNER
    [1343252230194597896] = true, -- MANAGER
    [1343252230194597892] = true, -- ADMIN
    [1369345519184515123] = true, -- TRIAL ADMIN
}

Config.Webhooks = {
    KickLobby = "https://discord.com/api/webhooks/1373117640129642566/DQysdPv_uuT3pZxNCTHF6mZK8x7SYCWKj2HcA5LLLo4RM43wDiri3WqIa2axyKbM75m2" 
}

Config.LobbyBypassRoles = {
    [1343252230194597897] = true, 
}
