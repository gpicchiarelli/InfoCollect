package interactive_cli;

use strict;
use warnings;
use Term::ReadLine;
use Term::ANSIColor;
use rss_crawler;
use web_crawler;
use config_manager;

# Funzione principale per la CLI interattiva
sub run {
    my $term = Term::ReadLine->new('InfoCollect CLI');
    my $prompt = colored("infocollect> ", 'bold green');
    my $OUT = $term->OUT || \*STDOUT;

    print colored("\n=== Benvenuto nella CLI interattiva di InfoCollect ===\n", 'bold cyan');
    print colored("Digita 'help' per la lista dei comandi.\n\n", 'cyan');

    while (defined (my $input = $term->readline($prompt))) {
        chomp $input;
        $input =~ s/^\s+|\s+$//g;  # Rimuove spazi iniziali e finali

        # Gestione dei comandi
        if ($input eq 'help') {
            print_help($OUT);
        }
        elsif ($input eq 'exit' || $input eq 'quit') {
            print colored("\nUscita dalla CLI. Arrivederci!\n", 'bold yellow');
            last;
        }
        elsif ($input eq 'rss-crawl') {
            print colored("\nAvvio del crawler RSS...\n", 'bold magenta');
            rss_crawler::run();
        }
        elsif ($input eq 'web-crawl') {
            print colored("\nAvvio del web crawler...\n", 'bold magenta');
            web_crawler::run();
        }
        elsif ($input =~ /^add-setting\s+(\S+)\s+(.+)$/) {
            my ($key, $value) = ($1, $2);
            config_manager::add_setting($key, $value);
            print colored("Impostazione aggiunta o aggiornata: $key = $value\n", 'bold green');
        }
        elsif ($input =~ /^get-setting\s+(\S+)$/) {
            my $key = $1;
            my $value = config_manager::get_setting($key);
            if (defined $value) {
                print colored("Valore per '$key': $value\n", 'bold blue');
            } else {
                print colored("Chiave '$key' non trovata.\n", 'bold red');
            }
        }
        elsif ($input =~ /^delete-setting\s+(\S+)$/) {
            my $key = $1;
            config_manager::delete_setting($key);
            print colored("Impostazione eliminata: $key\n", 'bold yellow');
        }
        elsif ($input eq 'import-opml') {
            my $file_path = $1;
            unless ($file_path) {
                print colored("Uso: import-opml <file.opml>\n", 'red');
                next;
            }
            import_opml($file_path);
        }
        elsif ($input eq 'export-opml') {
            my $file_path = $1;
            unless ($file_path) {
                print colored("Uso: export-opml <file.opml>\n", 'red');
                next;
            }
            export_opml($file_path);
        }
        else {
            print colored("Comando non riconosciuto. Digita 'help' per la lista dei comandi.\n", 'bold red');
        }

        # Aggiunge l'input alla cronologia
        $term->addhistory($input) if $input;
    }
}

# Funzione per stampare l'help
sub print_help {
    my ($OUT) = @_;
    print colored("\n=== Comandi disponibili ===\n", 'bold cyan');
    print colored("  help                      ", 'bold yellow'), "Mostra questo messaggio di aiuto.\n";
    print colored("  exit | quit               ", 'bold yellow'), "Esce dalla CLI.\n";
    print colored("  rss-crawl                 ", 'bold yellow'), "Esegue il crawler RSS.\n";
    print colored("  web-crawl                 ", 'bold yellow'), "Esegue il web crawler.\n";
    print colored("  add-setting <key> <value> ", 'bold yellow'), "Aggiunge o aggiorna una voce di configurazione.\n";
    print colored("  get-setting <key>         ", 'bold yellow'), "Ottiene il valore di una voce di configurazione.\n";
    print colored("  delete-setting <key>      ", 'bold yellow'), "Elimina una voce di configurazione.\n";
    print colored("  import-opml <file>  ", 'cyan'), " - Importa feed RSS da un file OPML\n";
    print colored("  export-opml <file>  ", 'cyan'), " - Esporta i feed RSS in un file OPML\n";
    print colored("  exit                ", 'cyan'), " - Esce dalla CLI\n";
    print colored("\nEsempi di utilizzo:\n", 'bold yellow');
    print colored("  import-opml feeds.opml\n", 'green');
    print colored("  export-opml export.opml\n", 'green');
    print colored("\nImpostazioni:\n", 'bold cyan');
    print colored("  add-setting refresh_interval 30\n", 'cyan');
    print colored("  get-setting refresh_interval\n", 'cyan');
    print colored("  delete-setting refresh_interval\n\n", 'cyan');
}

# Assicurati che il modulo restituisca un valore positivo
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
