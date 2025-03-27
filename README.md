# InfoCollect

**InfoCollect** è un sistema avanzato di raccolta automatica di notizie da fonti RSS e Web, scritto interamente in Perl. Utilizza una pipeline NLP multilingua per analizzare, riassumere e filtrare le notizie in base a interessi predefiniti. È pensato per funzionare in modo asincrono, efficiente e configurabile sia da terminale che in modalità automatica (daemon).

---

## 🧠 Funzionalità principali

- 📥 Crawling parallelo da fonti RSS e siti web
- 🧾 Riassunto automatico dei contenuti tramite NLP (IT/EN)
- 🔒 Autenticazione locale basata sull'utente del sistema operativo
- 🧠 Filtraggio intelligente in base a "interessi" personalizzati
- 🗃️ Archiviazione con metadati completi in SQLite
- 🧪 CLI interattiva per test ed esecuzione manuale
- ⏲️ Modalità daemon per raccolta ciclica automatica

---

## 📦 Requisiti

- Perl 5.32+
- Moduli Perl (puoi installarli con `modules_installer.pl`):
  - `LWP::UserAgent`, `XML::RSS`, `HTML::TreeBuilder`, `HTML::Strip`
  - `Text::Summarizer`, `Lingua::Identify`, `Lingua::EN::Tagger`, `Lingua::IT::Stemmer`
  - `Term::ReadLine`, `Term::ANSIColor`, `Parallel::ForkManager`, `DBI`, `DBD::SQLite`, `Time::HiRes`

---

## 🚀 Avvio rapido

```bash
perl modules_installer.pl   # Installa i moduli necessari
perl start.pl               # Avvia la CLI interattiva
```

Oppure in modalità automatica:

```bash
perl agent.pl 15   # Avvia raccolta automatica ogni 15 minuti
```

---

## 💻 CLI interattiva

Comandi disponibili:

- `rss-crawl` – Avvia il crawler RSS
- `web-crawl` – Avvia il crawler Web
- `run-all` – Avvia entrambi
- `loop <min>` – Avvia raccolta automatica ogni N minuti
- `add-setting <k> <v>` – Aggiungi impostazioni
- `get-setting <k>` – Leggi impostazioni
- `delete-setting <k>` – Rimuovi impostazioni
- `exit` / `quit` – Esci dalla CLI

---

## 🗃️ Database

Il database `infocollect.db` contiene:

- `settings` – Configurazioni generali
- `rss` e `web` – Fonti attive
- `interessi` – Parole chiave da monitorare
- `riassunti` – Contenuti rilevanti riassunti e con metadati
- `pages`, `rss_articles`, `rss_feeds` – Archiviazione completa

---

## 📂 Struttura del progetto

```
InfoCollect/
├── start.pl
├── agent.pl
├── info_collect.pl
├── modules_installer.pl
├── lib/
│   ├── rss_crawler.pm
│   ├── web_crawler.pm
│   ├── nlp.pm
│   ├── init_db.pm
│   ├── config_manager.pm
│   ├── interactive_cli.pm
│   └── ...
├── infocollect.db
├── Feeds.opml (opzionale)
└── README.md
```

---

## 🔒 Autenticazione

InfoCollect supporta due metodi di autenticazione:

1. **Token API**: Configurabile tramite la variabile d'ambiente `INFOCOLLECT_API_TOKEN`.
2. **Autenticazione locale**: L'accesso è consentito all'utente locale che esegue lo script, determinato dinamicamente tramite le funzioni del sistema operativo.

---

## 📝 Licenza

Distribuito sotto licenza BSD. Vedi intestazione dei file per i dettagli.
