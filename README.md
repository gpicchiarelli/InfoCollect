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

InfoCollect utilizza un database SQLite per gestire le richieste di peer e i peer accettati. Lo schema del database è definito in `schema.sql`.

### Tabelle principali

- `peer_requests`: Memorizza le richieste di peer in attesa di approvazione.
- `accepted_peers`: Memorizza i peer accettati.

Questo approccio riduce il carico di lavoro duplicato e garantisce coerenza tra le istanze.
