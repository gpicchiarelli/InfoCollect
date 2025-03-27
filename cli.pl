#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use lib './lib';
use db;

my ($action, $key, $value);

GetOptions(
    'action=s' => \$action,
    'key=s'    => \$key,
    'value=s'  => \$value,
) or die "Errore nei parametri.\n";

if ($action eq 'get') {
    die "Chiave mancante.\n" unless $key;
    my $result = db::get_setting($key);
    print $result ? "$key: $result\n" : "Chiave non trovata.\n";
} elsif ($action eq 'set') {
    die "Chiave e valore richiesti.\n" unless $key && $value;
    db::set_setting($key, $value);
    print "Impostazione aggiornata.\n";
} else {
    die "Azione non supportata. Usa 'get' o 'set'.\n";
}
