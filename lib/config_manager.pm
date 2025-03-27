package config_manager;

use strict;
use warnings;
use DBI;
use db;  # Importiamo il modulo db per la connessione al database
use IO::Socket::INET;  # Importiamo il modulo IO::Socket::INET per la connessione di rete
use init_conf; # Importa il modulo init_conf per utilizzare configuraValoriIniziali
use Exporter 'import'; # Importa Exporter per esportare funzioni
our @EXPORT_OK = qw(get_all_settings); # Esporta la funzione get_all_settings

# Funzione per aggiungere una nuova impostazione
sub add_setting {
    my ($key, $value) = @_;

    my $dbh = db::connect_db();
    my $sql = q{
        INSERT INTO settings (key, value)
        VALUES (?, ?)
        ON CONFLICT(key) DO UPDATE SET value = excluded.value
    };

    my $sth = $dbh->prepare($sql);
    $sth->execute($key, $value) or die $dbh->errstr;

    print "Impostazione aggiunta o aggiornata: $key = $value\n";

    $sth->finish();
    $dbh->disconnect();
}

# Funzione per ottenere una singola impostazione
sub get_setting {
    my ($key) = @_;

    my $dbh = db::connect_db();
    my $sql = q{
        SELECT value FROM settings WHERE key = ?
    };

    my $sth = $dbh->prepare($sql);
    $sth->execute($key) or die $dbh->errstr;

    my $row = $sth->fetchrow_arrayref;
    $sth->finish();
    $dbh->disconnect();

    return $row ? $row->[0] : undef;
}

# Funzione per ottenere tutte le impostazioni con valori predefiniti
sub get_all_settings {
    my %defaults = (
        RSS_INTERVALLO_MINUTI       => 15,
        WEB_INTERVALLO_MINUTI       => 15,
        CRAWLER_TIMEOUT             => 10,
        MAX_PROCESSES               => 5,
        UDP_DISCOVERY_INTERVAL_SEC  => 5,  # Intervallo per il discovery UDP
        TCP_SYNC_PORT               => 5001,  # Porta per la sincronizzazione TCP
        UDP_DISCOVERY_PORT          => 5000,  # Porta per il discovery UDP
    );

    my $dbh = db::connect_db();
    my $sql = q{
        SELECT key, value FROM settings
    };

    my $sth = $dbh->prepare($sql);
    $sth->execute() or die $dbh->errstr;

    while (my $row = $sth->fetchrow_hashref) {
        $defaults{$row->{key}} = $row->{value};
    }

    $sth->finish();
    $dbh->disconnect();

    return %defaults;
}

# Funzione per eliminare una impostazione
sub delete_setting {
    my ($key) = @_;

    my $dbh = db::connect_db();
    my $sql = q{
        DELETE FROM settings WHERE key = ?
    };

    my $sth = $dbh->prepare($sql);
    $sth->execute($key) or die $dbh->errstr;

    print "Impostazione eliminata: $key\n";

    $sth->finish();
    $dbh->disconnect();
}

# Funzione per verificare se una chiave esiste
sub setting_exists {
    my ($key) = @_;

    my $dbh = db::connect_db();
    my $sql = q{
        SELECT 1 FROM settings WHERE key = ?
    };

    my $sth = $dbh->prepare($sql);
    $sth->execute($key) or die $dbh->errstr;

    my $exists = $sth->fetchrow_arrayref ? 1 : 0;

    $sth->finish();
    $dbh->disconnect();

    return $exists;
}

# Funzione per sincronizzare le impostazioni
sub sync_settings {
    my ($peer_ip, $peer_port) = @_;

    my $socket = IO::Socket::INET->new(
        PeerAddr => $peer_ip,
        PeerPort => $peer_port,
        Proto    => 'tcp',
    ) or warn "Impossibile connettersi a $peer_ip:$peer_port: $!\n" and return;

    print $socket "SYNC_REQUEST\n";
    my $response = <$socket>;
    if ($response =~ /^SYNC_RESPONSE\n(.+)/s) {
        my $received_settings = $1;
        foreach my $line (split("\n", $received_settings)) {
            my ($key, $value) = split('=', $line, 2);
            add_setting($key, $value);
        }
    }
    close($socket);
}

# Funzione per applicare i delta alle impostazioni
sub apply_delta {
    my ($received_settings) = @_;

    my %local_settings = get_all_settings();
    my %remote_settings = map { split('=', $_, 2) } split("\n", $received_settings);

    foreach my $key (keys %remote_settings) {
        if (!exists $local_settings{$key} || $local_settings{$key} ne $remote_settings{$key}) {
            add_setting($key, $remote_settings{$key});
            print "Impostazione aggiornata: $key = $remote_settings{$key}\n";
        }
    }
}

# Definizione della subroutine configuraValoriIniziali
sub configuraValoriIniziali {
    return init_conf::configuraValoriIniziali(); # Richiamo alla funzione in init_conf.pm
}

1;

#use strict;
#use warnings;
#use config_manager;

# Aggiungi o aggiorna impostazioni
#config_manager::add_setting('refresh_interval', '30');
#config_manager::add_setting('theme', 'dark');

# Recupera una singola impostazione
#my $theme = config_manager::get_setting('theme');
#print "Tema attuale: $theme\n" if defined $theme;

# Verifica se una chiave esiste
#if (config_manager::setting_exists('refresh_interval')) {
#    print "L'impostazione 'refresh_interval' esiste.\n";
#}

# Ottieni tutte le impostazioni
#my $settings = config_manager::get_all_settings();
#foreach my $key (keys %$settings) {
#    print "$key => $settings->{$key}\n";
#}

# Elimina una impostazione
#config_manager::delete_setting('theme');


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
