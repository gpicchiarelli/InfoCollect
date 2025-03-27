# InfoCollect

**InfoCollect** è un sistema avanzato di raccolta automatica di notizie da fonti RSS e Web, scritto interamente in Perl.

---

## 🧠 Funzionalità principali

- 📥 Crawling parallelo da fonti RSS e siti web
- 🧾 Riassunto automatico dei contenuti tramite NLP (IT/EN)
- 🔄 **Sincronizzazione P2P** tra istanze nella rete locale
- 🧠 Filtraggio intelligente in base a "interessi" personalizzati
- 🗃️ Archiviazione con metadati completi in SQLite

---

## 🔄 Sincronizzazione P2P

InfoCollect utilizza un protocollo P2P per sincronizzare dati e impostazioni tra istanze nella rete locale. Ogni istanza:

1. Invia messaggi UDP broadcast per annunciare la propria presenza.
2. Utilizza connessioni TCP per sincronizzare dati e impostazioni.
3. **Algoritmi di Delta**: Durante la sincronizzazione, vengono trasferite solo le differenze tra le impostazioni locali e quelle ricevute, riducendo il carico di rete.

InfoCollect utilizza un database SQLite per gestire le richieste di peer e i peer accettati. Lo schema del database è definito in `db/schema.sql`.

### Tabelle principali

- `peer_requests`: Memorizza le richieste di peer in attesa di approvazione.
- `accepted_peers`: Memorizza i peer accettati.

Questo approccio riduce il carico di lavoro duplicato e garantisce coerenza tra le istanze.

InfoCollect supporta ora applicazioni di calcolo distribuito tramite il protocollo P2P. Le funzionalità includono:

1. **Distribuzione dei task**: I task possono essere inviati ai peer disponibili per l'elaborazione.
2. **Raccolta dei risultati**: I risultati dei task vengono raccolti e aggregati automaticamente.
3. **Gestione degli errori**: I task falliti vengono riassegnati ad altri peer.

### Nuovi Endpoint API

- **POST /api/send_task**: Invia un task a un peer specifico.
  - Parametri:
    - `peer_id`: ID del peer destinatario.
    - `task_data`: Dati del task da elaborare.
  - Risposta:
    - `{ success: 1 }` se il task è stato inviato con successo.
    - `{ success: 0, error: "messaggio di errore" }` in caso di errore.
