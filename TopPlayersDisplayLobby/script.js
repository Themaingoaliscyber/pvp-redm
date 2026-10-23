let currentStats = null;
let statsMenuOpen = false;
let currentServerId = null;
let canSpectatePlayers = false;
let domReady = document.readyState !== "loading";
let queuedNuiMessages = [];
let top3HudPosition = null;
let top3HudEditorMode = false;
let localDuelPendingTargetId = null;

function handleNuiMessage(data) {
    if (data.action === "showTop3Hud") {
        if (data.position !== undefined) {
            setTop3HudPosition(data.position);
        }

        if (data.editor !== undefined) {
            setTop3HudEditorMode(data.editor);
        }

        showTop3(data.stats || null, { demo: data.demo === true });
    } else if (data.action === "updateTopKills") {
        if (data.position !== undefined) {
            setTop3HudPosition(data.position);
        }

        showTop3(data.stats || data, { demo: data.demo === true });
    } else if (data.action === "hideTopKills") {
        hideTop3();
    } else if (data.action === "setTop3HudPosition") {
        setTop3HudPosition(data.position);
    } else if (data.action === "setTop3HudEditorMode") {
        setTop3HudEditorMode(data.enabled, data.position);
    } else if (data.action === "showJoinBanner") {
        showLobbyBanner(data.name, data.messageType || "join", data.lobby);
    } else if (data.action === "openLobbyStatsMenu") {
        openStatsMenu(data.stats || null, data.lobbyId, data.currentServerId, data.canSpectatePlayers);
    } else if (data.action === "updateLobbyStats") {
        updateStats(data.stats || null, data.currentServerId, data.canSpectatePlayers);
    } else if (data.action === "closeLobbyStatsMenu") {
        closeStatsMenu(false);
    } else if (data.action === "warmupLobbyStatsMenu") {
        warmupStatsMenu();
    }
}

window.addEventListener("message", function(event) {
    const data = event.data || {};

    if (!domReady) {
        queuedNuiMessages.push(data);
        return;
    }

    handleNuiMessage(data);
});

document.addEventListener("DOMContentLoaded", function() {
    domReady = true;

    document.getElementById("closeStatsMenu")?.addEventListener("click", function() {
        closeStatsMenu(true);
    });

    document.getElementById("statsPlayersBody")?.addEventListener("wheel", handleStatsWheel, { passive: false });

    if (queuedNuiMessages.length) {
        queuedNuiMessages.forEach(handleNuiMessage);
        queuedNuiMessages = [];
    }
});

document.addEventListener("keydown", function(event) {
    if (event.key === "Escape" && statsMenuOpen) {
        closeStatsMenu(true);
    }
});

window.addEventListener("resize", function() {
    applyTop3HudPosition();
});

function postNuiCallback(name, payload = {}) {
    return fetch(`https://${GetParentResourceName()}/${name}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
    }).catch(() => {});
}

function setSpectateContext(serverId, isAllowed) {
    if (serverId !== undefined) {
        const parsedServerId = Number(serverId);
        currentServerId = Number.isFinite(parsedServerId) && parsedServerId > 0 ? parsedServerId : null;
    }

    if (isAllowed !== undefined) {
        canSpectatePlayers = isAllowed === true;
    }
}

function handleStatsWheel(event) {
    if (!statsMenuOpen) {
        return;
    }

    const body = event.currentTarget;
    if (!body || body.scrollHeight <= body.clientHeight) {
        return;
    }

    const lineHeight = 44;
    const deltaMultiplier = event.deltaMode === 1 ? lineHeight : 1.55;
    body.scrollTop += event.deltaY * deltaMultiplier;
    event.preventDefault();
}

function openStatsMenu(stats, lobbyId, serverId, isSpectateAllowed) {
    statsMenuOpen = true;
    setSpectateContext(serverId, isSpectateAllowed);
    document.body.classList.add("stats-open");
    document.getElementById("statsMenu")?.classList.remove("hidden");

    if (stats) {
        updateStats(stats);
        return;
    }

    currentStats = normalizeStats({
        inLobby: true,
        lobbyId: lobbyId || null,
        totalPlayers: 0,
        players: []
    });

    renderStats();
}

function closeStatsMenu(shouldNotifyClient = true) {
    statsMenuOpen = false;
    document.body.classList.remove("stats-open");
    document.getElementById("statsMenu")?.classList.add("hidden");

    if (shouldNotifyClient) {
        postNuiCallback("closeLobbyStats");
    }
}

function updateStats(stats, serverId, isSpectateAllowed) {
    setSpectateContext(serverId, isSpectateAllowed);
    currentStats = normalizeStats(stats);
    localDuelPendingTargetId = currentStats.viewerDuelPending ? currentStats.viewerPendingDuelTargetId : null;
    renderStats();
}

function warmupStatsMenu() {
    const menu = document.getElementById("statsMenu");
    if (!menu || statsMenuOpen) {
        return;
    }

    const wasHidden = menu.classList.contains("hidden");
    const previousVisibility = menu.style.visibility;
    const previousPointerEvents = menu.style.pointerEvents;

    menu.style.visibility = "hidden";
    menu.style.pointerEvents = "none";
    menu.classList.remove("hidden");

    currentStats = normalizeStats({
        inLobby: true,
        lobbyId: null,
        totalPlayers: 0,
        players: []
    });
    renderStats();

    menu.offsetHeight;

    requestAnimationFrame(function() {
        menu.style.visibility = previousVisibility;
        menu.style.pointerEvents = previousPointerEvents;

        if (!statsMenuOpen && wasHidden) {
            menu.classList.add("hidden");
        }
    });
}

function normalizeStats(stats) {
    if (!stats || typeof stats !== "object") {
        return {
            inLobby: false,
            lobbyId: null,
            totalPlayers: 0,
            players: [],
            viewerDuelPending: false,
            viewerPendingDuelTargetId: null
        };
    }

    const players = Array.isArray(stats.players) ? stats.players : [];

    const pendingTargetId = Number(stats.viewerPendingDuelTargetId || 0);

    return {
        inLobby: stats.inLobby !== false,
        lobbyId: stats.lobbyId || null,
        totalPlayers: Math.max(Number(stats.totalPlayers || 0), players.length),
        players,
        viewerDuelPending: stats.viewerDuelPending === true,
        viewerPendingDuelTargetId: Number.isFinite(pendingTargetId) && pendingTargetId > 0 ? pendingTargetId : null
    };
}

function renderStats() {
    const badge = document.getElementById("statsLobbyBadge");
    const count = document.getElementById("statsPlayerCount");
    const body = document.getElementById("statsPlayersBody");
    const empty = document.getElementById("statsEmpty");

    if (!badge || !count || !body || !empty) {
        return;
    }

    const stats = currentStats || {
        inLobby: false,
        lobbyId: null,
        totalPlayers: 0,
        players: []
    };

    badge.textContent = `LOBBY: ${stats.lobbyId || "-"}`;
    count.textContent = `PLAYERS: ${stats.totalPlayers || 0}`;
    body.innerHTML = "";

    if (!stats.inLobby) {
        empty.textContent = "You are not in a lobby.";
        empty.classList.remove("hidden");
        return;
    }

    if (!stats.players.length) {
        empty.textContent = "No player stats yet.";
        empty.classList.remove("hidden");
        return;
    }

    empty.classList.add("hidden");

    stats.players.forEach(function(player, index) {
        body.appendChild(createStatsRow(player, index));
    });
}

function requestSpectatePlayer(targetId, button) {
    const parsedTargetId = Number(targetId);
    if (!Number.isFinite(parsedTargetId) || parsedTargetId <= 0) {
        return;
    }

    if (button) {
        button.disabled = true;
        button.classList.add("is-loading");
    }

    postNuiCallback("spectateLobbyPlayer", { targetId: parsedTargetId }).finally(function() {
        setTimeout(function() {
            if (button && statsMenuOpen) {
                button.disabled = false;
                button.classList.remove("is-loading");
            }
        }, 500);
    });
}

function applyLocalDuelPending(targetId) {
    const parsedTargetId = Number(targetId);
    if (!Number.isFinite(parsedTargetId) || parsedTargetId <= 0) {
        return;
    }

    localDuelPendingTargetId = parsedTargetId;
    if (currentStats) {
        currentStats.viewerDuelPending = true;
        currentStats.viewerPendingDuelTargetId = parsedTargetId;
        renderStats();
    }
}
function requestDuelPlayer(targetId, button) {
    const parsedTargetId = Number(targetId);
    if (!Number.isFinite(parsedTargetId) || parsedTargetId <= 0) {
        return;
    }

    applyLocalDuelPending(parsedTargetId);

    if (currentStats && String(currentStats.lobbyId || "").toUpperCase() === "DEMO") {
        return;
    }

    postNuiCallback("duelLobbyPlayer", { targetId: parsedTargetId });
}
function createStatsRow(player, index) {
    const kills = Number(player.kills || 0);
    const deaths = Number(player.deaths || 0);
    const targetId = Number(player.id || 0);
    const playerIdLabel = `PLAYER ID [ ${player.id || "-"} ]`;
    const row = document.createElement("div");
    row.className = `stats-row rank-${index + 1}`;

    const rank = document.createElement("span");
    rank.className = "stats-rank";
    rank.textContent = String(index + 1);

    const name = document.createElement("span");
    name.className = "stats-player-name";
    name.textContent = String(player.name || "Unknown");
    name.title = `${name.textContent} - ${playerIdLabel}`;
    const playerCell = document.createElement("span");
    playerCell.className = "stats-player-cell";
    playerCell.title = playerIdLabel;
    playerCell.append(name);

    const killsCell = document.createElement("span");
    killsCell.className = "stats-number stats-kills";
    killsCell.innerHTML = `<strong>${kills}</strong><small>KILLS</small>`;

    const deathsCell = document.createElement("span");
    deathsCell.className = "stats-number stats-deaths";
    deathsCell.innerHTML = `<strong>${deaths}</strong><small>DEATHS</small>`;

    const actions = document.createElement("span");
    actions.className = "stats-actions";

    const spectateButton = document.createElement("button");
    spectateButton.type = "button";
    spectateButton.className = "stats-action-button stats-spectate-button";

    const isSelf = currentServerId !== null && targetId === currentServerId;

    const hasValidTarget = targetId > 0;
    const canUseSpectate = canSpectatePlayers && hasValidTarget && !isSelf;

    if (isSelf) {
        spectateButton.textContent = "YOU";
        spectateButton.classList.add("is-unavailable");
        spectateButton.title = "You cannot spectate yourself.";
    } else if (!canSpectatePlayers) {
        spectateButton.textContent = "LOCKED";
        spectateButton.classList.add("is-unavailable");
        spectateButton.title = "Spectator is disabled in Team Battle arenas.";
    } else {
        spectateButton.textContent = "SPECTATE";
        spectateButton.title = "Spectate this player.";
    }

    spectateButton.disabled = !canUseSpectate;
    spectateButton.setAttribute("aria-disabled", canUseSpectate ? "false" : "true");

    if (canUseSpectate) {
        spectateButton.addEventListener("click", function() {
            requestSpectatePlayer(targetId, spectateButton);
        });
    }

    actions.append(spectateButton);

    if (!isSelf) {
        const duelRequestsEnabled = player.duelRequestsEnabled !== false;
        const pendingTargetFallback = Number(localDuelPendingTargetId || 0);
        const viewerPendingTargetId = currentStats ? Number(currentStats.viewerPendingDuelTargetId || pendingTargetFallback || 0) : pendingTargetFallback;
        const viewerDuelPending = (currentStats && currentStats.viewerDuelPending === true) || viewerPendingTargetId > 0;
        const targetDuelPending = player.duelInvitePending === true;
        const duelButton = document.createElement("button");
        duelButton.type = "button";
        duelButton.className = "stats-action-button stats-duel-button";

        let canUseDuel = hasValidTarget && duelRequestsEnabled;
        if (viewerDuelPending && viewerPendingTargetId === targetId) {
            duelButton.textContent = "DUEL PENDING";
            duelButton.classList.add("is-duel-pending");
            duelButton.title = "Waiting for this player to answer your duel invite.";
            canUseDuel = false;
        } else if (!duelRequestsEnabled) {
            duelButton.textContent = "REQUESTS OFF";
            duelButton.classList.add("is-duel-off");
            duelButton.title = "This player has duel requests turned off.";
            canUseDuel = false;
        } else if (targetDuelPending) {
            duelButton.textContent = "DUEL PENDING";
            duelButton.classList.add("is-duel-pending");
            duelButton.title = "This player already has a pending duel invite.";
            canUseDuel = false;
        } else if (viewerDuelPending) {
            duelButton.textContent = "LOCKED";
            duelButton.classList.add("is-duel-locked");
            duelButton.title = "You already have a duel invite pending.";
            canUseDuel = false;
        } else {
            duelButton.textContent = "DUEL";
            duelButton.title = "Invite this player to a duel.";
        }

        duelButton.disabled = !canUseDuel;
        duelButton.setAttribute("aria-disabled", canUseDuel ? "false" : "true");

        if (canUseDuel) {
            duelButton.addEventListener("click", function() {
                requestDuelPlayer(targetId, duelButton);
            });
        }

        actions.append(duelButton);
    }

    row.append(rank, playerCell, killsCell, deathsCell, actions);
    return row;
}

function getTop3Players(stats) {
    const normalized = normalizeStats(stats);

    if (!normalized.inLobby || !normalized.players.length) {
        return { stats: normalized, players: [] };
    }

    const players = normalized.players
        .slice()
        .sort(function(a, b) {
            const killsA = Number(a.kills || 0);
            const killsB = Number(b.kills || 0);
            const deathsA = Number(a.deaths || 0);
            const deathsB = Number(b.deaths || 0);

            if (killsA === killsB) {
                if (deathsA === deathsB) {
                    return String(a.name || "").localeCompare(String(b.name || ""));
                }

                return deathsA - deathsB;
            }

            return killsB - killsA;
        })
        .slice(0, 3);

    return { stats: normalized, players };
}

function createTop3Row(player, index) {
    const kills = Math.max(Number(player.kills || 0), 0);
    const row = document.createElement("div");
    row.className = `top-three-row rank-${index + 1}`;

    const rank = document.createElement("span");
    rank.className = "top-three-rank";
    rank.textContent = `#${index + 1}`;

    const identity = document.createElement("span");
    identity.className = "top-three-identity";

    const name = document.createElement("span");
    name.className = "top-three-name";
    name.textContent = String(player.name || "Unknown");
    name.title = name.textContent;

    const meta = document.createElement("span");
    meta.className = "top-three-meta";
    meta.textContent = `PLAYER ID [ ${player.id || "-"} ]`;

    identity.append(name, meta);

    const score = document.createElement("span");
    score.className = "top-three-score";

    const killValue = document.createElement("strong");
    killValue.textContent = String(kills);

    score.append(killValue);
    row.append(rank, identity, score);

    return row;
}

function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
}

function normalizeTop3HudPosition(position) {
    if (!position || typeof position !== "object") {
        return null;
    }

    const x = Number(position.x ?? position.left);
    const y = Number(position.y ?? position.top);

    if (!Number.isFinite(x) || !Number.isFinite(y)) {
        return null;
    }

    return {
        x: clamp(x, 0, 100),
        y: clamp(y, 0, 100)
    };
}

function applyTop3HudPosition(panel = document.getElementById("topKills")) {
    if (!panel) {
        return;
    }

    if (!top3HudPosition) {
        panel.style.left = "";
        panel.style.top = "";
        panel.style.right = "";
        return;
    }

    panel.style.right = "auto";

    const rect = panel.getBoundingClientRect();
    const maxLeft = Math.max(0, window.innerWidth - rect.width);
    const maxTop = Math.max(0, window.innerHeight - rect.height);
    const left = clamp((top3HudPosition.x / 100) * window.innerWidth, 0, maxLeft);
    const top = clamp((top3HudPosition.y / 100) * window.innerHeight, 0, maxTop);

    panel.style.left = `${Math.round(left)}px`;
    panel.style.top = `${Math.round(top)}px`;
}

function setTop3HudPosition(position) {
    top3HudPosition = normalizeTop3HudPosition(position);
    applyTop3HudPosition();
}

function setTop3HudEditorMode(enabled, position) {
    if (position !== undefined) {
        setTop3HudPosition(position);
    }

    top3HudEditorMode = enabled === true;
    document.body.classList.toggle("top-three-editing", top3HudEditorMode);

    const panel = document.getElementById("topKills");
    if (panel) {
        panel.classList.toggle("is-editing", top3HudEditorMode);
    }
}

function showTop3(stats, options = {}) {
    const result = getTop3Players(stats);

    if (!result.players.length) {
        hideTop3();
        return;
    }

    const hud = document.getElementById("hud");
    if (!hud) {
        return;
    }

    let panel = document.getElementById("topKills");
    if (!panel) {
        panel = document.createElement("div");
        panel.id = "topKills";
        hud.appendChild(panel);
    }

    panel.className = `top-three-panel${options.demo ? " is-demo" : ""}${top3HudEditorMode ? " is-editing" : ""}`;
    panel.innerHTML = "";

    const rows = document.createElement("div");
    rows.className = "top-three-list";
    result.players.forEach(function(player, index) {
        rows.appendChild(createTop3Row(player, index));
    });

    const hint = document.createElement("div");
    hint.className = "top-three-hint";
    hint.textContent = "Press F6 to view all players";

    panel.append(rows, hint);
    applyTop3HudPosition(panel);
}

function hideTop3() {
    const existing = document.getElementById("topKills");
    if (existing) {
        existing.remove();
    }
}

function showLobbyBanner(playerName, messageType, lobby) {
    const existing = document.getElementById("joinBanner");
    if (existing) existing.remove();

    const banner = document.createElement("div");
    banner.id = "joinBanner";
    banner.className = "lobby-join-banner";

    let message = "";
    let className = "join-text";

    switch (messageType) {
        case "join":
            message = "has joined the arena";
            className = "join-text";
            break;
        case "leave":
            message = "has left the arena";
            className = "leave-text";
            break;
        case "switch":
            message = `has switched to arena ${lobby || "?"}`;
            className = "switch-text";
            break;
        default:
            message = "has joined the arena";
            className = "join-text";
    }

    const nameSpan = document.createElement("span");
    nameSpan.className = "join-name";
    nameSpan.textContent = String(playerName || "Unknown");

    const messageSpan = document.createElement("span");
    messageSpan.className = className;
    messageSpan.textContent = message;

    banner.append(nameSpan, messageSpan);
    document.getElementById("hud")?.appendChild(banner);

    setTimeout(function() {
        banner.remove();
    }, 5000);
}
