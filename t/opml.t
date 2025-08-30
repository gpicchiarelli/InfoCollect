use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";
BEGIN {
  eval { require DBI; 1 }           or plan skip_all => 'DBI non installato';
  eval { require DBD::SQLite; 1 }   or plan skip_all => 'DBD::SQLite non installato';
  eval { require Crypt::AuthEnc::GCM; 1 } or plan skip_all => 'CryptX non installato';
  require opml; opml->import();
}

# Test del file OPML valido
my $test_file = "$FindBin::Bin/../script/test_data/test.opml";
my $feeds = opml::import_opml($test_file);
is(ref $feeds, 'ARRAY', "import_opml restituisce un array");
ok(scalar(@$feeds) >= 1, "import_opml importa almeno un feed");

# Test del file OPML non trovato
throws_ok { opml::import_opml('non_esistente.opml') }
    qr/File OPML non trovato/, "import_opml genera un errore per file non trovato";

done_testing();
