package rss_crawler;

use strict;
use warnings;
use utf8;
use LWP::UserAgent;
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

# Funzione principale per eseguire il crawler RSS
sub esegui_crawler_rss {
    my %config = config_manager::get_all_settings();
    my $timeout = $config{CRAWLER_TIMEOUT};
    my $max_processes = $config{MAX_PROCESSES};

    # Connessione al database
    my $dbh = DBI->connect("dbi:SQLite:dbname=infocollect.db", "", "", { RaiseError => 1, sqlite_unicode => 1, AutoCommit => 1 })
        or die "Errore di connessione al database: $DBI::errstr";

    # Recupera tutti i feed RSS dal database
    my $sth = $dbh->prepare("SELECT id, url FROM rss_feeds");
    $sth->execute();

    # Configura l'UserAgent per le richieste HTTP
    my $ua = LWP::UserAgent->new(timeout => $timeout);
    my $pm = Parallel::ForkManager->new($max_processes);

    while (my $feed = $sth->fetchrow_hashref) {
        $pm->start and next;

        eval {
            print "Elaborazione del feed RSS: $feed->{url}\n";

            # Effettua la richiesta HTTP per il feed RSS
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
