#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib './lib';  
use interactive_cli;
use init_db;
use init_conf;

$0 = "InfoCollect";

init_db::Inizializza();
init_conf::configuraValoriIniziali();

# Lista dei moduli richiesti
my @modules = qw(LWP::Simple XML::RSS Term::ANSIColor);

# Controlla e installa i moduli mancanti
foreach my $module (@modules) {
    eval "use $module";
    if ($@) {
        print "Il modulo $module non è installato. Installazione in corso...\n";
        system("cpan -T $module") == 0 or die "Impossibile installare $module\n";
    }
}

# Esegui la CLI interattiva
interactive_cli::run();

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
