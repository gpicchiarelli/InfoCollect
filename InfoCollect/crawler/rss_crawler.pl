package rss_crawler;

use strict;
use warnings;
use DBI;
use LWP::UserAgent;
use XML::RSS;
use Time::Piece;
use threads;
use Thread::Queue;
use db;  # Importiamo il modulo db per la connessione al database

# Funzione per recuperare gli URL dei feed RSS non visitati da almeno 2 ore
sub get_feed_urls {
    my $dbh = db::connect_db();  # Usa la connessione dal modulo db
    
    my $sql = q{
        SELECT id, url FROM rss_feeds
        WHERE updated_at < datetime('now', '-2 hours')
    };
    
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    
    my @feeds;
    while (my $row = $sth->fetchrow_hashref) {
        push @feeds, { id => $row->{id}, url => $row->{url} };
    }
    
    $sth->finish();
    $dbh->disconnect();
    
    return @feeds;
}

# Funzione per aggiornare il timestamp del feed
sub update_feed_timestamp {
    my ($feed_id) = @_;
    
    my $dbh = db::connect_db();  # Usa la connessione dal modulo db
    my $sql = q{
        UPDATE rss_feeds
        SET updated_at = CURRENT_TIMESTAMP
        WHERE id = ?
    };
    
    my $sth = $dbh->prepare($sql);
    $sth->execute($feed_id);
    $sth->finish();
    $dbh->disconnect();
}

# Funzione per recuperare gli articoli da un feed RSS
sub crawl_feed {
    my ($feed_url, $feed_id, $queue) = @_;
    
    my $ua = LWP::UserAgent->new;
    my $response = $ua->get($feed_url);
    
    if ($response->is_success) {
        my $rss = XML::RSS->new;
        $rss->parse($response->decoded_content);
        
        my $dbh = db::connect_db();  # Usa la connessione dal modulo db
        
        foreach my $item (@{$rss->{items}}) {
            my $title = $item->{title};
            my $url = $item->{link};
            my $published_at = $item->{pubDate} ? Time::Piece->strptime($item->{pubDate}, "%a, %d %b %Y %H:%M:%S %z")->datetime : 'NULL';
            my $content = $item->{description} || '';
            my $author = $item->{author} || '';
            
            # Inserire l'articolo nel database se non esiste già
            my $check_sql = q{
                SELECT id FROM rss_articles
                WHERE url = ?
            };
            my $sth_check = $dbh->prepare($check_sql);
            $sth_check->execute($url);
            
            if ($sth_check->fetchrow_arrayref) {
                # Se l'articolo esiste già, non fare nulla
                $sth_check->finish();
                next;
            }
            
            $sth_check->finish();
            
            # Inserire il nuovo articolo
            my $insert_sql = q{
                INSERT INTO rss_articles (feed_id, title, url, published_at, content, author)
                VALUES (?, ?, ?, ?, ?, ?)
            };
            
            my $sth_insert = $dbh->prepare($insert_sql);
            $sth_insert->execute($feed_id, $title, $url, $published_at, $content, $author);
            $sth_insert->finish();
        }
        
        # Aggiornare la data di aggiornamento del feed
        update_feed_timestamp($feed_id);
        
        $dbh->disconnect();
    } else {
        warn "Errore nel recuperare il feed $feed_url: " . $response->status_line . "\n";
    }

    # Aggiungi al queue per segnalare che il thread ha finito
    $queue->enqueue($feed_url);
}

# Funzione principale per avviare il crawler
sub run_crawler {
    my @feeds = get_feed_urls();
    
    # Coda per gestire i thread
    my $queue = Thread::Queue->new();
    
    # Creare un thread per ogni feed
    my @threads;
    foreach my $feed (@feeds) {
        print "Avvio il crawling per il feed: $feed->{url}\n";
        my $thread = threads->create(\&crawl_feed, $feed->{url}, $feed->{id}, $queue);
        push @threads, $thread;
    }
    
    # Attendere che tutti i thread siano completati
    foreach my $thread (@threads) {
        $thread->join();
    }
    
    print "Crawling completato per tutti i feed.\n";
}

# Rendi il modulo utilizzabile con l'uso di `run_crawler`
1;  # Assicurati che il modulo restituisca un valore positivo


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
