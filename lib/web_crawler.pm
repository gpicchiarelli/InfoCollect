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
    # Carica configurazione
    my $config = config_manager::carica_configurazione();
    my $db_path = $config->{database};

    # Connessione al database
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_path", "", "", { RaiseError => 1, sqlite_unicode => 1, AutoCommit => 1 })
        or die "Errore di connessione al database: $DBI::errstr";

    # Prepara la query per ottenere gli URL da processare
    my $sth = $dbh->prepare("SELECT id, url FROM web WHERE attivo = 1");
    $sth->execute();

    # Configura l'UserAgent e il gestore dei processi paralleli
    my $ua = LWP::UserAgent->new(timeout => 10);
    my $pm = Parallel::ForkManager->new($MAX_PROCESSES);

    while (my $row = $sth->fetchrow_hashref) {
        $pm->start and next;  # Avvia un processo figlio

        eval {
            my $url = $row->{url};
            next unless $url;  # Salta se l'URL è vuoto o non valido

            # Effettua la richiesta HTTP
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
                    # Inserisce il riassunto nel database
                    my $ins = $dbh->prepare("INSERT INTO riassunti (titolo, url, autore, data_pubblicazione, lingua, fonte, riassunto, testo_originale) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
                    $ins->execute($title, $url, undef, undef, $lingua, 'web', $riassunto, $plain_text);
                }

                # Inserisce i metadati della pagina nel database
                my $meta_sth = $dbh->prepare("INSERT INTO pages (url, title, content, metadata) VALUES (?, ?, ?, ?)");
                $meta_sth->execute($url, $title, $plain_text, '');

                # Pulisce l'albero HTML
                $tree->delete;
            } else {
                warn "Errore fetching $url: " . $res->status_line;
            }
        };
        if ($@) {
            warn "Errore durante l'elaborazione dell'URL: $@";
        }

        $pm->finish;  # Termina il processo figlio
    }

    $pm->wait_all_children;  # Aspetta che tutti i processi figli terminino

    # Chiude il cursore e la connessione al database
    $sth->finish();
    $dbh->disconnect or warn "Errore durante la disconnessione dal database: $DBI::errstr";
}

1;

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