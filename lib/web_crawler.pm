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

sub esegui_crawler_web {
    my %config = eval { config_manager::get_all_settings() };
    if ($@) {
        warn "Errore durante il recupero delle impostazioni: $@";
        return;
    }

    my $max_processes = $config{MAX_PROCESSES} // 4;  # Valore predefinito
    my $timeout = $config{CRAWLER_TIMEOUT} // 10;    # Valore predefinito

    my $dbh = eval {
        DBI->connect("dbi:SQLite:dbname=infocollect.db", "", "", { RaiseError => 1, sqlite_unicode => 1, AutoCommit => 1 });
    };
    if ($@) {
        die "Errore di connessione al database: $@";
    }

    my $sth = eval { $dbh->prepare("SELECT id, url FROM web WHERE attivo = 1") };
    if ($@) {
        warn "Errore durante la preparazione della query: $@";
        return;
    }

    $sth->execute();
    my $ua = LWP::UserAgent->new(timeout => $timeout);
    my $pm = Parallel::ForkManager->new($max_processes);

    while (my $row = $sth->fetchrow_hashref) {
        $pm->start and next;

        eval {
            my $url = $row->{url};
            next unless $url;

            my $res = $ua->get($url);
            if ($res->is_success) {
                my $content = $res->decoded_content;

                # Analizza il contenuto HTML
                my $tree = HTML::TreeBuilder->new_from_content($content);
                my $title = decode('utf-8', $tree->look_down(_tag => 'title') ? $tree->look_down(_tag => 'title')->as_text : '');

                # Riassunto tramite NLP
                my $summary = eval { nlp::riassumi_contenuto($content) };
                if ($@) {
                    warn "Errore durante il riassunto del contenuto: $@";
                    $summary = "Riassunto non disponibile";
                }

                # Salva i dati nel database
                my $insert_sth = $dbh->prepare("INSERT INTO pages (url, title, content, summary) VALUES (?, ?, ?, ?)");
                $insert_sth->execute($url, $title, $content, $summary);
            } else {
                warn "Errore durante il download dell'URL $url: " . $res->status_line;
            }
        };
        if ($@) {
            warn "Errore durante l'elaborazione dell'URL: $@";
        }

        $pm->finish;
    }

    $pm->wait_all_children;
    $sth->finish();
    $dbh->disconnect();
}

1;