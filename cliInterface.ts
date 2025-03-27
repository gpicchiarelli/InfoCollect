import { NetworkMonitor, ClientState } from './networkMonitor';

const monitor = new NetworkMonitor();

// Simulazione di aggiornamenti periodici
setInterval(() => {
    console.clear();
    console.log('--- Stato del Client ---');
    console.log(`Stato: ${monitor.getClientState()}`);
    console.log('--- Host Connessi ---');
    monitor.getHostData().forEach(host => {
        console.log(`Host: ${host.hostName}, Latenza: ${host.latency}ms`);
    });
}, 5000);

// Esempio di aggiornamento dati
monitor.updateHostData('host1', 120);
monitor.updateHostData('host2', 85);
monitor.setClientState(ClientState.SYNCING);
