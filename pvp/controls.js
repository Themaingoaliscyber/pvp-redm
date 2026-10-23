function renderTeamWeaponOverlay() {
    const lobby = getLobbyById(teamWeaponDraft.lobbyId);
    const arenaLabel = lobby?.category === "private"
        ? "private arena"
        : (lobby?.category === "custom" ? "custom arena" : "team battle");
    const categories = Array.isArray(teamWeaponMenu.categories) ? teamWeaponMenu.categories : [];
    const teamWeaponOverlay = document.getElementById("team-weapon-overlay");
    if (!categories.some(category => String(category.id || "") === teamWeaponActiveCategoryId)) {
        teamWeaponActiveCategoryId = String(categories[0]?.id || "");
    }

    teamWeaponOverlay.setAttribute("data-weapon-mode", teamWeaponDraft.mode);

    document.getElementById("team-weapon-title").textContent = `${lobby?.name || `Arena ${teamWeaponDraft.lobbyId}`} Weapon Rules`;
    document.getElementById("team-weapon-subtitle").textContent = "Choose blocked weapons or switch to Allow Only for a whitelist setup.";

    const presetsContainer = document.getElementById("team-weapon-presets");
    presetsContainer.innerHTML = "";
    (teamWeaponMenu.presets || []).forEach(preset => {
        const button = document.createElement("button");
        const isSelectedPreset = isTeamWeaponPresetSelected(preset);
        button.className = `team-weapon-preset-button ${isSelectedPreset ? "selected" : ""}`;

        const label = document.createElement("span");
        label.className = "team-weapon-preset-label";
        label.textContent = String(preset.label || "Preset").toUpperCase();
        button.appendChild(label);

        if (isSelectedPreset) {
            const indicatorTone = getTeamWeaponPresetIndicatorTone(preset);
            if (indicatorTone) {
                const check = document.createElement("span");
                check.className = `team-weapon-preset-check ${indicatorTone}`;
                check.setAttribute("aria-hidden", "true");
                button.appendChild(check);
            }
        }

        button.onclick = function () {
            teamWeaponDraft.mode = String(preset.mode || "restrict");
            teamWeaponDraft.weapons = Array.isArray(preset.weapons) ? [...preset.weapons] : [];
            renderTeamWeaponOverlay();
        };
        presetsContainer.appendChild(button);
    });

    document.getElementById("mode-restrict").classList.toggle("active", teamWeaponDraft.mode === "restrict");
    document.getElementById("mode-allow-only").classList.toggle("active", teamWeaponDraft.mode === "allow_only");
    document.getElementById("team-weapon-help").textContent = teamWeaponDraft.mode === "allow_only"
        ? `Only the selected weapons will remain usable inside this ${arenaLabel}.`
        : `Selected weapons will be blocked inside this ${arenaLabel}.`;

    const tabsContainer = document.getElementById("team-weapon-category-tabs");
    tabsContainer.innerHTML = "";

    categories.forEach(category => {
        const totalWeapons = Array.isArray(category.weapons) ? category.weapons.length : 0;
        const selectedCount = (category.weapons || []).reduce((count, weapon) => {
            return count + (teamWeaponDraft.weapons.includes(String(weapon.code || "")) ? 1 : 0);
        }, 0);

        const button = document.createElement("button");
        button.className = `team-weapon-category-tab ${String(category.id || "") === teamWeaponActiveCategoryId ? "active" : ""}`;
        button.innerHTML = `
            <span class="team-weapon-category-tab-label">${String(category.label || category.id || "Weapons").toUpperCase()}</span>
            <span class="team-weapon-category-tab-count ${selectedCount > 0 ? "active" : ""}">${selectedCount}/${totalWeapons}</span>
        `;
        button.onclick = function () {
            setActiveWeaponCategory(String(category.id || ""));
        };
        tabsContainer.appendChild(button);
    });

    const categoriesContainer = document.getElementById("team-weapon-categories");
    categoriesContainer.innerHTML = "";

    const activeCategory = categories.find(category => String(category.id || "") === teamWeaponActiveCategoryId);
    if (activeCategory) {
        const category = activeCategory;
        const categoryBox = document.createElement("div");
        categoryBox.className = "team-weapon-category";

        const totalWeapons = Array.isArray(category.weapons) ? category.weapons.length : 0;
        const selectedCount = (category.weapons || []).reduce((count, weapon) => {
            return count + (teamWeaponDraft.weapons.includes(String(weapon.code || "")) ? 1 : 0);
        }, 0);
        if (selectedCount > 0) {
            categoryBox.classList.add("has-selection");
        }

        const header = document.createElement("div");
        header.className = "team-weapon-category-header";

        const title = document.createElement("div");
        title.className = "team-weapon-category-title";
        title.textContent = String(category.label || category.id || "Weapons").toUpperCase();
        header.appendChild(title);

        const counter = document.createElement("div");
        counter.className = `team-weapon-category-count ${selectedCount > 0 ? "active" : ""}`;
        counter.textContent = `${selectedCount}/${totalWeapons}`;
        header.appendChild(counter);

        categoryBox.appendChild(header);

        const weaponList = document.createElement("div");
        weaponList.className = "team-weapon-list";

        (category.weapons || []).forEach(weapon => {
            const code = String(weapon.code || "");
            const isSelected = teamWeaponDraft.weapons.includes(code);

            const button = document.createElement("button");
            button.className = `team-weapon-chip ${isSelected ? "selected" : ""}`;
            button.textContent = String(weapon.label || normalizeWeaponLabel(code)).toUpperCase();
            button.onclick = function () {
                toggleWeaponSelection(code);
            };
            weaponList.appendChild(button);
        });

        categoryBox.appendChild(weaponList);
        categoriesContainer.appendChild(categoryBox);
    }

    const selectedCount = teamWeaponDraft.weapons.length;
    document.getElementById("team-weapon-summary").textContent = teamWeaponDraft.mode === "allow_only"
        ? `Allowed weapons selected: ${selectedCount}`
        : `Restricted weapons selected: ${selectedCount}`;
}

function toggleWeaponSelection(code) {
    const current = new Set(teamWeaponDraft.weapons);
    if (current.has(code)) current.delete(code);
    else current.add(code);
    teamWeaponDraft.weapons = Array.from(current);
    renderTeamWeaponOverlay();
}

function setWeaponMode(mode) {
    teamWeaponDraft.mode = mode === "allow_only" ? "allow_only" : "restrict";
    renderTeamWeaponOverlay();
}

function setActiveWeaponCategory(categoryId) {
    teamWeaponActiveCategoryId = String(categoryId || "");
    renderTeamWeaponOverlay();
}

const sortButton = document.getElementById("sort-button");
if (sortButton) {
    sortButton.addEventListener("click", function () {
        isSorted = !isSorted;
        updateLobbyList(currentLobbies, isSorted, { force: true, restoreSavedScroll: true });
        sortButton.textContent = isSorted ? "RESET ORDER" : "SORT BY PLAYERS";
    });
}

const duelHistoryTopButton = document.getElementById("duel-history-top-button");
if (duelHistoryTopButton) {
    duelHistoryTopButton.addEventListener("click", function () {
        openDuelHistoryOverlay();
    });
}

const duelChangeArenaButton = document.getElementById("duel-change-arena-button");
if (duelChangeArenaButton) {
    duelChangeArenaButton.addEventListener("click", function () {
        requestDuelArenaChange();
    });
    renderDuelArenaButton();
}

const duelRequestsToggleButton = document.getElementById("duel-requests-toggle-button");
if (duelRequestsToggleButton) {
    duelRequestsToggleButton.addEventListener("click", function () {
        toggleDuelRequestsPreference();
    });
    renderDuelRequestsToggle();
}

const showPublicButton = document.getElementById("show-public");
if (showPublicButton) {
    showPublicButton.addEventListener("click", function () {
        setLobbyCategory("public");
    });
}

const showPrivateButton = document.getElementById("toggle-private");
if (showPrivateButton) {
    showPrivateButton.addEventListener("click", function () {
        setLobbyCategory("private");
    });
}

const showCustomButton = document.getElementById("toggle-custom");
if (showCustomButton) {
    showCustomButton.addEventListener("click", function () {
        setLobbyCategory("custom");
    });
}

const showTeamButton = document.getElementById("toggle-team");
if (showTeamButton) {
    showTeamButton.addEventListener("click", function () {
        setLobbyCategory("team");
    });
}

const lobbyListScrollElement = getLobbyListElement();
if (lobbyListScrollElement) {
    lobbyListScrollElement.addEventListener("scroll", function () {
        storeLobbyScrollPosition(currentCategory);
    }, { passive: true });
}

function openTeamWeaponRules(lobbyId) {
    fetch(`https://${GetParentResourceName()}/openTeamWeaponRules`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ lobbyId })
    }).catch(() => {
        sendNotification("error", "Weapon Rules", "Failed to open the weapon rules menu.");
    });
}

