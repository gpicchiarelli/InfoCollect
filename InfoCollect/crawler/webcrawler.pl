package WebCrawler;

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
use db;  # Il modulo db.pl che gestisce il database

# Costruttore del modulo
sub new {
    my ($class, %args) = @_;
    my $self = {
        start_urls => $args{start_urls} || ['https://www.example.com', 'https://www.wikipedia.org'],
        num_threads => $args{num_threads} || 5,
        queue => Thread::Queue->new(),
    };
    bless $self, $class;
    return $self;
}

# Funzione per scaricare e analizzare la pagina
sub crawl_page {
    my ($self, $url) = @_;
    
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
    my ($self) = @_;
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
    my ($self) = @_;
    while (my $url = $self->{queue}->dequeue()) {
        $self->crawl_page($url);
    }
}

# Funzione per avviare il processo di crawling
sub start_crawling {
    my ($self) = @_;

    # Aggiungi gli URL iniziali alla coda
    foreach my $url (@{$self->{start_urls}}) {
        $self->{queue}->enqueue($url);
    }

    # Aggiungi gli URL dal database (che non sono stati visitati nelle ultime 2 ore)
    my @db_urls = $self->get_urls_to_crawl();
    foreach my $url (@db_urls) {
        $self->{queue}->enqueue($url);
    }

    # Creazione dei thread di crawling
    my @threads;
    for (1..$self->{num_threads}) {
        push @threads, threads->create(sub { $self->worker() });
    }

    # Aspetta che tutti i thread finiscano
    $_->join() for @threads;
}

1;  # Il modulo deve restituire un 1 per essere caricato correttamente

#utilizzo del modulo
#!/usr/bin/env perl
#
#use strict;
#use warnings;
#use WebCrawler;

# Crea un'istanza del crawler con le URL iniziali
#my $crawler = WebCrawler->new(
#    start_urls => ['https://www.example.com', 'https://www.wikipedia.org'],
#    num_threads => 5,
#);

# Avvia il processo di crawling
#$crawler->start_crawling();
#*/

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

