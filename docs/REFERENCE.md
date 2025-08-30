Riferimenti funzioni (Cross‑Reference)
=====================================

Legenda: ciascuna voce indica il file e la riga iniziale della funzione.

DB (lib/db.pm)
--------------
- connect_db: lib/db.pm:20
- get_encryption_key: lib/db.pm:34
- encrypt_data: lib/db.pm:41
- decrypt_data: lib/db.pm:54
- add_rss_feed: lib/db.pm:70
- get_all_rss_feeds: lib/db.pm:91
- get_all_rss_data: lib/db.pm:106
- add_web_url: lib/db.pm:116
- get_all_web_urls: lib/db.pm:137
- get_all_web_data: lib/db.pm:152
- update_web_url_status: lib/db.pm:162
- add_setting: lib/db.pm:183
- add_or_update_setting: lib/db.pm:204
- set_setting: lib/db.pm:211
- get_all_settings: lib/db.pm:217
- delete_setting: lib/db.pm:232
- setting_exists: lib/db.pm:253
- get_logs: lib/db.pm:271
- get_all_summaries: lib/db.pm:286
- add_summary: lib/db.pm:301
- share_summary: lib/db.pm:322
- add_notification_channel: lib/db.pm:334
- get_notification_channels: lib/db.pm:343
- deactivate_notification_channel: lib/db.pm:356
- add_sender: lib/db.pm:365
- get_all_senders: lib/db.pm:376
- update_sender: lib/db.pm:392
- delete_sender: lib/db.pm:403
- register_user: lib/db.pm:413
- add_template: lib/db.pm:434
- get_all_templates: lib/db.pm:443
- update_template: lib/db.pm:458
- delete_template: lib/db.pm:467
- get_template_by_name: lib/db.pm:476

P2P (lib/p2p.pm)
----------------
- start_udp_discovery: lib/p2p.pm:24
- start_tcp_server: lib/p2p.pm:42
- log_latency: lib/p2p.pm:95
- verify_peer: lib/p2p.pm:109
- encrypt_with_public_key: lib/p2p.pm:115
- decrypt_with_private_key: lib/p2p.pm:122
- get_public_key: lib/p2p.pm:129
- get_machine_id: lib/p2p.pm:134
- add_peer_request: lib/p2p.pm:139
- accept_peer: lib/p2p.pm:154
- reject_peer: lib/p2p.pm:174
- is_peer_accepted: lib/p2p.pm:187
- get_accepted_peers: lib/p2p.pm:199
- get_peer_requests: lib/p2p.pm:213
- sync_data: lib/p2p.pm:227
- send_task: lib/p2p.pm:235
- receive_task: lib/p2p.pm:249
- execute_task: lib/p2p.pm:259
- collect_results: lib/p2p.pm:266
- get_peer_address: lib/p2p.pm:273

Crawler (lib/rss_crawler.pm, lib/web_crawler.pm)
-----------------------------------------------
- esegui_crawler_rss: lib/rss_crawler.pm:17
- esegui_crawler_web: lib/web_crawler.pm:18

NLP (lib/nlp.pm)
----------------
- riassumi_contenuto: lib/nlp.pm:28
- rilevanza_per_interessi: lib/nlp.pm:58
- estrai_parole_chiave: lib/nlp.pm:75

Config (lib/config_manager.pm)
------------------------------
- add_setting: lib/config_manager.pm:13
- get_setting: lib/config_manager.pm:33
- get_all_settings: lib/config_manager.pm:52
- delete_setting: lib/config_manager.pm:82
- setting_exists: lib/config_manager.pm:100
- sync_settings: lib/config_manager.pm:120
- apply_delta: lib/config_manager.pm:142

Notifiche e canali
------------------
- notification::send_notification: lib/notification.pm:14
- irc::send_notification: lib/irc.pm:8
- mail::send_notification: lib/mail.pm:10
- teams::send_notification: lib/teams.pm:8
- whatsapp::send_notification: lib/whatsapp.pm:8
- rss::send_notification: lib/rss.pm:8

OPML (lib/opml.pm)
------------------
- import_opml: lib/opml.pm:17
- export_opml: lib/opml.pm:41

Init e bootstrap
----------------
- init_db::createDB: lib/init_db.pm:9

CLI interattiva (lib/interactive_cli.pm) — funzioni principali
--------------------------------------------------------------
- avvia_cli: lib/interactive_cli.pm:19
- mostra_aiuto: lib/interactive_cli.pm:151
- aggiungi_feed_rss: lib/interactive_cli.pm:200
- lista_feed_rss: lib/interactive_cli.pm:216
- esegui_crawler_rss: lib/interactive_cli.pm:234
- rilancia_rss: lib/interactive_cli.pm:245
- aggiungi_url_web: lib/interactive_cli.pm:256
- lista_url_web: lib/interactive_cli.pm:272
- esegui_crawler_web: lib/interactive_cli.pm:290
- rilancia_web: lib/interactive_cli.pm:301
- mostra_configurazione: lib/interactive_cli.pm:312
- imposta_configurazione: lib/interactive_cli.pm:326
- lista_riassunti: lib/interactive_cli.pm:342
- aggiungi_riassunto: lib/interactive_cli.pm:360
- condividi_riassunto: lib/interactive_cli.pm:375
- aggiungi_mittente: lib/interactive_cli.pm:390
- lista_mittenti: lib/interactive_cli.pm:406
- aggiorna_mittente: lib/interactive_cli.pm:424
- elimina_mittente: lib/interactive_cli.pm:440
- rigenera_procedure: lib/interactive_cli.pm:456
- aggiungi_setting: lib/interactive_cli.pm:467
- rimuovi_setting: lib/interactive_cli.pm:477
- modifica_setting: lib/interactive_cli.pm:487

Note
----
- I numeri di riga si riferiscono allo stato attuale del repository e possono variare con modifiche successive.

