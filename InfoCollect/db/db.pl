#!/usr/bin/env perl
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

# Funzione per inserire un nuovo feed con timestamp preciso
sub insert_feed {
    my ($title, $url) = @_;
    my $dbh = connect_db();
    my $timestamp = get_timestamp();
    my $sth = $dbh->prepare("INSERT INTO feeds (title, url, fetched_at) VALUES (?, ?, ?)");
    $sth->execute($title, $url, $timestamp);
    $dbh->disconnect;
}

# Funzione per ottenere tutti i feed
sub get_feeds {
    my $dbh = connect_db();
    my $sth = $dbh->prepare("SELECT title, url, fetched_at FROM feeds");
    $sth->execute();
    my @feeds;
    while (my @row = $sth->fetchrow_array) {
        push @feeds, { title => $row[0], url => $row[1], fetched_at => $row[2] };
    }
    $dbh->disconnect;
    return \@feeds;
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
