# Modulo `interactive_cli.pm`

Il modulo `interactive_cli.pm` fornisce un'interfaccia CLI interattiva per gestire il sistema InfoCollect.

---

## 📚 Funzioni

### `avvia_cli`
**Descrizione**: Avvia l'interfaccia CLI interattiva.

**Parametri**: Nessuno.

**Ritorno**: Nessuno.

---

### `mostra_aiuto`
**Descrizione**: Mostra l'elenco dei comandi disponibili nella CLI.

**Parametri**: Nessuno.

**Ritorno**: Nessuno.

---

### `aggiungi_feed_rss($titolo, $url)`
**Descrizione**: Aggiunge un nuovo feed RSS tramite la CLI.

**Parametri**:
- `$titolo`: Titolo del feed.
- `$url`: URL del feed.

**Ritorno**: Nessuno.

---

### `lista_feed_rss`
**Descrizione**: Mostra l'elenco dei feed RSS salvati.

**Parametri**: Nessuno.

**Ritorno**: Nessuno.

---

### `esegui_crawler_rss`
**Descrizione**: Avvia il crawler RSS tramite la CLI.

**Parametri**: Nessuno.

**Ritorno**: Nessuno.

---

### `import_opml($file_path)`
**Descrizione**: Importa feed RSS da un file OPML tramite la CLI.

**Parametri**:
- `$file_path`: Percorso del file OPML.

**Ritorno**: Nessuno.

---

### `export_opml($file_path)`
**Descrizione**: Esporta i feed RSS in un file OPML tramite la CLI.

**Parametri**:
- `$file_path`: Percorso del file OPML di destinazione.

**Ritorno**: Nessuno.

---

## 📄 Licenza

Questo modulo è distribuito sotto la [Licenza BSD 3-Clause](../LICENSE).
