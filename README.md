# InfoCollect

InfoCollect è un sistema avanzato di raccolta automatica di notizie da fonti RSS e Web. La maggior parte del codice è in Perl (core, crawler, DB, P2P, web server), con componenti ausiliarie in TypeScript/Node per strumenti di sviluppo e monitoraggio.

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

Installazione (verboso)
-----------------------
La procedura seguente guida in modo dettagliato al primo avvio, passando dall’installazione delle dipendenze fino all’esecuzione simultanea del servizio web e della console testuale.

1) Prerequisiti
   - Perl 5.32+ con toolchain (make/gcc) per moduli XS
   - cpanm (App::cpanminus) per installare CPAN in modo affidabile
   - SQLite3 (presente di default su molte piattaforme)
   - Node.js 18+ (solo per la parte TS opzionale)

2) Setup automatico
   - Esegui: `./setup.sh`
   - Cosa fa in dettaglio:
     - Verifica la presenza di `perl` e `cpanm`; se manca `cpanm` prova a installarlo localmente
     - Installa tutte le dipendenze CPAN elencate in `cpanfile` (incluso CryptX, Mojolicious, Dancer2, ecc.)
     - Inizializza o aggiorna il database SQLite creando tutte le tabelle necessarie e, se assente, una chiave di cifratura di sviluppo in `settings`
     - Se `npm` è disponibile, installa anche le dipendenze Node definite in `package.json`

3) Verifica post-setup (facoltativa ma consigliata)
   - Avvia l’API web su porta 3000: `perl web/api_server.pl daemon -l http://*:3000`
   - In un altro terminale, avvia il daemon P2P: `perl daemon.pl`
   - Apri la console testuale: `perl script/console.pl`
   - Le tre componenti condividono lo stesso database (`infocollect.db`), quindi ogni modifica si riflette ovunque.

4) Avvio semplificato “tutto-in-uno”
   - `perl script/start_all.pl --port 3000`
   - Esegue in background il server web e il daemon, poi avvia la console interattiva in foreground.

Comandi utili (panoramica)
--------------------------
- API web (Mojolicious): `perl web/api_server.pl daemon -l http://*:3000`
  - Dashboard HTML (templates in `web/templates/`) per operazioni frequenti
  - API JSON per integrazione: vedi `web/api_server.pl` (es. `/api/pages`, `/api/send_task`, `/api/import_opml`)
- Daemon P2P: `perl daemon.pl`
  - Server TCP minimale per ping, sync e task
- Agent (crawler + P2P): `perl InfoCollect/agent.pl`
  - Avvia discovery/server P2P e lancia periodicamente i crawler RSS/Web
- Console testuale: `perl script/console.pl`
  - Interfaccia CLI interattiva per gestire feed, URL, impostazioni, riassunti, notifiche e sender
- Start combinato: `perl script/start_all.pl --port 3000`
  - Avvio guidato di web+daemon in background e CLI in foreground
- Dev TS (demo): `npm run dev:web`
  - Strumenti ausiliari di monitoraggio/local dev (non necessari in produzione)
- Make target: `make start`
  - Esegue l’avvio combinato equivalente a `script/start_all.pl`

Documentazione
--------------
- Setup: `docs/SETUP.md`
- API Web: vedi `web/api_server.pl`
- P2P: vedi `lib/p2p.pm`
- DB e funzioni: vedi `lib/db.pm`
- Riferimenti cross‑reference: `docs/REFERENCE.md`
 - Console interattiva (comandi): `docs/CLI.md`

Cross-reference funzioni (principali)
-------------------------------------
- Crawler RSS: `lib/rss_crawler.pm:1` — esegue fetch e parsing feed RSS, inserendo articoli in `rss_articles`.
- Crawler Web: `lib/web_crawler.pm:1` — visita URL attivi, estrae titolo e genera riassunto, salva in `pages`.
- NLP riassunti: `lib/nlp.pm:1` — `riassumi_contenuto`, `rilevanza_per_interessi`, `estrai_parole_chiave`.
- DB accesso: `lib/db.pm:1` — connessione, cifratura, CRUD su impostazioni, feed, web, summaries, notification e senders.
- P2P: `lib/p2p.pm:1` — discovery UDP, server TCP, sync impostazioni, gestione peer.
- Notifiche: `lib/notification.pm:1` — dispatch verso IRC/Mail/RSS/Teams/WhatsApp.
 - Console CLI: `lib/interactive_cli.pm:19` — comandi interattivi amministrativi.

Allineamento tra servizi
------------------------
Sia la console testuale (Perl) sia il servizio web (Mojolicious) condividono le stesse funzioni di accesso al DB (`lib/db.pm`) e lo stesso file di database (`infocollect.db`). Questo garantisce coerenza: ogni operazione fatta via CLI è immediatamente visibile sul web (e viceversa).

Sicurezza e cifratura
---------------------
- Le configurazioni sensibili dei mittenti sono cifrate in AES‑GCM tramite le utilità in `lib/db.pm`.
- Alla prima inizializzazione viene inserita una chiave di cifratura di sviluppo; in produzione, impostarne una personalizzata in `settings` (chiave `INFOCOLLECT_ENCRYPTION_KEY`).
- Per abilitare il riassunto remoto (HuggingFace), imposta la chiave `HUGGINGFACE_API_TOKEN` nelle impostazioni o esporta l’ENV `HUGGINGFACE_API_TOKEN` prima di eseguire `./setup.sh`.

Linguaggi e struttura del codice
--------------------------------
- Core, orchestrazione, crawler, P2P e web server sono in Perl (Mojolicious e Dancer2).
- Componenti opzionali in TypeScript/Node forniscono tool di sviluppo e monitor: non sono necessarie in produzione.
### Tabelle principali

- `peer_requests`: Memorizza le richieste di peer in attesa di approvazione.
- `accepted_peers`: Memorizza i peer accettati.

Questo approccio riduce il carico di lavoro duplicato e garantisce coerenza tra le istanze.
