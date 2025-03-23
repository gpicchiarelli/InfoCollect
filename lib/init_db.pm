package init_db;

use strict;
use warnings;
use DBI;

sub inizializza_db {
    my ($db_path) = @_;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_path", "", "", { RaiseError => 1, sqlite_unicode => 1 });

    # Tabella per interessi (temi chiave)
    $dbh->do(qq{
        CREATE TABLE IF NOT EXISTS interessi (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tema TEXT NOT NULL UNIQUE
        )
    });

    # Tabella per riassunti con metadati
    $dbh->do(qq{
        CREATE TABLE IF NOT EXISTS riassunti (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            titolo TEXT,
            url TEXT,
            autore TEXT,
            data_pubblicazione TEXT,
            lingua TEXT,
            fonte TEXT,
            riassunto TEXT,
            testo_originale TEXT
        )
    });

    $dbh->disconnect;
}

1;