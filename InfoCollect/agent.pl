#!/usr/bin/env perl

use strict;
use warnings;
use lib "../lib";
use rss_crawler;
use web_crawler;
use Time::HiRes qw(sleep);

my $intervallo = shift @ARGV || 30; # default ogni 30 minuti

print "[Agent] Avvio in modalità automatica. Intervallo: $intervallo minuti\n";

while (1) {
    print "[Agent] Avvio dei crawler...\n";
    rss_crawler::esegui_crawler_rss();
    web_crawler::esegui_crawler_web();
    print "[Agent] Attesa $intervallo minuti prima del prossimo ciclo...\n";
    sleep($intervallo * 60);
}
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