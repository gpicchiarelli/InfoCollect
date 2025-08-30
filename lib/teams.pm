package teams;

use strict;
use warnings;
use LWP::UserAgent;
use JSON qw(decode_json encode_json);

sub send_notification {
    my ($channel, $message) = @_;
    my $config = decode_json($channel->{config});

    my $ua = LWP::UserAgent->new();
    my $res = $ua->post(
        $config->{webhook_url},
        'Content-Type' => 'application/json',
        Content => encode_json({ text => $message }),
    );

    warn "Errore Teams: " . $res->status_line unless $res->is_success;
}

1;
