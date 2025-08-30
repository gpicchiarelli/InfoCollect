use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
    use_ok('p2p') or BAIL_OUT("Impossibile caricare il modulo p2p");
    use_ok('db') or BAIL_OUT("Impossibile caricare il modulo db");
    use_ok('rss_crawler') or BAIL_OUT("Impossibile caricare il modulo rss_crawler");
    use_ok('web_crawler') or BAIL_OUT("Impossibile caricare il modulo web_crawler");
}

done_testing();
