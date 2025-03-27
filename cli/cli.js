const config = require('../config/config');
const fs = require('fs');

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

// ...existing code...
