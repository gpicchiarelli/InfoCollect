#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib"; # Aggiunge la directory lib al percorso dei moduli
use lib './lib';

# Verifica che il percorso sia stato aggiunto correttamente
BEGIN {
    unless (grep { $_ eq "$FindBin::Bin/../lib" } @INC) {
        die "Errore: la directory lib non è stata aggiunta a \@INC.\n";
    }
}

# Funzione per determinare i moduli necessari analizzando i file sorgente
sub find_required_modules {
    my $project_dir = "$FindBin::Bin/.."; # Directory del progetto
    my %modules;

    # Cerca nei file Perl del progetto
    opendir(my $dh, $project_dir) or die "Impossibile aprire la directory $project_dir: $!";
    my @files = grep { /\.pl$|\.pm$/ } map { "$project_dir/$_" } readdir($dh);
    closedir($dh);

    foreach my $file (@files) {
        open(my $fh, '<', $file) or die "Impossibile aprire il file $file: $!";
        while (my $line = <$fh>) {
            if ($line =~ /^\s*(?:use|require)\s+([\w:]+)/) {
                my $module = $1;
                # Escludi i moduli locali del progetto (quelli sotto la directory lib)
                next if $module =~ /^interactive_cli|db|rss_crawler|web_crawler|config_manager|p2p$/;
                $modules{$module} = 1;
            }
        }
        close($fh);
    }

    return keys %modules;
}

# Funzione per verificare e installare i moduli
sub ensure_modules_installed {
    my @modules = @_;
    foreach my $module (@modules) {
        eval "use $module";
        if ($@) {
            print "Modulo $module non trovato. Tentativo di installazione...\n";
            system("cpan -i $module") == 0
                or die "Impossibile installare il modulo $module: $!";
            eval "use $module";
            die "Errore nel caricamento del modulo $module dopo l'installazione: $@" if $@;
        }
    }
}

# Assicura che tutti i moduli necessari siano installati
eval {
    my @required_modules = find_required_modules();
    ensure_modules_installed(@required_modules);
};
if ($@) {
    die "Errore durante l'installazione dei moduli necessari: $@\n";
}

# Carica il modulo interactive_cli
eval {
    require interactive_cli;
    interactive_cli->import();
};
if ($@) {
    die "Errore: impossibile caricare il modulo interactive_cli: $@\n";
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