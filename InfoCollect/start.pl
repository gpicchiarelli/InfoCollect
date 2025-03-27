#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib"; # Aggiunge la directory lib al percorso dei moduli
#use lib './lib';


# Importa il modulo per l'installazione dei moduli
use modules_install;

# Verifica che il percorso sia stato aggiunto correttamente
BEGIN {
    unless (grep { $_ eq "$FindBin::Bin/../lib" } @INC) {
        die "Errore: la directory lib non è stata aggiunta a \@INC.\n";
    }
}

# Verifica e installazione dei moduli necessari
modules_install::ensure_modules_installed();

# Carica il modulo interactive_cli
eval {
    require interactive_cli;
    interactive_cli->import();
};
if ($@) {
    die "Errore: impossibile caricare il modulo: $@\n";
}

print "Avvio dell'interfaccia CLI interattiva...\n";
interactive_cli::avvia_cli();

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