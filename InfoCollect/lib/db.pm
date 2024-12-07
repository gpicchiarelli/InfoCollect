package db;

use strict;
use warnings;
use DBI;
use Time::HiRes qw(gettimeofday);

# Nome del database SQLite
my $db_file = 'infocollect.db';

# Funzione per connettersi al database
sub connect_db {
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file", "", "", {
        RaiseError => 1,
        AutoCommit => 1,
    }) or die $DBI::errstr;
    return $dbh;
}

# Funzione per ottenere il timestamp con millisecondi
sub get_timestamp {
    my ($seconds, $microseconds) = gettimeofday();
    my $milliseconds = int($microseconds / 1000);
    my ($sec, $min, $hour, $day, $month, $year) = (localtime($seconds))[0,1,2,3,4,5];
    return sprintf("%04d-%02d-%02d %02d:%02d:%02d.%03d",
                   $year + 1900, $month + 1, $day, $hour, $min, $sec, $milliseconds);
}

# Funzione per inserire una pagina nel database
sub insert_page {
    my ($url, $title, $content, $metadata) = @_;
    
    my $dbh = connect_db();
    
    # Ottieni il timestamp corrente
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
    my $timestamp = sprintf("%04d-%02d-%02d %02d:%02d:%02d",
        $year + 1900, $mon + 1, $mday, $hour, $min, $sec);

    # Prepara la query per inserire i dati
    my $sth = $dbh->prepare("INSERT INTO pages (url, title, content, metadata, visited_at) VALUES (?, ?, ?, ?, ?)");
    $sth->execute($url, $title, $content, encode_json($metadata), $timestamp);

    $dbh->disconnect;
}

# Funzione per verificare quante copie di un URL esistono nel database
sub check_url_count {
    my ($url) = @_;
    
    my $dbh = connect_db();
    
    # Query per contare quante righe esistono per questo URL
    my $sth = $dbh->prepare("SELECT COUNT(*) FROM pages WHERE url = ?");
    $sth->execute($url);
    
    my ($count) = $sth->fetchrow_array;
    
    $dbh->disconnect;
    return $count;
}

# Funzione per rimuovere la copia più vecchia di un URL, se ce ne sono più di 5
sub remove_oldest_copy {
    my ($url) = @_;

    my $dbh = connect_db();
    
    # Trova e rimuovi la copia più vecchia di questo URL
    my $sth = $dbh->prepare("DELETE FROM pages WHERE url = ? ORDER BY visited_at ASC LIMIT 1");
    $sth->execute($url);
    
    $dbh->disconnect;
}

# Funzione per ottenere tutte le pagine visitate
sub get_pages {
    my $dbh = connect_db();
    my $sth = $dbh->prepare("SELECT url, title, content, metadata, visited_at FROM pages");
    $sth->execute();
    my @pages;
    while (my @row = $sth->fetchrow_array) {
        push @pages, {
            url        => $row[0],
            title      => $row[1],
            content    => $row[2],
            metadata   => decode_json($row[3]),
            visited_at => $row[4],
        };
    }
    $dbh->disconnect;
    return \@pages;
}

# Aggiungi un nuovo feed RSS al database
sub add_rss_feed {
    my ($title, $url) = @_;

    my $sth = $dbh->prepare(q{
        INSERT INTO rss_feeds (title, url, published_at)
        VALUES (?, ?, CURRENT_TIMESTAMP)
    });
    $sth->execute($title, $url);
}

# Ottieni tutti i feed RSS dal database
sub get_all_rss_feeds {
    my $sth = $dbh->prepare(q{
        SELECT title, url FROM rss_feeds
    });
    $sth->execute();
    return $sth->fetchall_arrayref({});
}

# Inserimento di un nuovo feed RSS nel database
sub insert_feed {
    my ($title, $url, $published_at, $source) = @_;

    my $dbh = connect_db();
    my $sth = $dbh->prepare("INSERT INTO rss_feeds (title, url, published_at, source) VALUES (?, ?, ?, ?)");
    $sth->execute($title, $url, $published_at, $source);
    $sth->finish();
    $dbh->disconnect();
}

# Inserimento di un articolo RSS nel database
sub insert_article {
    my ($feed_id, $title, $url, $published_at, $content, $author) = @_;

    my $dbh = connect_db();
    my $sth = $dbh->prepare("INSERT INTO rss_articles (feed_id, title, url, published_at, content, author) VALUES (?, ?, ?, ?, ?, ?)");
    $sth->execute($feed_id, $title, $url, $published_at, $content, $author);
    $sth->finish();
    $dbh->disconnect();
}

# Funzione per ottenere gli URL dei feed RSS dal database
sub get_feeds_from_db {
    my @feeds;
    
    my $dbh = connect_db();
    my $sth = $dbh->prepare("SELECT id, url FROM rss_feeds");
    $sth->execute();

    while (my @row = $sth->fetchrow_array) {
        push @feeds, { id => $row[0], url => $row[1] };
    }

    $sth->finish();
    $dbh->disconnect();
    
    return @feeds;
}

# Funzione per ottenere gli articoli di un feed RSS
sub get_articles_from_feed {
    my ($feed_id) = @_;
    
    my @articles;
    
    my $dbh = connect_db();
    my $sth = $dbh->prepare("SELECT * FROM rss_articles WHERE feed_id = ?");
    $sth->execute($feed_id);

    while (my $row = $sth->fetchrow_hashref) {
        push @articles, $row;
    }

    $sth->finish();
    $dbh->disconnect();
    
    return @articles;
}

1;  # Necessario per i moduli Perl

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
