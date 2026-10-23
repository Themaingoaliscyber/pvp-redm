ConfigCraft = {}

-- ['Weapon label'] = { 
--     hashname = 'WEAPON_MELEE_KNIFE_TRADER',
--     amount = (number), -- Quantity that will be created with this craft
--     locations = { (Id of the locations or 'all')},
--     costcraft = {   -- list or false
--         label = 'Currency label',
--         type = (number),   -- 0 = money, 1 = gold, 2 = rol
--         amount = (number),
--     },
--     exp = { required = (Experience required), reward = (Experience gain when crafting) },
--     craft = {
--         { label = (Name to be displayed in the menu), item = (Name of the required item), amount = (Quantity required for the item) },
--     },
--     CustomComps = (json.decode('Text copied from the comps column of the database') or false),
--     CustomLabel = ('Custom weapon name' or false),
--     CustomDesc = ('Custom weapon description' or false),
-- },

-- ['Item label'] = { 
--     item = (Name of the item to craft),
--     amount = (number), -- Quantity that will be created with this craft
--     locations = { (Id of the locations or 'all')},
--     costcraft = false,   -- list or false
--     exp = { required = (Experience required), reward = (Experience gain when crafting) },
--     craft = {
--         { label = (Name to be displayed in the menu), item = (Name of the required item), amount = (Quantity required for the item) },
--     },
-- },

-- NOTE: If you add 1 'all' location the product will be in all locations.

ConfigCraft.Crafts = {
    [_U('Weapons')] = {
        [_U('Melee')] = {
            [_U('TraddersKnife')] = { 
                hashname = 'WEAPON_MELEE_KNIFE_TRADER',
                amount = 1,
                locations = { 'Rhodes', 'Valentine', 'Annesburg' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 14 },
                    { label = 'Wood', item = 'wood', amount = 7 },
                },
            },
            [_U('Knife')] = { 
                hashname = 'WEAPON_MELEE_KNIFE',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 2 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 10 },
                    { label = 'Wood', item = 'wood', amount = 2 },
                },
            },
            [_U('RusticKnife')] = { 
                hashname = 'WEAPON_MELEE_KNIFE_RUSTIC',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 2 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 15 },
                    { label = 'Wood', item = 'wood', amount = 2 },
                },
            },
            [_U('JawBoneKnife')] = { 
                hashname = 'WEAPON_MELEE_KNIFE_JAWBONE',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 15 },
                    { label = 'Wood', item = 'wood', amount = 2 },
                },
            },
            [_U('Cleaver')] = { 
                hashname = 'WEAPON_MELEE_CLEAVER',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 22 },
                    { label = 'Wood', item = 'wood', amount = 7 },
                },
            },
            [_U('Hatchet')] = { 
                hashname = 'WEAPON_MELEE_HATCHET',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 20 },
                    { label = 'Wood', item = 'wood', amount = 4 },
                },
            },
            [_U('HunterHatchet')] = { 
                hashname = 'WEAPON_MELEE_HATCHET_HUNTER',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 25 },
                    { label = 'Wood', item = 'wood', amount = 5 },
                },
            },
            [_U('Machete')] = { 
                hashname = 'WEAPON_MELEE_MACHETE',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 35 },
                    { label = 'Wood', item = 'wood', amount = 8 },
                },
            },
            [_U('CollectorMachete')] = { 
                hashname = 'WEAPON_MELEE_MACHETE_COLLECTOR',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 40 },
                    { label = 'Wood', item = 'wood', amount = 10 },
                },
            },
            [_U('KnifeHorror')] = { 
                hashname = 'WEAPON_MELEE_KNIFE_HORROR',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 35 },
                },
            },
            [_U('Hammer')] = { 
                hashname = 'WEAPON_MELEE_HAMMER',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 10 },
                    { label = 'Hard wood', item = 'hwood', amount = 5 },
                },
            },
            [_U('Torch')] = { 
                hashname = 'WEAPON_MELEE_TORCH',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Hard wood', item = 'hwood', amount = 20 },
                    { label = 'Wood', item = 'wood', amount = 5 },
                },
            },
            [_U('MetalDetector')] = { 
                hashname = 'WEAPON_KIT_METAL_DETECTOR',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 30 },
                },
            },
        },
        [_U('Bows')] = {
            [_U('Bow')] = { 
                hashname = 'WEAPON_BOW',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Hard wood', item = 'hwood', amount = 10 },
                    { label = 'Wood', item = 'wood', amount = 4 },
                },
            },
            [_U('ImprovedBow')] = { 
                hashname = 'WEAPON_BOW_IMPROVED',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Hard wood', item = 'hwood', amount = 40 },
                    { label = 'Wood', item = 'wood', amount = 10 },
                },
            },
        },
        [_U('Rifles')] = {
            [_U('ElephantRifle')] = { 
                hashname = 'WEAPON_RIFLE_ELEPHANT',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 100 },
                    { label = 'Wood', item = 'wood', amount = 40 },
                },
            },
            [_U('VarmintRifle')] = { 
                hashname = 'WEAPON_RIFLE_VARMINT',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 50 },
                    { label = 'Wood', item = 'wood', amount = 30 },
                },
            },
            [_U('RollingblockRifle')] = { 
                hashname = 'WEAPON_SNIPERRIFLE_ROLLINGBLOCK',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 150 },
                    { label = 'Wood', item = 'wood', amount = 60 },
                },
            },
            [_U('CarcanoRifle')] = { 
                hashname = 'WEAPON_SNIPERRIFLE_CARCANO',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 250 },
                    { label = 'Wood', item = 'wood', amount = 100 },
                },
            },
            [_U('SpringfieldRifle')] = { 
                hashname = 'WEAPON_RIFLE_SPRINGFIELD',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 180 },
                    { label = 'Wood', item = 'wood', amount = 70 },
                },
            },
            [_U('BoltactionRifle')] = { 
                hashname = 'WEAPON_RIFLE_BOLTACTION',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 65 },
                    { label = 'Wood', item = 'wood', amount = 120 },
                },
            },
        },
        [_U('Repeaters')] = {
            [_U('WinchesterRepeater')] = { 
                hashname = 'WEAPON_REPEATER_WINCHESTER',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 150 },
                    { label = 'Wood', item = 'wood', amount = 50 },
                },
            },
            [_U('HenryRepeater')] = { 
                hashname = 'WEAPON_REPEATER_HENRY',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 110 },
                    { label = 'Wood', item = 'wood', amount = 40 },
                },
            },
            [_U('EvansRepeater')] = { 
                hashname = 'WEAPON_REPEATER_EVANS',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 105 },
                    { label = 'Wood', item = 'wood', amount = 40 },
                },
            },
            [_U('CarbineRepeater')] = { 
                hashname = 'WEAPON_REPEATER_CARBINE',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 95 },
                    { label = 'Wood', item = 'wood', amount = 35 },
                },
            },
        },
        [_U('Pistols')] = {
            [_U('Volcanic')] = { 
                hashname = 'WEAPON_PISTOL_VOLCANIC',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 50 },
                    { label = 'Wood', item = 'wood', amount = 10 },
                },
            },
            [_U('M1899')] = { 
                hashname = 'WEAPON_PISTOL_M1899',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 45 },
                    { label = 'Wood', item = 'wood', amount = 9 },
                },
            },
            [_U('SemiAuto')] = { 
                hashname = 'WEAPON_PISTOL_SEMIAUTO',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 43 },
                    { label = 'Wood', item = 'wood', amount = 8 },
                },
            },
            [_U('Mauser')] = { 
                hashname = 'WEAPON_PISTOL_MAUSER',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 45 },
                    { label = 'Wood', item = 'wood', amount = 11 },
                },
            },
        },
        [_U('Revolvers')] = {
            [_U('Schofield')] = { 
                hashname = 'WEAPON_REVOLVER_SCHOFIELD',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 38 },
                    { label = 'Wood', item = 'wood', amount = 8 },
                },
            },
            [_U('Lemat')] = { 
                hashname = 'WEAPON_REVOLVER_LEMAT',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 42 },
                    { label = 'Wood', item = 'wood', amount = 7 },
                },
            },
            [_U('DoubleAction')] = { 
                hashname = 'WEAPON_REVOLVER_DOUBLEACTION',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 37 },
                    { label = 'Wood', item = 'wood', amount = 7 },
                },
            },
            [_U('DoubleActionGambler')] = { 
                hashname = 'WEAPON_REVOLVER_DOUBLEACTION_GAMBLER',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 40 },
                    { label = 'Wood', item = 'wood', amount = 10 },
                },
            },
            [_U('Cattleman')] = { 
                hashname = 'WEAPON_REVOLVER_CATTLEMAN',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 35 },
                    { label = 'Wood', item = 'wood', amount = 5 },
                },
            },
            [_U('CattlemanMexican')] = { 
                hashname = 'WEAPON_REVOLVER_CATTLEMAN_MEXICAN',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 35 },
                    { label = 'Wood', item = 'wood', amount = 5 },
                },
            },
            [_U('Navy')] = { 
                hashname = 'WEAPON_REVOLVER_NAVY',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 65 },
                    { label = 'Wood', item = 'wood', amount = 15 },
                },
            },
            [_U('NavyCrossover')] = { 
                hashname = 'WEAPON_REVOLVER_NAVY_CROSSOVER',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 75 },
                    { label = 'Wood', item = 'wood', amount = 25 },
                },
            },
        },
        [_U('Throwable')] = {
            [_U('Tomahawk')] = { 
                hashname = 'WEAPON_THROWN_TOMAHAWK',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 45 },
                    { label = 'Wood', item = 'wood', amount = 10 },
                },
            },
            [_U('Knives')] = { 
                hashname = 'WEAPON_THROWN_THROWING_KNIVES',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 55 },
                    { label = 'Wood', item = 'wood', amount = 15 },
                },
            },
            [_U('PoisonBottle')] = { 
                hashname = 'WEAPON_THROWN_POISONBOTTLE',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 70 },
                    { label = 'Wood', item = 'wood', amount = 30 },
                },
            },
            [_U('Bolas')] = { 
                hashname = 'WEAPON_THROWN_BOLAS',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 100 },
                    { label = 'Wood', item = 'wood', amount = 50 },
                },
            },
            [_U('BolasHawkmoth')] = { 
                hashname = 'WEAPON_THROWN_BOLAS_HAWKMOTH',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 100 },
                    { label = 'Wood', item = 'wood', amount = 50 },
                },
            },
            [_U('BolasIronspiked')] = { 
                hashname = 'WEAPON_THROWN_BOLAS_IRONSPIKED',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 100 },
                    { label = 'Wood', item = 'wood', amount = 50 },
                },
            },
            [_U('BolasIntertwined')] = { 
                hashname = 'WEAPON_THROWN_BOLAS_INTERTWINED',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 100 },
                    { label = 'Wood', item = 'wood', amount = 50 },
                },
            },
            [_U('Dynamite')] = { 
                hashname = 'WEAPON_THROWN_DYNAMITE',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 250 },
                    { label = 'Wood', item = 'wood', amount = 100 },
                },
            },
            [_U('Molotov')] = { 
                hashname = 'WEAPON_THROWN_MOLOTOV',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 150 },
                    { label = 'Wood', item = 'wood', amount = 50 },
                },
            },
        },
        [_U('Shotguns')] = {
            ['Semiauto Shotgun'] = { 
                hashname = 'WEAPON_SHOTGUN_SEMIAUTO',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 150 },
                    { label = 'Wood', item = 'wood', amount = 47 },
                },
            },
            [_U('Sawedoff')] = { 
                hashname = 'WEAPON_SHOTGUN_SAWEDOFF',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 125 },
                    { label = 'Wood', item = 'wood', amount = 44 },
                },
            },
            [_U('Repeating')] = { 
                hashname = 'WEAPON_SHOTGUN_REPEATING',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 175 },
                    { label = 'Wood', item = 'wood', amount = 67 },
                },
            },
            [_U('Pump')] = { 
                hashname = 'WEAPON_SHOTGUN_PUMP',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 80 },
                    { label = 'Wood', item = 'wood', amount = 25 },
                },
            },
            [_U('Doublebarrel')] = { 
                hashname = 'WEAPON_SHOTGUN_DOUBLEBARREL',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 55 },
                    { label = 'Wood', item = 'wood', amount = 19 },
                },
            },
            [_U('DoublebarrelExotic')] = { 
                hashname = 'WEAPON_SHOTGUN_DOUBLEBARREL_EXOTIC',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 55 },
                    { label = 'Wood', item = 'wood', amount = 19 },
                },
            },
        },
        [_U('Misc')] = {
            [_U('Lasso')] = { 
                hashname = 'WEAPON_LASSO',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Wood', item = 'wood', amount = 30 },
                },
            },
            [_U('ReinforcedLasso')] = { 
                hashname = 'WEAPON_LASSO_REINFORCED',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Wood', item = 'wood', amount = 60 },
                },
            },
            [_U('ImprovedBinoculars')] = { 
                hashname = 'WEAPON_KIT_BINOCULARS_IMPROVED',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 35 },
                },
            },
            [_U('Binoculars')] = { 
                hashname = 'WEAPON_kIT_BINOCULARS',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 15 },
                },
            },
            [_U('FishingRod')] = { 
                hashname = 'WEAPON_FISHINGROD',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Hard wood', item = 'hwood', amount = 5 },
                    { label = 'Wood', item = 'wood', amount = 25 },
                },
            },
            [_U('Camera')] = { 
                hashname = 'WEAPON_KIT_CAMERA',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 35 },
                },
            },
            [_U('AdvancedCamera')] = { 
                hashname = 'WEAPON_kIT_CAMERA_ADVANCED',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 60 },
                },
            },
            [_U('Lantern')] = { 
                hashname = 'WEAPON_MELEE_LANTERN',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 50 },
                    { label = 'Wood', item = 'wood', amount = 10 },
                },
            },
            [_U('DavyLantern')] = { 
                hashname = 'WEAPON_MELEE_DAVY_LANTERN',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 70 },
                    { label = 'Wood', item = 'wood', amount = 20 },
                },
            },
            [_U('LanternHalloween')] = { 
                hashname = 'WEAPON_MELEE_LANTERN_HALLOWEEN',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 50 },
                    { label = 'Sulfur', item = 'sulfur', amount = 10 },
                },
            },
        },
    },
    [_U('Ammo')] = {
        [_U('RepeaterAmmo')] = {
            [_U('RepeaterAmmoNormal')] = { 
                item = 'ammorepeaternormal',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 23 },
                },
            },
            [_U('RepeaterAmmoExpress')] = { 
                item = 'ammorepeaterexpress',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 29 },
                },
            },
            [_U('RepeaterAmmoExplosive')] = { 
                item = 'ammorepeaterexplosive',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 60 },
                },
            },
            [_U('RepeaterAmmoVelocity')] = { 
                item = 'ammorepeatervelocity',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 29 },
                },
            },
            [_U('RepeaterAmmoSplitpoint')] = { 
                item = 'ammorepeatersplitpoint',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 29 },
                },
            },
        },

        [_U('RevolverAmmo')] = {
            [_U('RevolverAmmoNormal')] = { 
                item = 'ammorevolvernormal',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 15 },
                },
            },
            [_U('RevolverAmmoExpress')] = { 
                item = 'ammorevolverexpress',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 25 },
                },
            },
            [_U('RevolverAmmoExplosive')] = { 
                item = 'ammorevolverexplosive',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 50 },
                },
            },
            [_U('RevolverAmmoVelocity')] = { 
                item = 'ammorevolvervelocity',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 25 },
                },
            },
            [_U('RevolverAmmoSplitpoint')] = { 
                item = 'ammorevolversplitpoint',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 25 },
                },
            },
        },
        [_U('RifleAmmo')] = {
            [_U('RifleAmmoNormal')] = { 
                item = 'ammoriflenormal',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 20 },
                },
            },
            [_U('ElephantRifleAmmo')] = { 
                item = 'ammoelephant',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 15 },
                },
            },
            [_U('RifleAmmoExpress')] = { 
                item = 'ammorifleexpress',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 30 },
                },
            },
            [_U('RifleAmmoExplosive')] = { 
                item = 'ammorifleexplosive',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 70 },
                },
            },
            [_U('RifleAmmoVelocity')] ={ 
                item = 'ammoriflevelocity',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 35 },
                },
            },
            [_U('RifleAmmoSplitpoint')] = { 
                item = 'ammoriflesplitpoint',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 35 },
                },
            },
        },
        [_U('ShotgunAmmo')] = {
            [_U('ShotgunAmmoIncendiary')] = { 
                item = 'ammoshotgunincendiary',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 30 },
                },
            },
            [_U('ShotgunAmmoExplosive')] = { 
                item = 'ammoshotgunexplosive',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 60 },
                },
            },
            [_U('ShotgunAmmoNormal')] = { 
                item = 'ammoshotgunnormal',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 19 },
                },
            },
            ['Shotgun Ammo Slug'] = { 
                item = 'ammoshotgunslug',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 23 },
                },
            },
        },
        [_U('PistolAmmo')] = {
            [_U('PistolAmmoNormal')] = { 
                item = 'ammopistolnormal',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 10 },
                },
            },
            [_U('PistolAmmoExpress')] = { 
                item = 'ammopistolexpress',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 15 },
                },
            },
            [_U('PistolAmmoExplosive')] = { 
                item = 'ammopistolexplosive',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 50 },
                },
            },
            [_U('PistolAmmoVelocity')] = { 
                item = 'ammopistolvelocity',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 20 },
                },
            },
            [_U('PistolAmmoSplitpoint')] = { 
                item = 'ammopistolsplitpoint',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 15 },
                },
            },
        },
        [_U('ArrowAmmo')] = {
            [_U('ArrowNormal')] = { 
                item = 'ammoarrownormal',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 10 },
                    { label = 'Wood', item = 'wood', amount = 4 },
                },
            },
            [_U('ArrowFire')] = { 
                item = 'ammoarrowfire',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 10 },
                    { label = 'Wood', item = 'wood', amount = 4 },
                    { label = 'Sulfur', item = 'sulfur', amount = 1 },
                },
            },
            [_U('ArrowImproved')] = { 
                item = 'ammoarrowimproved',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 20 },
                    { label = 'Wood', item = 'wood', amount = 8 },
                },
            },
            [_U('ArrowSmallGame')] = { 
                item = 'ammoarrowsmallgame',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 8 },
                    { label = 'Wood', item = 'wood', amount = 1 },
                },
            },
            [_U('ArrowPoison')] = { 
                item = 'ammoarrowpoison',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 10 },
                    { label = 'Sulfur', item = 'sulfur', amount = 20 },
                },
            },
            [_U('ArrowDynamite')] = { 
                item = 'ammoarrowdynamite',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 10 },
                    { label = 'Wood', item = 'wood', amount = 4 },
                    { label = 'Sulfur', item = 'sulfur', amount = 40 },
                },
            },
        },
        [_U('VarmintAmmo')] = {
            [_U('VarmintAmmo')] = { 
                item = 'ammovarmint',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 5 },
                },
            },
            [_U('VarmintTranquilizerAmmo')] = { 
                item = 'ammovarminttranq',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 10 },
                },
            },
        },
        [_U('ThrowingAmmo')] = {
            [_U('KnivesAmmo')] = { 
                item = 'ammoknives',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 15 },
                },
            },
            [_U('TomahawkAmmo')] = { 
                item = 'ammotomahawk',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 20 },
                },
            },
            [_U('HatchetAmmo')] = { 
                item = 'ammohatchet',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 20 },
                },
            },
            [_U('HatchetCleaverAmmo')] = { 
                item = 'ammohatchetcleaver',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 20 },
                },
            },
            [_U('HatchetHunterAmmo')] = { 
                item = 'ammohatchethunter',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 20 },
                },
            },
            [_U('PoisonBottleAmmo')] = { 
                item = 'ammopoisonbottle',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 40 },
                },
            },
            [_U('BolasAmmo')] = { 
                item = 'ammobolla',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 20 },
                },
            },
            [_U('DynamiteAmmo')] = { 
                item = 'ammodynamite',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 45 },
                },
            },
            [_U('VolatileDynamiteAmmo')] = { 
                item = 'ammovoldynamite',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 50 },
                },
            },
            [_U('MolotovAmmo')] = { 
                item = 'ammomolotov',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 20 },
                },
            },
            [_U('VolatileMolotovAmmo')] = { 
                item = 'ammovolmolotov',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 25 },
                },
            },
            [_U('BolasAmmo')] = { 
                item = 'ammobola',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 35 },
                    { label = 'Wood', item = 'wood', amount = 15 },
                },
            },
            [_U('BolasHawkmothAmmo')] = { 
                item = 'ammobolahawk',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 35 },
                    { label = 'Wood', item = 'wood', amount = 15 },
                },
            },
            [_U('BolasIronspikedAmmo')] = { 
                item = 'ammobolaironspiked',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 35 },
                    { label = 'Wood', item = 'wood', amount = 15 },
                },
            },
            [_U('BolasIntertwinedAmmo')] = { 
                item = 'ammobolaintertwined',
                amount = 1,
                locations = { 'all' },
                -- costcraft = {   -- list or false
                --     label = _U('Money'),
                --     type = 0,   -- 0 = money, 1 = gold, 2 = rol
                --     amount = 5,
                -- },
                exp = { required = 0, reward = 5 },
                craft = {
                    { label = 'Iron', item = 'iron', amount = 35 },
                    { label = 'Wood', item = 'wood', amount = 15 },
                },
            },
        },
    },
}