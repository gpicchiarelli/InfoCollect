package notification;

use strict;
use warnings;
use lib './lib';
use irc;
use mail;
use rss;
use teams;
use whatsapp;
use Text::Template;
use db;

sub send_notification {
    my ($channel, $message, $template_name, $template_data) = @_;

    # Usa il template se specificato
    if ($template_name) {
        my $template_content = db::get_template_by_name($template_name);
        if ($template_content) {
            my $template = Text::Template->new(TYPE => 'STRING', SOURCE => $template_content);
            $message = $template->fill_in(HASH => $template_data);
        } else {
            warn "Template non trovato: $template_name\n";
        }
    }

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
