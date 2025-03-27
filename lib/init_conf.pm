package init_conf;

use strict;
use warnings;
use DBI;
use db;
use config_manager;

our %settings = config_manager::get_all_settings();

sub configuraValoriIniziali{
    
    if(!defined config_manager::get_setting("RSS_INTERVALLO_MINUTI")){
        config_manager::add_setting("RSS_INTERVALLO_MINUTI", "1");
    }
    if(!defined config_manager::get_setting("WEB_INTERVALLO_MINUTI")){
        config_manager::add_setting("WEB_INTERVALLO_MINUTI", "1");
    }
    if(!defined config_manager::get_setting("PRUNING_GENERICO_GIORNI")){
        config_manager::add_setting("PRUNING_GENERICO_GIORNI", "7");
    }
    if(!defined config_manager::get_setting("NOTIFICATION_INTERVAL_MINUTI")){
        config_manager::add_setting("NOTIFICATION_INTERVAL_MINUTI", "10");
    }
    %settings = config_manager::get_all_settings();
}

sub impostaValoriInizialiForzatamente{
        config_manager::add_setting("RSS_INTERVALLO_MINUTI", "1");
        config_manager::add_setting("WEB_INTERVALLO_MINUTI", "1");
        config_manager::add_setting("PRUNING_GENERICO_GIORNI", "7");
    %settings = config_manager::get_all_settings();
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
