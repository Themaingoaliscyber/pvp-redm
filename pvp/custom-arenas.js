function normalizeCustomArenaSlotInput(rawValue) {
    const textValue = String(rawValue ?? "").trim();
    if (textValue === "") {
        return "";
    }

    const numericValue = Number(textValue);
    if (!Number.isFinite(numericValue)) {
        return "";
    }

    const slotCount = Math.floor(numericValue);
    if (slotCount < CUSTOM_ARENA_SLOT_MIN) {
        return String(CUSTOM_ARENA_SLOT_MIN);
    }

    return String(Math.min(slotCount, CUSTOM_ARENA_SLOT_MAX));
}

function normalizeCustomArenaSlotField(input) {
    if (!input) {
        return;
    }

    const rawValue = String(input.value ?? "");
    if (rawValue.trim() === "") {
        return;
    }

    const normalizedValue = normalizeCustomArenaSlotInput(rawValue);
    if (normalizedValue !== "" && normalizedValue !== rawValue) {
        input.value = normalizedValue;
    }
}

function getCustomArenaRequestedSlots() {
    const input = document.getElementById("custom-arena-slot-input");
    const normalizedValue = normalizeCustomArenaSlotInput(input?.value ?? "");
    if (normalizedValue === "") {
        return CUSTOM_ARENA_SLOT_DEFAULT;
    }

    return Number(normalizedValue);
}

function isCustomArenaOverlayVisible() {
    const overlay = document.getElementById("custom-arena-overlay");
    return Boolean(overlay) && !overlay.classList.contains("hidden");
}

function setCustomArenaAccessType(accessType) {
    customArenaDraftAccessType = accessType === "public" ? "public" : "private";
    syncCustomArenaAccessUi();
}

function renderCustomArenaAccessButton(button, label, isActive, tone) {
    if (!button) {
        return;
    }

    button.textContent = label;
    button.classList.toggle("active", Boolean(isActive));

    if (isActive) {
        const check = document.createElement("span");
        check.className = `custom-arena-access-check ${tone}`;
        check.setAttribute("aria-hidden", "true");
        button.appendChild(check);
    }
}

function syncCustomArenaAccessUi() {
    const publicButton = document.getElementById("custom-arena-access-public");
    const privateButton = document.getElementById("custom-arena-access-private");
    const hint = document.getElementById("custom-arena-access-hint");

    renderCustomArenaAccessButton(publicButton, "Public", customArenaDraftAccessType === "public", "public");
    renderCustomArenaAccessButton(privateButton, "Private", customArenaDraftAccessType === "private", "private");

    if (hint) {
        hint.textContent = customArenaDraftAccessType === "public"
            ? "Public arenas can be joined by everyone immediately."
            : "Private arenas require /allow <playerid> from the owner before a player can join.";
    }
}

function syncCustomArenaOverlayState() {
    if (!isCustomArenaOverlayVisible()) {
        return;
    }

    const overlay = document.getElementById("custom-arena-overlay");
    const overlayTitle = document.getElementById("custom-arena-title");
    const overlaySubtitle = document.getElementById("custom-arena-subtitle");
    const nameInput = document.getElementById("custom-arena-name-input");
    const slotInput = document.getElementById("custom-arena-slot-input");
    const submitButton = document.getElementById("custom-arena-submit-button");
    const ownerPanel = document.getElementById("custom-arena-owner-panel");
    const ownerSummary = document.getElementById("custom-arena-owner-summary-text");
    const activeLobby = getLobbyById(Number(currentCustomArenaState?.lobbyId || 0));
    const isEditMode = customArenaOverlayMode === "edit";
    const isOwner = Boolean(currentCustomArenaState?.active && (currentCustomArenaState?.isOwner || currentCustomArenaState?.isLeader));

    if (overlay) {
        overlay.dataset.mode = isEditMode ? "edit" : "create";
    }

    if (overlayTitle) {
        overlayTitle.textContent = isEditMode ? "Edit Custom Arena" : "Create Custom Arena";
    }

    if (overlaySubtitle) {
        overlaySubtitle.textContent = isEditMode
            ? "Update the arena settings, add more spawn points, or rebuild the whole spawn set from your current position."
            : "Choose your arena name, slot count and access mode. The owner keeps access even after leaving. The arena is deleted only when the last player leaves it.";
    }

    if (isEditMode) {
        if (nameInput) {
            nameInput.value = String(currentCustomArenaState?.name || activeLobby?.name || "");
        }
        if (slotInput) {
            slotInput.value = String(Number(currentCustomArenaState?.maxPlayers || activeLobby?.max_players || CUSTOM_ARENA_SLOT_DEFAULT));
        }
        customArenaDraftAccessType = String(currentCustomArenaState?.accessType || activeLobby?.accessType || "private") === "public" ? "public" : "private";
    } else {
        if (nameInput && !String(nameInput.value || "").trim()) {
            nameInput.value = "";
        }
        if (slotInput) {
            slotInput.value = normalizeCustomArenaSlotInput(slotInput.value) || String(CUSTOM_ARENA_SLOT_DEFAULT);
        }
    }

    syncCustomArenaAccessUi();

    if (submitButton) {
        submitButton.textContent = isEditMode ? "Save Arena Settings" : "Create Arena";
    }

    if (ownerPanel) {
        ownerPanel.classList.toggle("hidden", !(isEditMode && isOwner));
    }

    if (ownerSummary) {
        ownerSummary.textContent = `Spawn points saved: ${Number(currentCustomArenaState?.spawnCount || 0)} | Access: ${String(currentCustomArenaState?.accessType || customArenaDraftAccessType || "private").toUpperCase()}`;
    }
}

function openCustomArenaCreateOverlay() {
    customArenaOverlayMode = "create";
    customArenaDraftAccessType = "private";

    const nameInput = document.getElementById("custom-arena-name-input");
    const slotInput = document.getElementById("custom-arena-slot-input");
    if (nameInput) {
        nameInput.value = "";
    }
    if (slotInput) {
        slotInput.value = String(CUSTOM_ARENA_SLOT_DEFAULT);
    }

    setCustomArenaOverlayOpen(true);
    document.getElementById("custom-arena-overlay").classList.remove("hidden");
    syncCustomArenaOverlayState();
}

function openCustomArenaEditOverlay() {
    if (!(currentCustomArenaState && currentCustomArenaState.active && (currentCustomArenaState.isOwner || currentCustomArenaState.isLeader))) {
        sendNotification("error", "Custom Arena", "You must own an active custom arena before you can edit it.");
        return;
    }

    customArenaOverlayMode = "edit";
    setCustomArenaOverlayOpen(true);
    document.getElementById("custom-arena-overlay").classList.remove("hidden");
    syncCustomArenaOverlayState();
}

function closeCustomArenaOverlay() {
    setCustomArenaOverlayOpen(false);
    document.getElementById("custom-arena-overlay").classList.add("hidden");
}

function submitCustomArenaForm() {
    const nameInput = document.getElementById("custom-arena-name-input");
    const slotInput = document.getElementById("custom-arena-slot-input");
    let arenaName = String(nameInput?.value || "").trim();
    const normalizedSlots = normalizeCustomArenaSlotInput(slotInput?.value ?? "");
    const maxPlayers = normalizedSlots === "" ? CUSTOM_ARENA_SLOT_DEFAULT : Number(normalizedSlots);
    const endpoint = customArenaOverlayMode === "edit" ? "updateCustomArenaSettings" : "createCustomArena";

    if (slotInput) {
        slotInput.value = normalizedSlots || String(CUSTOM_ARENA_SLOT_DEFAULT);
    }

    if (arenaName.length < 3) {
        sendNotification("error", "Custom Arena", "Arena name must contain at least 3 characters.");
        return;
    }

    if (arenaName.length > CUSTOM_ARENA_NAME_MAX) {
        arenaName = arenaName.slice(0, CUSTOM_ARENA_NAME_MAX).trim();
        if (nameInput) {
            nameInput.value = arenaName;
        }
    }

    fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            name: arenaName,
            maxPlayers,
            accessType: customArenaDraftAccessType
        })
    }).then(response => {
        if (!response.ok) {
            throw new Error(`Server error: ${response.status}`);
        }

        return response.text();
    }).then(() => {
        if (customArenaOverlayMode === "edit") {
            sendNotification("success", "Custom Arena", "Arena settings update sent.");
            closeCustomArenaOverlay();
            return;
        }

        sendNotification("success", "Custom Arena", "Custom arena creation requested.");
        closeLobbyUI();
    }).catch(() => {
        sendNotification("error", "Custom Arena", customArenaOverlayMode === "edit"
            ? "Failed to update the custom arena."
            : "Failed to create the custom arena.");
    });
}

function addCustomArenaSpawn() {
    if (!(currentCustomArenaState && currentCustomArenaState.active && (currentCustomArenaState.isOwner || currentCustomArenaState.isLeader))) {
        sendNotification("error", "Custom Arena", "You must own the active custom arena to add spawn points.");
        return;
    }

    fetch(`https://${GetParentResourceName()}/addCustomArenaSpawn`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({})
    }).then(response => {
        if (!response.ok) {
            throw new Error(`Server error: ${response.status}`);
        }
        return response.text();
    }).then(() => {
        return null;
    }).catch(() => {
        sendNotification("error", "Custom Arena", "Failed to add a new spawn point.");
    });
}

function normalizeCustomRandomSpawnCountInput(rawValue) {
    const numericValue = Number(rawValue);
    if (!Number.isFinite(numericValue)) {
        return String(CUSTOM_RANDOM_SPAWN_COUNT_DEFAULT);
    }

    const count = Math.floor(numericValue);
    return String(Math.min(Math.max(count, CUSTOM_RANDOM_SPAWN_COUNT_MIN), CUSTOM_RANDOM_SPAWN_COUNT_MAX));
}

function normalizeCustomRandomSpawnDistanceInput(rawValue) {
    const numericValue = Number(rawValue);
    if (!Number.isFinite(numericValue)) {
        return String(CUSTOM_RANDOM_SPAWN_DISTANCE_DEFAULT);
    }

    const distance = Math.floor(numericValue);
    return String(Math.min(Math.max(distance, CUSTOM_RANDOM_SPAWN_DISTANCE_MIN), CUSTOM_RANDOM_SPAWN_DISTANCE_MAX));
}

function normalizeCustomRandomSpawnField(input, fieldType) {
    if (!input) return;

    input.value = fieldType === "count"
        ? normalizeCustomRandomSpawnCountInput(input.value)
        : normalizeCustomRandomSpawnDistanceInput(input.value);
}

function openCustomRandomSpawnOverlay() {
    if (!canManageActiveCustomArenaSpawns()) {
        sendNotification("error", "Random Spawn Points", "You must own the active custom arena to add random spawn points.");
        return;
    }

    const countInput = document.getElementById("custom-random-spawn-count-input");
    const distanceInput = document.getElementById("custom-random-spawn-distance-input");
    if (countInput) {
        countInput.value = String(CUSTOM_RANDOM_SPAWN_COUNT_DEFAULT);
    }
    if (distanceInput) {
        distanceInput.value = String(CUSTOM_RANDOM_SPAWN_DISTANCE_DEFAULT);
    }

    document.getElementById("custom-random-spawn-overlay").classList.remove("hidden");
}

function closeCustomRandomSpawnOverlay() {
    const overlay = document.getElementById("custom-random-spawn-overlay");
    if (overlay) {
        overlay.classList.add("hidden");
    }
}

function addRandomCustomArenaSpawns() {
    if (!canManageActiveCustomArenaSpawns()) {
        sendNotification("error", "Random Spawn Points", "You must own the active custom arena to add random spawn points.");
        return;
    }

    const countInput = document.getElementById("custom-random-spawn-count-input");
    const distanceInput = document.getElementById("custom-random-spawn-distance-input");
    const count = Number(normalizeCustomRandomSpawnCountInput(countInput?.value));
    const minDistance = Number(normalizeCustomRandomSpawnDistanceInput(distanceInput?.value));

    fetch(`https://${GetParentResourceName()}/addRandomCustomArenaSpawns`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ count, minDistance })
    }).then(response => {
        if (!response.ok) {
            throw new Error(`Server error: ${response.status}`);
        }
        return response.text();
    }).then(result => {
        const normalizedResult = String(result || "").trim().replace(/^"|"$/g, "");
        if (normalizedResult !== "ok") {
            throw new Error("Random spawn generation rejected");
        }

        closeCustomRandomSpawnOverlay();
        sendNotification("success", "Random Spawn Points", "Random spawn generation started.");
    }).catch(() => {
        sendNotification("error", "Random Spawn Points", "Failed to start random spawn generation.");
    });
}

function resetCustomArenaSpawns() {
    if (!(currentCustomArenaState && currentCustomArenaState.active && (currentCustomArenaState.isOwner || currentCustomArenaState.isLeader))) {
        sendNotification("error", "Custom Arena", "You must own the active custom arena to reset spawn points.");
        return;
    }

    fetch(`https://${GetParentResourceName()}/resetCustomArenaSpawns`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({})
    }).then(response => {
        if (!response.ok) {
            throw new Error(`Server error: ${response.status}`);
        }
        return response.text();
    }).then(() => {
        return null;
    }).catch(() => {
        sendNotification("error", "Custom Arena", "Failed to reset the spawn points.");
    });
}

function openCustomArenaDeleteOverlay(lobbyId) {
    const numericLobbyId = Number(lobbyId || 0);
    const lobby = getLobbyById(numericLobbyId);
    if (!lobby || !canDeleteCustomArenaCard(lobby)) {
        sendNotification("error", "Custom Arena", "You can only delete your own custom arena.");
        return;
    }

    pendingCustomArenaDeleteLobbyId = numericLobbyId;
    const warning = document.getElementById("custom-delete-warning");
    if (warning) {
        warning.textContent = `Are you sure you want to delete ${String(lobby.name || "your arena")}? You will lose all arena settings and spawn points.`;
    }

    const overlay = document.getElementById("custom-delete-overlay");
    if (overlay) {
        overlay.classList.remove("hidden");
    }
}

function closeCustomArenaDeleteOverlay() {
    pendingCustomArenaDeleteLobbyId = null;
    const overlay = document.getElementById("custom-delete-overlay");
    if (overlay) {
        overlay.classList.add("hidden");
    }
}

function removeCustomArenaFromUi(lobbyId) {
    const numericLobbyId = Number(lobbyId || 0);
    if (!numericLobbyId) {
        return;
    }

    currentLobbies = currentLobbies.filter(lobby => Number(lobby?.id || 0) !== numericLobbyId);

    if (Number(currentCustomArenaState?.lobbyId || 0) === numericLobbyId) {
        currentCustomArenaState = { active: false };
    }

    closeCustomArenaDeleteOverlay();
    closeCustomArenaOverlay();
    closeCustomRandomSpawnOverlay();
    closeCustomSpawnOverlay();

    if (currentCategory === "custom" && isLobbyUiOpen()) {
        updateLobbyList(currentLobbies, isSorted, { force: true });
    } else {
        refreshLobbyStateUi();
    }
}

function confirmCustomArenaDelete() {
    const lobbyId = Number(pendingCustomArenaDeleteLobbyId || 0);
    if (!lobbyId) {
        closeCustomArenaDeleteOverlay();
        return;
    }

    removeCustomArenaFromUi(lobbyId);

    fetch(`https://${GetParentResourceName()}/deleteCustomArena`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ lobbyId })
    }).then(response => {
        if (!response.ok) {
            throw new Error(`Server error: ${response.status}`);
        }

        return response.text();
    }).then(() => {
        sendNotification("success", "Custom Arena", "Delete request sent.");
    }).catch(() => {
        sendNotification("error", "Custom Arena", "Failed to delete the custom arena.");
    });
}

function canManageActiveCustomArenaSpawns() {
    return Boolean(currentCustomArenaState
        && currentCustomArenaState.active
        && (currentCustomArenaState.isOwner || currentCustomArenaState.isLeader));
}

function getCustomArenaSpawnPoints() {
    return Array.isArray(currentCustomArenaState?.spawnPoints)
        ? currentCustomArenaState.spawnPoints
        : [];
}

function isCustomSpawnOverlayVisible() {
    const overlay = document.getElementById("custom-spawn-overlay");
    return Boolean(overlay) && !overlay.classList.contains("hidden");
}

function formatCustomSpawnCoord(value) {
    const numericValue = Number(value || 0);
    return Number.isFinite(numericValue) ? numericValue.toFixed(2) : "0.00";
}

function renderCustomSpawnOverlay() {
    const list = document.getElementById("custom-spawn-list");
    const subtitle = document.getElementById("custom-spawn-subtitle");
    if (!list) return;

    const spawnPoints = getCustomArenaSpawnPoints();
    if (subtitle) {
        const arenaName = String(currentCustomArenaState?.name || "Custom Arena");
        subtitle.textContent = `${arenaName} | ${spawnPoints.length} spawn point${spawnPoints.length === 1 ? "" : "s"}`;
    }

    list.innerHTML = "";

    if (!canManageActiveCustomArenaSpawns()) {
        const empty = document.createElement("div");
        empty.className = "custom-spawn-empty";
        empty.textContent = "Join your custom arena as owner to manage spawn points.";
        list.appendChild(empty);
        return;
    }

    if (spawnPoints.length === 0) {
        const empty = document.createElement("div");
        empty.className = "custom-spawn-empty";
        empty.textContent = "No spawn points saved yet.";
        list.appendChild(empty);
        return;
    }

    spawnPoints.forEach((spawnPoint, spawnIndex) => {
        const displayIndex = spawnIndex + 1;
        const card = document.createElement("div");
        card.className = "custom-spawn-card";

        const details = document.createElement("div");
        details.className = "custom-spawn-details";
        details.innerHTML = `
            <div class="custom-spawn-title">Spawn Point ${displayIndex}</div>
            <div class="custom-spawn-coords">
                X ${formatCustomSpawnCoord(spawnPoint?.x)} | Y ${formatCustomSpawnCoord(spawnPoint?.y)} | Z ${formatCustomSpawnCoord(spawnPoint?.z)}
            </div>
        `;
        card.appendChild(details);

        const actions = document.createElement("div");
        actions.className = "custom-spawn-actions";

        const teleportButton = document.createElement("button");
        teleportButton.className = "secondary-button custom-spawn-teleport-button";
        teleportButton.textContent = "Teleport";
        teleportButton.onclick = function () {
            teleportCustomArenaSpawn(displayIndex);
        };
        actions.appendChild(teleportButton);

        const updateButton = document.createElement("button");
        updateButton.className = "secondary-button custom-arena-add-spawn-button";
        updateButton.textContent = "Update Here";
        updateButton.onclick = function () {
            updateCustomArenaSpawn(displayIndex);
        };
        actions.appendChild(updateButton);

        const deleteButton = document.createElement("button");
        deleteButton.className = "secondary-button custom-arena-danger-button";
        deleteButton.textContent = "Delete";
        deleteButton.disabled = spawnPoints.length <= 1;
        deleteButton.onclick = function () {
            deleteCustomArenaSpawn(displayIndex);
        };
        actions.appendChild(deleteButton);

        card.appendChild(actions);
        list.appendChild(card);
    });
}

function openCustomSpawnOverlay() {
    if (!canManageActiveCustomArenaSpawns()) {
        sendNotification("error", "Spawn Points", "You must own the active custom arena to manage spawn points.");
        return;
    }

    renderCustomSpawnOverlay();
    document.getElementById("custom-spawn-overlay").classList.remove("hidden");
}

function closeCustomSpawnOverlay() {
    const overlay = document.getElementById("custom-spawn-overlay");
    if (overlay) {
        overlay.classList.add("hidden");
    }
}

function teleportCustomArenaSpawn(spawnIndex) {
    fetch(`https://${GetParentResourceName()}/teleportCustomArenaSpawn`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ index: spawnIndex })
    }).then(response => {
        if (!response.ok) {
            throw new Error(`Server error: ${response.status}`);
        }
        return response.text();
    }).then(result => {
        const normalizedResult = String(result || "").trim().replace(/^"|"$/g, "");
        if (normalizedResult !== "ok") {
            throw new Error("Teleport rejected");
        }

        closeLobbyUI();
    }).catch(() => {
        sendNotification("error", "Spawn Points", "Failed to teleport to that spawn point.");
    });
}

function updateCustomArenaSpawn(spawnIndex) {
    fetch(`https://${GetParentResourceName()}/updateCustomArenaSpawn`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ index: spawnIndex })
    }).then(response => {
        if (!response.ok) {
            throw new Error(`Server error: ${response.status}`);
        }
        return response.text();
    }).then(() => {
        return null;
    }).catch(() => {
        sendNotification("error", "Spawn Points", "Failed to update that spawn point.");
    });
}

function deleteCustomArenaSpawn(spawnIndex) {
    const spawnPoints = getCustomArenaSpawnPoints();
    if (spawnPoints.length <= 1) {
        sendNotification("error", "Spawn Points", "You must keep at least one spawn point.");
        return;
    }

    fetch(`https://${GetParentResourceName()}/deleteCustomArenaSpawn`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ index: spawnIndex })
    }).then(response => {
        if (!response.ok) {
            throw new Error(`Server error: ${response.status}`);
        }
        return response.text();
    }).then(() => {
        return null;
    }).catch(() => {
        sendNotification("error", "Spawn Points", "Failed to delete that spawn point.");
    });
}

