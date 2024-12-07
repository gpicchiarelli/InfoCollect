#!/usr/bin/env perl
use strict;
use warnings;
use LWP::UserAgent;
use HTML::TreeBuilder;
use DBI;
use JSON;
use Thread::Queue;
use threads;
use threads::shared;
use Time::HiRes qw(gettimeofday);
use db; # Il modulo db.pl che gestisce il database

# URL iniziali per iniziare la scansione
my @start_urls = ('https://www.example.com', 'https://www.wikipedia.org');

# Coda per i URL da scaricare
my $queue :shared = Thread::Queue->new();

# Numero di thread di crawling
my $num_threads = 5;

# Funzione per scaricare e analizzare la pagina
sub crawl_page {
    my ($url) = @_;

    # Creare un oggetto UserAgent
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);  # Timeout di 10 secondi

    my $response = $ua->get($url);
    if ($response->is_success) {
        # Estrai il contenuto HTML della pagina
        my $content = $response->decoded_content;
        
        # Estrai il titolo della pagina (usiamo HTML::TreeBuilder per analizzare)
        my $tree = HTML::TreeBuilder->new_from_content($content);
        my $title = $tree->look_down(_tag => 'title')->as_text || 'No Title';

        # Estrai i metadati come esempio (puoi aggiungere più metadati in base alle necessità)
        my $metadata = {
            description => $tree->look_down(_tag => 'meta', name => 'description')->attr('content') || 'No Description',
            keywords    => $tree->look_down(_tag => 'meta', name => 'keywords')->attr('content') || 'No Keywords',
        };

        # Gestione delle copie
        if (db::check_url_count($url) >= 5) {
            db::remove_oldest_copy($url);  # Rimuove la copia più vecchia
        }

        # Inserisci nel database
        db::insert_page($url, $title, $content, $metadata);
        print "Pagina crawled: $url\n";
    }
    else {
        print "Errore nel recupero della pagina $url: " . $response->status_line . "\n";
    }
}

# Funzione per recuperare gli URL dal database che non sono stati visitati negli ultimi 2 ore
sub get_urls_to_crawl {
    my $dbh = db::connect_db();

    # Calcola il timestamp di 2 ore fa
    my $timestamp = `date -u +"%Y-%m-%d %H:%M:%S" -d "2 hours ago"`;
    chomp($timestamp); # Rimuovi eventuali newline

    # Query per selezionare gli URL che non sono stati visitati nelle ultime 2 ore
    my $sth = $dbh->prepare("SELECT url FROM pages WHERE visited_at < ?");
    $sth->execute($timestamp);

    my @urls;
    while (my @row = $sth->fetchrow_array) {
        push @urls, $row[0];
    }

    $dbh->disconnect;
    return @urls;
}

# Funzione per scaricare i URL dalla coda (multithreading)
sub worker {
    while (my $url = $queue->dequeue()) {
        crawl_page($url);
    }
}

# Funzione per iniziare il crawling
sub start_crawling {
    # Aggiungi gli URL iniziali alla coda
    foreach my $url (@start_urls) {
        $queue->enqueue($url);
    }

    # Aggiungi gli URL dal database (che non sono stati visitati nelle ultime 2 ore)
    my @db_urls = get_urls_to_crawl();
    foreach my $url (@db_urls) {
        $queue->enqueue($url);
    }

    # Creazione dei thread di crawling
    my @threads;
    for (1..$num_threads) {
        push @threads, threads->create(\&worker);
    }

    # Aspetta che tutti i thread finiscano
    $_->join() for @threads;
}

# Avvia il crawler
start_crawling();


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

