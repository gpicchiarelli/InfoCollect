Connettori e account
====================

Panoramica
----------
InfoCollect supporta vari connettori per l'invio di notifiche. Gli “account” da usare per i connettori sono memorizzati nella tabella `senders` (nome, tipo, configurazione cifrata, stato attivo) e sono gestibili dall’interfaccia Web e dalla CLI.

Connettori supportati (built‑in)
--------------------------------
- IRC: invia messaggi in un canale IRC
  - Richiesti: `server`, `port`, `nick`, `ircname`, `channel`
- Mail: invia email via SMTP
  - Richiesti: `to`, `from`, `subject`, `smtp_host`, `smtp_port`
- RSS: genera un feed RSS su file
  - Richiesti: `title`, `link`, `description`, `item_title`, `item_link`, `output_file`
- Teams: webhook Microsoft Teams
  - Richiesti: `webhook_url`
- WhatsApp: invio via API
  - Richiesti: `api_url`, `phone`

Pannelli Web
------------
- Mittenti (Accounts): `/senders`
  - Aggiunta/gestione di account da usare per i connettori. La configurazione viene cifrata automaticamente.
- Connettori: `/connectors`
  - Elenco connettori supportati con campi richiesti e descrizioni.
  - API di validazione: `POST /connectors/:type/validate` con `config` (JSON) restituisce esito `{ok: true}` o `{ok:false, error:"..."}`.

CLI
---
- Aggiunta account: `add_sender <name> <type> <json_config>`
- Lista account: `list_senders`
- Aggiornamento: `update_sender <id> <name> <type> <json_config> <active>`
- Eliminazione: `delete_sender <id>`
- Test invio (via API Web): `curl -X POST http://localhost:3000/senders/<id>/test -d 'message=Prova'`

Sicurezza
---------
- Le configurazioni degli account sono cifrate con AES‑GCM tramite `lib/db.pm` e memorizzate in `senders.config`.
- La chiave di cifratura è salvata in `settings.INFOCOLLECT_ENCRYPTION_KEY`; sostituirla in produzione.

Estensioni
----------
- Per aggiungere un connettore, creare un modulo in `lib/` con una funzione `send_notification($channel, $message)` e registrarlo in `lib/notification.pm::supported_connectors`.

