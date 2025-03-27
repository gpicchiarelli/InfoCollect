package init_conf;

use strict;
use warnings;
use DBI;
use db;
use config_manager qw(get_all_settings); # Importa esplicitamente get_all_settings
use Digest::SHA qw(sha256_hex);

our %settings = config_manager::get_all_settings(); # Richiamo corretto della funzione

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
    if(!defined config_manager::get_setting("LOG_LEVEL")){
        config_manager::add_setting("LOG_LEVEL", "INFO");
    }
    if(!defined config_manager::get_setting("MAX_CONNECTIONS")){
        config_manager::add_setting("MAX_CONNECTIONS", "100");
    }
    if(!defined config_manager::get_setting("CACHE_EXPIRATION_MINUTI")){
        config_manager::add_setting("CACHE_EXPIRATION_MINUTI", "30");
    }
    if(!defined config_manager::get_setting("CRAWLER_TIMEOUT")){
        config_manager::add_setting("CRAWLER_TIMEOUT", "10");
    }
    if(!defined config_manager::get_setting("MAX_PROCESSES")){
        config_manager::add_setting("MAX_PROCESSES", "5");
    }
    if(!defined config_manager::get_setting("UDP_DISCOVERY_INTERVAL_SEC")){
        config_manager::add_setting("UDP_DISCOVERY_INTERVAL_SEC", "5");
    }
    if(!defined config_manager::get_setting("TCP_SYNC_PORT")){
        config_manager::add_setting("TCP_SYNC_PORT", "5001");
    }
    if(!defined config_manager::get_setting("UDP_DISCOVERY_PORT")){
        config_manager::add_setting("UDP_DISCOVERY_PORT", "5000");
    }
    if(!defined config_manager::get_setting("INFOCOLLECT_ENCRYPTION_KEY")){
        configuraChiaveCrittografia();
    }
    %settings = get_all_settings();
    db::initialize_default_procedures();
}

sub impostaValoriInizialiForzatamente {
    # Imposta i parametri di configurazione richiesti
    config_manager::add_setting("RSS_INTERVALLO_MINUTI", "1");
    config_manager::add_setting("WEB_INTERVALLO_MINUTI", "1");
    config_manager::add_setting("PRUNING_GENERICO_GIORNI", "7");
    config_manager::add_setting("NOTIFICATION_INTERVAL_MINUTI", "10");
    config_manager::add_setting("CRAWLER_TIMEOUT", "10");
    config_manager::add_setting("MAX_PROCESSES", "5");
    config_manager::add_setting("UDP_DISCOVERY_INTERVAL_SEC", "5");
    config_manager::add_setting("TCP_SYNC_PORT", "5001");
    config_manager::add_setting("UDP_DISCOVERY_PORT", "5000");

    # Genera e imposta la chiave di crittografia
    if (!config_manager::setting_exists("INFOCOLLECT_ENCRYPTION_KEY")) {
        generaChiaveCrittografia();
    }

    # Aggiorna la variabile globale delle impostazioni
    %settings = get_all_settings();

    # Inizializza le procedure predefinite
    db::initialize_default_procedures();
}

sub generaChiaveCrittografia {
    my $chiave = sha256_hex(time . rand());
    config_manager::add_setting("INFOCOLLECT_ENCRYPTION_KEY", $chiave);
    print "Chiave di crittografia generata: $chiave\n";
}

sub configuraChiaveCrittografia {
    if (!defined config_manager::get_setting("INFOCOLLECT_ENCRYPTION_KEY")) {
        generaChiaveCrittografia();
    } else {
        my $chiave = config_manager::get_setting("INFOCOLLECT_ENCRYPTION_KEY");
        if (!$chiave || length($chiave) != 64) {  # Verifica che la chiave sia valida
            print "Chiave di crittografia non valida, rigenerazione in corso...\n";
            rigeneraChiaveCrittografia();
        }
    }
}

sub rigeneraChiaveCrittografia {
    config_manager::delete_setting("INFOCOLLECT_ENCRYPTION_KEY");
    generaChiaveCrittografia();
}

configuraChiaveCrittografia();

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
