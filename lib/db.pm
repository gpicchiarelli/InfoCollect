package db;

use strict;
use warnings;
use DBI;
use JSON;
use Time::HiRes qw(gettimeofday);

# Nome del database SQLite
my $db_file = 'infocollect.db';

# Funzione per connettersi al database
sub connect_db {
    unless (-e $db_file) {
        die "Errore: il database '$db_file' non esiste. Esegui init_db.pm per inizializzarlo.\n";
    }
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file", "", "", {
        RaiseError => 1,
        AutoCommit => 1,
    }) or die $DBI::errstr;
    return $dbh;
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
    $dbh->disconnect();
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
    $dbh->disconnect();
    return \@feeds;
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
    $dbh->disconnect();
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
    $dbh->disconnect();
    return \@urls;
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
    $dbh->disconnect();
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
    $dbh->disconnect();
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
    $dbh->disconnect();
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
    $dbh->disconnect();
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
    $dbh->disconnect();
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
    $dbh->disconnect();
    return \@logs;
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