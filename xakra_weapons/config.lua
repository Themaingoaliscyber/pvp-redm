Config = {}

Config.defaultlang = 'en'

Config.Align = 'top-left'   -- 'center', 'top-left' or 'top-right'

Config.CustomWebhook = '' -- VORP WEBHOOK
Config.StoreWebhook = '' -- VORP WEBHOOK
Config.CraftWebhook = '' -- VORP WEBHOOK
Config.BreakableWeaponsWebhook = '' -- VORP WEBHOOK

Config.KeyOpenMenu = 0x760A9C6F -- G

Config.KeyAhead = 0x911CB09E    -- UP ARROW
Config.KeyAback = 0x4403F97F    -- DOWN ARROW

Config.KeyRollLeft = 0xE6F612E4 -- BUTTON 1
Config.KeyRollRight = 0x1CE6D9EB    -- BUTTON 2
Config.KeyPitchAback = 0x4F49CC4C	-- BUTTON 3
Config.KeyPitchAhead = 0x8F9F9E58   -- BUTTON 4

Config.KeyMoreZoom = 0x3076E97C -- MOUSE SCROLL UP
Config.KeyLessZoom = 0x8BDE7443 -- MOUSE SCROLL DOWN

Config.KeyRoll = 0x760A9C6F -- G

Config.WeaponsCondition = {
    Enable = true, -- Enable or disable the condition and dirt system of the weapon
    Modifier = 0.0, -- number (Weapon condition loss multiplier min 0.0, normal 1.0)
    Breakable = {
        Enable = false,  -- (THIS OPTION WILL REMOVE WEAPONS WITHOUT CONDITION) Enable or disable if weapons will break when the weapon has no condition
        Item = 'brokenweapon', -- item name (Item that the player will receive when the weapon is broken, saved in metadata) or false (the player will lose the weapon without receiving anything)
        jobs = {    -- List of jobs required to use the item and repair the weapon or false
            { job = 'gunsmithR', grade = false },
        },
        ItemsRequired = {   -- Items required to use the item and repair the weapon or false
            { label = 'Iron', item = 'iron', amount = 14 },
            { label = 'Wood', item = 'wood', amount = 7 },
        },
        WeaponsItemsRequired = {   -- List of specific weapons required items
            ['WEAPON_SNIPERRIFLE_CARCANO'] = {
                { label = 'Iron', item = 'iron', amount = 30 },
                { label = 'Wood', item = 'wood', amount = 15 },
            },
            -- ['Example weapon name'] = {
            --     { label = 'Example 1', item = 'example1', amount = 5 },
            --     { label = 'Example 2', item = 'example2', amount = 2 },
            -- },
        },
    },  
}

Config.StoreExpSystem = false    -- Enable or disable the experience system (System of experience gained from the characters table)
Config.CraftExpSystem = false    -- Enable or disable the experience system (Gunsmiths must gain experience by crafting and access new crafting)

Config.ShowIdWeapon = true  -- Enable or disable display of weapon id when inspecting

Config.ItemsCleanGun = {    -- Items to clean the weapon with a rag, choose whether to consume the item. The items that have the subitem option set to false must be first in the list to prevent it from consuming items if you have more than one in your inventory.
    { 
        item = 'guncloth',  -- Item name
        uses = false,   -- -- number (Number of uses each item) or false (never consumed)
        jobs = {    -- List of jobs and degree to use the item or false
            { job = 'gunsmithR', grade = false },
            { job = 'gunsmithS', grade = false },
            { job = 'gunsmithV', grade = false },
            { job = 'gunsmithA', grade = false },
            { job = 'gunsmithT', grade = false },
        },
    },
    { 
        item = 'cloth', -- Item name
        uses = 1,   -- number (Number of uses each item) or false (never consumed)
        -- jobs = {    -- List of jobs and degree to use the item or false
        --     { job = 'Example1', grade = false },
        --     { job = 'Example2', grade = false },
        -- },
    },
    -- { 
    --     item = 'example', -- Item name
    --     uses = 3,   -- number (Number of uses each item) or false (never consumed)
    --     jobs = {    -- List of jobs and degree to use the item or false
    --         { job = 'Example1', grade = false },
    --         { job = 'Example2', grade = false },
    --     },
    -- },
}

-- COLORS: https://github.com/femga/rdr3_discoveries/tree/master/useful_info_from_rpfs/blip_modifiers
Config.ColorStoreBlips = 'BLIP_MODIFIER_MP_COLOR_11'
Config.ColorClosedStoreBlips = 'BLIP_MODIFIER_MP_COLOR_20'

Config.ProgressBar = {
    CustomizeScenario = 'WORLD_HUMAN_WRITE_NOTEBOOK',
    CraftScenario = 'WORLD_HUMAN_WRITE_NOTEBOOK',
    TimePreparation = 15000,    -- (Milliseconds) Time to customize weapons and craft
    type = 'innercircle',   -- 'linear', 'circle' or 'innercircle'
    color = '#0A4F05',  -- HTML Hex Color
}

Config.Locations = {
	['Rhodes'] = {
        craftCoords = vector3(1329.54, -1320.9, 77.89), -- Location to open the crafting menu or false
        Custom = {  -- Custom list or false
            Location = { coords = vector3(1326.45, -1321.96, 78.1), heading = 74.59 },    -- Location to open weapon customization and spawn menu, the weapon will point to the right of the header
            -- CategoryBlacklist = { -- Blacklist of the personalization category List, indicates the categories of the Config.CustomPrices list that you do not want to appear in this location or false
            --     'Name',
            --     'Serial',
            --     'Description',
            --     'Scope',
            -- },
            -- CompsBlacklist = { -- List of components that will not be able to use [https://github.com/femga/rdr3_discoveries/blob/master/weapons/weapon_components.lua] or false
            --     'COMPONENT_RIFLE_SCOPE03',
            --     'COMPONENT_RIFLE_SCOPE04',
            -- },
            -- weaponWhitelist = { -- List of weapons allowed in the location or false
            --     'WEAPON_BOW',
            --     'WEAPON_BOW_IMPROVED',
            -- },
        },
        -- Groups = {  -- List of groups to access customization and crafting or false
        --     'admin',
        --     'moderator',
        --     'vip',
        -- },
        jobs = false, -- Acum oricine poate accesa personalizarea armelor

        Store = {   -- Store list or false
            blip = { enable = true, sprite = GetHashKey('blip_shop_gunsmith') },    -- Enable or disable store blip sprite and blip
            storeCoords = { coords = vector3(1322.79, -1322.2, 78.00), heading = 165.00 },  -- Location of the store and the spawn of the products of the store, , the weapon will point to the right of the header
            StoreOpen = 7,  -- AM or false or false
            StoreClose = 21,    -- PM or false
            NPC = { coords = vector4(1322.58, -1323.19, 76.89, -26.55), model = 'U_M_M_AsbGunsmith_01', scenario = 'SC_WORLD_HUMAN_STAND_BAR' },    -- Location of the npc, the model and scenario or false
            -- jobs = {    -- List of jobs and grade to access store or false
            --     { job = 'example1', grade = false },
            --     { job = 'example2', grade = false },
            -- },
        },
	},
    ['Saint Denis'] = {
        craftCoords = vector3(2710.81, -1287.88, 49.64),    -- Location to open the crafting menu or false
        Custom = {  -- Custom list or false
            Location = { coords = vector3(2708.63, -1283.69, 49.9), heading = 29.61 },    -- Location to open weapon customization and spawn menu, the weapon will point to the right of the header
            -- CategoryBlacklist = { -- Blacklist of the personalization category List, indicates the categories of the Config.CustomPrices list that you do not want to appear in this location or false
            --     'Name',
            --     'Serial',
            --     'Description',
            --     'Scope',
            -- },
            -- CompsBlacklist = { -- List of components that will not be able to use [https://github.com/femga/rdr3_discoveries/blob/master/weapons/weapon_components.lua] or false
            --     'COMPONENT_RIFLE_SCOPE03',
            --     'COMPONENT_RIFLE_SCOPE04',
            -- },
            -- weaponWhitelist = { -- List of weapons allowed in the location or false
            --     'WEAPON_BOW',
            --     'WEAPON_BOW_IMPROVED',
            -- },
        },
        -- Groups = {  -- List of groups to access customization and crafting or false
        --     'admin',
        --     'moderator',
        --     'vip',
        -- },
		jobs = {    -- List of jobs and grade to access customization and crafting or false
			{ job = 'gunsmithS', grade = 2 },
		},
        Store = {   -- Store list or false
            blip = { enable = true, sprite = GetHashKey('blip_shop_gunsmith') },    -- Enable or disable store blip sprite and blip
            storeCoords = { coords = vector3(2716.35, -1286.20, 49.8), heading = 205.0 },  -- Location of the store and the spawn of the products of the store, , the weapon will point to the right of the header
            StoreOpen = 7,  -- AM or false
            StoreClose = 21,    -- PM or false
            NPC = { coords = vector4(2716.83, -1287.18, 48.69, 19.40), model = 'U_M_M_AsbGunsmith_01', scenario = 'SC_WORLD_HUMAN_STAND_BAR' }, -- Location of the npc, the model and scenario or false
            -- jobs = {    -- List of jobs and grade to access store or false
            --     { job = 'example1', grade = false },
            --     { job = 'example2', grade = false },
            -- },
        },
	},
    ['L1'] = {
        craftCoords = vector3(-276.56, 777.15, 119.5),  -- Location to open the crafting menu or false
        Custom = {  -- Custom list or false
            Location = { coords = vector3(-1302.27, 394.31, 95.55), heading = 160 },    -- Location to open weapon customization and spawn menu, the weapon will point to the right of the header
            -- CategoryBlacklist = { -- Blacklist of the personalization category List, indicates the categories of the Config.CustomPrices list that you do not want to appear in this location or false
            --     'Name',
            --     'Serial',
            --     'Description',
            --     'Scope',
            -- },
            -- CompsBlacklist = { -- List of components that will not be able to use [https://github.com/femga/rdr3_discoveries/blob/master/weapons/weapon_components.lua] or false
            --     'COMPONENT_RIFLE_SCOPE03',
            --     'COMPONENT_RIFLE_SCOPE04',
            -- },
            -- weaponWhitelist = { -- List of weapons allowed in the location or false
            --     'WEAPON_BOW',
            --     'WEAPON_BOW_IMPROVED',
            -- },
        },
        -- Groups = {  -- List of groups to access customization and crafting or false
        --     'admin',
        --     'moderator',
        --     'vip',
        -- },
        jobs = false, -- Acum oricine poate accesa personalizarea armelor

        Store = {   -- Store list or false
            blip = { enable = true, sprite = GetHashKey('blip_shop_gunsmith') },    -- Enable or disable store blip sprite and blip
            storeCoords = { coords = vector3(-1304.99, 391.22, 95.11), heading = 178.87 },    -- Location of the store and the spawn of the products of the store, , the weapon will point to the right of the header
            StoreOpen = false,
            StoreClose = false,
            NPC = { coords = vector4(-1304.98, 391.78, 94.43, 345.09), model = 'U_M_M_AsbGunsmith_01', scenario = '' },    -- Location of the npc, the model and scenario or false
            -- jobs = {    -- List of jobs and grade to access store or false
            --     { job = 'example1', grade = false },
            --     { job = 'example2', grade = false },
            -- },
        },
	},
    ['L2'] = {
        craftCoords = vector3(2950.41, 1314.8, 44.82),  -- Location to open the crafting menu or false
        Custom = {  -- Custom list or false
            Location = { coords = vector3(-1300.6678, 412.8876, 95.3441), heading = 00.0 },    -- Location to open weapon customization and spawn menu, the weapon will point to the right of the header
            -- CategoryBlacklist = { -- Blacklist of the personalization category List, indicates the categories of the Config.CustomPrices list that you do not want to appear in this location or false
            --     'Name',
            --     'Serial',
            --     'Description',
            --     'Scope',
            -- },
            -- CompsBlacklist = { -- List of components that will not be able to use [https://github.com/femga/rdr3_discoveries/blob/master/weapons/weapon_components.lua] or false
            --     'COMPONENT_RIFLE_SCOPE03',
            --     'COMPONENT_RIFLE_SCOPE04',
            -- },
            -- weaponWhitelist = { -- List of weapons allowed in the location or false
            --     'WEAPON_BOW',
            --     'WEAPON_BOW_IMPROVED',
            -- },
        },
        -- Groups = {  -- List of groups to access customization and crafting or false
        --     'admin',
        --     'moderator',
        --     'vip',
        -- },
        jobs = false, -- Acum oricine poate accesa personalizarea armelor

        Store = {   -- Store list or false
            blip = { enable = true, sprite = GetHashKey('blip_shop_gunsmith') },    -- Enable or disable store blip sprite and blip
            storeCoords = { coords = vector3(2947.41, 1319.85, 45.0), heading = 251.45 },   -- Location of the store and the spawn of the products of the store, , the weapon will point to the right of the header
            StoreOpen = 7,  -- AM or false
            StoreClose = 21,    -- PM or false
            NPC = { coords = vector4(2948.42, 1319.49, 43.87, 55.97), model = 'U_M_M_AsbGunsmith_01', scenario = 'SC_WORLD_HUMAN_STAND_BAR' },   -- Location of the npc, the model and scenario or false
            -- jobs = {    -- List of jobs and grade to access store or false
            --     { job = 'example1', grade = false },
            --     { job = 'example2', grade = false },
            -- },
        },
	},
    ['Strawberry'] = {
        craftCoords = vector3(-1790.14, -389.74, 160.33),   -- Location to open the crafting menu or false
        Custom = {  -- Custom list or false
            Location = { coords = vector3(-1790.55, -383.51, 160.2), heading = 322.64 },    -- Location to open weapon customization and spawn menu, the weapon will point to the right of the header
            CategoryBlacklist = { -- Blacklist of the personalization category List, indicates the categories of the Config.CustomPrices list that you do not want to appear in this location or false
                'Name',
                'Serial',
                'Description',
                'Scope',
            },
            CompsBlacklist = { -- List of components that will not be able to use [https://github.com/femga/rdr3_discoveries/blob/master/weapons/weapon_components.lua] or false
                'COMPONENT_RIFLE_SCOPE03',
                'COMPONENT_RIFLE_SCOPE04',
            },
            weaponWhitelist = { -- List of weapons allowed in the location or false
                'WEAPON_BOW',
                'WEAPON_BOW_IMPROVED',
            },
        },
        -- Groups = {  -- List of groups to access customization and crafting or false
        --     'admin',
        --     'moderator',
        --     'vip',
        -- },
        jobs = {    -- List of jobs and grade to access customization and crafting or false
            { job = 'gunsmithS', grade = false },
        },
        Store = {   -- Store list or false
            blip = { enable = true, sprite = GetHashKey('blip_shop_gunsmith') },    -- Enable or disable store blip sprite and blip
            storeCoords = { coords = vector3(-1790.57, -387.6, 160.4), heading = 235.82 },  -- Location of the store and the spawn of the products of the store, , the weapon will point to the right of the header
            StoreOpen = 7,  -- AM or false
            StoreClose = 21,    -- PM or false
            NPC = { coords = vector4(-1789.73, -388.17, 159.38, 44.94), model = 'U_M_M_AsbGunsmith_01', scenario = 'SC_WORLD_HUMAN_STAND_BAR' },    -- Location of the npc, the model and scenario or false
            -- jobs = {    -- List of jobs and grade to access store or false
            --     { job = 'example1', grade = false },
            --     { job = 'example2', grade = false },
            -- },
        },
	},
    ['Tumbleweed'] = {
        craftCoords = vector3(-5508.44, -2969.02, -0.63),   -- Location to open the crafting menu or false
        Custom = {  -- Custom list or false
            Location = { coords = vector3(-5506.54, -2962.79, -0.45), heading = 194.36 },    -- Location to open weapon customization and spawn menu, the weapon will point to the right of the header
            -- CategoryBlacklist = { -- Blacklist of the personalization category List, indicates the categories of the Config.CustomPrices list that you do not want to appear in this location or false
            --     'Name',
            --     'Serial',
            --     'Description',
            --     'Scope',
            -- },
            -- CompsBlacklist = { -- List of components that will not be able to use [https://github.com/femga/rdr3_discoveries/blob/master/weapons/weapon_components.lua] or false
            --     'COMPONENT_RIFLE_SCOPE03',
            --     'COMPONENT_RIFLE_SCOPE04',
            -- },
            -- weaponWhitelist = { -- List of weapons allowed in the location or false
            --     'WEAPON_BOW',
            --     'WEAPON_BOW_IMPROVED',
            -- },
        },
        -- Groups = {  -- List of groups to access customization and crafting or false
        --     'admin',
        --     'moderator',
        --     'vip',
        -- },
		jobs = {    -- List of jobs and grade to access customization and crafting or false
			{ job = 'gunsmithT', grade = false },
		},
        Store = {   -- Store list or false
            blip = { enable = true, sprite = GetHashKey('blip_shop_gunsmith') },    -- Enable or disable store blip sprite and blip
            storeCoords = { coords = vector3(-5506.97, -2966.01, -0.55), heading = 282.86 },    -- Location of the store and the spawn of the products of the store, , the weapon will point to the right of the header
            StoreOpen = 7,  -- AM or false
            StoreClose = 21,    -- PM or false
            NPC = { coords = vector4(-5505.91, -2965.82, -1.59, 92.46), model = 'U_M_M_AsbGunsmith_01', scenario = 'SC_WORLD_HUMAN_STAND_BAR' },   -- Location of the npc, the model and scenario or false
            -- jobs = {    -- List of jobs and grade to access store or false
            --     { job = 'example1', grade = false },
            --     { job = 'example2', grade = false },
            -- },
        },
	},
}

Config.DisableCompPrint = false -- true or false (Enable or disable print when component is changed)

Config.CostCustomization = { -- Price list of each customization
    Name = {    -- Change weapon name
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    Serial = {  -- Change weapon serial
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    DeleteSerial = {    -- Delete weapon serial number
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    Description = { -- Change weapon description
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
	Barrel = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
        },
    },
    Grip = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    Sight = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
        },
    },
    Clip = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    Wrap = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    Frame = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    Stock = {   -- SHOTGUN SAWEDOFF
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    Tube = {    -- REPEATER CARBINE
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    Mag = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    FrameWoodColor = { -- Bow Improved
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    GripLeatherColor = { -- Bow Improved
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    StringColor = { -- Bow Improved
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    TriggerMaterial = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    SightMaterial = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    HammerMaterial = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    FrameMaterial = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    FrameEngraving = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    FrameEngravingMaterial = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    GripMaterial = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    GripStockTint = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    GripStockEngraving = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    BarrelRifling = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    Scope = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    BarrelMaterial = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    BarrelEngraving = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    BarrelEngravingMaterial = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    CylinderMaterial = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    CylinderEngraving = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    CylinderEngravingMaterial = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    WrapMaterial = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    WrapTint = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    Strap = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    StrapTint = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    BladeMaterial = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    BladeEngraving = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    BladeEngravingMaterial = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    GripTint = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    TorchMatchstick = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
    FishingLine = {
        Currency = {
            label = _U('Money'),
            type = 0,   -- 0 = money, 1 = gold, 2 = rol
            amount = 0,
        },
        Items = {
            -- { label = 'Example 1', item = 'iron', amount = 5 },
            -- { label = 'Example 2', item = 'wood', amount = 10 },
        },
    },
}