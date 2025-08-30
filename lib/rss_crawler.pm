package rss_crawler;

use strict;
use warnings;
use utf8;
use LWP::UserAgent;
use LWP::Protocol::https;
use Mozilla::CA;
use XML::RSS;
use XML::Simple;
use DBI;
use Encode qw(decode);
use open ':std', ':encoding(UTF-8)';
use Parallel::ForkManager;
use Time::HiRes qw(time);

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
    my ($feeds_count) = eval { $dbh->selectrow_array('SELECT COUNT(*) FROM rss_feeds') };
    if (!$feeds_count) {
        eval { db::add_log('WARN', 'RSS: nessun feed configurato') };
        print "Nessun feed RSS configurato.\n";
        $sth->finish();
        return;
    }

    my $t0 = time();

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
    $ua->agent('InfoCollectRSS/1.0');
    my $use_fork = ($max_processes && $max_processes > 1) ? 1 : 0;
    my $pm = $use_fork ? Parallel::ForkManager->new($max_processes) : undef;

    while (my $feed = $sth->fetchrow_hashref) {
        # Stop se richiesto (generale o solo RSS)
        %config = config_manager::get_all_settings();
        last if ($config{CRAWLER_STOP} && $config{CRAWLER_STOP} == 1)
             || ($config{CRAWLER_RSS_STOP} && $config{CRAWLER_RSS_STOP} == 1);
        if ($use_fork) { $pm->start and next; }

        eval {
            print "Elaborazione del feed RSS: $feed->{url}\n";
            eval { db::add_log('INFO', "RSS: elaborazione feed $feed->{url}") };

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
                my $items = [];
                eval {
                    my $rss = XML::RSS->new();
                    $rss->parse($rss_content);
                    $items = $rss->{items} if $rss && $rss->{items} && @{$rss->{items}};
                };
                if (!@$items) {
                    # Fallback: parsing generico (RSS/Atom) con XML::Simple
                    my $xs = XML::Simple->new(KeyAttr => [], ForceArray => [qw(item entry link)]);
                    my $data = eval { $xs->XMLin($rss_content) };
                    if ($data) {
                        # RSS 2.0: channel->item[]
                        if ($data->{channel} && $data->{channel}->{item}) {
                            $items = $data->{channel}->{item};
                        }
                        # Atom: feed->entry[]
                        elsif ($data->{entry}) {
                            $items = $data->{entry};
                        }
                    }
                }

                # Ogni child usa una nuova connessione DB (post-fork)
                my $dbh_worker = db::connect_db();

                my $added = 0;
                foreach my $item (@$items) {
                    # Normalizza campi RSS/Atom
                    my $title = '';
                    if (ref($item->{title}) eq 'HASH') {
                        $title = decode('utf-8', $item->{title}->{content} // '');
                    } else {
                        $title = decode('utf-8', $item->{title} // '');
                    }
                    my $url = '';
                    if (ref($item->{link}) eq 'HASH') {
                        # Atom: array di <link>; cerca rel=self|alternate
                        my @links = ref($item->{link}) eq 'ARRAY' ? @{$item->{link}} : ($item->{link});
                        my ($alt) = grep { (($_->{rel}//'') eq 'alternate') && $_->{href} } @links;
                        $url = $alt ? $alt->{href} : ($links[0]->{href} // '');
                    } else {
                        $url = $item->{link} // '';
                    }
                    my $published = $item->{pubDate} // $item->{published} // $item->{updated} // undef;
                    my $content = '';
                    if (exists $item->{description}) {
                        $content = decode('utf-8', $item->{description} // '');
                    } elsif (exists $item->{summary}) {
                        $content = decode('utf-8', $item->{summary} // '');
                    } elsif (exists $item->{content}) {
                        if (ref($item->{content}) eq 'HASH') { $content = decode('utf-8', $item->{content}->{content} // ''); }
                        else { $content = decode('utf-8', $item->{content} // ''); }
                    }
                    my $author = '';
                    if (ref($item->{author}) eq 'HASH') { $author = decode('utf-8', $item->{author}->{name} // ''); }
                    else { $author = decode('utf-8', $item->{author} // ''); }

                    # Salta se l'URL è vuoto o già presente nel database
                    next unless $url;
                    my $exists_sth = $dbh_worker->prepare("SELECT 1 FROM rss_articles WHERE url = ?");
                    $exists_sth->execute($url);
                    next if $exists_sth->fetchrow_array;

                    # Inserisce l'articolo nel database
                    my $insert_sth = $dbh_worker->prepare(q{
                        INSERT INTO rss_articles (feed_id, title, url, published_at, content, author)
                        VALUES (?, ?, ?, ?, ?, ?)
                    });
                    $insert_sth->execute($feed->{id}, $title, $url, $published, $content, $author);

                    print "Articolo aggiunto: $title ($url)\n";
                    eval { db::add_log('INFO', "RSS: articolo aggiunto '$title'") };
                    $added++;
                }
                eval { db::add_log('INFO', "RSS: feed $feed->{url} — nuovi: $added") };
            } else {
                my $err = "Errore nel recupero del feed $feed->{url}: " . $response->status_line;
                warn $err;
                eval { db::add_log('ERROR', $err) };
            }
        };
        if ($@) {
            my $err = "Errore durante l'elaborazione del feed $feed->{url}: $@";
            warn $err;
            eval { db::add_log('ERROR', $err) };
        }

        if ($use_fork) { $pm->finish; }
    }

    $pm->wait_all_children if $use_fork;

    # Chiude il cursore (lascia la connessione del padre attiva)
    $sth->finish();

    my $dt = sprintf('%.2f', time() - $t0);
    eval { db::add_log('INFO', "RSS: crawler completato in ${dt}s per $feeds_count feed") };
    print "Crawler RSS completato in ${dt}s.\n";
}

1;
