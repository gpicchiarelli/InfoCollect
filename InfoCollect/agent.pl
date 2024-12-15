#!/usr/bin/perl
use strict;
use warnings;
use POSIX qw(setsid);    # Per la demonizzazione su Unix
use Win32;               # Modulo per funzionalità Windows (se su Windows)
use Win32::Service;      # Modulo per gestire servizi su Windows
use Cwd 'abs_path';      # Per ottenere il percorso assoluto dello script

# Identifica il sistema operativo
my $os = $^O;

# Funzione per demonizzare su macOS/Linux
sub daemonize {
    chdir '/' or die "Impossibile cambiare cartella to /: $!";
    open STDIN, '/dev/null' or die "Impossibile leggere /dev/null: $!";
    open STDOUT, '>>/dev/null' or die "Impossibile scrivere su /dev/null: $!";
    open STDERR, '>>/dev/null' or die "Impossibile scrivere su /dev/null: $!";
    defined(my $pid = fork) or die "Impossibile fork: $!";
    exit if $pid;
    setsid or die "Impossibile creare una nuova sessione: $!";
}

# Funzione per installare il servizio su Windows
sub install_windows_service {
    my $service_name = "InfoCollectService";
    my $script_path  = abs_path($0);
    my $perl_path    = $^X; # Percorso dell'interprete Perl corrente

    # Comando per creare il servizio
    my $create_cmd = qq(sc create "$service_name" binPath= "$perl_path \"$script_path\"");

    system($create_cmd) == 0
        or die "Errore nell'installazione del servizio: $!";
    
    print "Servizio '$service_name' installato con successo.\n";
}

# Funzione principale del servizio
sub run_service {
    while (1) {
        my $logfile = $os eq 'MSWin32' ? 'C:\\temp\\info_collect.log' : '/tmp/infocollect.log';
        open my $log, '>>', $logfile or die "Cannot open log file: $!";
        print $log scalar(localtime), " - Servizio in esecuzione...\n";
        close $log;
        sleep 10;
    }
}

# Funzione per creare uno script di servizio per BSD
sub install_bsd_service {
    my $service_name = 'AgenteInfoCollect';
    my $script_path  = abs_path($0);
    my $rc_script    = "/etc/rc.d/$service_name";

    # Contenuto dello script di servizio per BSD
    my $content = <<"END";
#!/bin/sh
#
# PROVIDE: $service_name
# REQUIRE: DAEMON
# KEYWORD: shutdown

. /etc/rc.subr

name="$service_name"
rcvar="\${name}_enable"
command="/usr/bin/perl"
command_args="$script_path"

load_rc_config "\$name"
run_rc_command "\$1"
END

    # Scrive lo script in /etc/rc.d
    open my $fh, '>', $rc_script or die "Cannot write to $rc_script: $!";
    print $fh $content;
    close $fh;

    # Rendi lo script eseguibile
    chmod 0755, $rc_script or die "Cannot chmod $rc_script: $!";

    print "Servizio BSD '$service_name' installato con successo.\n";
    print "Per abilitarlo, aggiungi '${service_name}_enable=\"YES\"' in /etc/rc.conf\n";
}

# Logica principale
if ($os eq 'MSWin32') {
    # Su Windows, gestisce l'installazione con `sc`
    if (@ARGV && $ARGV[0] eq 'install') {
        my $service_name = "MyPerlService";
        my $script_path  = abs_path($0);
        my $perl_path    = $^X;

        my $create_cmd = qq(sc create "$service_name" binPath= "$perl_path \"$script_path\"");

        system($create_cmd) == 0
            or die "Errore nell'installazione del servizio: $!";
        
        print "Servizio '$service_name' installato con successo.\n";
        exit;
    }
    run_service();
} elsif ($os eq 'darwin' || $os eq 'linux') {
    # Su macOS e Linux, demonizza e avvia il servizio
    daemonize();
    run_service();
} elsif ($os =~ /bsd/i) {
    # Su sistemi BSD, installa il servizio se richiesto
    if (@ARGV && $ARGV[0] eq 'install') {
        install_bsd_service();
        exit;
    }
    daemonize();
    run_service();
} else {
    die "Sistema operativo non supportato: $os\n";
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
