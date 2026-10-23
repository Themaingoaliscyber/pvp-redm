Config = Config or {}

-- seteaza pe true doar cand ai nevoie de loguri locale
Config.DebugMode = false

-- HUD refresh
Config.HudRefreshInterval = 2000
Config.HudFallbackRefreshInterval = 30000
Config.HudRequestCooldown = 1000
Config.DefaultHUDVisible = true
Config.DefaultRankHUDVisible = true

-- XP / Rank
Config.DefaultXP = 10
Config.LossXP = 5
Config.XPEventCooldown = 3000
Config.RankNotifications = true
Config.MaxXP = 16000
Config.NotifyPosition = "middle-right"

Config.Ranks = {
    { name = "Greenhorn", xp = 0 },
    { name = "Gunslinger", xp = 4000 },
    { name = "Outlaw of the West", xp = 8000 },
    { name = "Bounty Hunter", xp = 12000 },
    { name = "Legend of the West", xp = 16000 }
}

-- Admin permissions for rank commands
Config.AdminRanks = { "admin", "superadmin" }
