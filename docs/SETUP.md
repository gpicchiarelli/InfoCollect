Setup rapido
============

Prerequisiti
------------
- Perl 5.32+ con toolchain (make, gcc) per moduli XS
- cpanm (App::cpanminus)
- SQLite3 (librerie presenti sul sistema)
- Node.js 18+ (per le parti TypeScript opzionali)
 - HTTPS: installiamo automaticamente i moduli necessari per HTTPS (LWP::Protocol::https, IO::Socket::SSL, Mozilla::CA). Il bundle CA (Mozilla::CA) consente la verifica SSL.

Installazione automatica
------------------------
1) Esegui lo script di setup

   ./setup.sh

2) Avvio servizi principali

   - API Web (Mojolicious):  perl web/api_server.pl daemon -l http://*:3000
   - Daemon P2P:              perl daemon.pl
   - Agent (crawler+P2P):     perl InfoCollect/agent.pl

3) Dev server per TypeScript (opzionale)

   npm run dev:web

Note
----
- Alla prima esecuzione viene generata automaticamente una chiave di cifratura di sviluppo (settings.INFOCOLLECT_ENCRYPTION_KEY). Sostituiscila in produzione.
- Per la funzionalità di riassunto via API (HuggingFace) imposta un token valido in lib/nlp.pm oppure lascia il fallback locale.
 - Verifica SSL per i crawler: di default è abilitata e usa il bundle di Mozilla::CA. Se in ambienti senza CA vuoi disabilitare temporaneamente la verifica, imposta in Impostazioni `SSL_NO_VERIFY=1` (sconsigliato in produzione).
