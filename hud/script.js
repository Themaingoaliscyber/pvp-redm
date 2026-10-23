const GRID_SIZE = 24;
const ALIGN_SNAP_DISTANCE = 10;
const RESOURCE_NAME = typeof GetParentResourceName === "function"
    ? GetParentResourceName()
    : "hud";
const CARD_OFFSETS_KEY = "hudCardOffsetsV1";
const GRID_VISIBILITY_KEY = "hudEditorGridVisibleV1";
const CARD_VISIBILITY_KEY = "hudCardVisibilityV1";
const EDIT_PANEL_POSITION_KEY = "hudEditorPanelPositionV2";
const EXTERNAL_CARD_POSITIONS_KEY = "hudExternalCardPositionsV1";

const state = {
    hudVisible: true,
    rankVisible: true,
    editMode: false,
    gridVisible: true,
    statsLoaded: false,
    metaLoaded: false,
    rankLoaded: false,
    cardVisibility: {},
    ranks: [],
    lastRankSnapshot: null,
    cardOffsets: {},
    externalCardPositions: {},
    dragging: null,
    externalDragging: null,
    dragFrame: null,
    externalFrame: null,
    editorPanelPosition: null,
    panelDragging: null,
    panelFrame: null
};

const rankClasses = [
    "rank-greenhorn",
    "rank-gunslinger",
    "rank-outlawofthewest",
    "rank-bountyhunter",
    "rank-legendofthewest"
];

const elements = {
    body: document.body,
    root: document.getElementById("hud-root"),
    overlay: document.getElementById("edit-overlay"),
    editorPanel: document.getElementById("edit-panel"),
    editorPanelHandle: document.querySelector(".edit-header"),
    grid: document.querySelector(".edit-grid"),
    statsRow: document.getElementById("stats-row"),
    rankStack: document.getElementById("rank-stack"),
    metaStack: document.getElementById("meta-stack"),
    externalTopPlayersCard: document.getElementById("external-topplayers-card"),
    gridButton: document.getElementById("toggle-grid"),
    resetButton: document.getElementById("reset-position"),
    doneButton: document.getElementById("done-editing"),
    visibleCount: document.getElementById("visible-count"),
    gridState: document.getElementById("grid-state"),
    elementCount: document.getElementById("element-count"),
    kills: document.getElementById("kills"),
    deaths: document.getElementById("deaths"),
    kd: document.getElementById("kd"),
    playerCount: document.getElementById("playerCount"),
    playerId: document.getElementById("playerId"),
    rankCard: document.getElementById("rank-card"),
    rankName: document.getElementById("rank-name"),
    xpText: document.getElementById("xp-text"),
    xpFill: document.getElementById("xp-fill")
};

const editableCards = Array.from(document.querySelectorAll("[data-editor-card]"));
const externalCards = Array.from(document.querySelectorAll("[data-external-editor-card]"));
const toggleButtons = Array.from(document.querySelectorAll("[data-toggle-card]"));

function postNui(endpoint, payload = {}) {
    return fetch(`https://${RESOURCE_NAME}/${endpoint}`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json; charset=UTF-8"
        },
        body: JSON.stringify(payload)
    }).catch(() => {});
}

function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
}

function snapPixel(value) {
    return Math.round(value / GRID_SIZE) * GRID_SIZE;
}

function getProjectedRect(baseRect, offset) {
    return {
        left: baseRect.left + offset.x,
        top: baseRect.top + offset.y,
        width: baseRect.width,
        height: baseRect.height
    };
}

function getCardBaseRect(card, offset) {
    const rect = card.getBoundingClientRect();

    return {
        left: rect.left - offset.x,
        top: rect.top - offset.y,
        width: rect.width,
        height: rect.height
    };
}

function getVisibleCardRect(card) {
    if (
        card.hidden
        || card.closest("[hidden]")
        || card.closest(".is-section-hidden")
        || card.classList.contains("is-user-hidden")
    ) {
        return null;
    }

    const rect = card.getBoundingClientRect();

    if (rect.width <= 0 || rect.height <= 0) {
        return null;
    }

    return rect;
}

function getOtherCardRects(card) {
    return editableCards
        .filter((otherCard) => otherCard !== card)
        .map(getVisibleCardRect)
        .filter(Boolean);
}

function alignRectAxis(projectedRect, otherRects, axis) {
    const isHorizontal = axis === "x";
    const startKey = isHorizontal ? "left" : "top";
    const sizeKey = isHorizontal ? "width" : "height";
    const start = projectedRect[startKey];
    const size = projectedRect[sizeKey];
    const anchorRatios = [0, 0.5, 1];
    let bestDelta = 0;
    let bestDistance = ALIGN_SNAP_DISTANCE + 1;

    for (const otherRect of otherRects) {
        const otherStart = isHorizontal ? otherRect.left : otherRect.top;
        const otherSize = isHorizontal ? otherRect.width : otherRect.height;

        anchorRatios.forEach((ratio) => {
            const movingAnchor = start + (size * ratio);
            const targetAnchor = otherStart + (otherSize * ratio);
            const distance = Math.abs(movingAnchor - targetAnchor);

            if (distance < bestDistance && distance <= ALIGN_SNAP_DISTANCE) {
                bestDistance = distance;
                bestDelta = targetAnchor - movingAnchor;
            }
        });
    }

    return {
        aligned: bestDistance <= ALIGN_SNAP_DISTANCE,
        value: start + bestDelta
    };
}

function resolveRectAxis(projectedRect, otherRects, axis, snapToGrid) {
    const startKey = axis === "x" ? "left" : "top";
    const directAlignment = alignRectAxis(projectedRect, otherRects, axis);

    if (directAlignment.aligned) {
        return directAlignment.value;
    }

    if (!snapToGrid) {
        return projectedRect[startKey];
    }

    const snappedRect = {
        ...projectedRect,
        [startKey]: snapPixel(projectedRect[startKey])
    };
    const snappedAlignment = alignRectAxis(snappedRect, otherRects, axis);

    return snappedAlignment.aligned ? snappedAlignment.value : snappedRect[startKey];
}

function getAlignedCardOffset(card, offset, options = {}) {
    const baseRect = options.baseRect || getCardBaseRect(card, offset);
    const otherRects = getOtherCardRects(card);
    let projectedRect = getProjectedRect(baseRect, offset);

    projectedRect.left = resolveRectAxis(projectedRect, otherRects, "x", options.snapToGrid);
    projectedRect.top = resolveRectAxis(projectedRect, otherRects, "y", options.snapToGrid);

    return {
        x: Math.round(projectedRect.left - baseRect.left),
        y: Math.round(projectedRect.top - baseRect.top)
    };
}

function cleanRankName(rankName) {
    return String(rankName || "greenhorn")
        .toLowerCase()
        .replace(/\s+/g, "")
        .replace(/[^a-z0-9]/g, "");
}

function formatNumber(value) {
    return Number(value || 0).toLocaleString("en-US");
}

function loadCardOffsets() {
    try {
        const raw = localStorage.getItem(CARD_OFFSETS_KEY);
        if (!raw) {
            return {};
        }

        const parsed = JSON.parse(raw);
        return typeof parsed === "object" && parsed ? parsed : {};
    } catch {
        return {};
    }
}

function saveCardOffsets() {
    localStorage.setItem(CARD_OFFSETS_KEY, JSON.stringify(state.cardOffsets));
}

function loadGridVisibility() {
    return localStorage.getItem(GRID_VISIBILITY_KEY) !== "false";
}

function saveGridVisibility() {
    localStorage.setItem(GRID_VISIBILITY_KEY, String(state.gridVisible));
}

function setGridVisibility(visible) {
    state.gridVisible = Boolean(visible);
    elements.grid.classList.toggle("is-hidden", !state.gridVisible);
    elements.gridButton.classList.toggle("is-off", !state.gridVisible);
    elements.gridButton.setAttribute("aria-pressed", state.gridVisible ? "true" : "false");
    elements.gridButton.setAttribute("aria-label", state.gridVisible ? "Hide grid" : "Show grid");
    elements.gridButton.dataset.tooltip = state.gridVisible ? "Hide grid" : "Show grid";

    if (elements.gridState) {
        elements.gridState.textContent = state.gridVisible ? "On" : "Off";
    }

    saveGridVisibility();
}

function loadCardVisibility() {
    try {
        const raw = localStorage.getItem(CARD_VISIBILITY_KEY);
        if (!raw) {
            return {};
        }

        const parsed = JSON.parse(raw);
        return typeof parsed === "object" && parsed ? parsed : {};
    } catch {
        return {};
    }
}

function saveCardVisibility() {
    localStorage.setItem(CARD_VISIBILITY_KEY, JSON.stringify(state.cardVisibility));
}

function isCardVisible(key) {
    return state.cardVisibility[key] !== false;
}

function getVisibleCardCount() {
    return toggleButtons.filter((button) => isCardVisible(button.dataset.toggleCard)).length;
}

function updateElementCounters() {
    const visibleCards = getVisibleCardCount();
    const totalCards = toggleButtons.length;

    if (elements.visibleCount) {
        elements.visibleCount.textContent = String(visibleCards);
    }

    if (elements.elementCount) {
        elements.elementCount.textContent = `${visibleCards} / ${totalCards}`;
    }
}

function hasVisibleCards(keys) {
    return keys.some(isCardVisible);
}

function setSectionLayoutVisibility(section, visible) {
    section.hidden = false;
    section.classList.toggle("is-section-hidden", !visible);
    section.setAttribute("aria-hidden", visible ? "false" : "true");
}

function syncSectionVisibility() {
    const canShowPendingCards = state.editMode;
    const statsVisible = state.hudVisible
        && hasVisibleCards(["kills", "deaths", "kd"])
        && (state.statsLoaded || canShowPendingCards);
    const metaVisible = state.hudVisible
        && hasVisibleCards(["online", "id"])
        && (state.metaLoaded || canShowPendingCards);
    const rankVisible = state.rankVisible
        && hasVisibleCards(["rank", "xp"])
        && (state.rankLoaded || canShowPendingCards);

    setSectionLayoutVisibility(elements.statsRow, statsVisible);
    setSectionLayoutVisibility(elements.metaStack, metaVisible);
    setSectionLayoutVisibility(elements.rankStack, rankVisible);
    syncRootVisibility();
}

function applyCardVisibility() {
    editableCards.forEach((card) => {
        const visible = isCardVisible(card.dataset.editorCard);
        card.hidden = false;
        card.classList.toggle("is-user-hidden", !visible);
        card.setAttribute("aria-hidden", visible ? "false" : "true");
    });

    toggleButtons.forEach((button) => {
        const key = button.dataset.toggleCard;
        const label = button.dataset.toggleLabel || key;
        const visible = isCardVisible(key);
        const nameElement = button.querySelector(".toggle-name");
        const stateElement = button.querySelector(".toggle-state");

        button.classList.toggle("is-off", !visible);
        button.setAttribute("aria-pressed", visible ? "true" : "false");
        button.setAttribute("aria-label", `${visible ? "Hide" : "Show"} ${label}`);

        if (nameElement) {
            nameElement.textContent = label;
        } else {
            button.textContent = label;
        }

        if (stateElement) {
            stateElement.textContent = visible ? "On" : "Off";
        }
    });

    updateElementCounters();
    syncSectionVisibility();
}

function setCardVisibility(key, visible) {
    state.cardVisibility[key] = Boolean(visible);
    saveCardVisibility();
    applyCardVisibility();
}

function getCardOffset(key) {
    const offset = state.cardOffsets[key];
    if (!offset) {
        return { x: 0, y: 0 };
    }

    return {
        x: Number(offset.x) || 0,
        y: Number(offset.y) || 0
    };
}

function applyCardOffset(card) {
    const key = card.dataset.editorCard;
    const offset = getCardOffset(key);
    card.style.transform = `translate3d(${offset.x}px, ${offset.y}px, 0)`;
}

function applyAllCardOffsets() {
    editableCards.forEach(applyCardOffset);
}

function scheduleDraggedCardRender() {
    if (state.dragFrame !== null) {
        return;
    }

    state.dragFrame = requestAnimationFrame(() => {
        state.dragFrame = null;

        if (state.dragging?.card) {
            applyCardOffset(state.dragging.card);
        }
    });
}

function cancelDraggedCardRender() {
    if (state.dragFrame === null) {
        return;
    }

    cancelAnimationFrame(state.dragFrame);
    state.dragFrame = null;
}

function resetCardOffsets() {
    state.cardOffsets = {};
    localStorage.removeItem(CARD_OFFSETS_KEY);
    applyAllCardOffsets();
}

function normalizeExternalCardPosition(position) {
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

function loadExternalCardPositions() {
    try {
        const raw = localStorage.getItem(EXTERNAL_CARD_POSITIONS_KEY);
        if (!raw) {
            return {};
        }

        const parsed = JSON.parse(raw);
        if (!parsed || typeof parsed !== "object") {
            return {};
        }

        return Object.entries(parsed).reduce((positions, [key, position]) => {
            const normalized = normalizeExternalCardPosition(position);
            if (normalized) {
                positions[key] = normalized;
            }

            return positions;
        }, {});
    } catch {
        return {};
    }
}

function saveExternalCardPositions() {
    localStorage.setItem(EXTERNAL_CARD_POSITIONS_KEY, JSON.stringify(state.externalCardPositions));
}

function getExternalCardSize(card) {
    const rect = card.getBoundingClientRect();

    return {
        width: rect.width || 232,
        height: rect.height || 142
    };
}

function getDefaultExternalCardPosition(card) {
    const key = card.dataset.externalEditorCard;
    const size = getExternalCardSize(card);

    if (key === "topplayers") {
        return {
            x: clamp(((window.innerWidth - size.width - 14) / window.innerWidth) * 100, 0, 100),
            y: clamp((145 / window.innerHeight) * 100, 0, 100)
        };
    }

    return { x: 50, y: 50 };
}

function getExternalCardPosition(card) {
    const key = card.dataset.externalEditorCard;
    return state.externalCardPositions[key] || getDefaultExternalCardPosition(card);
}

function getExternalCardPixelPosition(card) {
    const position = getExternalCardPosition(card);
    const size = getExternalCardSize(card);
    const maxLeft = Math.max(0, window.innerWidth - size.width);
    const maxTop = Math.max(0, window.innerHeight - size.height);

    return {
        left: clamp((position.x / 100) * window.innerWidth, 0, maxLeft),
        top: clamp((position.y / 100) * window.innerHeight, 0, maxTop)
    };
}

function applyExternalCardPosition(card) {
    const pixelPosition = getExternalCardPixelPosition(card);
    card.style.left = `${Math.round(pixelPosition.left)}px`;
    card.style.top = `${Math.round(pixelPosition.top)}px`;
}

function applyAllExternalCardPositions() {
    externalCards.forEach(applyExternalCardPosition);
}

function setExternalCardPosition(key, position, options = {}) {
    const normalized = normalizeExternalCardPosition(position);

    if (normalized) {
        state.externalCardPositions[key] = normalized;
    } else {
        delete state.externalCardPositions[key];
    }

    if (options.persist !== false) {
        saveExternalCardPositions();
    }

    externalCards
        .filter((card) => card.dataset.externalEditorCard === key)
        .forEach(applyExternalCardPosition);
}

function publishExternalCardPosition(key, options = {}) {
    postNui("setExternalHudPosition", {
        key,
        position: state.externalCardPositions[key] || null,
        persist: options.persist === true
    });
}

function scheduleExternalCardRender() {
    if (state.externalFrame !== null) {
        return;
    }

    state.externalFrame = requestAnimationFrame(() => {
        state.externalFrame = null;

        if (state.externalDragging?.card) {
            applyExternalCardPosition(state.externalDragging.card);
            publishExternalCardPosition(state.externalDragging.key, { persist: false });
        }
    });
}

function cancelExternalCardRender() {
    if (state.externalFrame === null) {
        return;
    }

    cancelAnimationFrame(state.externalFrame);
    state.externalFrame = null;
}

function resetExternalCardPositions() {
    state.externalCardPositions = {};
    localStorage.removeItem(EXTERNAL_CARD_POSITIONS_KEY);
    applyAllExternalCardPositions();
    postNui("resetExternalHudLayout", { key: "topplayers" });
}

function resetCardVisibility() {
    state.cardVisibility = {};
    localStorage.removeItem(CARD_VISIBILITY_KEY);
    applyCardVisibility();
}

function loadEditorPanelPosition() {
    try {
        const raw = localStorage.getItem(EDIT_PANEL_POSITION_KEY);
        if (!raw) {
            return null;
        }

        const parsed = JSON.parse(raw);
        if (!parsed || typeof parsed !== "object") {
            return null;
        }

        const x = Number(parsed.x);
        const y = Number(parsed.y);

        if (!Number.isFinite(x) || !Number.isFinite(y)) {
            return null;
        }

        return { x, y };
    } catch {
        return null;
    }
}

function saveEditorPanelPosition() {
    if (!state.editorPanelPosition) {
        localStorage.removeItem(EDIT_PANEL_POSITION_KEY);
        return;
    }

    localStorage.setItem(EDIT_PANEL_POSITION_KEY, JSON.stringify(state.editorPanelPosition));
}

function getClampedEditorPanelPosition(position) {
    const rect = elements.editorPanel.getBoundingClientRect();
    const margin = 8;
    const maxX = Math.max(margin, window.innerWidth - rect.width - margin);
    const maxY = Math.max(margin, window.innerHeight - rect.height - margin);

    return {
        x: clamp(position.x, margin, maxX),
        y: clamp(position.y, margin, maxY)
    };
}

function applyEditorPanelPosition() {
    if (!state.editorPanelPosition) {
        elements.editorPanel.style.left = "";
        elements.editorPanel.style.top = "";
        elements.editorPanel.style.bottom = "";
        elements.editorPanel.style.transform = "";
        return;
    }

    state.editorPanelPosition = getClampedEditorPanelPosition(state.editorPanelPosition);
    elements.editorPanel.style.left = `${state.editorPanelPosition.x}px`;
    elements.editorPanel.style.top = `${state.editorPanelPosition.y}px`;
    elements.editorPanel.style.bottom = "auto";
    elements.editorPanel.style.transform = "none";
}

function scheduleEditorPanelRender() {
    if (state.panelFrame !== null) {
        return;
    }

    state.panelFrame = requestAnimationFrame(() => {
        state.panelFrame = null;
        applyEditorPanelPosition();
    });
}

function cancelEditorPanelRender() {
    if (state.panelFrame === null) {
        return;
    }

    cancelAnimationFrame(state.panelFrame);
    state.panelFrame = null;
}

function syncRootVisibility() {
    const hasHudSection = state.hudVisible
        && (
            (state.statsLoaded && hasVisibleCards(["kills", "deaths", "kd"]))
            || (state.metaLoaded && hasVisibleCards(["online", "id"]))
        );
    const hasRankSection = state.rankVisible
        && state.rankLoaded
        && hasVisibleCards(["rank", "xp"]);
    const hasVisibleSection = hasHudSection || hasRankSection || state.editMode;
    elements.root.classList.toggle("is-empty", !hasVisibleSection);
}

function setHudVisibility(visible) {
    state.hudVisible = Boolean(visible);
    syncSectionVisibility();
}

function setRankVisibility(visible) {
    state.rankVisible = Boolean(visible);
    syncSectionVisibility();
}

function setEditMode(enabled) {
    state.editMode = Boolean(enabled);
    elements.body.classList.toggle("is-editing", state.editMode);
    elements.overlay.classList.toggle("is-active", state.editMode);
    elements.overlay.setAttribute("aria-hidden", state.editMode ? "false" : "true");
    elements.root.classList.toggle("is-editing", state.editMode);
    editableCards.forEach((card) => card.classList.toggle("is-editable", state.editMode));
    externalCards.forEach((card) => {
        card.hidden = !state.editMode;
        card.classList.toggle("is-editable", state.editMode);
        applyExternalCardPosition(card);
    });

    if (!state.editMode) {
        cancelDraggedCardRender();
        cancelExternalCardRender();
        state.dragging = null;
        state.externalDragging = null;
        state.panelDragging = null;
        elements.body.classList.remove("is-dragging-card", "is-dragging-external", "is-dragging-panel");
        editableCards.forEach((card) => card.classList.remove("dragging"));
        externalCards.forEach((card) => card.classList.remove("dragging"));
        elements.editorPanel.classList.remove("dragging");
    }

    syncSectionVisibility();
}

function updateStats(data) {
    if (data.kills === undefined || data.deaths === undefined) {
        return;
    }

    state.statsLoaded = true;
    elements.kills.textContent = formatNumber(data.kills);
    elements.deaths.textContent = formatNumber(data.deaths);
    elements.kd.textContent = Number(data.kd || 0).toFixed(2);
    syncSectionVisibility();
}

function updateMeta(data) {
    state.metaLoaded = true;
    elements.playerCount.textContent = formatNumber(data.count);
    elements.playerId.textContent = data.id ?? "-";
    syncSectionVisibility();
}

function getNextRankXP(ranks, currentXP) {
    if (!Array.isArray(ranks) || ranks.length === 0) {
        return currentXP;
    }

    for (const rank of ranks) {
        if (currentXP < Number(rank.xp || 0)) {
            return Number(rank.xp || 0);
        }
    }

    const lastRank = ranks[ranks.length - 1];
    return Number(lastRank?.xp || currentXP);
}

function applyRankTheme(rankName) {
    const cleanRank = cleanRankName(rankName);
    elements.rankCard.classList.remove(...rankClasses);
    elements.rankCard.classList.add(`rank-${cleanRank}`);
    elements.body.dataset.rank = cleanRank;
}

function updateRank(data) {
    if (Array.isArray(data.ranks) && data.ranks.length > 0) {
        state.ranks = data.ranks;
    }

    const rankName = data.rank || "Greenhorn";
    const currentXP = Number(data.xp || 0);
    const nextXP = Number(data.nextXP || 0) > currentXP
        ? Number(data.nextXP)
        : getNextRankXP(state.ranks, currentXP);
    const lastRankName = state.ranks.length > 0
        ? state.ranks[state.ranks.length - 1].name
        : "Legend of the West";
    const isMaxRank = cleanRankName(rankName) === cleanRankName(lastRankName);
    const percentage = isMaxRank || nextXP <= 0
        ? 100
        : Math.max(0, Math.min((currentXP / nextXP) * 100, 100));
    const snapshot = `${cleanRankName(rankName)}|${currentXP}|${nextXP}|${percentage}`;

    if (state.lastRankSnapshot === snapshot && state.rankLoaded) {
        return;
    }

    state.lastRankSnapshot = snapshot;
    state.rankLoaded = true;

    elements.rankName.textContent = rankName;
    elements.xpText.textContent = isMaxRank
        ? `${formatNumber(currentXP)} XP (MAX)`
        : `${formatNumber(currentXP)} / ${formatNumber(nextXP)} XP`;
    elements.xpFill.style.width = `${percentage}%`;
    applyRankTheme(rankName);
    elements.rankStack.classList.remove("is-pending");
    syncSectionVisibility();
}

function beginCardDrag(event) {
    if (!state.editMode || event.button !== 0) {
        return;
    }

    const card = event.currentTarget;
    const key = card.dataset.editorCard;
    const startOffset = getCardOffset(key);

    state.dragging = {
        key,
        card,
        pointerId: event.pointerId,
        startX: startOffset.x,
        startY: startOffset.y,
        pointerX: event.clientX,
        pointerY: event.clientY
    };

    if (card.setPointerCapture) {
        card.setPointerCapture(event.pointerId);
    }

    elements.body.classList.add("is-dragging-card");
    card.classList.add("dragging");
    event.preventDefault();
}

function moveCardDrag(event) {
    if (!state.dragging) {
        return;
    }

    const deltaX = event.clientX - state.dragging.pointerX;
    const deltaY = event.clientY - state.dragging.pointerY;
    const nextX = Math.round(state.dragging.startX + deltaX);
    const nextY = Math.round(state.dragging.startY + deltaY);

    state.cardOffsets[state.dragging.key] = { x: nextX, y: nextY };
    scheduleDraggedCardRender();
    event.preventDefault();
}

function endCardDrag(event) {
    if (!state.dragging) {
        return;
    }

    cancelDraggedCardRender();

    const { card, pointerId } = state.dragging;

    if (card) {
        applyCardOffset(card);
        card.classList.remove("dragging");

        if (card.releasePointerCapture && card.hasPointerCapture?.(pointerId) && event?.pointerId === pointerId) {
            card.releasePointerCapture(pointerId);
        }
    }

    state.dragging = null;
    elements.body.classList.remove("is-dragging-card");
    saveCardOffsets();
}

function beginExternalCardDrag(event) {
    if (!state.editMode || event.button !== 0) {
        return;
    }

    const card = event.currentTarget;
    const key = card.dataset.externalEditorCard;
    const startPosition = getExternalCardPixelPosition(card);

    state.externalDragging = {
        key,
        card,
        pointerId: event.pointerId,
        startLeft: startPosition.left,
        startTop: startPosition.top,
        pointerX: event.clientX,
        pointerY: event.clientY
    };

    if (card.setPointerCapture) {
        card.setPointerCapture(event.pointerId);
    }

    elements.body.classList.add("is-dragging-external");
    card.classList.add("dragging");
    event.preventDefault();
}

function moveExternalCardDrag(event) {
    if (!state.externalDragging) {
        return;
    }

    const { card, key } = state.externalDragging;
    const size = getExternalCardSize(card);
    const deltaX = event.clientX - state.externalDragging.pointerX;
    const deltaY = event.clientY - state.externalDragging.pointerY;
    const maxLeft = Math.max(0, window.innerWidth - size.width);
    const maxTop = Math.max(0, window.innerHeight - size.height);
    const nextLeft = clamp(state.externalDragging.startLeft + deltaX, 0, maxLeft);
    const nextTop = clamp(state.externalDragging.startTop + deltaY, 0, maxTop);

    state.externalCardPositions[key] = {
        x: clamp((nextLeft / window.innerWidth) * 100, 0, 100),
        y: clamp((nextTop / window.innerHeight) * 100, 0, 100)
    };

    scheduleExternalCardRender();
    event.preventDefault();
}

function endExternalCardDrag(event) {
    if (!state.externalDragging) {
        return;
    }

    cancelExternalCardRender();

    const { card, key, pointerId } = state.externalDragging;

    if (card) {
        applyExternalCardPosition(card);
        card.classList.remove("dragging");

        if (card.releasePointerCapture && card.hasPointerCapture?.(pointerId) && event?.pointerId === pointerId) {
            card.releasePointerCapture(pointerId);
        }
    }

    state.externalDragging = null;
    elements.body.classList.remove("is-dragging-external");
    saveExternalCardPositions();
    publishExternalCardPosition(key, { persist: true });
}

function beginEditorPanelDrag(event) {
    const clickedButton = event.target instanceof Element && event.target.closest("button");

    if (!state.editMode || event.button !== 0 || clickedButton) {
        return;
    }

    const rect = elements.editorPanel.getBoundingClientRect();
    state.editorPanelPosition = getClampedEditorPanelPosition({
        x: rect.left,
        y: rect.top
    });
    applyEditorPanelPosition();

    state.panelDragging = {
        pointerId: event.pointerId,
        startX: state.editorPanelPosition.x,
        startY: state.editorPanelPosition.y,
        pointerX: event.clientX,
        pointerY: event.clientY
    };

    if (elements.editorPanelHandle.setPointerCapture) {
        elements.editorPanelHandle.setPointerCapture(event.pointerId);
    }

    elements.body.classList.add("is-dragging-panel");
    elements.editorPanel.classList.add("dragging");
    event.preventDefault();
}

function moveEditorPanelDrag(event) {
    if (!state.panelDragging) {
        return;
    }

    const deltaX = event.clientX - state.panelDragging.pointerX;
    const deltaY = event.clientY - state.panelDragging.pointerY;

    state.editorPanelPosition = getClampedEditorPanelPosition({
        x: state.panelDragging.startX + deltaX,
        y: state.panelDragging.startY + deltaY
    });
    scheduleEditorPanelRender();
    event.preventDefault();
}

function endEditorPanelDrag(event) {
    if (!state.panelDragging) {
        return;
    }

    cancelEditorPanelRender();
    applyEditorPanelPosition();

    if (
        elements.editorPanelHandle.releasePointerCapture
        && elements.editorPanelHandle.hasPointerCapture?.(state.panelDragging.pointerId)
        && event?.pointerId === state.panelDragging.pointerId
    ) {
        elements.editorPanelHandle.releasePointerCapture(state.panelDragging.pointerId);
    }

    state.panelDragging = null;
    elements.body.classList.remove("is-dragging-panel");
    elements.editorPanel.classList.remove("dragging");
    saveEditorPanelPosition();
}

editableCards.forEach((card) => {
    card.addEventListener("pointerdown", beginCardDrag);
});

externalCards.forEach((card) => {
    card.addEventListener("pointerdown", beginExternalCardDrag);
});

elements.editorPanelHandle.addEventListener("pointerdown", beginEditorPanelDrag);

toggleButtons.forEach((button) => {
    button.addEventListener("click", () => {
        const key = button.dataset.toggleCard;
        setCardVisibility(key, !isCardVisible(key));
    });
});

window.addEventListener("pointermove", moveCardDrag);
window.addEventListener("pointermove", moveExternalCardDrag);
window.addEventListener("pointermove", moveEditorPanelDrag);
window.addEventListener("pointerup", endCardDrag);
window.addEventListener("pointerup", endExternalCardDrag);
window.addEventListener("pointerup", endEditorPanelDrag);
window.addEventListener("pointercancel", endCardDrag);
window.addEventListener("pointercancel", endExternalCardDrag);
window.addEventListener("pointercancel", endEditorPanelDrag);

document.addEventListener("selectstart", (event) => {
    if (state.editMode) {
        event.preventDefault();
    }
});

document.addEventListener("dragstart", (event) => {
    if (state.editMode) {
        event.preventDefault();
    }
});

window.addEventListener("resize", () => {
    applyAllExternalCardPositions();

    if (!state.editorPanelPosition) {
        return;
    }

    applyEditorPanelPosition();
    saveEditorPanelPosition();
});

elements.resetButton.addEventListener("click", () => {
    resetCardOffsets();
    resetExternalCardPositions();
    resetCardVisibility();
});

elements.gridButton.addEventListener("click", () => {
    setGridVisibility(!state.gridVisible);
});

elements.doneButton.addEventListener("click", () => {
    setEditMode(false);
    postNui("closeHudEditor");
});

window.addEventListener("keydown", (event) => {
    if (!state.editMode) {
        return;
    }

    if (event.key === "Escape") {
        setEditMode(false);
        postNui("closeHudEditor");
    }
});

window.addEventListener("message", (event) => {
    const data = event.data || {};
    const action = data.action || data.type;

    switch (action) {
        case "updateHUD":
            updateStats(data);
            break;
        case "updatePlayerCount":
            updateMeta(data);
            break;
        case "updateRank":
        case "update_rank":
            updateRank(data);
            break;
        case "toggleHUD":
            setHudVisibility(data.visible);
            break;
        case "toggleRankHUD":
            setRankVisibility(data.visible);
            break;
        case "setEditMode":
            setEditMode(data.enabled);
            break;
        case "setExternalHudPosition":
            setExternalCardPosition(data.key, data.position);
            break;
        default:
            break;
    }
});

state.cardOffsets = loadCardOffsets();
state.externalCardPositions = loadExternalCardPositions();
state.gridVisible = loadGridVisibility();
state.cardVisibility = loadCardVisibility();
state.editorPanelPosition = loadEditorPanelPosition();
applyAllCardOffsets();
applyAllExternalCardPositions();
applyEditorPanelPosition();
setGridVisibility(state.gridVisible);
applyCardVisibility();

setHudVisibility(true);
setRankVisibility(true);
