# Modulo `rss_crawler.pm`

Il modulo `rss_crawler.pm` gestisce il crawling dei feed RSS salvati nel database.

---

## 📚 Funzioni

### `esegui_crawler_rss`
**Descrizione**: Avvia il crawling di tutti i feed RSS salvati.

**Parametri**: Nessuno.

**Ritorno**: Nessuno.

**Dettagli**:
- Recupera i feed RSS dal database.
- Effettua richieste HTTP per ogni feed.
- Analizza il contenuto RSS e salva gli articoli nel database.

---

## 📄 Licenza

Questo modulo è distribuito sotto la [Licenza BSD 3-Clause](../LICENSE).
