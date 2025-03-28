# Modulo `db.pm`

Il modulo `db.pm` gestisce l'interazione con il database SQLite. Contiene funzioni per la gestione di feed RSS, URL web, impostazioni e altre entità del sistema.

---

## 📚 Funzioni

### `connect_db`
**Descrizione**: Stabilisce una connessione al database SQLite.

**Parametri**: Nessuno.

**Ritorno**: Oggetto database handler (`DBI`).

---

### `add_rss_feed($title, $url)`
**Descrizione**: Aggiunge un nuovo feed RSS al database.

**Parametri**:
- `$title`: Titolo del feed.
- `$url`: URL del feed.

**Ritorno**: Nessuno.

---

### `get_all_rss_feeds`
**Descrizione**: Recupera tutti i feed RSS salvati.

**Parametri**: Nessuno.

**Ritorno**: Array di hash contenenti `id`, `title` e `url`.

---

### `add_web_url($url)`
**Descrizione**: Aggiunge un nuovo URL per il crawling web.

**Parametri**:
- `$url`: URL da aggiungere.

**Ritorno**: Nessuno.

---

### `get_all_web_urls`
**Descrizione**: Recupera tutti gli URL web salvati.

**Parametri**: Nessuno.

**Ritorno**: Array di hash contenenti `id`, `url` e `attivo`.

---

### `add_or_update_setting($key, $value)`
**Descrizione**: Aggiunge o aggiorna una chiave di configurazione.

**Parametri**:
- `$key`: Nome della chiave.
- `$value`: Valore della chiave.

**Ritorno**: Nessuno.

---

### `get_all_settings`
**Descrizione**: Recupera tutte le impostazioni salvate.

**Parametri**: Nessuno.

**Ritorno**: Hash di chiavi e valori.

---

### `delete_setting($key)`
**Descrizione**: Elimina una chiave di configurazione.

**Parametri**:
- `$key`: Nome della chiave da eliminare.

**Ritorno**: Nessuno.

---

### `add_summary($page_id, $summary)`
**Descrizione**: Aggiunge un nuovo riassunto.

**Parametri**:
- `$page_id`: ID della pagina associata.
- `$summary`: Testo del riassunto.

**Ritorno**: Nessuno.

---

### `get_all_summaries`
**Descrizione**: Recupera tutti i riassunti salvati.

**Parametri**: Nessuno.

**Ritorno**: Array di hash contenenti `id`, `summary` e `created_at`.

---

### `share_summary($summary_id, $recipient)`
**Descrizione**: Condivide un riassunto con un destinatario.

**Parametri**:
- `$summary_id`: ID del riassunto.
- `$recipient`: Destinatario della condivisione.

**Ritorno**: Nessuno.

---

### `add_notification_channel($name, $type, $config)`
**Descrizione**: Aggiunge un nuovo canale di notifica.

**Parametri**:
- `$name`: Nome del canale.
- `$type`: Tipo di canale (es. email, webhook).
- `$config`: Configurazione in formato JSON.

**Ritorno**: Nessuno.

---

### `get_notification_channels`
**Descrizione**: Recupera tutti i canali di notifica.

**Parametri**: Nessuno.

**Ritorno**: Array di hash contenenti `id`, `name` e `type`.

---

### `deactivate_notification_channel($id)`
**Descrizione**: Disattiva un canale di notifica.

**Parametri**:
- `$id`: ID del canale da disattivare.

**Ritorno**: Nessuno.

---

### `add_sender($name, $type, $config)`
**Descrizione**: Aggiunge un nuovo mittente.

**Parametri**:
- `$name`: Nome del mittente.
- `$type`: Tipo di mittente (es. email, webhook).
- `$config`: Configurazione in formato JSON.

**Ritorno**: Nessuno.

---

### `get_all_senders`
**Descrizione**: Recupera tutti i mittenti configurati.

**Parametri**: Nessuno.

**Ritorno**: Array di hash contenenti `id`, `name`, `type` e `active`.

---

### `update_sender($id, $name, $type, $config, $active)`
**Descrizione**: Aggiorna un mittente esistente.

**Parametri**:
- `$id`: ID del mittente.
- `$name`: Nome del mittente.
- `$type`: Tipo di mittente.
- `$config`: Configurazione aggiornata.
- `$active`: Stato attivo/inattivo.

**Ritorno**: Nessuno.

---

### `delete_sender($id)`
**Descrizione**: Elimina un mittente.

**Parametri**:
- `$id`: ID del mittente da eliminare.

**Ritorno**: Nessuno.

---

## 📄 Licenza

Questo modulo è distribuito sotto la [Licenza BSD 3-Clause](../LICENSE).
