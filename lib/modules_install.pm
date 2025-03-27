package modules_install;

use strict;
use warnings;

# Funzione per verificare e installare i moduli
sub ensure_modules_installed {
    my @required_modules = qw(
        DBI
        Crypt::AuthEnc::GCM
        Crypt::PK::RSA
        Digest::SHA
        FindBin
        JSON
        Time::HiRes
        Lingua::Identify
        Lingua::Stem::It
        Lingua::EN::Tagger
        Text::Extract::Word
        LWP::UserAgent
        Encode
        Exporter
    );

    foreach my $module (@required_modules) {
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

1; # Il modulo deve restituire un valore vero
