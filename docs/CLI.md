Console Interattiva (interactive_cli)
=====================================

Panoramica
----------
La console interattiva consente di amministrare InfoCollect via REPL: gestione feed RSS, URL web, impostazioni, riassunti, notifiche e mittenti. Condivide lo stesso DB dell'interfaccia web.

Avvio
-----
- Avvio standalone: `perl script/console.pl`
- Avvio combinato (web+daemon+CLI): `perl script/start_all.pl --port 3000`

Comandi principali
------------------
- help: mostra l'elenco dei comandi
- exit: esce dalla console

RSS
---
- add_rss_feed <titolo> <url>
- list_rss_feeds
- run_rss_crawler
- relaunch_rss

Web
---
- add_web_url <url>
- list_web_urls
- run_web_crawler
- relaunch_web

Impostazioni
------------
- show_config
- set_config <chiave> <valore>
- add_setting <chiave> <valore>
- del_setting <chiave>
- mod_setting <chiave> <valore>
- (token HF) set_config HUGGINGFACE_API_TOKEN <token>

Riassunti
---------
- list_summaries
- add_summary <page_id> <summary>
- share_summary <summary_id> <recipient>

Notifiche e mittenti
--------------------
- add_notification_channel <name> <type> <json_config>
- list_notification_channels
- deactivate_notification_channel <id>
- add_sender <name> <type> <json_config>
- list_senders
- update_sender <id> <name> <type> <json_config> <active>
- delete_sender <id>

Note
----
- I comandi accettano valori UTF‑8; usa virgolette per argomenti con spazi.
- Le configurazioni sensibili sono cifrate (AES‑GCM) in DB.

