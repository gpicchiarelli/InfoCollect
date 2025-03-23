package rss_crawler;

use strict;
use warnings;
use utf8;
use LWP::UserAgent;
use XML::RSS;
use DBI;
use Parallel::ForkManager;
use HTML::Strip;
use Encode qw(decode);
use open ':std', ':encoding(UTF-8)';

use lib './lib';
use nlp qw(riassumi_contenuto rilevanza_per_interessi);
use config_manager;

my $MAX_PROCESSES = 10;

sub esegui_crawler_rss {
    my $config = config_manager::carica_configurazione();
    my $db_path = $config->{database};

    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_path", "", "", { RaiseError => 1, sqlite_unicode => 1 });

    my $sth = $dbh->prepare("SELECT id, url, fonte FROM rss WHERE attivo = 1");
    $sth->execute();

    my $ua = LWP::UserAgent->new(timeout => 10);
    my $pm = Parallel::ForkManager->new($MAX_PROCESSES);

    while (my $row = $sth->fetchrow_hashref) {
        $pm->start and next;

        my $rss_url = $row->{url};
        my $fonte   = $row->{fonte};
        my $rss_id  = $row->{id};

        my $res = $ua->get($rss_url);
        if ($res->is_success) {
            my $rss = XML::RSS->new();
            eval { $rss->parse($res->decoded_content); };
            if ($@) {
                warn "Errore parsing RSS $rss_url: $@";
                $pm->finish;
            }

            my $interessi_sth = $dbh->prepare("SELECT tema FROM interessi");
            $interessi_sth->execute();
            my @interessi = map { $_->[0] } @{$interessi_sth->fetchall_arrayref};

            foreach my $item (@{ $rss->{items} }) {
                my $titolo = decode('utf-8', $item->{title} // '');
                my $link   = $item->{link} // '';
                my $descr  = decode('utf-8', $item->{description} // '');
                my $autore = $item->{author} // '';
                my $data   = $item->{pubDate} // '';

                my $hs = HTML::Strip->new();
                my $testo_pulito = $hs->parse($descr);
                $hs->eof;

                my ($riassunto, $lingua) = riassumi_contenuto($testo_pulito);

                if (rilevanza_per_interessi($riassunto, \@interessi)) {
                    my $ins = $dbh->prepare("INSERT INTO riassunti (titolo, url, autore, data_pubblicazione, lingua, fonte, riassunto, testo_originale) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
                    $ins->execute($titolo, $link, $autore, $data, $lingua, $fonte, $riassunto, $testo_pulito);
                }
            }
        } else {
            warn "Errore fetching RSS $rss_url: " . $res->status_line;
        }

        $pm->finish;
    }

    $pm->wait_all_children;
    $dbh->disconnect;
}

1;