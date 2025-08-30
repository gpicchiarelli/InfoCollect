use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
    my @required = qw(
      DBI
      DBD::SQLite
      Crypt::AuthEnc::GCM
      Crypt::PK::RSA
      Parallel::ForkManager
      Mojolicious::Lite
      Dancer2
    );
    for my $m (@required) {
      eval "use $m (); 1" or plan skip_all => "Modulo richiesto mancante: $m";
    }

    use_ok('p2p') or BAIL_OUT("Impossibile caricare il modulo p2p");
    use_ok('db') or BAIL_OUT("Impossibile caricare il modulo db");
    use_ok('rss_crawler') or BAIL_OUT("Impossibile caricare il modulo rss_crawler");
    use_ok('web_crawler') or BAIL_OUT("Impossibile caricare il modulo web_crawler");
}

done_testing();
