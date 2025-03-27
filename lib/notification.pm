package notification;

use strict;
use warnings;
use lib './lib';
use irc;
use mail;
use rss;
use teams;
use whatsapp;

sub send_notification {
    my ($channel, $message) = @_;

    if ($channel->{type} eq 'IRC') {
        irc::send_notification($channel, $message);
    } elsif ($channel->{type} eq 'Mail') {
        mail::send_notification($channel, $message);
    } elsif ($channel->{type} eq 'RSS') {
        rss::send_notification($channel, $message);
    } elsif ($channel->{type} eq 'Teams') {
        teams::send_notification($channel, $message);
    } elsif ($channel->{type} eq 'WhatsApp') {
        whatsapp::send_notification($channel, $message);
    } else {
        warn "Tipo di canale non supportato: $channel->{type}\n";
    }
}

1;
