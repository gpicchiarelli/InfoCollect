#!/usr/bin/env perl

use strict;
use warnings;
use DBI;

my $db_file = "infocollect.db";
my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file", "", "", {
    RaiseError => 1,
    AutoCommit => 1,
});

print "Inizializzazione database '$db_file'...\n";

# Tabella feed RSS
$dbh->do(q{
    CREATE TABLE IF NOT EXISTS feeds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        url TEXT NOT NULL,
        added_at TEXT
    )
});

# Tabella pagine raccolte
$dbh->do(q{
    CREATE TABLE IF NOT EXISTS pages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL,
        title TEXT,
        content TEXT,
        metadata TEXT,
        visited_at TEXT
    )
});

# Tabella impostazioni
$dbh->do(q{
    CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT
    )
});

# Tabella riassunti associati a pagine
$dbh->do(q{
    CREATE TABLE IF NOT EXISTS summaries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        page_id INTEGER,
        summary TEXT,
        created_at TEXT,
        FOREIGN KEY(page_id) REFERENCES pages(id)
    )
});

# Tabella autori (opzionale per metadati estesi)
$dbh->do(q{
    CREATE TABLE IF NOT EXISTS authors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT,
        affiliation TEXT
    )
});

# Tabella web se si vuole gestire crawling diretto su siti
$dbh->do(q{
    CREATE TABLE IF NOT EXISTS web (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL,
        attivo INTEGER DEFAULT 1
    )
});

print "Database inizializzato correttamente.\n";
$dbh->disconnect;

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
