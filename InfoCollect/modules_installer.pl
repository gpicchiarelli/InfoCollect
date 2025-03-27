#!/usr/bin/env perl

use strict;
use warnings;

my @modules = qw(
    LWP::UserAgent
    XML::RSS
    DBI
    DBD::SQLite
    HTML::TreeBuilder
    HTML::Strip
    Parallel::ForkManager
    Text::Summarizer
    Lingua::Identify
    Lingua::IT::Stemmer
    Lingua::EN::Tagger
    Text::Extract::Words
    Term::ReadLine
    Term::ANSIColor
    JSON
    Time::HiRes
    XML::Simple
    File::Slurp
);

print "Verifica e installazione dei moduli Perl richiesti...\n";

foreach my $module (@modules) {
    eval "use $module";
    if ($@) {
        print "Installazione del modulo: $module\n";
        system("cpan -i $module");
    } else {
        print "Modulo già installato: $module\n";
    }
}

print "Installazione completata.\n";

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
