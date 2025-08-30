use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";
use p2p;

# Test della funzione get_machine_id
ok(p2p::get_machine_id(), "get_machine_id restituisce un valore");

# Test della funzione encrypt_with_public_key
my $public_key = p2p::get_public_key();
my $data = "test_data";
my $encrypted = p2p::encrypt_with_public_key($data, $public_key);
ok($encrypted, "encrypt_with_public_key restituisce un valore");

# Test della funzione decrypt_with_private_key
my $decrypted = p2p::decrypt_with_private_key($encrypted);
is($decrypted, $data, "decrypt_with_private_key restituisce i dati originali");

# Test della funzione send_task
throws_ok { p2p::send_task("peer_id_non_esistente", "task_data") }
    qr/Impossibile connettersi/, "send_task genera un errore per peer non valido";

# Test della funzione start_udp_discovery
ok(p2p::start_udp_discovery(5000, 5001), 'start_udp_discovery funziona');

# Test della funzione start_tcp_server
ok(p2p::start_tcp_server(5001, 'config_manager'), 'start_tcp_server funziona');

done_testing();
