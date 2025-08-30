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
use JSON qw(decode_json);

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

sub supported_connectors {
    return [
        { type => 'IRC',      required => [qw(server port nick ircname channel)], desc => 'Invia messaggi in un canale IRC' },
        { type => 'Mail',     required => [qw(to from subject smtp_host smtp_port)], desc => 'Invia email via SMTP' },
        { type => 'RSS',      required => [qw(title link description item_title item_link output_file)], desc => 'Scrive feed RSS su file' },
        { type => 'Teams',    required => [qw(webhook_url)], desc => 'Microsoft Teams webhook' },
        { type => 'WhatsApp', required => [qw(api_url phone)], desc => 'Invio messaggi via API WhatsApp' },
    ];
}

sub validate_config {
    my ($type, $config_str_or_hash) = @_;
    my $cfg = ref $config_str_or_hash eq 'HASH' ? $config_str_or_hash : eval { decode_json($config_str_or_hash) };
    return (0, 'Config JSON non valido') unless $cfg && ref $cfg eq 'HASH';
    my ($c) = grep { $_->{type} eq $type } @{ supported_connectors() };
    return (0, 'Tipo connettore non supportato') unless $c;
    my @missing = grep { !exists $cfg->{$_} || $cfg->{$_} eq '' } @{ $c->{required} };
    return @missing ? (0, 'Chiavi mancanti: ' . join(', ', @missing)) : (1, undef);
}

1;
