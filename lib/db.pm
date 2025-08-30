package db;

use strict;
use warnings;
use DBI;
use JSON;
use Time::HiRes qw(gettimeofday);
use Crypt::AuthEnc::GCM;
use Digest::SHA qw(sha256);
use init_db;
use config_manager; # accesso alle impostazioni per la chiave di cifratura

=pod

=head1 NAME

db - Accesso unificato al database SQLite e utilità di cifratura

=head1 DESCRIPTION

Fornisce connessione singleton al DB e funzioni CRUD per feed RSS, pagine web,
riassunti, impostazioni, canali di notifica, mittenti e template. Include
primitive di cifratura (AES-GCM) per configurazioni sensibili.

Cross-reference funzioni: vedi docs/REFERENCE.md (sezione "DB").

=cut

# Nome del database SQLite
my $db_file = 'infocollect.db';

# Variabile globale per un unico handler
my $dbh_global;

# Funzione per connettersi al database
sub connect_db {
    return $dbh_global if defined $dbh_global;
    my $dbh;
    eval {
        $dbh = init_db::createDB();
    };
    if ($@ || !$dbh) {
        die "Errore durante l'inizializzazione del database: $@";
    }
    $dbh_global = $dbh;
    return $dbh_global;
}

# Ottieni la chiave di crittografia dal database
sub get_encryption_key {
    my $key = config_manager::get_setting("INFOCOLLECT_ENCRYPTION_KEY");
    die "Chiave di crittografia non configurata nel database.\n" unless $key;
    return $key;
}

# Funzione per crittografare i dati
sub encrypt_data {
    my ($data) = @_;
    my $encryption_key = get_encryption_key();
    my $key = sha256($encryption_key); # Chiave a 256 bit
    my $iv = substr(sha256(time . $$), 0, 12); # IV unico per ogni crittografia
    my $cipher = Crypt::AuthEnc::GCM->new('AES', $key, $iv);
    # Nessun AAD
    my $ciphertext = $cipher->encrypt_add($data);
    my $tag = $cipher->encrypt_done();
    return unpack("H*", $iv . $ciphertext . $tag);
}

# Funzione per decrittografare i dati
sub decrypt_data {
    my ($encrypted_data) = @_;
    my $encryption_key = get_encryption_key();
    my $key = sha256($encryption_key); # Chiave a 256 bit
    my $binary_data = pack("H*", $encrypted_data);
    my $iv = substr($binary_data, 0, 12); # Estrai IV
    my $tag = substr($binary_data, -16); # Estrai tag
    my $ciphertext = substr($binary_data, 12, -16); # Estrai testo cifrato
    my $cipher = Crypt::AuthEnc::GCM->new('AES', $key, $iv);
    # Nessun AAD
    my $plaintext = $cipher->decrypt_add($ciphertext);
    die "Errore nella decrittografia: tag non valido\n" unless $cipher->decrypt_done($tag);
    return $plaintext;
}

# Funzione per aggiungere un feed RSS
sub add_rss_feed {
    my ($title, $url) = @_;

    unless ($title && $url) {
        die "Errore: titolo e URL sono richiesti per aggiungere un feed.\n";
    }

    my $dbh = connect_db();
    my $sth = $dbh->prepare("INSERT INTO rss_feeds (title, url) VALUES (?, ?)");
    eval {
        $sth->execute($title, $url);
    };
    if ($@) {
        warn "Errore durante l'inserimento del feed RSS: $@";
    } else {
        print "Feed RSS aggiunto con successo: $title ($url)\n";
    }
    $sth->finish();
}

# Funzione per ottenere tutti i feed RSS
sub get_all_rss_feeds {
    my $dbh = connect_db();
    my $sth = $dbh->prepare("SELECT id, title, url FROM rss_feeds");
    $sth->execute();

    my @feeds;
    while (my $row = $sth->fetchrow_hashref) {
        push @feeds, $row;
    }

    $sth->finish();
    return \@feeds;
}

# Funzione per ottenere tutti i dati RSS
sub get_all_rss_data {
    my $dbh = connect_db();
    my $sth = $dbh->prepare("SELECT * FROM rss_articles");
    $sth->execute();
    my $data = $sth->fetchall_arrayref({});
    $sth->finish();
    return $data;
}

# Funzione per aggiungere un URL web
sub add_web_url {
    my ($url) = @_;

    unless ($url) {
        die "Errore: URL è richiesto per aggiungere un URL web.\n";
    }

    my $dbh = connect_db();
    my $sth = $dbh->prepare("INSERT INTO web (url, attivo) VALUES (?, 1)");
    eval {
        $sth->execute($url);
    };
    if ($@) {
        warn "Errore durante l'inserimento dell'URL web: $@";
    } else {
        print "URL web aggiunto con successo: $url\n";
    }
    $sth->finish();
}

# Funzione per ottenere tutti gli URL web
sub get_all_web_urls {
    my $dbh = connect_db();
    my $sth = $dbh->prepare("SELECT id, url, attivo FROM web");
    $sth->execute();

    my @urls;
    while (my $row = $sth->fetchrow_hashref) {
        push @urls, $row;
    }

    $sth->finish();
    return \@urls;
}

# Funzione per ottenere tutti i dati web
sub get_all_web_data {
    my $dbh = connect_db();
    my $sth = $dbh->prepare("SELECT * FROM pages");
    $sth->execute();
    my $data = $sth->fetchall_arrayref({});
    $sth->finish();
    return $data;
}

# Funzione per aggiornare lo stato di un URL web (attivo/inattivo)
sub update_web_url_status {
    my ($id, $status) = @_;

    unless (defined $id && defined $status) {
        die "Errore: ID e stato sono richiesti per aggiornare lo stato di un URL web.\n";
    }

    my $dbh = connect_db();
    my $sth = $dbh->prepare("UPDATE web SET attivo = ? WHERE id = ?");
    eval {
        $sth->execute($status, $id);
    };
    if ($@) {
        warn "Errore durante l'aggiornamento dello stato dell'URL web: $@";
    } else {
        print "Stato dell'URL web aggiornato con successo: ID=$id, Stato=$status\n";
    }
    $sth->finish();
}

# Funzione per aggiungere una nuova impostazione
sub add_setting {
    my ($key, $value) = @_;

    unless ($key && defined $value) {
        die "Errore: chiave e valore sono richiesti per aggiungere una impostazione.\n";
    }

    my $dbh = connect_db();
    my $sth = $dbh->prepare("INSERT INTO settings (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value");
    eval {
        $sth->execute($key, $value);
    };
    if ($@) {
        warn "Errore durante l'aggiunta o l'aggiornamento dell'impostazione: $@";
    } else {
        print "Impostazione aggiunta o aggiornata: $key = $value\n";
    }
    $sth->finish();
}

# Funzione per aggiungere o aggiornare una impostazione
sub add_or_update_setting {
    my ($key, $value) = @_;
    my $dbh = connect_db();
    $dbh->do("INSERT INTO settings (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = ?", undef, $key, $value, $value);
}

# Alias compatibile per set_setting (usato in alcune interfacce)
sub set_setting {
    my ($key, $value) = @_;
    return add_or_update_setting($key, $value);
}

# Funzione per ottenere tutte le impostazioni
sub get_all_settings {
    my $dbh = connect_db();
    my $sth = $dbh->prepare("SELECT key, value FROM settings");
    $sth->execute();

    my %settings;
    while (my $row = $sth->fetchrow_hashref) {
        $settings{$row->{key}} = $row->{value};
    }

    $sth->finish();
    return \%settings;
}

# Funzione per eliminare un'impostazione
sub delete_setting {
    my ($key) = @_;

    unless ($key) {
        die "Errore: chiave è richiesta per eliminare un'impostazione.\n";
    }

    my $dbh = connect_db();
    my $sth = $dbh->prepare("DELETE FROM settings WHERE key = ?");
    eval {
        $sth->execute($key);
    };
    if ($@) {
        warn "Errore durante l'eliminazione dell'impostazione: $@";
    } else {
        print "Impostazione eliminata: $key\n";
    }
    $sth->finish();
}

# Funzione per verificare se un'impostazione esiste
sub setting_exists {
    my ($key) = @_;

    unless ($key) {
        die "Errore: chiave è richiesta per verificare l'esistenza di un'impostazione.\n";
    }

    my $dbh = connect_db();
    my $sth = $dbh->prepare("SELECT 1 FROM settings WHERE key = ?");
    $sth->execute($key);

    my $exists = $sth->fetchrow_arrayref ? 1 : 0;

    $sth->finish();
    return $exists;
}

# Funzione per ottenere i log
sub get_logs {
    my $dbh = connect_db();
    my $sth = $dbh->prepare("SELECT * FROM logs ORDER BY timestamp DESC LIMIT 100");
    $sth->execute();

    my @logs;
    while (my $row = $sth->fetchrow_hashref) {
        push @logs, $row;
    }

    $sth->finish();
    return \@logs;
}

# Funzione per ottenere tutti i riassunti
sub get_all_summaries {
    my $dbh = connect_db();
    my $sth = $dbh->prepare("SELECT * FROM summaries ORDER BY created_at DESC");
    $sth->execute();

    my @summaries;
    while (my $row = $sth->fetchrow_hashref) {
        push @summaries, $row;
    }

    $sth->finish();
    return \@summaries;
}

# Funzione per aggiungere un nuovo riassunto
sub add_summary {
    my ($page_id, $summary) = @_;

    unless ($page_id && $summary) {
        die "Errore: page_id e summary sono richiesti per aggiungere un riassunto.\n";
    }

    my $dbh = connect_db();
    my $sth = $dbh->prepare("INSERT INTO summaries (page_id, summary) VALUES (?, ?)");
    eval {
        $sth->execute($page_id, $summary);
    };
    if ($@) {
        warn "Errore durante l'aggiunta del riassunto: $@";
    } else {
        print "Riassunto aggiunto con successo.\n";
    }
    $sth->finish();
}

# Funzione per condividere un riassunto
sub share_summary {
    my ($summary_id, $recipient) = @_;

    unless ($summary_id && $recipient) {
        die "Errore: summary_id e recipient sono richiesti per condividere un riassunto.\n";
    }

    # Simulazione di condivisione (es. invio email o API esterna)
    print "Riassunto $summary_id condiviso con $recipient.\n";
}

# Aggiunge un canale di notifica
sub add_notification_channel {
    my ($name, $type, $config) = @_;
    my $dbh = connect_db();
    my $sth = $dbh->prepare("INSERT INTO notification_channels (name, type, config) VALUES (?, ?, ?)");
    $sth->execute($name, $type, $config);
    $sth->finish();
}

# Ottiene tutti i canali di notifica
sub get_notification_channels {
    my $dbh = connect_db();
    my $sth = $dbh->prepare("SELECT * FROM notification_channels WHERE active = 1");
    $sth->execute();
    my @channels;
    while (my $row = $sth->fetchrow_hashref) {
        push @channels, $row;
    }
    $sth->finish();
    return \@channels;
}

# Disattiva un canale di notifica
sub deactivate_notification_channel {
    my ($id) = @_;
    my $dbh = connect_db();
    my $sth = $dbh->prepare("UPDATE notification_channels SET active = 0 WHERE id = ?");
    $sth->execute($id);
    $sth->finish();
}

# Funzione per aggiungere un mittente
sub add_sender {
    my ($name, $type, $config) = @_;
    my $encrypted_config = encrypt_data($config);

    my $dbh = connect_db();
    my $sth = $dbh->prepare("INSERT INTO senders (name, type, config) VALUES (?, ?, ?)");
    $sth->execute($name, $type, $encrypted_config);
    $sth->finish();
}

# Funzione per ottenere tutti i mittenti
sub get_all_senders {
    my $dbh = connect_db();
    my $sth = $dbh->prepare("SELECT id, name, type, config, active FROM senders");
    $sth->execute();

    my @senders;
    while (my $row = $sth->fetchrow_hashref) {
        $row->{config} = decrypt_data($row->{config});
        push @senders, $row;
    }

    $sth->finish();
    return \@senders;
}

# Funzione per aggiornare un mittente
sub update_sender {
    my ($id, $name, $type, $config, $active) = @_;
    my $encrypted_config = encrypt_data($config);

    my $dbh = connect_db();
    my $sth = $dbh->prepare("UPDATE senders SET name = ?, type = ?, config = ?, active = ? WHERE id = ?");
    $sth->execute($name, $type, $encrypted_config, $active, $id);
    $sth->finish();
}

# Funzione per eliminare un mittente
sub delete_sender {
    my ($id) = @_;

    my $dbh = connect_db();
    my $sth = $dbh->prepare("DELETE FROM senders WHERE id = ?");
    $sth->execute($id);
    $sth->finish();
}

# Funzione per registrare un nuovo utente
sub register_user {
    my ($username, $password) = @_;

    unless ($username && $password) {
        die "Errore: username e password sono richiesti per registrare un utente.\n";
    }

    my $dbh = connect_db();
    my $sth = $dbh->prepare("INSERT INTO users (username, password) VALUES (?, ?)");
    eval {
        $sth->execute($username, encrypt_data($password));
    };
    if ($@) {
        warn "Errore durante la registrazione dell'utente: $@";
    } else {
        print "Utente registrato con successo: $username\n";
    }
    $sth->finish();
}

# Funzione per aggiungere un template
sub add_template {
    my ($name, $content) = @_;
    my $dbh = connect_db();
    my $sth = $dbh->prepare("INSERT INTO templates (name, content) VALUES (?, ?)");
    $sth->execute($name, $content);
    $sth->finish();
}

# Funzione per ottenere tutti i template
sub get_all_templates {
    my $dbh = connect_db();
    my $sth = $dbh->prepare("SELECT id, name, content FROM templates");
    $sth->execute();

    my @templates;
    while (my $row = $sth->fetchrow_hashref) {
        push @templates, $row;
    }

    $sth->finish();
    return \@templates;
}

# Funzione per aggiornare un template
sub update_template {
    my ($id, $name, $content) = @_;
    my $dbh = connect_db();
    my $sth = $dbh->prepare("UPDATE templates SET name = ?, content = ? WHERE id = ?");
    $sth->execute($name, $content, $id);
    $sth->finish();
}

# Funzione per eliminare un template
sub delete_template {
    my ($id) = @_;
    my $dbh = connect_db();
    my $sth = $dbh->prepare("DELETE FROM templates WHERE id = ?");
    $sth->execute($id);
    $sth->finish();
}

# Funzione per ottenere un template per nome
sub get_template_by_name {
    my ($name) = @_;
    my $dbh = connect_db();
    my $sth = $dbh->prepare("SELECT content FROM templates WHERE name = ?");
    $sth->execute($name);

    my $row = $sth->fetchrow_hashref;
    $sth->finish();
    return $row ? $row->{content} : undef;
}

1;

# Licenza BSD
# -----------------------------------------------------------------------------
# Copyright (c) 2024, Giacomo Picchiarelli
# All rights reserved.
#
# Ridistribuzione e uso nel formato sorgente e binario, con o senza modifiche,
# sono consentiti purché siano soddisfatte le seguenti condizioni:
#
# 1. Le ridistribuzioni del codice sorgente devono conservare l'avviso di copyright
#    di cui sopra, questo elenco di condizioni e il seguente disclaimer.
# 2. Le ridistribuzioni in formato binario devono riprodurre l'avviso di copyright,
#    questo elenco di condizioni e il seguente disclaimer nella documentazione
#    e/o nei materiali forniti con la distribuzione.
# 3. Né il nome dell'autore né i nomi dei suoi collaboratori possono essere utilizzati
#    per promuovere prodotti derivati da questo software senza un'autorizzazione
#    specifica scritta.
#
# QUESTO SOFTWARE È FORNITO "COSÌ COM'È" E QUALSIASI GARANZIA ESPRESSA O IMPLICITA
# È ESCLUSA. IN NESSUN CASO L'AUTORE SARÀ RESPONSABILE PER DANNI DERIVANTI
# DALL'USO DEL SOFTWARE.
# -----------------------------------------------------------------------------
