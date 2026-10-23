const FALLBACK_TEXT = "Unknown";
let deathScreenActive = false;
let spectatorHudActive = false;
let spectatorHudMode = "killer";
let lastActionAt = 0;
let deathOverlayEventsBound = false;

function safeText(value, fallback = FALLBACK_TEXT) {
    if (typeof value !== "string") {
        return fallback;
    }

    const clean = value.trim();
    return clean.length > 0 ? clean : fallback;
}

function shouldThrottle() {
    const now = Date.now();
    if (now - lastActionAt < 250) {
        return true;
    }

    lastActionAt = now;
    return false;
}

function postNui(route, payload = {}) {
    fetch(`https://${GetParentResourceName()}/${route}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
    }).catch(() => {});
}

function clearTextSelection() {
    if (typeof window.getSelection !== "function") {
        return;
    }

    const selection = window.getSelection();
    if (selection && typeof selection.removeAllRanges === "function") {
        selection.removeAllRanges();
    }
}

function applyDeathInfo(info) {
    const data = info && typeof info === "object" ? info : {};
    const lobbyLabel = safeText(data.lobby, "");

    document.getElementById("killer-name").textContent = safeText(data.killer);
    document.getElementById("killer-weapon").textContent = safeText(data.weapon);
    document.getElementById("killer-distance").textContent = safeText(data.distance);

    const lobbyElement = document.getElementById("report-lobby");
    if (lobbyElement) {
        if (lobbyLabel) {
            lobbyElement.textContent = lobbyLabel;
            lobbyElement.hidden = false;
        } else {
            lobbyElement.textContent = "";
            lobbyElement.hidden = true;
        }
    }
}

function applySpectateContext(context) {
    const data = context && typeof context === "object" ? context : {};
    const label = safeText(data.label, "Spectate Killer");
    const noteText = safeText(data.note, "Spectator mode is available in Public and Private arenas.");

    const button = document.getElementById("spectate-action");
    const buttonLabel = button ? button.querySelector("span") : null;
    if (buttonLabel) {
        buttonLabel.textContent = label;
    }

    const note = document.querySelector(".spectate-note");
    if (note) {
        note.textContent = noteText;
    }
}
function showDeathScreen(info, spectateContext) {
    const overlay = document.getElementById("death-overlay");
    if (!overlay) {
        return;
    }

    hideSpectatorHud();
    applyDeathInfo(info);
    applySpectateContext(spectateContext);
    clearTextSelection();

    if (!deathScreenActive) {
        overlay.style.display = "flex";
        requestAnimationFrame(() => {
            overlay.classList.add("active");
        });
    }

    deathScreenActive = true;
}

function hideDeathScreen() {
    const overlay = document.getElementById("death-overlay");
    if (!overlay) {
        return;
    }

    clearTextSelection();
    overlay.classList.remove("active");

    setTimeout(() => {
        overlay.style.display = "none";
        deathScreenActive = false;
    }, 180);
}

function setSpectatorHint(mode) {
    const isTeamMode = mode === "team";
    const hint = document.querySelector(".spectator-hint");
    const actionLabel = document.querySelector(".spectator-exit-text");
    const actionKey = document.querySelector(".spectator-exit kbd");

    if (actionLabel) {
        actionLabel.textContent = isTeamMode ? "Switch" : "Exit";
    }

    if (actionKey) {
        actionKey.textContent = isTeamMode ? "SPACE" : "ESC";
    }

    if (!hint) {
        return;
    }

    const key = document.createElement("kbd");
    key.textContent = isTeamMode ? "SPACE" : "ESC";
    hint.textContent = "";
    hint.append(
        "Press ",
        key,
        isTeamMode ? " to switch teammate" : " to leave spectator mode and return to your arena"
    );
}

function showSpectatorHud(targetName, mode = "killer") {
    const overlay = document.getElementById("spectator-overlay");
    const target = document.getElementById("spectator-target-name");
    if (!overlay || !target) {
        return;
    }

    spectatorHudMode = mode === "team" ? "team" : "killer";
    target.textContent = safeText(targetName, spectatorHudMode === "team" ? "Teammate" : "Killer");
    setSpectatorHint(spectatorHudMode);
    clearTextSelection();
    overlay.style.display = "flex";
    requestAnimationFrame(() => {
        overlay.classList.add("active");
    });
    spectatorHudActive = true;
}

function hideSpectatorHud() {
    const overlay = document.getElementById("spectator-overlay");
    if (!overlay) {
        return;
    }

    clearTextSelection();
    overlay.classList.remove("active");
    setTimeout(() => {
        overlay.style.display = "none";
        spectatorHudActive = false;
        spectatorHudMode = "killer";
    }, 180);
}

function shouldBlockOverlayEvent(event) {
    if (!deathScreenActive && !spectatorHudActive) {
        return false;
    }

    const target = event.target instanceof Element ? event.target : null;
    if (!target) {
        return false;
    }

    const deathOverlay = document.getElementById("death-overlay");
    const spectatorOverlay = document.getElementById("spectator-overlay");

    return Boolean(
        (deathScreenActive && deathOverlay && deathOverlay.contains(target)) ||
        (spectatorHudActive && spectatorOverlay && spectatorOverlay.contains(target))
    );
}

function bindButton(id, route, requiresDeathScreen) {
    const button = document.getElementById(id);
    if (!button || button.dataset.bound === "1") {
        return;
    }

    button.dataset.bound = "1";
    button.addEventListener("click", () => {
        if (requiresDeathScreen && !deathScreenActive) {
            return;
        }

        if (shouldThrottle()) {
            return;
        }

        postNui(route);
    });
}

function bindUiActions() {
    bindButton("respawn-action", "deathRespawnPressed", true);
    bindButton("spectate-action", "deathSpectatePressed", true);

    if (!deathOverlayEventsBound) {
        deathOverlayEventsBound = true;
        ["selectstart", "dragstart", "contextmenu"].forEach((eventName) => {
            window.addEventListener(eventName, (event) => {
                if (shouldBlockOverlayEvent(event)) {
                    event.preventDefault();
                }
            });
        });
    }
}

window.addEventListener("message", (event) => {
    const data = event.data || {};

    if (data.action === "showDeathScreen") {
        showDeathScreen(data.deathInfo, data.spectateContext);
    } else if (data.action === "hideDeathScreen") {
        hideDeathScreen();
    } else if (data.action === "updateDeathInfo") {
        applyDeathInfo(data.deathInfo);
        if (data.spectateContext) {
            applySpectateContext(data.spectateContext);
        }
    } else if (data.action === "showSpectatorHud") {
        hideDeathScreen();
        showSpectatorHud(data.targetName, data.mode || data.spectateMode);
    } else if (data.action === "hideSpectatorHud") {
        hideSpectatorHud();
    }
});

window.addEventListener("keydown", (event) => {
    const key = (event.key || "").toLowerCase();

    const isSpace = key === " " || key === "space" || key === "spacebar" || event.code === "Space";
    if (spectatorHudActive && spectatorHudMode === "team" && isSpace) {
        event.preventDefault();
        event.stopPropagation();
        if (!shouldThrottle()) {
            postNui("spectatorSwitchPressed");
        }
        return;
    }

    if (spectatorHudActive && key === "escape") {
        event.preventDefault();
        event.stopPropagation();
        if (!shouldThrottle()) {
            postNui("spectatorExitPressed");
        }
        return;
    }

    if (!deathScreenActive) {
        return;
    }

    if (key === "e") {
        if (!shouldThrottle()) {
            postNui("deathRespawnPressed");
        }
        return;
    }

    if (key === "g") {
        if (!shouldThrottle()) {
            postNui("deathSpectatePressed");
        }
    }
});

window.addEventListener("DOMContentLoaded", bindUiActions);
bindUiActions();
