#!/usr/bin/env perl

use strict;
use warnings;

my @modules = (
    # --- Database ---
    'DBI',
    'DBD::SQLite',

    # --- Web & parsing ---
    'LWP::UserAgent',
    'HTML::TreeBuilder',
    'HTML::Strip',
    'XML::RSS',

    # --- NLP & linguistica ---
    'Text::Summarizer',
    'Lingua::Identify',
    'Lingua::IT::Stemmer',
    'Lingua::EN::Tagger',

    # --- CLI interattiva ---
    'Term::ReadLine',
    'Term::ANSIColor',

    # --- Esecuzione parallela ---
    'Parallel::ForkManager',

    # --- Interfaccia web Mojolicious ---
    'Mojolicious',
);

my @ok;
my @failed;

sub check_cpanm {
    print "Controllo cpanm...\n";
    my $exists = `which cpanm`;
    chomp $exists;
    if (!$exists) {
        print "Installo cpanm...\n";
        system("curl -L https://cpanmin.us | perl - App::cpanminus") == 0
            or die "Installazione di cpanm fallita.";
    }
}

sub install_modules {
    foreach my $mod (@modules) {
        print "\n▶ Verifica: $mod\n";
        eval "use $mod";
        if ($@) {
            print "  ↳ Non trovato. Provo installazione...\n";
            system("cpanm $mod") == 0 ? push(@ok, $mod) : push(@failed, $mod);
        } else {
            print "  ↳ Già installato.\n";
            push @ok, $mod;
        }
    }
}

check_cpanm();
install_modules();

# Riepilogo
print "\n📦 Moduli installati correttamente:\n";
print " - $_\n" for @ok;

if (@failed) {
    print "\n❌ Moduli che NON sono stati installati correttamente:\n";
    print " - $_\n" for @failed;
    print "\n⚠️ Controlla la connessione o i permessi di installazione.\n";
} else {
    print "\n✅ Tutti i moduli richiesti sono stati installati o erano già presenti.\n";
}
