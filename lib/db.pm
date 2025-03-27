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