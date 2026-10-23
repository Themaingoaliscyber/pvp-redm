let leaderboardOpen = false;
let currentPayload = null;
let domReady = document.readyState !== "loading";
let queuedMessages = [];
let refreshButton = null;
let readyNotified = false;
let refreshCooldownEndsAt = 0;
let refreshCooldownTimer = null;
const TOP_LIMIT_OPTIONS = [20, 40, 60, 80, 100];
const COMPLETE_TOP_LIMIT = Math.max(...TOP_LIMIT_OPTIONS);
const REFRESH_BUTTON_COOLDOWN_MS = 3000;
let selectedTopLimit = 20;

let searchInput = null;
let clearSearchButton = null;
let searchQuery = "";
let searchDisplayValue = "";
function getResourceName() {
    if (typeof GetParentResourceName === "function") {
        return GetParentResourceName();
    }

    return "leaderboard";
}

function postNuiCallback(name, payload = {}) {
    return fetch(`https://${getResourceName()}/${name}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
    }).catch(() => {});
}

function notifyLeaderboardReady() {
    if (readyNotified) {
        return;
    }

    readyNotified = true;
    postNuiCallback("leaderboardReady");
}

function getTextTarget(element) {
    if (!element) {
        return null;
    }

    if (element.classList && element.classList.contains("intel-chip")) {
        return element.querySelector("span") || element;
    }

    return element;
}

function setText(id, value) {
    const element = getTextTarget(document.getElementById(id));
    if (element) {
        const nextValue = String(value);
        if (element.textContent !== nextValue) {
            element.textContent = nextValue;
        }
    }
}

function formatNumber(value) {
    const number = Number(value || 0);
    if (!Number.isFinite(number)) {
        return "0";
    }

    return String(Math.max(0, Math.floor(number))).replace(/\B(?=(\d{3})+(?!\d))/g, ".");
}

function clampTopLimit(value) {
    const parsed = Number(value || selectedTopLimit || TOP_LIMIT_OPTIONS[0]);

    for (const option of TOP_LIMIT_OPTIONS) {
        if (parsed <= option) {
            return option;
        }
    }

    return TOP_LIMIT_OPTIONS[TOP_LIMIT_OPTIONS.length - 1];
}

function updateTopRangeButtons() {
    document.querySelectorAll(".top-range-button").forEach(function(button) {
        const buttonLimit = clampTopLimit(button.dataset.topLimit);
        const isActive = buttonLimit === selectedTopLimit;
        button.classList.toggle("is-active", isActive);
        button.setAttribute("aria-pressed", isActive ? "true" : "false");
        button.title = `View top ${buttonLimit}`;
    });

    if (!searchQuery) {
        setText("rangeLabel", `Top ${selectedTopLimit}`);
    }
}

function setTopLimit(value) {
    const nextLimit = clampTopLimit(value);
    if (nextLimit === selectedTopLimit) {
        updateTopRangeButtons();
        if (currentPayload) {
            renderLeaderboard(currentPayload);
        } else {
            updateSearchSummary(0, 0, false);
        }
        return;
    }

    selectedTopLimit = nextLimit;
    updateTopRangeButtons();

    const body = document.getElementById("leaderboardRows");
    if (body) {
        body.scrollTop = 0;
    }

    if (currentPayload) {
        renderLeaderboard(currentPayload);
    } else {
        updateSearchSummary(0, 0, false);
    }
}
function calculateKd(kills, deaths, fallback) {
    const killsNumber = Number(kills);
    const deathsNumber = Number(deaths);

    if (Number.isFinite(killsNumber) && Number.isFinite(deathsNumber)) {
        const safeKills = Math.max(0, Math.floor(killsNumber));
        const safeDeaths = Math.max(0, Math.floor(deathsNumber));

        return safeDeaths > 0 ? safeKills / safeDeaths : safeKills;
    }

    return Number(fallback || 0);
}

function formatKd(value, kills, deaths) {
    const number = calculateKd(kills, deaths, value);
    if (!Number.isFinite(number)) {
        return "0.00";
    }

    return number.toFixed(2);
}

function getRankClass(rank) {
    const parsedRank = Number(rank || 0);
    return parsedRank >= 1 && parsedRank <= 3 ? `rank-${parsedRank}` : "";
}

function createMetric(value, label, className) {
    const metric = document.createElement("span");
    metric.className = `leaderboard-number ${className}`;

    const strong = document.createElement("strong");
    strong.textContent = String(value);

    const small = document.createElement("small");
    small.textContent = label;

    metric.append(strong, small);
    return metric;
}

function createLeaderboardRow(player, index) {
    const rankValue = Number(player.rank || index + 1);
    const row = document.createElement("div");
    row.className = `leaderboard-row ${getRankClass(rankValue)}`;
    row.dataset.playerKey = String(player.key || "");
    row.dataset.playerRank = String(rankValue);

    const rank = document.createElement("span");
    rank.className = "leaderboard-rank";
    rank.textContent = `#${formatNumber(rankValue)}`;

    const status = document.createElement("span");
    status.className = `leaderboard-status-dot ${player.isOnline ? "is-online" : "is-offline"}`;
    status.title = player.isOnline ? "Online" : "Offline";

    const name = document.createElement("span");
    name.className = "leaderboard-player-name";
    name.textContent = String(player.name || "Steam Player");
    name.title = name.textContent;

    const nameLine = document.createElement("span");
    nameLine.className = "leaderboard-player-line";
    nameLine.append(name, status);

    const playerCell = document.createElement("span");
    playerCell.className = "leaderboard-player-cell";
    playerCell.append(nameLine);

    row.append(
        rank,
        playerCell,
        createMetric(formatNumber(player.kills), "Kills", "leaderboard-kills"),
        createMetric(formatNumber(player.deaths), "Deaths", "leaderboard-deaths"),
        createMetric(formatKd(player.kd, player.kills, player.deaths), "K/D", "leaderboard-kd")
    );

    return row;
}

function patchRenderedPlayer(changedPlayer, previousPlayer) {
    const rank = Number(changedPlayer && changedPlayer.rank ? changedPlayer.rank : 0);
    if (rank === 1) {
        renderChampion(changedPlayer);
        return;
    }
    if (rank === 2) {
        renderSecondPlace(changedPlayer);
        return;
    }
    if (rank === 3) {
        renderThirdPlace(changedPlayer);
        return;
    }

    const safeLimit = clampTopLimit(selectedTopLimit);
    const wasVisible = previousPlayer
        ? (searchQuery ? playerMatchesSearch(previousPlayer) : rank > 3 && rank <= safeLimit)
        : false;
    const isVisible = searchQuery
        ? playerMatchesSearch(changedPlayer)
        : rank > 3 && rank <= safeLimit;

    const body = document.getElementById("leaderboardRows");
    if (!body || (!wasVisible && !isVisible)) {
        return;
    }

    if (wasVisible !== isVisible) {
        const displayPlayers = getDisplayPlayers(currentPayload.topPlayers, safeLimit);
        renderRows(displayPlayers, currentPayload.topPlayers.length > 0, safeLimit, false, searchQuery ? 0 : 3);
        return;
    }

    const changedKey = String(changedPlayer && changedPlayer.key ? changedPlayer.key : "");
    const renderedRow = Array.from(body.children).find((row) => {
        const rowKey = String(row.dataset.playerKey || "");
        const rowRank = Number(row.dataset.playerRank || 0);
        return (changedKey && rowKey === changedKey) || rowRank === rank;
    });

    if (renderedRow) {
        renderedRow.replaceWith(createLeaderboardRow(changedPlayer, Math.max(0, rank - 1)));
        return;
    }

    const displayPlayers = getDisplayPlayers(currentPayload.topPlayers, safeLimit);
    renderRows(displayPlayers, currentPayload.topPlayers.length > 0, safeLimit, false, searchQuery ? 0 : 3);
}

function renderLoadingRows(count = 8) {
    const body = document.getElementById("leaderboardRows");
    const empty = document.getElementById("leaderboardEmpty");
    if (!body || !empty) {
        return;
    }

    body.innerHTML = "";
    empty.classList.add("hidden");

    const fragment = document.createDocumentFragment();
    for (let index = 0; index < count; index += 1) {
        const row = document.createElement("div");
        row.className = "skeleton-row";
        fragment.appendChild(row);
    }

    body.appendChild(fragment);
}

function renderRows(players, hasFeaturedPlayer = false, visibleLimit = selectedTopLimit, isLoading = false, fallbackOffset = 3) {
    const body = document.getElementById("leaderboardRows");
    const empty = document.getElementById("leaderboardEmpty");
    const safeLimit = clampTopLimit(visibleLimit);

    if (!body || !empty) {
        return;
    }

    if (isLoading && (!Array.isArray(players) || players.length === 0)) {
        renderLoadingRows();
        return;
    }

    body.innerHTML = "";

    if (!Array.isArray(players) || players.length === 0) {
        if (searchQuery) {
            empty.textContent = `No player found for "${searchDisplayValue}".`;
        } else {
            empty.textContent = hasFeaturedPlayer
                ? `Ranks 4-${safeLimit} are waiting for more players.`
                : "No PvP stats yet.";
        }
        empty.classList.remove("hidden");
        return;
    }

    empty.classList.add("hidden");

    const fragment = document.createDocumentFragment();
    players.forEach(function(player, index) {
        fragment.appendChild(createLeaderboardRow(player, index + fallbackOffset));
    });

    body.appendChild(fragment);
}
function setStatusDot(id, player) {
    const status = document.getElementById(id);
    if (!status) {
        return;
    }

    const isOnline = player && player.isOnline === true;
    status.classList.toggle("is-online", isOnline);
    status.classList.toggle("is-offline", !isOnline);
    status.title = isOnline ? "Online" : "Offline";
}

function renderPodiumSlot(config, player) {
    const safePlayer = player && typeof player === "object" ? player : null;
    const hasPlayer = Boolean(safePlayer);
    const card = document.getElementById(config.cardId);

    if (card) {
        card.classList.toggle("is-empty", !hasPlayer);
    }

    setText(config.rankId, hasPlayer ? `#${formatNumber(safePlayer.rank || config.defaultRank)}` : `#${config.defaultRank}`);
    setText(config.nameId, hasPlayer ? safePlayer.name || "Steam Player" : config.emptyName);
    setText(config.subtitleId, hasPlayer ? config.subtitle : "Waiting for PvP stats");
    setText(config.killsId, hasPlayer ? formatNumber(safePlayer.kills) : "0");
    setText(config.deathsId, hasPlayer ? formatNumber(safePlayer.deaths) : "0");
    setText(config.kdId, hasPlayer ? formatKd(safePlayer.kd, safePlayer.kills, safePlayer.deaths) : "0.00");
    setStatusDot(config.statusId, safePlayer);
}

function renderChampion(player) {
    renderPodiumSlot({
        cardId: "topChampionCard",
        rankId: "championRank",
        nameId: "championName",
        statusId: "championStatus",
        subtitleId: "championSubtitle",
        killsId: "championKills",
        deathsId: "championDeaths",
        kdId: "championKd",
        defaultRank: 1,
        emptyName: "No leader yet",
        subtitle: "Highest kills right now"
    }, player);
}

function renderSecondPlace(player) {
    renderPodiumSlot({
        cardId: "podiumRank2",
        rankId: "secondRank",
        nameId: "secondName",
        statusId: "secondStatus",
        subtitleId: "secondSubtitle",
        killsId: "secondKills",
        deathsId: "secondDeaths",
        kdId: "secondKd",
        defaultRank: 2,
        emptyName: "No second place yet",
        subtitle: "Closest contender"
    }, player);
}

function renderThirdPlace(player) {
    renderPodiumSlot({
        cardId: "podiumRank3",
        rankId: "thirdRank",
        nameId: "thirdName",
        statusId: "thirdStatus",
        subtitleId: "thirdSubtitle",
        killsId: "thirdKills",
        deathsId: "thirdDeaths",
        kdId: "thirdKd",
        defaultRank: 3,
        emptyName: "No third place yet",
        subtitle: "Holding the podium"
    }, player);
}

function renderViewer(viewer) {
    const safeViewer = viewer && typeof viewer === "object" ? viewer : {};
    const rankNumber = Number(safeViewer.rank || 0);
    const hasRank = rankNumber > 0;
    const total = Number(safeViewer.totalPlayers || 0);
    const rankElement = document.getElementById("viewerRank");

    if (rankElement) {
        rankElement.textContent = hasRank ? `#${formatNumber(rankNumber)}` : "UNRANKED";
        rankElement.classList.toggle("is-unranked", !hasRank);
        rankElement.classList.toggle("rank-1", rankNumber === 1);
        rankElement.classList.toggle("rank-2", rankNumber === 2);
        rankElement.classList.toggle("rank-3", rankNumber === 3);
    }

    setText("viewerName", safeViewer.name || "Steam Player");
    setText("viewerMessage", safeViewer.message || "Your stats are syncing.");

    if (safeViewer.rank && total > 0) {
        setText("playersBadge", `PLAYERS: ${formatNumber(total)}`);
    }
}

function normalizeForSearch(value) {
    return String(value || "")
        .toLowerCase()
        .normalize("NFD")
        .replace(/[\u0300-\u036f]/g, "")
        .trim();
}

function playerMatchesSearch(player) {
    if (!searchQuery) {
        return true;
    }

    const safePlayer = player && typeof player === "object" ? player : {};
    const rankValue = safePlayer.rank ? String(safePlayer.rank) : "";
    const rankQuery = searchQuery.replace(/^#/, "");
    const playerName = normalizeForSearch(safePlayer.name || "Steam Player");

    return playerName.includes(searchQuery)
        || rankValue.includes(rankQuery)
        || (`#${rankValue}`).includes(searchQuery);
}

function getDisplayPlayers(topPlayers, safeLimit) {
    const players = Array.isArray(topPlayers) ? topPlayers : [];

    if (searchQuery) {
        return players.filter(playerMatchesSearch);
    }

    return players.length > 3 ? players.slice(3, safeLimit) : [];
}

function updateSearchQuery(value) {
    searchDisplayValue = String(value || "").trim();
    searchQuery = normalizeForSearch(searchDisplayValue);
}

function clearSearch(shouldRender = false) {
    searchDisplayValue = "";
    searchQuery = "";

    if (searchInput && searchInput.value !== "") {
        searchInput.value = "";
    }

    if (clearSearchButton) {
        clearSearchButton.classList.add("hidden");
    }

    if (shouldRender && currentPayload) {
        renderLeaderboard(currentPayload);
    }
}

function updateSearchSummary(displayCount, totalCount, isLoading) {
    const hasSearch = searchQuery.length > 0;
    const safeTotal = Number(totalCount || 0);
    const shownCount = hasSearch ? displayCount : Math.min(safeTotal, selectedTopLimit);

    setText("rangeLabel", hasSearch ? "Search Results" : `Top ${selectedTopLimit}`);

    if (isLoading) {
        setText("resultCount", "loading cache");
    } else if (hasSearch) {
        setText("resultCount", `${formatNumber(displayCount)} found from ${formatNumber(safeTotal)}`);
    } else {
        setText("resultCount", `${formatNumber(shownCount)} shown from ${formatNumber(safeTotal)}`);
    }
if (clearSearchButton) {
        clearSearchButton.classList.toggle("hidden", !hasSearch);
    }
}
function renderLeaderboard(payload, options = {}) {
    const safePayload = payload && typeof payload === "object" ? payload : {};
    const topPlayers = Array.isArray(safePayload.topPlayers) ? safePayload.topPlayers : [];
    const safeLimit = clampTopLimit(selectedTopLimit);
    const isLoading = safePayload.loading === true || options.pending === true;
    const champion = topPlayers.length > 0 ? topPlayers[0] : null;
    const runnerUp = topPlayers.length > 1 ? topPlayers[1] : null;
    const third = topPlayers.length > 2 ? topPlayers[2] : null;
    const displayPlayers = getDisplayPlayers(topPlayers, safeLimit);
    const menu = document.getElementById("leaderboardMenu");

    if (menu) {
        menu.classList.toggle("is-loading", isLoading);
    }

    setText("playersBadge", `PLAYERS: ${formatNumber(safePayload.totalPlayers)}`);
    renderChampion(champion);
    renderSecondPlace(runnerUp);
    renderThirdPlace(third);
    renderRows(displayPlayers, Boolean(champion), safeLimit, isLoading, searchQuery ? 0 : 3);
    renderViewer(safePayload.viewer);
    updateTopRangeButtons();
    updateSearchSummary(displayPlayers.length, topPlayers.length, isLoading);
}
function getLoadingPayload() {
    return {
        loading: true,
        totalPlayers: currentPayload && currentPayload.totalPlayers ? currentPayload.totalPlayers : 0,
        topPlayers: currentPayload && Array.isArray(currentPayload.topPlayers) ? currentPayload.topPlayers : [],
        viewer: currentPayload && currentPayload.viewer ? currentPayload.viewer : {
            name: "Steam Player",
            message: "Leaderboard cache is waking up."
        }
    };
}

function getStableTopPlayers(incomingTopPlayers, totalPlayers) {
    const incoming = Array.isArray(incomingTopPlayers) ? incomingTopPlayers : [];
    const previous = currentPayload && Array.isArray(currentPayload.topPlayers) ? currentPayload.topPlayers : null;

    if (!previous) {
        return incoming;
    }

    const numericTotal = Number(totalPlayers);
    const expectedTopSize = Math.min(COMPLETE_TOP_LIMIT, Math.max(Number.isFinite(numericTotal) ? numericTotal : 0, previous.length));

    if (previous.length >= COMPLETE_TOP_LIMIT && expectedTopSize >= COMPLETE_TOP_LIMIT && incoming.length < expectedTopSize) {
        return previous;
    }

    return incoming;
}

function normalizePayload(payload) {
    if (!payload || typeof payload !== "object") {
        return payload;
    }

    return {
        ...payload,
        topPlayers: getStableTopPlayers(payload.topPlayers, payload.totalPlayers)
    };
}

function openLeaderboard(payload, options = {}) {
    if (payload) {
        currentPayload = normalizePayload(payload);
    }

    if (!currentPayload) {
        currentPayload = getLoadingPayload();
    }

    leaderboardOpen = true;
    const menu = document.getElementById("leaderboardMenu");
    if (menu) {
        menu.style.visibility = "";
        menu.style.pointerEvents = "";
        menu.classList.remove("hidden");
    }

    renderLeaderboard(currentPayload, options);
}

function warmupLeaderboard(payload) {
    if (payload) {
        currentPayload = normalizePayload(payload);
    }

    if (!currentPayload || leaderboardOpen) {
        return;
    }

    renderLeaderboard(currentPayload);
    const menu = document.getElementById("leaderboardMenu");
    if (menu) {
        menu.classList.add("hidden");
        menu.style.visibility = "";
        menu.style.pointerEvents = "";
    }
}

function closeLeaderboard(shouldNotify = true) {
    leaderboardOpen = false;
    clearSearch(false);
    document.getElementById("leaderboardMenu")?.classList.add("hidden");

    if (shouldNotify) {
        postNuiCallback("closeLeaderboard");
    }
}
function setRefreshing(isRefreshing) {
    if (!refreshButton) {
        return;
    }

    const cooldownActive = Date.now() < refreshCooldownEndsAt;
    refreshButton.classList.toggle("is-refreshing", Boolean(isRefreshing) || cooldownActive);
    refreshButton.disabled = Boolean(isRefreshing) || cooldownActive;
}

function startRefreshCooldown(durationMs = REFRESH_BUTTON_COOLDOWN_MS) {
    const cooldownMs = Math.max(0, Number(durationMs) || 0);
    refreshCooldownEndsAt = Date.now() + cooldownMs;
    setRefreshing(true);

    if (refreshCooldownTimer) {
        clearTimeout(refreshCooldownTimer);
    }

    refreshCooldownTimer = setTimeout(function() {
        refreshCooldownEndsAt = 0;
        refreshCooldownTimer = null;
        setRefreshing(false);
    }, cooldownMs);
}

function applyTopOnlyPayload(payload) {
    if (!payload || typeof payload !== "object") {
        return;
    }

    const previousViewer = currentPayload && currentPayload.viewer ? currentPayload.viewer : null;
    const stableTopPlayers = getStableTopPlayers(payload.topPlayers, payload.totalPlayers);
    currentPayload = {
        ...(currentPayload || {}),
        generatedAt: payload.generatedAt,
        cacheTtlMs: payload.cacheTtlMs,
        totalPlayers: payload.totalPlayers,
        loading: payload.loading === true,
        topPlayers: stableTopPlayers
    };

    if (previousViewer) {
        currentPayload.viewer = previousViewer;
    }

    renderLeaderboard(currentPayload);
}

function applyPlayerPatch(payload) {
    if (!payload || typeof payload !== "object" || !Array.isArray(payload.players)) {
        return;
    }

    if (!currentPayload || !Array.isArray(currentPayload.topPlayers)) {
        return;
    }

    const topPlayers = currentPayload.topPlayers.slice();
    const renderedPatches = [];

    payload.players.forEach((changedPlayer) => {
        const changedKey = String(changedPlayer && changedPlayer.key ? changedPlayer.key : "");
        const changedRank = Number(changedPlayer && changedPlayer.rank ? changedPlayer.rank : 0);
        const index = topPlayers.findIndex((player) => {
            const playerKey = String(player && player.key ? player.key : "");
            const playerRank = Number(player && player.rank ? player.rank : 0);
            return playerKey === changedKey || (changedRank > 0 && playerRank === changedRank);
        });

        if (index >= 0) {
            renderedPatches.push({
                previousPlayer: topPlayers[index],
                changedPlayer
            });
            topPlayers[index] = changedPlayer;
        }
    });

    currentPayload = {
        ...currentPayload,
        generatedAt: payload.generatedAt || currentPayload.generatedAt,
        cacheTtlMs: payload.cacheTtlMs || currentPayload.cacheTtlMs,
        totalPlayers: Number(payload.totalPlayers || currentPayload.totalPlayers || 0),
        loading: false,
        topPlayers
    };

    const menu = document.getElementById("leaderboardMenu");
    if (menu) {
        menu.classList.remove("is-loading");
    }

    setText("playersBadge", `PLAYERS: ${formatNumber(currentPayload.totalPlayers)}`);
    renderedPatches.forEach(({ changedPlayer, previousPlayer }) => {
        patchRenderedPlayer(changedPlayer, previousPlayer);
    });

    const displayPlayers = getDisplayPlayers(currentPayload.topPlayers, clampTopLimit(selectedTopLimit));
    updateSearchSummary(displayPlayers.length, currentPayload.topPlayers.length, false);
}
function handleNuiMessage(data) {
    if (data.action === "openLeaderboard") {
        openLeaderboard(data.payload || null, { pending: data.pending === true || data.stale === true });
        setRefreshing(data.stale === true || data.pending === true);
    } else if (data.action === "warmupLeaderboard") {
        warmupLeaderboard(data.payload || null);
    } else if (data.action === "updateLeaderboard") {
        currentPayload = normalizePayload(data.payload || null);
        if (currentPayload) {
            renderLeaderboard(currentPayload);
        }
        setRefreshing(false);
    } else if (data.action === "updateLeaderboardTop") {
        applyTopOnlyPayload(data.payload || null);
        setRefreshing(false);
    } else if (data.action === "patchLeaderboardPlayers") {
        applyPlayerPatch(data.payload || null);
        setRefreshing(false);
    } else if (data.action === "closeLeaderboard") {
        closeLeaderboard(false);
    } else if (data.action === "invalidateLeaderboard") {
        currentPayload = null;
        setRefreshing(false);
    }
}

window.addEventListener("message", function(event) {
    const data = event.data || {};

    if (!domReady) {
        queuedMessages.push(data);
        return;
    }

    handleNuiMessage(data);
});

document.addEventListener("DOMContentLoaded", function() {
    domReady = true;
    refreshButton = document.getElementById("refreshLeaderboard");
    searchInput = document.getElementById("leaderboardSearch");
    clearSearchButton = document.getElementById("clearSearch");

    notifyLeaderboardReady();
    updateTopRangeButtons();
    updateSearchSummary(0, 0, false);

    document.getElementById("closeLeaderboard")?.addEventListener("click", function() {
        closeLeaderboard(true);
    });

    document.querySelectorAll(".top-range-button").forEach(function(button) {
        button.addEventListener("click", function() {
            setTopLimit(button.dataset.topLimit);
        });
    });

    searchInput?.addEventListener("input", function() {
        updateSearchQuery(searchInput.value);
        const body = document.getElementById("leaderboardRows");
        if (body) {
            body.scrollTop = 0;
        }
        if (currentPayload) {
            renderLeaderboard(currentPayload);
        } else {
            updateSearchSummary(0, 0, false);
        }
    });

    clearSearchButton?.addEventListener("click", function() {
        clearSearch(true);
        searchInput?.focus();
    });

    refreshButton?.addEventListener("click", function() {
        if (Date.now() < refreshCooldownEndsAt) {
            return;
        }

        startRefreshCooldown();
        postNuiCallback("refreshLeaderboard");
    });

    if (queuedMessages.length) {
        queuedMessages.forEach(handleNuiMessage);
        queuedMessages = [];
    }
});
if (domReady) {
    notifyLeaderboardReady();
}

document.addEventListener("keydown", function(event) {
    if (event.key === "Escape" && leaderboardOpen) {
        closeLeaderboard(true);
    }
});