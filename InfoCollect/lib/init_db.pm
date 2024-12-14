package init_db;

use strict;
use warnings;
use DBI;

sub Inizializza {
    # Nome del database SQLite
    my $db_file = 'infocollect.db';
    
    if (-e $db_file) {return;}
    
    # Connettersi al database SQLite (crea il file se non esiste)
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file", "", "", {
        RaiseError => 1,
        AutoCommit => 1,
    }) or die $DBI::errstr;
    
    # Creare la tabella per le impostazioni
    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT NOT NULL
        )
    }) or die $dbh->errstr;
    
    # Creare la tabella per i feed RSS con timestamp fino al millisecondo
    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS rss_feeds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        url TEXT NOT NULL UNIQUE,
        published_at DATETIME NOT NULL,
        source TEXT,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    }) or die $dbh->errstr;
    
    # Creare la tabella per gli articoli RSS
    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS rss_articles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        feed_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        url TEXT NOT NULL UNIQUE,
        published_at DATETIME NOT NULL,
        content TEXT,
        author TEXT,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (feed_id) REFERENCES rss_feeds(id) ON DELETE CASCADE
        )
    }) or die $dbh->errstr;
    
    # Creare la tabella per le pagine web visitate
    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS pages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL,
        title TEXT,
        content TEXT,
        metadata TEXT,
        visited_at TEXT DEFAULT (strftime('%Y-%m-%d %H:%M:%f', 'now'))
        )
    }) or die $dbh->errstr;
    
    print "Database e tabelle creati con successo.\n";
    
    # Chiudere la connessione
    $dbh->disconnect;
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
