const labels = {
    hud: "HUD",
    notify: "NOTIFY",
    killfeed: "KILLFEED",
    headshotsound: "HEADSHOT SOUND",
    topplayers: "LOBBY TOP 3",
    lobbycommands: "QUICK COMMANDS"
};

const trackedOptions = ["hud", "notify", "killfeed", "topplayers", "lobbycommands"];

window.addEventListener("message", function(event) {
    if (event.data.type === "open") {
        document.body.style.display = "flex";
        updateAllButtons(event.data);
    } else if (event.data.type === "statusUpdate") {
        updateAllButtons(event.data);
    }
});

function post(endpoint, payload = {}) {
    fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
    });
}

function updateAllButtons(data) {
    trackedOptions.forEach(function(option) {
        if (typeof data[option] !== "undefined") {
            updateButton(option, Boolean(data[option]));
        }
    });
}

function toggle(option) {
    post("toggleOption", { option });
}

function enableAll() {
    post("enableAll");
}

function disableAll() {
    post("disableAll");
}

function closeUI() {
    post("close");
    document.body.style.display = "none";
}

function updateButton(option, state) {
    const el = document.getElementById(`${option}Btn`);
    if (!el) return;

    const label = labels[option] || option.toUpperCase();
    const labelEl = el.querySelector(".label");
    const stateEl = el.querySelector(".state");

    if (labelEl) {
        labelEl.textContent = label;
    }

    if (stateEl) {
        stateEl.textContent = state ? "ON" : "OFF";
    }

    el.classList.remove("on", "off");
    el.classList.add(state ? "on" : "off");
    el.setAttribute("aria-pressed", state ? "true" : "false");
}

document.addEventListener("keydown", function(event) {
    if (event.key === "Escape") {
        closeUI();
    }
});
