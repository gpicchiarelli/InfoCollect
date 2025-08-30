use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
BEGIN {
  eval { require DBI; 1 }           or plan skip_all => 'DBI non installato';
  eval { require DBD::SQLite; 1 }   or plan skip_all => 'DBD::SQLite non installato';
  eval { require Crypt::AuthEnc::GCM; 1 } or plan skip_all => 'CryptX non installato';
  eval { require Crypt::PK::RSA; 1 } or plan skip_all => 'CryptX non installato';
  require p2p; p2p->import();
  require db; db->import();
  require opml; opml->import();
}

# Simula l'aggiunta di un peer e verifica che venga accettato
my $peer_id = "test_peer";
my $public_key = p2p::get_public_key();
p2p::add_peer_request($peer_id, $public_key);
p2p::accept_peer($peer_id);
ok(p2p::is_peer_accepted($peer_id), "Il peer è stato accettato correttamente");

# Test dell'importazione OPML
my $opml_file = "$FindBin::Bin/../script/test_data/test.opml";
my $imported_feeds = opml::import_opml($opml_file);
ok(scalar @$imported_feeds > 0, "Importazione OPML completata con successo");

done_testing();
