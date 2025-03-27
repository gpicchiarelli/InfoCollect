const config = require('../config/config');
const fs = require('fs');
const p2p = require('../lib/p2p');

// ...existing code...

function setP2PMode(enable) {
    config.enableP2P = enable;
    fs.writeFileSync('./config/config.js', `module.exports = ${JSON.stringify(config, null, 4)};`);
    console.log(`Modalità P2P ${enable ? 'abilitata' : 'disabilitata'}.`);
}

// ...existing code...

// Aggiungere un comando CLI per gestire la modalità P2P
const args = process.argv.slice(2);
if (args[0] === 'setP2P') {
    const enable = args[1] === 'true';
    setP2PMode(enable);
}

// Comando per elencare le richieste di peer
if (args[0] === 'listPeerRequests') {
    const requests = p2p.get_peer_requests();
    console.log("Richieste di peer:");
    console.log(requests);
}

// Comando per accettare un peer
if (args[0] === 'acceptPeer') {
    const peerId = args[1];
    if (!peerId) {
        console.error("Errore: specificare l'ID del peer.");
        process.exit(1);
    }
    p2p.accept_peer(peerId);
}

// Comando per rifiutare un peer
if (args[0] === 'rejectPeer') {
    const peerId = args[1];
    if (!peerId) {
        console.error("Errore: specificare l'ID del peer.");
        process.exit(1);
    }
    p2p.reject_peer(peerId);
}

// Comando per elencare i peer accettati
if (args[0] === 'listAcceptedPeers') {
    const peers = p2p.get_accepted_peers();
    console.log("Peer accettati:");
    console.log(peers.join("\n"));
}

// ...existing code...
