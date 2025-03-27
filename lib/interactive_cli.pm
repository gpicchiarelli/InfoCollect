package interactive_cli;

use strict;
use warnings;
use utf8;
use Term::ReadLine;
use Encode qw(decode);
use lib './lib';

use db;
use rss_crawler;
use web_crawler;
use config_manager;
use init_conf;


# Funzione principale per avviare l'interfaccia CLI
sub avvia_cli {
    init_conf::configuraValoriIniziali();

    my $term = Term::ReadLine->new('InfoCollect CLI');
    system("clear"); # Pulisce lo schermo

    # Banner in ASCII art
    print "========================================================================\n";
    print "  ___        __        _      _      _      _     \n";
    print " |_ _|  ___ / _|  ___ | |__  (_)  __| |  __| | ___ \n";
    print "  | |  / _ \\ |_  / _ \\| '_ \\ | | / _` | / _` |/ _ \\\n";
    print "  | | |  __/  _||  __/| | | || || (_| || (_| |  __/\n";
    print " |___| \\___|_|   \\___||_| |_||_| \\__,_| \\__,_|\\___|\n";
    print "\n";
    print "          Progetto InfoCollect - https://github.com/gpicchiarelli/InfoCollect\n";
    print "========================================================================\n";
    print "\n";

    print "Benvenuto in InfoCollect CLI! Digita 'help' per vedere i comandi disponibili.\n";
    print "------------------------------------------------------------------------\n";

    while (1) {
        my $input = $term->readline('InfoCollect> ');
        $input = decode('utf-8', $input // '');
        chomp($input);

        next unless $input;  # Salta input vuoti
        my ($comando, @args) = split(/\s+/, $input);

        if ($comando eq 'help') {
            print "------------------------------------------------------------------------\n";
            mostra_aiuto();
            print "------------------------------------------------------------------------\n";
        } elsif ($comando eq 'exit') {
            print "------------------------------------------------------------------------\n";
            print "Uscita da InfoCollect CLI. Arrivederci!\n";
            print "------------------------------------------------------------------------\n";
            last;
        } elsif ($comando eq 'add_rss_feed') {
            aggiungi_feed_rss(@args);
        } elsif ($comando eq 'list_rss_feeds') {
            lista_feed_rss();
        } elsif ($comando eq 'run_rss_crawler') {
            esegui_crawler_rss();
        } elsif ($comando eq 'add_web_url') {
            aggiungi_url_web(@args);
        } elsif ($comando eq 'list_web_urls') {
            lista_url_web();
        } elsif ($comando eq 'run_web_crawler') {
            esegui_crawler_web();
        } elsif ($comando eq 'show_config') {
            mostra_configurazione();
        } elsif ($comando eq 'set_config') {
            imposta_configurazione(@args);
        } elsif ($comando eq 'list_summaries') {
            lista_riassunti();
        } elsif ($comando eq 'add_summary') {
            aggiungi_riassunto(@args);
        } elsif ($comando eq 'share_summary') {
            condividi_riassunto(@args);
        } elsif ($comando eq 'add_notification_channel') {
            my ($name, $type, $config) = @args;
            db::add_notification_channel($name, $type, $config);
            print "Canale di notifica aggiunto: $name ($type)\n";
        } elsif ($comando eq 'list_notification_channels') {
            my $channels = db::get_notification_channels();
            foreach my $channel (@$channels) {
                print "[$channel->{id}] $channel->{name} - $channel->{type}\n";
            }
        } elsif ($comando eq 'deactivate_notification_channel') {
            my ($id) = @args;
            db::deactivate_notification_channel($id);
            print "Canale di notifica disattivato: ID=$id\n";
        } elsif ($comando eq 'relaunch_rss') {
            rilancia_rss();
        } elsif ($comando eq 'relaunch_web') {
            rilancia_web();
        } elsif ($comando eq 'add_sender') {
            aggiungi_mittente(@args);
        } elsif ($comando eq 'list_senders') {
            lista_mittenti();
        } elsif ($comando eq 'update_sender') {
            aggiorna_mittente(@args);
        } elsif ($comando eq 'delete_sender') {
            elimina_mittente(@args);
        } elsif ($comando eq 'regenerate_procedures') {
            rigenera_procedure();
        } elsif ($comando eq 'add_setting') {
            aggiungi_setting(@args);
        } elsif ($comando eq 'del_setting') {
            rimuovi_setting(@args);
        } elsif ($comando eq 'mod_setting') {
            modifica_setting(@args);
        } else {
            print "Comando non riconosciuto: '$comando'. Digita 'help' per vedere i comandi disponibili.\n";
        }
    }
}

# Mostra l'elenco dei comandi disponibili
sub mostra_aiuto {
    print <<'END_HELP';
Comandi disponibili:
  help                  Mostra questo messaggio di aiuto.
  exit                  Esci dall'interfaccia CLI.
  add_rss_feed <titolo> <url>
                        Aggiungi un nuovo feed RSS.
  list_rss_feeds        Mostra l'elenco dei feed RSS salvati.
  run_rss_crawler       Esegui il crawler per i feed RSS.
  add_web_url <url>     Aggiungi un nuovo URL per il crawling web.
  list_web_urls         Mostra l'elenco degli URL per il crawling web.
  run_web_crawler       Esegui il crawler per gli URL web.
  show_config           Mostra la configurazione attuale.
  set_config <chiave> <valore>
                        Imposta un valore nella configurazione.
  list_summaries        Mostra l'elenco dei riassunti salvati.
  add_summary <page_id> <summary>
                        Aggiungi un nuovo riassunto.
  share_summary <summary_id> <recipient>
                        Condividi un riassunto con un destinatario.
  add_notification_channel <name> <type> <config>
                        Aggiungi un nuovo canale di notifica.
  list_notification_channels
                        Mostra l'elenco dei canali di notifica.
  deactivate_notification_channel <id>
                        Disattiva un canale di notifica.
  relaunch_rss          Rilancia i contenuti RSS.
  relaunch_web          Rilancia i contenuti delle pagine web.
  add_sender <name> <type> <config>
                        Aggiungi un nuovo mittente.
  list_senders          Mostra l'elenco dei mittenti configurati.
  update_sender <id> <name> <type> <config> <active>
                        Aggiorna un mittente.
  delete_sender <id>    Elimina un mittente.
  regenerate_procedures Rigenera tutte le procedure.
  add_setting <chiave> <valore>
                        Aggiunge o aggiorna una impostazione.
  del_setting <chiave>
                        Elimina una impostazione.
  mod_setting <chiave> <nuovo_valore>
                        Modifica una impostazione.
END_HELP
}

# Aggiungi un nuovo feed RSS
sub aggiungi_feed_rss {
    my ($titolo, $url) = @_;
    unless ($titolo && $url) {
        print "Errore: devi specificare un titolo e un URL.\n";
        return;
    }
    eval {
        db::add_rss_feed($titolo, $url);
        print "Feed RSS aggiunto con successo: $titolo ($url)\n";
    };
    if ($@) {
        print "Errore durante l'aggiunta del feed RSS: $@\n";
    }
}

# Mostra l'elenco dei feed RSS
sub lista_feed_rss {
    eval {
        my $feeds = db::get_all_rss_feeds();
        if (@$feeds) {
            print "Feed RSS salvati:\n";
            foreach my $feed (@$feeds) {
                print "  [$feed->{id}] $feed->{title} - $feed->{url}\n";
            }
        } else {
            print "Nessun feed RSS salvato.\n";
        }
    };
    if ($@) {
        print "Errore durante il recupero dei feed RSS: $@\n";
    }
}

# Esegui il crawler RSS
sub esegui_crawler_rss {
    eval {
        rss_crawler::esegui_crawler_rss();
        print "Crawler RSS completato con successo.\n";
    };
    if ($@) {
        print "Errore durante l'esecuzione del crawler RSS: $@\n";
    }
}

# Funzione per rilanciare i contenuti RSS
sub rilancia_rss {
    eval {
        rss_crawler::esegui_crawler_rss();
        print "Rilancio dei contenuti RSS completato con successo.\n";
    };
    if ($@) {
        print "Errore durante il rilancio dei contenuti RSS: $@\n";
    }
}

# Aggiungi un nuovo URL per il crawling web
sub aggiungi_url_web {
    my ($url) = @_;
    unless ($url) {
        print "Errore: devi specificare un URL.\n";
        return;
    }
    eval {
        db::add_web_url($url);
        print "URL aggiunto con successo: $url\n";
    };
    if ($@) {
        print "Errore durante l'aggiunta dell'URL: $@\n";
    }
}

# Mostra l'elenco degli URL per il crawling web
sub lista_url_web {
    eval {
        my $urls = db::get_all_web_urls();
        if (@$urls) {
            print "URL per il crawling web:\n";
            foreach my $url (@$urls) {
                print "  [$url->{id}] $url->{url} (Attivo: $url->{attivo})\n";
            }
        } else {
            print "Nessun URL salvato per il crawling web.\n";
        }
    };
    if ($@) {
        print "Errore durante il recupero degli URL: $@\n";
    }
}

# Esegui il crawler web
sub esegui_crawler_web {
    eval {
        web_crawler::esegui_crawler_web();
        print "Crawler web completato con successo.\n";
    };
    if ($@) {
        print "Errore durante l'esecuzione del crawler web: $@\n";
    }
}

# Funzione per rilanciare i contenuti delle pagine web
sub rilancia_web {
    eval {
        web_crawler::esegui_crawler_web();
        print "Rilancio dei contenuti delle pagine web completato con successo.\n";
    };
    if ($@) {
        print "Errore durante il rilancio dei contenuti delle pagine web: $@\n";
    }
}

# Mostra la configurazione attuale
sub mostra_configurazione {
    eval {
        my %config = config_manager::get_all_settings();
        print "Configurazione attuale:\n";
        foreach my $chiave (keys %config) {
            print "  $chiave: $config{$chiave}\n";
        }
    };
    if ($@) {
        print "Errore durante il caricamento della configurazione: $@\n";
    }
}

# Imposta un valore nella configurazione
sub imposta_configurazione {
    my ($chiave, $valore) = @_;
    unless ($chiave && $valore) {
        print "Errore: devi specificare una chiave e un valore.\n";
        return;
    }
    eval {
        config_manager::add_setting($chiave, $valore);
        print "Configurazione aggiornata: $chiave = $valore\n";
    };
    if ($@) {
        print "Errore durante l'aggiornamento della configurazione: $@\n";
    }
}

# Mostra l'elenco dei riassunti
sub lista_riassunti {
    eval {
        my $summaries = db::get_all_summaries();
        if (@$summaries) {
            print "Riassunti salvati:\n";
            foreach my $summary (@$summaries) {
                print "  [$summary->{id}] $summary->{summary} (Creato: $summary->{created_at})\n";
            }
        } else {
            print "Nessun riassunto salvato.\n";
        }
    };
    if ($@) {
        print "Errore durante il recupero dei riassunti: $@\n";
    }
}

# Aggiungi un nuovo riassunto
sub aggiungi_riassunto {
    my ($page_id, $summary) = @_;
    unless ($page_id && $summary) {
        print "Errore: devi specificare un page_id e un riassunto.\n";
        return;
    }
    eval {
        db::add_summary($page_id, $summary);
    };
    if ($@) {
        print "Errore durante l'aggiunta del riassunto: $@\n";
    }
}

# Condividi un riassunto
sub condividi_riassunto {
    my ($summary_id, $recipient) = @_;
    unless ($summary_id && $recipient) {
        print "Errore: devi specificare un summary_id e un destinatario.\n";
        return;
    }
    eval {
        db::share_summary($summary_id, $recipient);
    };
    if ($@) {
        print "Errore durante la condivisione del riassunto: $@\n";
    }
}

# Funzione per aggiungere un mittente
sub aggiungi_mittente {
    my ($name, $type, $config) = @_;
    unless ($name && $type && $config) {
        print "Errore: devi specificare un nome, un tipo e una configurazione.\n";
        return;
    }
    eval {
        db::add_sender($name, $type, $config);
        print "Mittente aggiunto con successo: $name ($type)\n";
    };
    if ($@) {
        print "Errore durante l'aggiunta del mittente: $@\n";
    }
}

# Funzione per elencare i mittenti
sub lista_mittenti {
    eval {
        my $senders = db::get_all_senders();
        if (@$senders) {
            print "Mittenti configurati:\n";
            foreach my $sender (@$senders) {
                print "  [$sender->{id}] $sender->{name} - $sender->{type} (Attivo: $sender->{active})\n";
            }
        } else {
            print "Nessun mittente configurato.\n";
        }
    };
    if ($@) {
        print "Errore durante il recupero dei mittenti: $@\n";
    }
}

# Funzione per aggiornare un mittente
sub aggiorna_mittente {
    my ($id, $name, $type, $config, $active) = @_;
    unless ($id && $name && $type && $config && defined $active) {
        print "Errore: devi specificare un ID, un nome, un tipo, una configurazione e lo stato attivo.\n";
        return;
    }
    eval {
        db::update_sender($id, $name, $type, $config, $active);
        print "Mittente aggiornato con successo: $name ($type)\n";
    };
    if ($@) {
        print "Errore durante l'aggiornamento del mittente: $@\n";
    }
}

# Funzione per eliminare un mittente
sub elimina_mittente {
    my ($id) = @_;
    unless ($id) {
        print "Errore: devi specificare un ID.\n";
        return;
    }
    eval {
        db::delete_sender($id);
        print "Mittente eliminato con successo: ID=$id\n";
    };
    if ($@) {
        print "Errore durante l'eliminazione del mittente: $@\n";
    }
}

# Funzione per rigenerare le procedure
sub rigenera_procedure {
    eval {
        db::regenerate_procedures();
        print "Tutte le procedure sono state rigenerate con successo.\n";
    };
    if ($@) {
        print "Errore durante la rigenerazione delle procedure: $@\n";
    }
}

# Aggiungi o aggiorna una impostazione
sub aggiungi_setting {
    my ($chiave, $valore) = @_;
    unless ($chiave && defined $valore) {
        print "Utilizzo: add_setting <chiave> <valore>\n";
        return;
    }
    config_manager::add_setting($chiave, $valore);
}

# Elimina una impostazione
sub rimuovi_setting {
    my ($chiave) = @_;
    unless ($chiave) {
        print "Utilizzo: del_setting <chiave>\n";
        return;
    }
    config_manager::delete_setting($chiave);
}

# Modifica una impostazione
sub modifica_setting {
    my ($chiave, $nuovo_valore) = @_;
    unless ($chiave && defined $nuovo_valore) {
        print "Utilizzo: mod_setting <chiave> <nuovo_valore>\n";
        return;
    }
    # Utilizza add_setting che aggiorna se la chiave esiste
    config_manager::add_setting($chiave, $nuovo_valore);
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