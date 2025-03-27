#!/usr/bin/env perl

use strict;
use warnings;

# Moduli richiesti per InfoCollect

my @modules = (
    # --- Database ---
    'DBI',
    'DBD::SQLite',

    # --- Crawler e Web ---
    'LWP::UserAgent',
    'HTML::TreeBuilder',
    'HTML::Strip',
    'XML::RSS',

    # --- NLP e linguistica ---
    'Text::Summarizer',
    'Lingua::Identify',
    'Lingua::IT::Stemmer',
    'Lingua::EN::Tagger',

    # --- CLI interattiva ---
    'Term::ReadLine',
    'Term::ANSIColor',

    # --- Esecuzione parallela ---
    'Parallel::ForkManager',

    # --- Interfaccia web ---
    'Mojolicious',
);

# Verifica se cpanm è installato
sub check_cpanm {
    print ">> Verifico cpanm...\n";
    my $cpanm = `which cpanm`;
    chomp $cpanm;
    if (!$cpanm) {
        print ">> cpanm non trovato. Lo installo...\n";
        system("curl -L https://cpanmin.us | perl - App::cpanminus") == 0
            or die "Errore durante installazione cpanm: $!";
    } else {
        print ">> cpanm trovato: $cpanm\n";
    }
}

# Installazione moduli
sub install_modules {
    foreach my $mod (@modules) {
        print ">> Controllo modulo $mod...\n";
        eval "use $mod";
        if ($@) {
            print "   >> Non installato. Procedo...\n";
            system("cpanm $mod") == 0
                or warn "   !! Errore durante installazione di $mod\n";
        } else {
            print "   >> Già installato.\n";
        }
    }
}

# Esecuzione
check_cpanm();
install_modules();

print "\n✅ Tutti i moduli sono installati e pronti.\n";
