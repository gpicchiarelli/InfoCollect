use strict;
use warnings;
use Test::More;
use p2p;
use db;
use opml;

# Simula l'aggiunta di un peer e verifica che venga accettato
my $peer_id = "test_peer";
my $public_key = p2p::get_public_key();
p2p::add_peer_request($peer_id, $public_key);
ok(p2p::is_peer_accepted($peer_id), "Il peer è stato accettato correttamente");

# Test dell'importazione OPML
my $opml_file = 'test_data/test.opml';
my $imported_feeds = opml::import_opml($opml_file);
ok(scalar @$imported_feeds > 0, "Importazione OPML completata con successo");

done_testing();
