use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib '../lib';
use opml;

# Test del file OPML valido
my $test_file = 'test_data/test.opml';
my $feeds = opml::import_opml($test_file);
is(ref $feeds, 'ARRAY', "import_opml restituisce un array");
is(scalar @$feeds, 2, "import_opml restituisce il numero corretto di feed");

# Test del file OPML non trovato
throws_ok { opml::import_opml('non_esistente.opml') }
    qr/File OPML non trovato/, "import_opml genera un errore per file non trovato";

done_testing();
