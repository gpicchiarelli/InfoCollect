package rss_crawler;

use strict;
use warnings;
use utf8;
use LWP::UserAgent;
use LWP::Protocol::https;
use Mozilla::CA;
use XML::RSS;
use DBI;
use Encode qw(decode);
use open ':std', ':encoding(UTF-8)';
use Parallel::ForkManager;

use lib './lib';
use config_manager;

=pod

=head1 NAME

rss_crawler - Crawler parallelo di feed RSS

=head1 DESCRIPTION

Recupera i feed RSS, effettua il parsing e inserisce articoli in `rss_articles`.
Onora `CRAWLER_TIMEOUT` e `MAX_PROCESSES` dalle impostazioni.

Cross-reference: docs/REFERENCE.md (Crawler).

=cut

=head1 FUNCTIONS

=over 4

=item esegui_crawler_rss()

Itera su tutti i feed in C<rss_feeds>, scarica e parse i contenuti RSS,
inserendo nuovi item in C<rss_articles>. Parallelizza con C<Parallel::ForkManager>.

=back

=cut

# Funzione principale per eseguire il crawler RSS
sub esegui_crawler_rss {
    my %config = config_manager::get_all_settings();
    my $timeout = $config{CRAWLER_TIMEOUT};
    my $max_processes = $config{MAX_PROCESSES};

    # Connessione al database
    my $dbh = db::connect_db();

    # Recupera tutti i feed RSS dal database
    my $sth = $dbh->prepare("SELECT id, url FROM rss_feeds");
    $sth->execute();

    # Configura l'UserAgent per le richieste HTTP
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

    while (my $feed = $sth->fetchrow_hashref) {
        # Stop se richiesto (generale o solo RSS)
        %config = config_manager::get_all_settings();
        last if ($config{CRAWLER_STOP} && $config{CRAWLER_STOP} == 1)
             || ($config{CRAWLER_RSS_STOP} && $config{CRAWLER_RSS_STOP} == 1);
        $pm->start and next;

        eval {
            print "Elaborazione del feed RSS: $feed->{url}\n";

            # Effettua la richiesta HTTP per il feed RSS
            my %cfg_now = config_manager::get_all_settings();
            if (($cfg_now{CRAWLER_STOP} && $cfg_now{CRAWLER_STOP} == 1)
             || ($cfg_now{CRAWLER_RSS_STOP} && $cfg_now{CRAWLER_RSS_STOP} == 1)) {
                print "Stop richiesto. Interrompo child RSS.\n";
                $pm->finish;
            }
            my $response = $ua->get($feed->{url});
            if ($response->is_success) {
                my $rss_content = $response->decoded_content;

                # Analizza il contenuto RSS
                my $rss = XML::RSS->new();
                $rss->parse($rss_content);

                foreach my $item (@{$rss->{items}}) {
                    my $title       = decode('utf-8', $item->{title} // '');
                    my $url         = $item->{link} // '';
                    my $published   = $item->{pubDate} // undef;
                    my $content     = decode('utf-8', $item->{description} // '');
                    my $author      = decode('utf-8', $item->{author} // '');

                    # Salta se l'URL è vuoto o già presente nel database
                    next unless $url;
                    my $exists_sth = $dbh->prepare("SELECT 1 FROM rss_articles WHERE url = ?");
                    $exists_sth->execute($url);
                    next if $exists_sth->fetchrow_array;

                    # Inserisce l'articolo nel database
                    my $insert_sth = $dbh->prepare(q{
                        INSERT INTO rss_articles (feed_id, title, url, published_at, content, author)
                        VALUES (?, ?, ?, ?, ?, ?)
                    });
                    $insert_sth->execute($feed->{id}, $title, $url, $published, $content, $author);

                    print "Articolo aggiunto: $title ($url)\n";
                }
            } else {
                warn "Errore nel recupero del feed $feed->{url}: " . $response->status_line;
            }
        };
        if ($@) {
            warn "Errore durante l'elaborazione del feed $feed->{url}: $@";
        }

        $pm->finish;
    }

    $pm->wait_all_children;

    # Chiude il cursore e la connessione al database
    $sth->finish();
    $dbh->disconnect or warn "Errore durante la disconnessione dal database: $DBI::errstr";

    print "Crawler RSS completato.\n";
}

1;
