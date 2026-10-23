window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === "showJoinBanner") {
        showLobbyBanner(data.name, data.messageType || "join", data.lobby);
    }
});

// 🎬 Banner cinematic universal: join, leave, switch
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

    banner.innerHTML = `
        <span class="join-name">${playerName}</span>
        <span class="${className}">${message}</span>
    `;

    document.getElementById("hud")?.appendChild(banner);

    setTimeout(() => {
        banner.remove();
    }, 5000);
}
