# Documentazione di InfoCollect

Benvenuto nella documentazione di **InfoCollect**, un sistema avanzato di raccolta automatica di notizie da fonti RSS e Web, scritto in Perl.

---

## 📚 Indice

1. [Introduzione](#introduzione)
2. [Struttura del Progetto](#struttura-del-progetto)
3. [Funzionalità Principali](#funzionalità-principali)
4. [Moduli e Componenti](#moduli-e-componenti)
5. [CLI Interattiva](#cli-interattiva)
6. [API Web](#api-web)
7. [Sincronizzazione P2P](#sincronizzazione-p2p)
8. [Test e Validazione](#test-e-validazione)
9. [Installazione e Avvio](#installazione-e-avvio)
10. [Licenza](#licenza)

---

## Introduzione

**InfoCollect** è un sistema progettato per raccogliere, analizzare e gestire contenuti da fonti RSS e pagine web. Supporta funzionalità avanzate come il riassunto automatico dei contenuti, la sincronizzazione P2P e l'esportazione/importazione di feed in formato OPML.

---

## Struttura del Progetto

La struttura del progetto è organizzata come segue:

```
InfoCollect/
├── lib/                # Moduli Perl principali
│   ├── db.pm           # Gestione del database
│   ├── rss_crawler.pm  # Crawler per feed RSS
│   ├── web_crawler.pm  # Crawler per pagine web
│   ├── opml.pm         # Gestione file OPML
│   ├── p2p.pm          # Sincronizzazione P2P
│   ├── nlp.pm          # Funzionalità di NLP (Natural Language Processing)
│   └── interactive_cli.pm # CLI interattiva
├── web/                # Interfaccia web e API
│   ├── api_server.pl   # Server API basato su Mojolicious
│   ├── templates/      # Template HTML
│   └── static/         # File statici (CSS, JS)
├── t/                  # Test
│   ├── integration.t   # Test di integrazione
│   ├── opml.t          # Test per la gestione OPML
│   └── ...             # Altri test
├── script/             # Script di utilità
│   └── test_data/      # File di test (es. OPML)
├── docs/               # Documentazione
├── InfoCollect/        # File di configurazione e script principali
│   ├── start.pl        # Script di avvio principale
│   ├── agent.pl        # Agente per il crawling e la sincronizzazione
│   └── Feeds.opml      # File OPML di esempio
└── README.md           # Documentazione principale del progetto
```

---

## Funzionalità Principali

- **📥 Crawling parallelo**: Raccolta di contenuti da fonti RSS e pagine web.
- **🧾 Riassunto automatico**: Generazione di riassunti tramite modelli NLP.
- **🔄 Sincronizzazione P2P**: Condivisione di dati tra istanze nella rete locale.
- **🧠 Filtraggio intelligente**: Contenuti filtrati in base a interessi personalizzati.
- **🗃️ Esportazione/Importazione OPML**: Gestione dei feed in formato OPML.
- **📊 API REST**: Endpoint per interagire con i dati raccolti.

---

## Moduli e Componenti

### 1. **`lib/db.pm`**
Gestisce l'interazione con il database SQLite. Contiene funzioni per:
- Aggiungere, aggiornare e recuperare feed RSS.
- Gestire URL web e impostazioni.

### 2. **`lib/rss_crawler.pm`**
Crawler per raccogliere contenuti da feed RSS. Funzioni principali:
- `esegui_crawler_rss`: Avvia il crawling dei feed RSS salvati.

### 3. **`lib/web_crawler.pm`**
Crawler per raccogliere contenuti da pagine web. Funzioni principali:
- `esegui_crawler_web`: Avvia il crawling degli URL web salvati.

### 4. **`lib/opml.pm`**
Gestisce l'importazione e l'esportazione di file OPML. Funzioni principali:
- `import_opml($file_path)`: Importa feed da un file OPML.
- `export_opml($file_path)`: Esporta feed in un file OPML.

### 5. **`lib/p2p.pm`**
Implementa la sincronizzazione P2P tra istanze. Funzioni principali:
- `start_udp_discovery`: Annuncia la presenza nella rete locale.
- `start_tcp_server`: Sincronizza dati e impostazioni.

### 6. **`lib/nlp.pm`**
Funzionalità di Natural Language Processing (NLP). Funzioni principali:
- `riassumi_contenuto`: Genera un riassunto di un testo.
- `estrai_parole_chiave`: Estrae parole chiave da un testo.

### 7. **`lib/interactive_cli.pm`**
CLI interattiva per gestire il sistema. Comandi principali:
- `import_opml <file_path>`: Importa feed da un file OPML.
- `export_opml <file_path>`: Esporta feed in un file OPML.
- `run_rss_crawler`: Avvia il crawler RSS.
- `run_web_crawler`: Avvia il crawler Web.

---

## CLI Interattiva

La CLI consente di interagire con il sistema tramite comandi testuali. Esempio di utilizzo:

```bash
InfoCollect> import_opml feeds.opml
Importazione completata dal file: feeds.opml

InfoCollect> export_opml export.opml
Esportazione completata nel file: export.opml

InfoCollect> run_rss_crawler
Crawler RSS completato con successo.
```

---

## API Web

Il server API è basato su Mojolicious e offre endpoint per interagire con i dati raccolti.

### Endpoint Principali

- **`GET /api/rss_data`**: Restituisce i dati RSS raccolti.
- **`GET /api/web_data`**: Restituisce i dati delle pagine web raccolte.
- **`POST /api/crawler/rss`**: Avvia il crawler RSS.
- **`POST /api/crawler/web`**: Avvia il crawler Web.
- **`POST /api/settings`**: Aggiunge o aggiorna un'impostazione.

---

## Sincronizzazione P2P

InfoCollect utilizza un protocollo P2P per sincronizzare dati e impostazioni tra istanze nella rete locale. Funzionalità principali:
1. **Annuncio della presenza**: Messaggi UDP broadcast.
2. **Sincronizzazione dati**: Connessioni TCP per trasferire dati e impostazioni.
3. **Gestione dei task distribuiti**: Invio e raccolta di risultati dai peer.

---

## Test e Validazione

I test sono implementati nella directory `t/` e includono:
- **`integration.t`**: Test di integrazione per la sincronizzazione P2P e l'importazione OPML.
- **`opml.t`**: Test specifici per la gestione dei file OPML.

Esegui i test con il comando:
```bash
prove -l t/
```

---

## Installazione e Avvio

### Prerequisiti
- Perl 5.34 o superiore.
- Moduli Perl richiesti (installabili con `cpanm`):
  - `DBI`, `XML::Simple`, `Mojolicious`, `Lingua::Identify`, ecc.

### Installazione
1. Clona il repository:
   ```bash
   git clone https://github.com/gpicchiarelli/InfoCollect.git
   cd InfoCollect
   ```
2. Installa i moduli richiesti:
   ```bash
   cpanm --installdeps .
   ```

### Avvio
- **CLI**:
  ```bash
  perl InfoCollect/start.pl
  ```
- **API Web**:
  ```bash
  perl web/api_server.pl daemon
  ```

---

## Licenza

Questo progetto è distribuito sotto la [Licenza BSD 3-Clause](../LICENSE).

