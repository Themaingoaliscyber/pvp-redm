window.addEventListener('message', function(event) {
    if (event.data.action === 'addKill') {
        addKillToFeed(
            event.data.killer,
            event.data.victim,
            event.data.distance || "0M",
            event.data.headshot || false
        );
    }
});

function getDistanceClass(distanceValue) {
    const dist = parseInt(distanceValue.replace('M', '')) || 0;
    if (dist < 20) return 'distance-close';
    if (dist < 50) return 'distance-mid';
    return 'distance-far';
}

function addKillToFeed(killer, victim, distance = "0M", headshot = false) {
    const killfeed = document.getElementById('killfeed');
    const killElement = document.createElement('div');
    killElement.className = 'kill';

    // 🟩 Clasă pentru distanță
    const distanceClass = getDistanceClass(distance);
    const distanceHTML = `<span class="kill-distance ${distanceClass}">${distance}</span>`;

    // 🔫 Iconiță armă
    const weaponIcon = `<img src="kill.png" class="weapon-icon">`;

    // 🧠 Killer name sau "Suicide"
    const killerHTML = killer && killer.trim() !== ""
        ? `<span class="killer">${killer}</span>`
        : `<span class="killer">Suicide</span>`;

    // ✅ Conținut killfeed
    killElement.innerHTML = `
        ${killerHTML}
        ${weaponIcon}
        <span class="victim">${victim}</span>
        ${distanceHTML}
    `;

    // Adaugă la începutul feedului
    killfeed.insertBefore(killElement, killfeed.firstChild);

    // Limită la 5 intrări
    if (killfeed.children.length > 5) {
        killfeed.removeChild(killfeed.lastChild);
    }

    // Șterge după 5 secunde
    setTimeout(() => {
        if (killElement && killElement.parentNode) {
            killElement.parentNode.removeChild(killElement);
        }
    }, 5000);
}
