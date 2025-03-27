#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use rss_crawler;
use web_crawler;
use Time::HiRes qw(sleep);
use IO::Socket::INET;
use threads;
use Crypt::PK::RSA;
use Digest::SHA qw(sha256_hex);
use Sys::Hostname;
use p2p;
use config_manager;
use DBI;

my $intervallo = shift @ARGV || 30; # default ogni 30 minuti

if ($ARGV[0] && $ARGV[0] eq 'show-latency') {
    my $dbh = DBI->connect("dbi:SQLite:dbname=infocollect.db", "", "", { RaiseError => 1, AutoCommit => 1 });
    my $sth = $dbh->prepare("SELECT host, latency_ms, last_updated FROM latency_monitor ORDER BY last_updated DESC");
    $sth->execute();
    while (my $row = $sth->fetchrow_hashref) {
        print "Host: $row->{host}, Latenza: $row->{latency_ms} ms, Ultimo aggiornamento: $row->{last_updated}\n";
    }
    $sth->finish();
    $dbh->disconnect();
    exit;
}

print "[Agent] Avvio in modalità automatica. Intervallo: $intervallo minuti\n";

# Generazione chiavi RSA
my $rsa = Crypt::PK::RSA->new();
$rsa->generate_key(2048);
my $private_key = $rsa->export_key_pem('private');
my $public_key = $rsa->export_key_pem('public');

# Identificatore univoco della macchina
my $machine_id = sha256_hex(hostname());

# Avvia il notification agent in un processo figlio
my $pid = fork();
if (!defined $pid) {
    die "[Agent] Errore durante il fork per il Notification Agent.\n";
} elsif ($pid == 0) {
    exec("$FindBin::Bin/notification_agent.pl") or die "[Agent] Errore durante l'avvio del Notification Agent: $!\n";
}

# Porta per il discovery UDP e TCP (lettura da configurazione)
my %settings = config_manager::get_all_settings();
my $udp_port = $settings{UDP_DISCOVERY_PORT} || 5000;
my $tcp_port = $settings{TCP_SYNC_PORT} || 5001;

# Avvia il discovery UDP e il server TCP utilizzando il modulo P2P
p2p::start_udp_discovery($udp_port, $tcp_port);
p2p::start_tcp_server($tcp_port, \&config_manager);

while (1) {
    eval {
        print "[Agent] Avvio dei crawler...\n";
        rss_crawler::esegui_crawler_rss();
        web_crawler::esegui_crawler_web();
        print "[Agent] Attesa $intervallo minuti prima del prossimo ciclo...\n";
    };
    if ($@) {
        warn "[Agent] Errore durante l'esecuzione: $@\n";
    }
    sleep($intervallo * 60);
}

# Licenza BSD
# -----------------------------------------------------------------------------
# Copyright (c) 2024, Giacomo Picchiarelli
# All rights reserved.
#
# Ridistribuzione e uso nel formato sorgente e binario, con o senza modifiche,
# sono consentiti purché siano soddisfatte le seguenti condizioni:
#
# 1. Le ridistribuzioni del codice sorgente devono conservare l'avviso di copyright
#    di cui sopra, questo elenco di condizioni e il seguente disclaimer.
# 2. Le ridistribuzioni in formato binario devono riprodurre l'avviso di copyright,
#    questo elenco di condizioni e il seguente disclaimer nella documentazione
#    e/o nei materiali forniti con la distribuzione.
# 3. Né il nome dell'autore né i nomi dei suoi collaboratori possono essere utilizzati
#    per promuovere prodotti derivati da questo software senza un'autorizzazione
#    specifica scritta.
#
# QUESTO SOFTWARE È FORNITO "COSÌ COM'È" E QUALSIASI GARANZIA ESPRESSA O IMPLICITA
# È ESCLUSA. IN NESSUN CASO L'AUTORE SARÀ RESPONSABILE PER DANNI DERIVANTI
# DALL'USO DEL SOFTWARE.
# -----------------------------------------------------------------------------