use strict;
use warnings;
use Test::More;

# Test di base per verificare che il file daemon.pl sia eseguibile
my $output = `perl ../daemon.pl --help 2>&1`;
like($output, qr/Daemon in ascolto/, 'daemon.pl si avvia correttamente');

done_testing();
