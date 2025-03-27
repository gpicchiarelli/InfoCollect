#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Time::HiRes qw(sleep);
use db;
use notification;
use config_manager;
use rss_crawler;
use web_crawler;

print "[Notification Agent] Avvio del thread di notifiche...\n";

# Recupera l'intervallo di notifiche dalla configurazione
my %settings = config_manager::get_all_settings();
my $interval = $settings{"NOTIFICATION_INTERVAL_MINUTI"} || 10;

while (1) {
    eval {
        print "[Notification Agent] Invio notifiche...\n";

        # Recupera i canali di notifica attivi
        my $channels = db::get_notification_channels();

        foreach my $channel (@$channels) {
            # Messaggio di esempio (può essere personalizzato)
            my $message = "Notifica automatica inviata alle " . localtime();
            notification::send_notification($channel, $message);
            print "[Notification Agent] Notifica inviata tramite $channel->{type} ($channel->{name})\n";
        }

        # Rilancio dei contenuti RSS
        print "[Notification Agent] Rilancio dei contenuti RSS...\n";
        eval {
            rss_crawler::esegui_crawler_rss();
            print "[Notification Agent] Rilancio RSS completato.\n";
        };
        if ($@) {
            warn "[Notification Agent] Errore durante il rilancio RSS: $@\n";
        }

        # Rilancio dei contenuti delle pagine web
        print "[Notification Agent] Rilancio dei contenuti delle pagine web...\n";
        eval {
            web_crawler::esegui_crawler_web();
            print "[Notification Agent] Rilancio Web completato.\n";
        };
        if ($@) {
            warn "[Notification Agent] Errore durante il rilancio Web: $@\n";
        }

        print "[Notification Agent] Attesa $interval minuti prima del prossimo ciclo...\n";
    };
    if ($@) {
        warn "[Notification Agent] Errore durante l'invio delle notifiche: $@\n";
    }
    sleep($interval * 60);
}
