Config = {}

-- Introdu link-ul webhook-ului de pe Discord aici
Config.WebhookURL = "https://discord.com/api/webhooks/1344339020250873866/cPe1bm74AN8knvQhPcnnVzQHh-OEPtxY66ck4RDvTBzmNuli9YMBWD7Xm4dEfyVhnfmm"

-- Configurarea bazei de date
Config.Database = {
    table = "users", -- Numele tabelului unde sunt stocate datele jucătorilor
    identifierColumn = "identifier", -- Coloana care identifică jucătorii (de obicei Steam ID)
    nameColumn = "name", -- Coloana cu numele jucătorului
    killsColumn = "kills", -- Coloana cu numărul de kill-uri
    deathsColumn = "deaths" -- Coloana cu numărul de death-uri
}
