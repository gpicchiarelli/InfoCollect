# Modulo `web_crawler.pm`

Il modulo `web_crawler.pm` gestisce il crawling delle pagine web salvate nel database.

---

## 📚 Funzioni

### `esegui_crawler_web`
**Descrizione**: Avvia il crawling di tutti gli URL web salvati.

**Parametri**: Nessuno.

**Ritorno**: Nessuno.

**Dettagli**:
- Recupera gli URL web dal database.
- Effettua richieste HTTP per ogni URL.
- Analizza il contenuto HTML e salva i dati nel database.

---

## 📄 Licenza

Questo modulo è distribuito sotto la [Licenza BSD 3-Clause](../LICENSE).
