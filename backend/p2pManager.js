const config = require('../config/config');

// ...existing code...

function initializeP2P() {
    if (!config.enableP2P) {
        console.log("Modalità P2P disabilitata.");
        return;
    }
    // ...codice per inizializzare la modalità P2P...
}

// ...existing code...
module.exports = { initializeP2P };
