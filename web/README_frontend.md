# Interfaccia Web InfoCollect

## Endpoint API

### `/api/latency`
- **Metodo**: `GET`
- **Descrizione**: Restituisce i dati di latenza e i nomi degli host connessi.
- **Risposta**:
  ```json
  [
    {
      "host": "192.168.1.10",
      "latency_ms": 15,
      "last_updated": "2024-01-01 12:00:00"
    },
    ...
  ]
  ```

# Interfaccia Web InfoCollect

Questa è l'interfaccia web scritta in React con TypeScript per InfoCollect.

## Funzionalità

- Visualizzazione dei dati RSS raccolti.
- Visualizzazione dei dati delle pagine web raccolte.
- Gestione delle impostazioni.
- Visualizzazione dello stato della sincronizzazione P2P.

## Installazione e Avvio

1. Assicurati di avere `Node.js` e `npm` installati.
   - **Windows**: Scarica Node.js da [nodejs.org](https://nodejs.org).
   - **macOS/Linux/BSD**: Usa il gestore pacchetti del sistema operativo.
2. Posizionati nella directory `web/`.
3. Installa le dipendenze:

```bash
npm install
```

4. Avvia in sviluppo:

```bash
npm run dev
```

L'interfaccia si collegherà al server Mojolicious (avvia `api_server.pl`).

Puoi anche integrarla con build Next.js o Vite per produrre una versione statica.
