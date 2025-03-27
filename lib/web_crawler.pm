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
    my %config = config_manager::get_all_settings();
    my $max_processes = $config{MAX_PROCESSES};
    my $timeout = $config{CRAWLER_TIMEOUT};

    # Connessione al database
    my $dbh = DBI->connect("dbi:SQLite:dbname=infocollect.db", "", "", { RaiseError => 1, sqlite_unicode => 1, AutoCommit => 1 })
        or die "Errore di connessione al database: $DBI::errstr";

    # Prepara la query per ottenere gli URL da processare
    my $sth = $dbh->prepare("SELECT id, url FROM web WHERE attivo = 1");
    $sth->execute();

    # Configura l'UserAgent e il gestore dei processi paralleli
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

                # Estrai il titolo della pagina
                my $title = decode('utf-8', $tree->look_down(_tag => 'title') ? $tree->look_down(_tag => 'title')->as_text : '');

                # Rimuovi i tag HTML per ottenere il testo semplice
                my $hs = HTML::Strip->new();
                my $plain_text = $hs->parse($content);
                $hs->eof;

                # Genera un riassunto e identifica la lingua
                my ($riassunto, $lingua) = riassumi_contenuto($plain_text);

                # Recupera gli interessi dal database
                my $interessi_sth = $dbh->prepare("SELECT tema FROM interessi");
                $interessi_sth->execute();
                my @interessi = map { $_->[0] } @{$interessi_sth->fetchall_arrayref};

                # Verifica la rilevanza del contenuto rispetto agli interessi
                if (rilevanza_per_interessi($riassunto, \@interessi)) {
                    my $ins = $dbh->prepare("INSERT INTO riassunti (titolo, url, autore, data_pubblicazione, lingua, fonte, riassunto, testo_originale) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
                    $ins->execute($title, $url, undef, undef, $lingua, 'web', $riassunto, $plain_text);
                }

                $tree->delete;
            } else {
                warn "Errore fetching $url: " . $res->status_line;
            }
        };
        if ($@) {
            warn "Errore durante l'elaborazione dell'URL: $@";
        }

        $pm->finish;
    }

    $pm->wait_all_children;

    $sth->finish();
    $dbh->disconnect or warn "Errore durante la disconnessione dal database: $DBI::errstr";
}

1;