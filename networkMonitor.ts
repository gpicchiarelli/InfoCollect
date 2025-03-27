import { EventEmitter } from 'events';

export interface HostData {
    hostName: string;
    latency: number;
}

export enum ClientState {
    SYNCING = 'Syncing',
    PROCESSING = 'Processing',
    WAITING = 'Waiting',
}

export class NetworkMonitor extends EventEmitter {
    private hosts: HostData[] = [];
    private clientState: ClientState = ClientState.WAITING;

    constructor() {
        super();
    }

    updateHostData(hostName: string, latency: number): void {
        const hostIndex = this.hosts.findIndex(h => h.hostName === hostName);
        if (hostIndex !== -1) {
            this.hosts[hostIndex].latency = latency;
        } else {
            this.hosts.push({ hostName, latency });
        }
        this.emit('hostDataUpdated', this.hosts);
    }

    setClientState(state: ClientState): void {
        this.clientState = state;
        this.emit('clientStateUpdated', this.clientState);
    }

    getHostData(): HostData[] {
        return this.hosts;
    }

    getClientState(): ClientState {
        return this.clientState;
    }
}
