window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === "showLobbyCommands") {
        showLobbyCommands();
    } else if (data.action === "hideLobbyCommands") {
        hideLobbyCommands();
    }
});

let commandsVisible = false;

function showLobbyCommands() {
    if (commandsVisible) return;
    const lobbyElement = document.getElementById("lobbyCommands");
    if (!lobbyElement) return;

    commandsVisible = true;
    lobbyElement.innerHTML = "";

    const commands = [
        { cmd: "/LOBBY", desc: " ↪ Access the list of lobbies." },
        { cmd: "/LEAVE", desc: " ↪ Leave the arena." },
        { cmd: "/SPAWN", desc: " ↪ Return to the SafeZone." },
        { cmd: "/NC", desc: " ↪ Activate noclip." },
        { cmd: "/SETTINGS", desc: " ↪ Toggle UI elements." },
       /// { cmd: "/CROSSHAIR", desc: " ↪ Enable custom crosshair overlay." }
    ];

    commands.forEach(({ cmd, desc }) => {
        const className = "cmd-" + cmd.replace("/", "").toLowerCase();
        const el = document.createElement("div");
        el.className = `lobby-command ${className}`;
        el.innerHTML = `<strong>${cmd}</strong> <span>${desc}</span>`;
        lobbyElement.appendChild(el);
    });

    lobbyElement.style.display = "flex";
}

function hideLobbyCommands() {
    if (!commandsVisible) return;
    const lobbyElement = document.getElementById("lobbyCommands");
    if (lobbyElement) {
        lobbyElement.style.display = "none";
        commandsVisible = false;
    }
}
