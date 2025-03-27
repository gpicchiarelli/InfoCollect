import express from 'express';
import { NetworkMonitor } from './networkMonitor';

const app = express();
const monitor = new NetworkMonitor();

app.get('/status', (req, res) => {
    res.json({
        clientState: monitor.getClientState(),
        hosts: monitor.getHostData(),
    });
});

// Avvio del server
app.listen(3000, () => {
    console.log('Interfaccia Web disponibile su http://localhost:3000');
});

// Esempio di aggiornamento dati
monitor.updateHostData('host1', 120);
monitor.updateHostData('host2', 85);
monitor.setClientState('Syncing');
