#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

=pod

=head1 NAME

console.pl - Avvia la console testuale (CLI) di InfoCollect

=head1 SYNOPSIS

  perl script/console.pl

Avvia l'interfaccia a riga di comando interattiva basata su Perl.
Condivide lo stesso database e le stesse impostazioni dell'interfaccia web.

=cut

use interactive_cli;

interactive_cli::avvia_cli();

exit 0;

