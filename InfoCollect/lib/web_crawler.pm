
package web_crawler;

use strict;
use warnings;
use utf8;
use LWP::UserAgent;
use HTML::TreeBuilder;
use DBI;
use Encode qw(decode);
use HTML::Strip;
use Parallel::ForkManager;
use open ':std', ':encoding(UTF-8)';

use lib './lib';
use nlp qw(riassumi_contenuto rilevanza_per_interessi);
use config_manager;

my $MAX_PROCESSES = 10;

sub esegui_crawler_web {
    my $config = config_manager::carica_configurazione();
    my $db_path = $config->{database};

    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_path", "", "", { RaiseError => 1, sqlite_unicode => 1 });

    my $sth = $dbh->prepare("SELECT id, url FROM web WHERE attivo = 1");
    $sth->execute();

    my $ua = LWP::UserAgent->new(timeout => 10);
    my $pm = Parallel::ForkManager->new($MAX_PROCESSES);

    while (my $row = $sth->fetchrow_hashref) {
        $pm->start and next;

        my $url = $row->{url};

        my $res = $ua->get($url);
        if ($res->is_success) {
            my $content = $res->decoded_content;
            my $tree = HTML::TreeBuilder->new_from_content($content);

            my $title = decode('utf-8', $tree->look_down(_tag => 'title') ? $tree->look_down(_tag => 'title')->as_text : '');

            my $hs = HTML::Strip->new();
            my $plain_text = $hs->parse($content);
            $hs->eof;

            my ($riassunto, $lingua) = riassumi_contenuto($plain_text);

            my $interessi_sth = $dbh->prepare("SELECT tema FROM interessi");
            $interessi_sth->execute();
            my @interessi = map { $_->[0] } @{$interessi_sth->fetchall_arrayref};

            if (rilevanza_per_interessi($riassunto, \@interessi)) {
                my $ins = $dbh->prepare("INSERT INTO riassunti (titolo, url, autore, data_pubblicazione, lingua, fonte, riassunto, testo_originale) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
                $ins->execute($title, $url, undef, undef, $lingua, 'web', $riassunto, $plain_text);
            }

            my $meta_sth = $dbh->prepare("INSERT INTO pages (url, title, content, metadata) VALUES (?, ?, ?, ?)");
            $meta_sth->execute($url, $title, $plain_text, '');

            $tree->delete;
        } else {
            warn "Errore fetching $url: " . $res->status_line;
        }

        $pm->finish;
    }

    $pm->wait_all_children;
    $dbh->disconnect;
}

1;
