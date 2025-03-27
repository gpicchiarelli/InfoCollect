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

my $intervallo = shift @ARGV || 30; # default ogni 30 minuti

print "[Agent] Avvio in modalità automatica. Intervallo: $intervallo minuti\n";

# Avvia il notification agent in un processo figlio
my $pid = fork();
if (!defined $pid) {
    die "[Agent] Errore durante il fork per il Notification Agent.\n";
} elsif ($pid == 0) {
    exec("$FindBin::Bin/notification_agent.pl") or die "[Agent] Errore durante l'avvio del Notification Agent: $!\n";
}

# Porta per il discovery UDP
my $udp_port = 5000;

# Porta per la sincronizzazione TCP
my $tcp_port = 5001;

# Thread per il discovery UDP
threads->create(\&udp_discovery);

# Thread per il server TCP
threads->create(\&tcp_server);

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

# Funzione per il discovery UDP
sub udp_discovery {
    my $socket = IO::Socket::INET->new(
        LocalPort => $udp_port,
        Proto     => 'udp',
        Broadcast => 1,
    ) or die "Errore nella creazione del socket UDP: $!\n";

    while (1) {
        my $message = "InfoCollect:$tcp_port";
        $socket->send($message, 0, sockaddr_in($udp_port, inet_aton('255.255.255.255')));
        sleep(5); # Invia messaggi ogni 5 secondi
    }
}

# Funzione per il server TCP
sub tcp_server {
    my $server = IO::Socket::INET->new(
        LocalPort => $tcp_port,
        Proto     => 'tcp',
        Listen    => 5,
        Reuse     => 1,
    ) or die "Errore nella creazione del server TCP: $!\n";

    while (my $client = $server->accept()) {
        my $data = <$client>;
        if ($data =~ /^SYNC_REQUEST$/) {
            # Invia solo le impostazioni locali
            my %local_settings = config_manager::get_all_settings();
            my $settings = join("\n", map { "$_=$local_settings{$_}" } keys %local_settings);
            print $client "SYNC_RESPONSE\n$settings\n";
        } elsif ($data =~ /^SYNC_RESPONSE\n(.+)/s) {
            # Ricevi e applica solo i delta
            my $received_settings = $1;
            config_manager::apply_delta($received_settings);
        }
        close($client);
    }
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