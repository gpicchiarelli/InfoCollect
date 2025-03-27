package whatsapp;

use strict;
use warnings;
use LWP::UserAgent;

sub send_notification {
    my ($channel, $message) = @_;
    my $config = decode_json($channel->{config});

    my $ua = LWP::UserAgent->new();
    my $res = $ua->post(
        $config->{api_url},
        Content => {
            phone   => $config->{phone},
            message => $message,
        },
    );

    warn "Errore WhatsApp: " . $res->status_line unless $res->is_success;
}

1;
