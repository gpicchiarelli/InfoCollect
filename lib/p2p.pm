package p2p;

use strict;
use warnings;
use IO::Socket::INET;
use Socket qw(inet_aton sockaddr_in);
use Crypt::PK::RSA;
use Digest::SHA qw(sha256_hex);
use Sys::Hostname;
use threads;
use DBI;
use Time::HiRes qw(gettimeofday tv_interval);
use db;
use config_manager;

# Variabili globali
my $rsa = Crypt::PK::RSA->new();
$rsa->generate_key(2048);
my $private_key = $rsa->export_key_pem('private');
my $public_key = $rsa->export_key_pem('public');
my $machine_id = sha256_hex(hostname());

# Funzione per avviare il discovery UDP
sub start_udp_discovery {
    my ($udp_port, $tcp_port) = @_;
    threads->create(sub {
        my $socket = IO::Socket::INET->new(
            LocalPort => $udp_port,
            Proto     => 'udp',
            Broadcast => 1,
        ) or die "Errore nella creazione del socket UDP: $!\n";

        while (1) {
            my $message = "InfoCollect:$tcp_port:$machine_id:$public_key";
            $socket->send($message, 0, sockaddr_in($udp_port, inet_aton('255.255.255.255')));
            sleep(5); # Invia messaggi ogni 5 secondi
        }
    });
}

# Funzione per avviare il server TCP
sub start_tcp_server {
    my ($tcp_port, $config_module) = @_;
    threads->create(sub {
        my $server = IO::Socket::INET->new(
            LocalPort => $tcp_port,
            Proto     => 'tcp',
            Listen    => 5,
            Reuse     => 1,
        ) or die "Errore nella creazione del server TCP: $!\n";

        while (my $client = $server->accept()) {
            my $start_time = [gettimeofday];
            my $data = <$client>;
            my $latency_ms = int((tv_interval($start_time) * 1000));
            log_latency($client->peerhost, $latency_ms);

            if ($data =~ /^SYNC_REQUEST:(.+):(.+)/) {
                my ($peer_id, $peer_public_key) = ($1, $2);

                # Verifica dell'identità del peer
                if (verify_peer($peer_id, $peer_public_key)) {
                    if (is_peer_accepted($peer_id)) {
                        # Invia solo le impostazioni locali (cifratura applicata)
                        my %local_settings = $config_module->get_all_settings();
                        my $settings = join("\n", map { "$_=$local_settings{$_}" } keys %local_settings);
                        my $encrypted_settings = encrypt_with_public_key($settings, $peer_public_key);
                        print $client "SYNC_RESPONSE\n$encrypted_settings\n";
                    } else {
                        print $client "SYNC_DENIED\n";
                    }
                }
            } elsif ($data =~ /^SYNC_RESPONSE\n(.+)/s) {
                my $encrypted_settings = $1;
                my $received_settings = decrypt_with_private_key($encrypted_settings);
                $config_module->apply_delta($received_settings);
            } elsif ($data =~ /^PEER_REQUEST:(.+):(.+)/) {
                my ($peer_id, $peer_public_key) = ($1, $2);
                add_peer_request($peer_id, $peer_public_key);
                print $client "PEER_REQUEST_RECEIVED\n";
            } elsif ($data =~ /^TASK:(.+)$/) {
                my $task_data = $1;
                my $result = execute_task($task_data);
                print $client "RESULT:$result\n";
            } elsif ($data =~ /^RESULT:(.+)$/) {
                my $result = $1;
                collect_results($client->peerhost, $result);
            }
            close($client);
        }
    });
}

# Funzione per registrare latenza e host nel database
sub log_latency {
    my ($host, $latency_ms) = @_;
    my $dbh = DBI->connect("dbi:SQLite:dbname=infocollect.db", "", "", { RaiseError => 1, AutoCommit => 1 });
    my $sth = $dbh->prepare(q{
        INSERT INTO latency_monitor (host, latency_ms)
        VALUES (?, ?)
        ON CONFLICT(host) DO UPDATE SET latency_ms = excluded.latency_ms, last_updated = CURRENT_TIMESTAMP
    });
    $sth->execute($host, $latency_ms);
    $sth->finish();
    $dbh->disconnect();
}

# Funzione per verificare l'identità del peer
sub verify_peer {
    my ($peer_id, $peer_public_key) = @_;
    return $peer_id eq sha256_hex($peer_public_key); # Verifica semplice
}

# Funzione per crittografare i dati con la chiave pubblica
sub encrypt_with_public_key {
    my ($data, $public_key) = @_;
    my $encrypted_data = db::encrypt_data($data);
    return $encrypted_data;
}

# Funzione per decrittografare i dati con la chiave privata
sub decrypt_with_private_key {
    my ($data) = @_;
    my $decrypted_data = db::decrypt_data($data);
    return $decrypted_data;
}

# Funzione per ottenere la chiave pubblica
sub get_public_key {
    return $public_key;
}

# Funzione per ottenere l'identificatore univoco della macchina
sub get_machine_id {
    return $machine_id;
}

# Funzione per aggiungere una richiesta di peer
sub add_peer_request {
    my ($peer_id, $peer_public_key) = @_;
    my $dbh = DBI->connect("dbi:SQLite:dbname=infocollect.db", "", "", { RaiseError => 1, AutoCommit => 1 });
    my $sth = $dbh->prepare(q{
        INSERT INTO peer_requests (peer_id, public_key)
        VALUES (?, ?)
        ON CONFLICT(peer_id) DO UPDATE SET public_key = excluded.public_key
    });
    $sth->execute($peer_id, $peer_public_key);
    $sth->finish();
    $dbh->disconnect();
    print "Richiesta di peer aggiunta: $peer_id\n";
}

# Funzione per accettare un peer
sub accept_peer {
    my ($peer_id) = @_;
    my $dbh = DBI->connect("dbi:SQLite:dbname=infocollect.db", "", "", { RaiseError => 1, AutoCommit => 1 });
    my $sth = $dbh->prepare(q{
        INSERT INTO accepted_peers (peer_id, public_key)
        SELECT peer_id, public_key FROM peer_requests WHERE peer_id = ?
    });
    my $rows = $sth->execute($peer_id);
    $sth->finish();

    if ($rows > 0) {
        $dbh->do("DELETE FROM peer_requests WHERE peer_id = ?", undef, $peer_id);
        print "Peer accettato: $peer_id\n";
    } else {
        print "Peer non trovato nella lista delle richieste: $peer_id\n";
    }
    $dbh->disconnect();
}

# Funzione per rifiutare un peer
sub reject_peer {
    my ($peer_id) = @_;
    my $dbh = DBI->connect("dbi:SQLite:dbname=infocollect.db", "", "", { RaiseError => 1, AutoCommit => 1 });
    my $rows = $dbh->do("DELETE FROM peer_requests WHERE peer_id = ?", undef, $peer_id);
    if ($rows > 0) {
        print "Peer rifiutato: $peer_id\n";
    } else {
        print "Peer non trovato nella lista delle richieste: $peer_id\n";
    }
    $dbh->disconnect();
}

# Funzione per verificare se un peer è accettato
sub is_peer_accepted {
    my ($peer_id) = @_;
    my $dbh = DBI->connect("dbi:SQLite:dbname=infocollect.db", "", "", { RaiseError => 1, AutoCommit => 1 });
    my $sth = $dbh->prepare("SELECT peer_id FROM accepted_peers WHERE peer_id = ?");
    $sth->execute($peer_id);
    my $row = $sth->fetchrow_hashref();
    $sth->finish();
    $dbh->disconnect();
    return defined $row;
}

# Funzione per ottenere la lista dei peer accettati
sub get_accepted_peers {
    my $dbh = DBI->connect("dbi:SQLite:dbname=infocollect.db", "", "", { RaiseError => 1, AutoCommit => 1 });
    my $sth = $dbh->prepare("SELECT peer_id FROM accepted_peers");
    $sth->execute();
    my @peers;
    while (my $row = $sth->fetchrow_hashref()) {
        push @peers, $row->{peer_id};
    }
    $sth->finish();
    $dbh->disconnect();
    return \@peers;
}

# Funzione per ottenere la lista delle richieste di peer
sub get_peer_requests {
    my $dbh = DBI->connect("dbi:SQLite:dbname=infocollect.db", "", "", { RaiseError => 1, AutoCommit => 1 });
    my $sth = $dbh->prepare("SELECT peer_id FROM peer_requests");
    $sth->execute();
    my @requests;
    while (my $row = $sth->fetchrow_hashref()) {
        push @requests, $row->{peer_id};
    }
    $sth->finish();
    $dbh->disconnect();
    return \@requests;
}

# Funzione per sincronizzazione semplice usata dal daemon
sub sync_data {
    my ($client) = @_;
    my %local_settings = config_manager::get_all_settings();
    my $settings = join("\n", map { "$_=$local_settings{$_}" } keys %local_settings);
    print $client "SYNC_RESPONSE\n$settings\n";
}

# Funzione per inviare un task a un peer
sub send_task {
    my ($peer_id, $task_data) = @_;
    my $peer_address = get_peer_address($peer_id);  # Funzione per ottenere l'indirizzo del peer
    my $socket = IO::Socket::INET->new(
        PeerAddr => $peer_address,
        PeerPort => 5001,
        Proto    => 'tcp'
    ) or die "Impossibile connettersi al peer $peer_id: $!\n";

    print $socket "TASK:$task_data\n";
    close($socket);
}

# Funzione per ricevere un task
sub receive_task {
    my ($data) = @_;
    if ($data =~ /^TASK:(.+)$/) {
        my $task_data = $1;
        my $result = execute_task($task_data);  # Funzione per eseguire il task
        return $result;
    }
}

# Funzione per eseguire un task
sub execute_task {
    my ($task_data) = @_;
    # Logica per eseguire il task (es. calcolo distribuito)
    return "Risultato del task: $task_data";
}

# Funzione per raccogliere i risultati dai peer
sub collect_results {
    my ($peer_id, $result) = @_;
    print "Risultato ricevuto dal peer $peer_id: $result\n";
    # Logica per aggregare i risultati
}

# Funzione per ottenere l'indirizzo di un peer
sub get_peer_address {
    my ($peer_id) = @_;
    # Logica per ottenere l'indirizzo IP del peer dal database
    return "127.0.0.1";  # Placeholder
}

1;
