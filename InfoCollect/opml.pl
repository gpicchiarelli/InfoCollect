#!/usr/bin/env perl
use strict;
use warnings;
use XML::LibXML;
use Data::Dumper;

# Controllo e installazione dei moduli necessari
my @modules = qw(XML::LibXML Data::Dumper);
foreach my $module (@modules) {
    eval "use $module";
    if ($@) {
        print "Il modulo $module non è installato. Installazione in corso...\n";
        system("cpan -T $module") == 0 or die "Impossibile installare $module\n";
    }
}

# Funzione per parsare il file OPML e inserire i dati in una struttura
sub parse_opml {
    my ($filename) = @_;
    my @feeds;

    # Controlla se il file esiste
    unless (-e $filename) {
        die "File OPML non trovato: $filename\n";
    }

    # Crea un nuovo parser XML
    my $parser = XML::LibXML->new();
    my $doc = $parser->parse_file($filename);

    # Trova tutti i nodi <outline> con attributo xmlUrl (feed RSS)
    foreach my $outline ($doc->findnodes('//outline[@xmlUrl]')) {
        my $title = $outline->getAttribute('title') || 'No Title';
        my $url   = $outline->getAttribute('xmlUrl');

        # Aggiungi il feed alla struttura dati
        push @feeds, {
            title => $title,
            url   => $url,
        };
    }

    return \@feeds;
}

# Esempio di utilizzo se eseguito direttamente
if (__FILE__ eq $0) {
    my $opml_file = 'feeds.opml';  # Cambia con il percorso del tuo file OPML

    my $feeds = parse_opml($opml_file);

    # Stampa la struttura dati risultante
    print Dumper($feeds);
}

1;  # Necessario per i moduli Perl



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
