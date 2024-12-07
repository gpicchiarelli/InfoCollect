package opml;

use strict;
use warnings;
use XML::Simple;
use Data::Dumper;
use File::Slurp;
use Exporter 'import';

# Modulo DB per interagire con il database
use db;

# Esporta le funzioni per essere utilizzate nella CLI
our @EXPORT_OK = qw(import_opml export_opml);

# Importa feed da un file OPML
sub import_opml {
    my ($file_path) = @_;

    unless (-e $file_path) {
        die "File OPML non trovato: $file_path\n";
    }

    my $xml = XML::Simple->new;
    my $data = $xml->XMLin($file_path, KeyAttr => [], ForceArray => ['outline']);

    foreach my $feed (@{$data->{body}->{outline}}) {
        my $title = $feed->{title} // 'Senza Titolo';
        my $url   = $feed->{xmlUrl};

        if ($url) {
            print "Importazione feed: $title ($url)\n";
            db::add_rss_feed($title, $url);
        }
    }

    print "Importazione completata.\n";
}

# Esporta i feed RSS esistenti in un file OPML
sub export_opml {
    my ($file_path) = @_;

    my $feeds = db::get_all_rss_feeds();

    my $opml_structure = {
        head => {
            title => 'Esportazione Feed RSS',
        },
        body => {
            outline => [map { { title => $_->{title}, xmlUrl => $_->{url} } } @$feeds],
        },
    };

    my $xml = XML::Simple->new(NoAttr => 1, RootName => 'opml');
    my $output = $xml->XMLout($opml_structure);

    write_file($file_path, $output);
    print "Esportazione completata in: $file_path\n";
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
