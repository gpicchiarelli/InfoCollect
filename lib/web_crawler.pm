package web_crawler;

use strict;
use warnings;
use utf8;
use LWP::UserAgent;
use LWP::Protocol::https;
use Mozilla::CA;
use HTML::TreeBuilder;
use DBI;
use Encode qw(decode);
use HTML::Strip;
use Parallel::ForkManager;
use open ':std', ':encoding(UTF-8)';

use lib './lib';
use nlp qw(riassumi_contenuto rilevanza_per_interessi);
use config_manager;

=pod

=head1 NAME

web_crawler - Crawler parallelo di pagine web con riassunto NLP

=head1 DESCRIPTION

Scarica URL attivi da `web`, estrae titolo e genera riassunto (`nlp::riassumi_contenuto`),
salvando in `pages` con `summary`.

Cross-reference: docs/REFERENCE.md (Crawler).

=cut

=head1 FUNCTIONS

=over 4

=item esegui_crawler_web()

Scarica tutte le pagine per gli URL attivi in C<web>, estrae titolo e genera
riassunto con C<nlp::riassumi_contenuto>, salvando in C<pages> (incluso C<summary>). Parallelizza con C<Parallel::ForkManager>.

=back

=cut

sub esegui_crawler_web {
    my %config = eval { config_manager::get_all_settings() };
    if ($@) {
        warn "Errore durante il recupero delle impostazioni: $@";
        return;
    }

    my $max_processes = $config{MAX_PROCESSES} // 4;  # Valore predefinito
    my $timeout = $config{CRAWLER_TIMEOUT} // 10;    # Valore predefinito

    my $dbh = eval { db::connect_db() };
    if ($@) {
        die "Errore di connessione al database: $@";
    }

    my $sth = eval { $dbh->prepare("SELECT id, url FROM web WHERE attivo = 1") };
    if ($@) {
        warn "Errore durante la preparazione della query: $@";
        return;
    }

    $sth->execute();
    my $no_verify = $config{SSL_NO_VERIFY} ? 1 : 0;
    my %ssl = (
        verify_hostname => $no_verify ? 0 : 1,
    );
    if (!$no_verify) {
        eval { $ssl{SSL_ca_file} = Mozilla::CA::SSL_ca_file(); 1 } or warn "CA bundle non trovato: $@";
    } else {
        $ssl{SSL_verify_mode} = 0x00; # no verify
    }
    my $ua = LWP::UserAgent->new(timeout => $timeout, ssl_opts => \%ssl);
    my $pm = Parallel::ForkManager->new($max_processes);

    while (my $row = $sth->fetchrow_hashref) {
        # Stop se richiesto (generale o solo WEB)
        %config = config_manager::get_all_settings();
        last if ($config{CRAWLER_STOP} && $config{CRAWLER_STOP} == 1)
             || ($config{CRAWLER_WEB_STOP} && $config{CRAWLER_WEB_STOP} == 1);
        $pm->start and next;

        eval {
            my $url = $row->{url};
            next unless $url;

            my %cfg_now = config_manager::get_all_settings();
            if (($cfg_now{CRAWLER_STOP} && $cfg_now{CRAWLER_STOP} == 1)
             || ($cfg_now{CRAWLER_WEB_STOP} && $cfg_now{CRAWLER_WEB_STOP} == 1)) {
                print "Stop richiesto. Interrompo child WEB.\n";
                $pm->finish;
            }
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

                # Salva i dati nel database (nuova connessione per child post-fork)
                my $dbh_worker = db::connect_db();
                my $insert_sth = $dbh_worker->prepare("INSERT INTO pages (url, title, content, summary) VALUES (?, ?, ?, ?)");
                $insert_sth->execute($url, $title, $content, $summary);
                eval { db::add_log('INFO', "WEB: pagina aggiunta '$title' ($url)") };
            } else {
                my $err = "Errore durante il download dell'URL $url: " . $res->status_line;
                warn $err;
                eval { db::add_log('ERROR', $err) };
            }
        };
        if ($@) {
            my $err = "Errore durante l'elaborazione dell'URL: $@";
            warn $err;
            eval { db::add_log('ERROR', $err) };
        }

        $pm->finish;
    }

    $pm->wait_all_children;
    $sth->finish();
}

1;
