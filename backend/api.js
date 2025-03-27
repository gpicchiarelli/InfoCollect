const config = require('../config/config');
const fs = require('fs');

// ...existing code...

app.post('/api/setP2P', (req, res) => {
    const { enableP2P } = req.body;
    config.enableP2P = enableP2P;
    fs.writeFileSync('./config/config.js', `module.exports = ${JSON.stringify(config, null, 4)};`);
    res.status(200).send({ message: `Modalità P2P ${enableP2P ? 'abilitata' : 'disabilitata'}.` });
});

// ...existing code...
