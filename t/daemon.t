use strict;
use warnings;
use Test::More;
use FindBin;
BEGIN {
  eval { require Crypt::PK::RSA; 1 } or plan skip_all => 'CryptX non installato';
}

my $root = "$FindBin::Bin/..";
my $perl = $^X;
my $cmd = "$perl $root/daemon.pl --help 2>&1";
my $output = `$cmd`;
like($output, qr/Daemon in ascolto/, 'daemon.pl si avvia correttamente');

done_testing();
