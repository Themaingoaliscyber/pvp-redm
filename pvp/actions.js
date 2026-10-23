function saveTeamWeaponRules() {
    fetch(`https://${GetParentResourceName()}/saveTeamWeaponRules`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            mode: teamWeaponDraft.mode,
            weapons: teamWeaponDraft.weapons
        })
    }).then(response => {
        if (!response.ok) {
            throw new Error(`Server error: ${response.status}`);
        }

        return response.text();
    }).then(result => {
        if (String(result || "").trim().toLowerCase() !== "ok") {
            return;
        }

        closeTeamWeaponOverlay();
    }).catch(() => {
        sendNotification("error", "Weapon Rules", "Failed to save the weapon rules.");
    });
}

function closeTeamWeaponOverlay() {
    setWeaponRulesOverlayOpen(false);
    document.getElementById("team-weapon-overlay").classList.add("hidden");
}

function escapeHtml(value) {
    return String(value ?? "").replace(/[&<>"']/g, character => ({
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        "\"": "&quot;",
        "'": "&#39;"
    }[character]));
}

function isPublicCtfLobby(lobby) {
    return Boolean(lobby)
        && String(lobby.matchMode || "").toLowerCase() === "ctf"
        && lobby.publicTeamSelect === true;
}

function isPublicCtfStartExpired(lobby) {
    const publicStartAt = Number(lobby?.publicStartAt || lobby?.teamPlayers?.publicStartAt || 0);
    return publicStartAt > 0 && publicStartAt <= Math.floor(Date.now() / 1000);
}

function isPublicCtfMatchLocked(lobby) {
    return isPublicCtfLobby(lobby)
        && (lobby.publicLocked === true
            || lobby.teamPlayers?.publicLocked === true
            || lobby.teamPlayers?.matchActive === true
            || isPublicCtfStartExpired(lobby));
}

function getPublicCtfTeamData(lobby, teamId) {
    const key = Number(teamId) === 1 ? "team1" : "team2";
    return lobby?.teamPlayers?.[key] || {
        name: Number(teamId) === 1 ? "RED TEAM" : "BLUE TEAM",
        players: []
    };
}

function getPublicCtfStartRemaining(lobby) {
    const publicStartAt = Number(lobby?.publicStartAt || lobby?.teamPlayers?.publicStartAt || 0);
    if (publicStartAt > 0) {
        return Math.max(0, Math.floor(publicStartAt - (Date.now() / 1000)));
    }

    return Number(lobby?.publicStartRemaining ?? lobby?.teamPlayers?.publicStartRemaining ?? 0);
}

const PUBLIC_CTF_PENDING_TIMEOUT_MS = 3500;

function getPublicCtfNow() {
    return typeof performance !== "undefined" ? performance.now() : Date.now();
}

function getPublicCtfPlayerRows(players) {
    const safePlayers = Array.isArray(players) ? players : [];
    if (safePlayers.length === 0) {
        return `<div class="ctf-team-empty-row">Waiting for players</div>`;
    }

    return safePlayers.map(player => {
        const isReady = player?.ready === true;
        const playerName = escapeHtml(player?.name || `Player ${player?.serverId || ""}`);

        return `
            <div class="ctf-team-player-row ${isReady ? "is-ready" : ""}">
                <span class="ctf-team-player-name">${playerName}</span>
                <span class="ctf-team-player-ready ${isReady ? "is-ready" : ""}">${isReady ? "READY" : "NO READY"}</span>
            </div>
        `;
    }).join("");
}

function getPublicCtfPlayerListSignature(players) {
    const safePlayers = Array.isArray(players) ? players : [];
    return JSON.stringify(safePlayers.map(player => [
        Number(player?.serverId || 0),
        String(player?.name || ""),
        player?.ready === true
    ]));
}

function renderPublicCtfPlayerList(elementId, players) {
    const element = document.getElementById(elementId);
    if (!element) {
        return;
    }

    const signature = getPublicCtfPlayerListSignature(players);
    if (element.dataset.ctfPlayersSignature === signature) {
        return;
    }

    element.innerHTML = getPublicCtfPlayerRows(players);
    element.dataset.ctfPlayersSignature = signature;
}

function setPublicCtfText(elementId, value) {
    const element = document.getElementById(elementId);
    const nextValue = String(value ?? "");
    if (element && element.textContent !== nextValue) {
        element.textContent = nextValue;
    }
}

function setPublicCtfDisabled(element, isDisabled) {
    if (element && element.disabled !== Boolean(isDisabled)) {
        element.disabled = Boolean(isDisabled);
    }
}

function setPublicCtfAriaPressed(element, isPressed) {
    if (!element) {
        return;
    }

    const nextValue = isPressed ? "true" : "false";
    if (element.getAttribute("aria-pressed") !== nextValue) {
        element.setAttribute("aria-pressed", nextValue);
    }
}

function clearPublicCtfSettledPending(ownEntry) {
    const now = getPublicCtfNow();
    const pendingTeamId = Number(publicCtfTeamSelectState.pendingTeamId || 0);
    if (pendingTeamId && (
        Number(ownEntry?.teamId || 0) === pendingTeamId
        || now - Number(publicCtfTeamSelectState.pendingTeamStartedAt || 0) > PUBLIC_CTF_PENDING_TIMEOUT_MS
    )) {
        publicCtfTeamSelectState.pendingTeamId = null;
        publicCtfTeamSelectState.pendingTeamStartedAt = 0;
    }

    if (typeof publicCtfTeamSelectState.pendingReady === "boolean") {
        const ownReady = ownEntry?.player?.ready === true;
        if ((ownEntry && ownReady === publicCtfTeamSelectState.pendingReady)
            || now - Number(publicCtfTeamSelectState.pendingReadyStartedAt || 0) > PUBLIC_CTF_PENDING_TIMEOUT_MS) {
            publicCtfTeamSelectState.pendingReady = null;
            publicCtfTeamSelectState.pendingReadyStartedAt = 0;
        }
    }
}

function getPublicCtfOwnEntry(lobby) {
    const ownId = Number(currentServerId || 0);
    if (!ownId || !lobby?.teamPlayers) {
        return null;
    }

    for (const teamId of [1, 2]) {
        const team = getPublicCtfTeamData(lobby, teamId);
        const player = Array.isArray(team.players)
            ? team.players.find(entry => Number(entry?.serverId || 0) === ownId)
            : null;
        if (player) {
            return { teamId, player };
        }
    }

    return null;
}

function getPublicCtfReadyCount(players) {
    return Array.isArray(players) ? players.filter(player => player?.ready === true).length : 0;
}

function getPublicCtfBalancedTeamId(lobby, requestedTeamId) {
    requestedTeamId = Number(requestedTeamId);
    if (requestedTeamId !== 1 && requestedTeamId !== 2) {
        return requestedTeamId;
    }

    const ownEntry = getPublicCtfOwnEntry(lobby);
    let redCount = getPublicCtfTeamData(lobby, 1).players?.length || 0;
    let blueCount = getPublicCtfTeamData(lobby, 2).players?.length || 0;

    if (ownEntry?.teamId === 1) {
        redCount = Math.max(0, redCount - 1);
    } else if (ownEntry?.teamId === 2) {
        blueCount = Math.max(0, blueCount - 1);
    }

    const getDiffAfterJoin = teamId => Math.abs(
        redCount + (teamId === 1 ? 1 : 0)
        - (blueCount + (teamId === 2 ? 1 : 0))
    );

    const requestedDiff = getDiffAfterJoin(requestedTeamId);
    if (requestedDiff <= 1) {
        return requestedTeamId;
    }

    const otherTeamId = requestedTeamId === 1 ? 2 : 1;
    return getDiffAfterJoin(otherTeamId) < requestedDiff ? otherTeamId : requestedTeamId;
}

function getPublicCtfTeamDisplayName(lobby, teamId) {
    const fallback = Number(teamId) === 2 ? "BLUE TEAM" : "RED TEAM";
    return String(getPublicCtfTeamData(lobby, teamId).name || fallback).toUpperCase();
}

function renderPublicCtfTeamSelect() {
    const lobby = getLobbyById(publicCtfTeamSelectState.lobbyId);
    const overlay = document.getElementById("ctf-team-select-overlay");
    if (!overlay || !lobby) {
        return;
    }

    const blueTeam = getPublicCtfTeamData(lobby, 2);
    const redTeam = getPublicCtfTeamData(lobby, 1);
    const bluePlayers = Array.isArray(blueTeam.players) ? blueTeam.players : [];
    const redPlayers = Array.isArray(redTeam.players) ? redTeam.players : [];
    const remaining = getPublicCtfStartRemaining(lobby);
    const matchLocked = isPublicCtfMatchLocked(lobby);
    const totalPlayers = Number(lobby.players || 0);
    const blueReady = getPublicCtfReadyCount(bluePlayers);
    const redReady = getPublicCtfReadyCount(redPlayers);
    const ownEntry = getPublicCtfOwnEntry(lobby);
    clearPublicCtfSettledPending(ownEntry);

    const ownReady = ownEntry?.player?.ready === true;
    const displayedReady = typeof publicCtfTeamSelectState.pendingReady === "boolean"
        ? publicCtfTeamSelectState.pendingReady
        : ownReady;
    const pendingTeamId = Number(publicCtfTeamSelectState.pendingTeamId || 0);
    const hasTeamPending = pendingTeamId === 1 || pendingTeamId === 2;

    setPublicCtfText("ctf-team-select-arena", `${String(lobby.name || "ARENA CTF").toUpperCase()} PUBLIC CTF`);
    setPublicCtfText("ctf-team-select-subtitle", `${totalPlayers}/${Number(lobby.max_players || 0)} players queued. Match starts with 2+ players once everyone is ready.`);
    setPublicCtfText("ctf-team-blue-name", String(blueTeam.name || "BLUE TEAM").toUpperCase());
    setPublicCtfText("ctf-team-red-name", String(redTeam.name || "RED TEAM").toUpperCase());
    setPublicCtfText("ctf-team-blue-count", `${blueReady}/${bluePlayers.length} READY`);
    setPublicCtfText("ctf-team-red-count", `${redReady}/${redPlayers.length} READY`);
    setPublicCtfText("ctf-team-select-note", matchLocked ? "This public CTF match is live. Join opens again after the match ends." : "Arena locks once the match is live.");

    renderPublicCtfPlayerList("ctf-team-blue-list", bluePlayers);
    renderPublicCtfPlayerList("ctf-team-red-list", redPlayers);

    const countdown = document.getElementById("ctf-team-select-countdown");
    if (matchLocked) {
        setPublicCtfText("ctf-team-select-state", "MATCH LIVE");
        setPublicCtfText("ctf-team-select-countdown", "LOCKED");
    } else if (remaining > 0) {
        setPublicCtfText("ctf-team-select-state", "MATCH STARTING");
        setPublicCtfText("ctf-team-select-countdown", `${String(remaining).padStart(2, "0")}S`);
    } else if (bluePlayers.length > 0 && redPlayers.length > 0) {
        setPublicCtfText("ctf-team-select-state", blueReady === bluePlayers.length && redReady === redPlayers.length ? "ALL PLAYERS READY" : "WAITING FOR READY");
        setPublicCtfText("ctf-team-select-countdown", "--");
    } else {
        setPublicCtfText("ctf-team-select-state", "WAITING FOR BOTH TEAMS");
        setPublicCtfText("ctf-team-select-countdown", "--");
    }
    if (countdown && countdown.style.display !== "inline-grid") {
        countdown.style.display = "inline-grid";
    }

    const blueButton = document.getElementById("ctf-team-blue-card");
    const redButton = document.getElementById("ctf-team-red-card");
    const ownTeamId = Number(ownEntry?.teamId || 0);
    if (blueButton) {
        const isSelected = ownTeamId === 2 || pendingTeamId === 2;
        setPublicCtfDisabled(blueButton, matchLocked || hasTeamPending);
        blueButton.classList.toggle("is-selected", isSelected);
        blueButton.classList.toggle("is-pending", pendingTeamId === 2);
        setPublicCtfAriaPressed(blueButton, isSelected);
    }
    if (redButton) {
        const isSelected = ownTeamId === 1 || pendingTeamId === 1;
        setPublicCtfDisabled(redButton, matchLocked || hasTeamPending);
        redButton.classList.toggle("is-selected", isSelected);
        redButton.classList.toggle("is-pending", pendingTeamId === 1);
        setPublicCtfAriaPressed(redButton, isSelected);
    }

    const readyNote = matchLocked
        ? "The current match is live."
        : ownEntry
        ? (remaining > 0 ? "Countdown started. Stay ready until the match begins." : "Press Ready when you are prepared to start.")
        : "Choose BLUE or RED first, then press Ready.";
    setPublicCtfText("ctf-team-ready-title", ownEntry
        ? `${ownEntry.teamId === 2 ? "BLUE" : "RED"} TEAM ${displayedReady ? "READY" : "NO READY"}`
        : "JOIN A TEAM");
    setPublicCtfText("ctf-team-ready-note", readyNote);

    const readyButton = document.getElementById("ctf-team-ready-button");
    if (readyButton) {
        setPublicCtfText("ctf-team-ready-button", displayedReady ? "Cancel Ready" : "Ready");
        setPublicCtfDisabled(readyButton, matchLocked || !ownEntry || publicCtfTeamSelectState.readyPending === true);
        readyButton.classList.toggle("is-ready", displayedReady);
        readyButton.classList.toggle("is-pending", publicCtfTeamSelectState.readyPending === true);
    }
}

function startPublicCtfTeamSelectTimer() {
    if (publicCtfTeamSelectState.timer) {
        window.clearInterval(publicCtfTeamSelectState.timer);
    }

    publicCtfTeamSelectState.timer = window.setInterval(renderPublicCtfTeamSelect, 1000);
}

function stopPublicCtfTeamSelectTimer() {
    if (!publicCtfTeamSelectState.timer) {
        return;
    }

    window.clearInterval(publicCtfTeamSelectState.timer);
    publicCtfTeamSelectState.timer = null;
}

function openPublicCtfTeamSelect(lobby) {
    if (!isPublicCtfLobby(lobby)) {
        return;
    }

    if (isPublicCtfMatchLocked(lobby)) {
        sendNotification("error", "CTF Match Live", "This public CTF match is already live.");
        return;
    }

    publicCtfTeamSelectState.lobbyId = Number(lobby.id || 0);
    publicCtfTeamSelectState.readyPending = false;
    publicCtfTeamSelectState.pendingTeamId = null;
    publicCtfTeamSelectState.pendingTeamStartedAt = 0;
    publicCtfTeamSelectState.pendingReady = null;
    publicCtfTeamSelectState.pendingReadyStartedAt = 0;
    setLobbyContainerVisible(false);
    document.getElementById("ctf-team-select-overlay").classList.remove("hidden");
    renderPublicCtfTeamSelect();
    startPublicCtfTeamSelectTimer();
}

function closePublicCtfTeamSelect(options = {}) {
    stopPublicCtfTeamSelectTimer();
    publicCtfTeamSelectState.lobbyId = null;
    publicCtfTeamSelectState.readyPending = false;
    publicCtfTeamSelectState.pendingTeamId = null;
    publicCtfTeamSelectState.pendingTeamStartedAt = 0;
    publicCtfTeamSelectState.pendingReady = null;
    publicCtfTeamSelectState.pendingReadyStartedAt = 0;

    const overlay = document.getElementById("ctf-team-select-overlay");
    if (overlay) {
        overlay.classList.add("hidden");
    }

    if (options.returnToLobby !== false) {
        setLobbyContainerVisible(true);
    }
}

function refreshPublicCtfTeamSelectOverlay() {
    const overlay = document.getElementById("ctf-team-select-overlay");
    if (!overlay || overlay.classList.contains("hidden")) {
        return;
    }

    renderPublicCtfTeamSelect();
}

function joinPublicCtfTeam(teamId) {
    const lobbyId = Number(publicCtfTeamSelectState.lobbyId || 0);
    const lobby = getLobbyById(lobbyId);
    const selectedTeamId = Number(teamId);

    if (!lobbyId || (selectedTeamId !== 1 && selectedTeamId !== 2) || joinLobbyRequestPending) {
        return;
    }

    if (isPublicCtfMatchLocked(lobby)) {
        sendNotification("error", "CTF Match Live", "This public CTF match is already live.");
        renderPublicCtfTeamSelect();
        return;
    }

    const balancedTeamId = getPublicCtfBalancedTeamId(lobby, selectedTeamId);
    if (balancedTeamId !== selectedTeamId) {
        sendNotification("success", "Teams Balanced", `Joining ${getPublicCtfTeamDisplayName(lobby, balancedTeamId)} to keep teams even.`);
    }

    joinLobbyRequestPending = true;
    publicCtfTeamSelectState.pendingTeamId = balancedTeamId;
    publicCtfTeamSelectState.pendingTeamStartedAt = getPublicCtfNow();
    renderPublicCtfTeamSelect();

    fetch(`https://${GetParentResourceName()}/joinPublicCtfTeam`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ lobbyId, teamId: balancedTeamId })
    }).then(response => {
        if (!response.ok) throw new Error(`Server error: ${response.status}`);
        return response.text();
    }).then(() => {
        sendNotification("success", "Public CTF", "Team join request sent. Press Ready when you are prepared.");
    }).catch(() => {
        publicCtfTeamSelectState.pendingTeamId = null;
        publicCtfTeamSelectState.pendingTeamStartedAt = 0;
        sendNotification("error", "CTF Error", "Failed to join this CTF team.");
    }).finally(() => {
        joinLobbyRequestPending = false;
        renderPublicCtfTeamSelect();
    });
}

function togglePublicCtfReady() {
    const lobbyId = Number(publicCtfTeamSelectState.lobbyId || 0);
    const lobby = getLobbyById(lobbyId);
    const ownEntry = getPublicCtfOwnEntry(lobby);
    if (!lobbyId || !ownEntry || publicCtfTeamSelectState.readyPending) {
        return;
    }

    const targetReady = ownEntry.player?.ready !== true;
    publicCtfTeamSelectState.readyPending = true;
    publicCtfTeamSelectState.pendingReady = targetReady;
    publicCtfTeamSelectState.pendingReadyStartedAt = getPublicCtfNow();
    renderPublicCtfTeamSelect();

    fetch(`https://${GetParentResourceName()}/setPublicCtfReady`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            lobbyId,
            ready: targetReady
        })
    }).then(response => {
        if (!response.ok) throw new Error(`Server error: ${response.status}`);
        return response.text();
    }).catch(() => {
        publicCtfTeamSelectState.pendingReady = null;
        publicCtfTeamSelectState.pendingReadyStartedAt = 0;
        sendNotification("error", "Public CTF", "Failed to update Ready status.");
    }).finally(() => {
        publicCtfTeamSelectState.readyPending = false;
        renderPublicCtfTeamSelect();
    });
}


function joinLobby(lobbyId) {
    if (!lobbyId || joinLobbyRequestPending) return;

    const lobby = getLobbyById(lobbyId);

    const isVisible = currentLobbies.some(lobby => {
        const lobbyCategory = lobby.category || "public";
        return lobby.id === lobbyId && lobbyCategory === currentCategory;
    });

    if (!isVisible) {
        sendNotification("error", "Lobby Blocked", "This lobby is currently not accessible.");
        return;
    }

    if (isPublicCtfLobby(lobby)) {
        openPublicCtfTeamSelect(lobby);
        return;
    }

    joinLobbyRequestPending = true;

    fetch(`https://${GetParentResourceName()}/joinLobby`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ lobbyId })
    }).then(response => {
        if (!response.ok) throw new Error(`Server error: ${response.status}`);
        return response.text();
    }).then(() => {
        sendNotification("success", "Lobby PvP", "Join request sent.");
        closeLobbyUI();
    }).catch(error => {
        sendNotification("error", "Lobby Error", "Failed to join the lobby.");
    }).finally(() => {
        joinLobbyRequestPending = false;
    });
}


function closeLobbyUI() {
    lobbyOpenRequestSequence += 1;
    clearScheduledLobbyListRender();
    clearDeferredDuelInsightsPrefetch();
    clearDeferredTeamBattleInsightsPrefetch();
    storeLobbyScrollPosition(currentCategory);
    setLobbyContainerVisible(false);
    closeOverlay();
    closeTeamWeaponOverlay();
    closePublicCtfTeamSelect({ returnToLobby: false });
    closePrivateArenaCreateOverlay();
    closeCustomArenaOverlay();
    closeSavedCustomArenasOverlay();
    closeCustomRandomSpawnOverlay();
    closeCustomSpawnOverlay();
    closeCustomArenaDeleteOverlay();
    closeTeamBattleInsightsOverlay(false);
    closeDuelInsightsOverlay(false);
    fetch(`https://${GetParentResourceName()}/closeLobby`, {
        method: "POST",
        headers: { "Content-Type": "application/json" }
    }).catch(console.error);
}

function handleEscapeKey(event) {
    if (event.key === "Escape") {
        const teamOverlay = document.getElementById("team-weapon-overlay");
        const privateArenaOverlay = document.getElementById("private-arena-overlay");
        const customArenaOverlay = document.getElementById("custom-arena-overlay");
        const savedCustomArenaOverlay = document.getElementById("saved-custom-arena-overlay");
        const customRandomSpawnOverlay = document.getElementById("custom-random-spawn-overlay");
        const customSpawnOverlay = document.getElementById("custom-spawn-overlay");
        const customDeleteOverlay = document.getElementById("custom-delete-overlay");
        const publicCtfOverlay = document.getElementById("ctf-team-select-overlay");
        const historyOverlay = document.getElementById("team-history-overlay");
        const duelHistoryOverlay = document.getElementById("duel-history-overlay");
        const overlay = document.getElementById("weapon-overlay");
        if (publicCtfOverlay && !publicCtfOverlay.classList.contains("hidden")) {
            closePublicCtfTeamSelect();
        } else if (!teamOverlay.classList.contains("hidden")) {
            closeTeamWeaponOverlay();
        } else if (privateArenaOverlay && !privateArenaOverlay.classList.contains("hidden")) {
            closePrivateArenaCreateOverlay();
        } else if (customDeleteOverlay && !customDeleteOverlay.classList.contains("hidden")) {
            closeCustomArenaDeleteOverlay();
        } else if (savedCustomArenaOverlay && !savedCustomArenaOverlay.classList.contains("hidden")) {
            closeSavedCustomArenasOverlay();
        } else if (customRandomSpawnOverlay && !customRandomSpawnOverlay.classList.contains("hidden")) {
            closeCustomRandomSpawnOverlay();
        } else if (customSpawnOverlay && !customSpawnOverlay.classList.contains("hidden")) {
            closeCustomSpawnOverlay();
        } else if (customArenaOverlay && !customArenaOverlay.classList.contains("hidden")) {
            closeCustomArenaOverlay();
        } else if (historyOverlay && !historyOverlay.classList.contains("hidden")) {
            closeTeamBattleInsightsOverlay();
        } else if (duelHistoryOverlay && !duelHistoryOverlay.classList.contains("hidden")) {
            closeDuelInsightsOverlay();
        } else if (!overlay.classList.contains("hidden")) {
            if (overlayState.mode === "kick") {
                returnToPlayersOverlay();
            } else {
                closeOverlay();
            }
        } else {
            closeLobbyUI();
        }
    }
}

document.addEventListener("keydown", handleEscapeKey);

function sendNotification(type, title, message) {
    fetch(`https://${GetParentResourceName()}/bln_notify`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ type, title, message, duration: 5000 })
    });
}
