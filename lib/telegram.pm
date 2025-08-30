package telegram;

use strict;
use warnings;
use LWP::UserAgent;
use JSON qw(decode_json encode_json);

sub send_notification {
    my ($channel, $message) = @_;
    my $config = decode_json($channel->{config});

    my $base = $config->{api_url} // 'https://api.telegram.org';
    my $token = $config->{bot_token};
    my $chat  = $config->{chat_id};
    return unless $token && $chat;

    my $url = "$base/bot$token/sendMessage";
    my $ua = LWP::UserAgent->new(timeout => 10);
    my $res = $ua->post(
        $url,
        'Content-Type' => 'application/json',
        Content => encode_json({ chat_id => $chat, text => $message }),
    );

    warn "Errore Telegram: " . $res->status_line unless $res->is_success;
}

1;

