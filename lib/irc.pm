package irc;

use strict;
use warnings;
use Net::IRC;
use JSON qw(decode_json);

sub send_notification {
    my ($channel, $message) = @_;
    my $config = decode_json($channel->{config});

    my $irc = Net::IRC->new();
    my $conn = $irc->newconn(
        Server   => $config->{server},
        Port     => $config->{port},
        Nick     => $config->{nick},
        Ircname  => $config->{ircname},
    );

    $conn->add_handler('376', sub {
        $conn->join($config->{channel});
        $conn->privmsg($config->{channel}, $message);
        $conn->quit("Notifica inviata.");
    });

    $irc->start();
}

1;
