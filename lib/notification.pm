package notification;

use strict;
use warnings;
use lib './lib';
use irc;
use mail;
use rss;
use teams;
use whatsapp;
use slack;
use telegram;
use discord;
use Text::Template;
use db;
use JSON qw(decode_json encode_json);
use LWP::UserAgent;
use IO::Socket::INET;
use File::Basename qw(dirname);
use File::Spec;

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
    } elsif ($channel->{type} eq 'Slack') {
        slack::send_notification($channel, $message);
    } elsif ($channel->{type} eq 'Telegram') {
        telegram::send_notification($channel, $message);
    } elsif ($channel->{type} eq 'Discord') {
        discord::send_notification($channel, $message);
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
        { type => 'Slack',    required => [qw(webhook_url)], desc => 'Slack Incoming Webhook' },
        { type => 'Telegram', required => [qw(bot_token chat_id)], desc => 'Telegram Bot API (sendMessage)' },
        { type => 'Discord',  required => [qw(webhook_url)], desc => 'Discord Webhook' },
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

sub check_connector {
    my ($type, $config_str_or_hash) = @_;
    my $cfg = ref $config_str_or_hash eq 'HASH' ? $config_str_or_hash : eval { decode_json($config_str_or_hash) };
    return (0, 'Config JSON non valido') unless $cfg && ref $cfg eq 'HASH';
    my ($ok, $err) = validate_config($type, $cfg);
    return (0, $err) unless $ok;

    my $ua = LWP::UserAgent->new(timeout => 8);

    if ($type eq 'Mail') {
        my $host = $cfg->{smtp_host};
        my $port = $cfg->{smtp_port} || 25;
        return (0, 'smtp_host richiesto') unless $host;
        my $sock = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port, Proto => 'tcp', Timeout => 5);
        return $sock ? (1, undef) : (0, 'Connessione SMTP fallita');
    }
    if ($type eq 'IRC') {
        my $sock = IO::Socket::INET->new(PeerAddr => $cfg->{server}, PeerPort => $cfg->{port}, Proto => 'tcp', Timeout => 5);
        return $sock ? (1, undef) : (0, 'Connessione IRC fallita');
    }
    if ($type eq 'Teams') {
        my $res = $ua->post($cfg->{webhook_url}, 'Content-Type' => 'application/json', Content => encode_json({ text => 'InfoCollect check' }));
        return $res->is_success ? (1, undef) : (0, 'Webhook Teams non raggiungibile: '.$res->status_line);
    }
    if ($type eq 'Slack') {
        my $res = $ua->post($cfg->{webhook_url}, 'Content-Type' => 'application/json', Content => encode_json({ text => 'InfoCollect check' }));
        return $res->is_success ? (1, undef) : (0, 'Webhook Slack non raggiungibile: '.$res->status_line);
    }
    if ($type eq 'Discord') {
        my $res = $ua->post($cfg->{webhook_url}, 'Content-Type' => 'application/json', Content => encode_json({ content => 'InfoCollect check' }));
        return $res->is_success ? (1, undef) : (0, 'Webhook Discord non raggiungibile: '.$res->status_line);
    }
    if ($type eq 'Telegram') {
        my $base = $cfg->{api_url} // 'https://api.telegram.org';
        my $token = $cfg->{bot_token};
        return (0, 'bot_token mancante') unless $token;
        my $res = $ua->get("$base/bot$token/getMe");
        return $res->is_success ? (1, undef) : (0, 'Bot non raggiungibile: '.$res->status_line);
    }
    if ($type eq 'WhatsApp') {
        my $res = $ua->get($cfg->{api_url});
        return $res->is_success ? (1, undef) : (0, 'API WhatsApp non raggiungibile: '.$res->status_line);
    }
    if ($type eq 'RSS') {
        my $file = $cfg->{output_file};
        return (0, 'output_file mancante') unless $file;
        my $dir = dirname(File::Spec->rel2abs($file));
        return (-w $dir) ? (1, undef) : (0, "Directory non scrivibile: $dir");
    }
    return (0, 'Tipo non supportato');
}

sub default_config_template {
    my ($type) = @_;
    my ($c) = grep { $_->{type} eq $type } @{ supported_connectors() } or return '{}';
    my %tpl;
    for my $k (@{ $c->{required} }) {
        $tpl{$k} = $k =~ /port/     ? 1234
                 : $k =~ /ssl/      ? JSON::false
                 : $k =~ /timeout/  ? 10
                 : $k =~ /host/     ? 'example.com'
                 : $k =~ /url/      ? 'https://example.com'
                 : $k =~ /to/       ? 'dest@example.com'
                 : $k =~ /from/     ? 'mitt@example.com'
                 : $k =~ /subject/  ? 'InfoCollect'
                 : $k =~ /phone/    ? '+390000000000'
                 : $k =~ /channel/  ? '#canale'
                 : $k =~ /nick/     ? 'infocollect'
                 : $k =~ /ircname/  ? 'InfoCollect Bot'
                 :                    '';
    }
    return JSON->new->pretty->encode(\%tpl);
}

1;
