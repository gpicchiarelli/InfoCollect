package mail;

use strict;
use warnings;
use Email::Sender::Simple qw(sendmail);
use Email::Simple;
use Email::Simple::Creator;

sub send_notification {
    my ($channel, $message) = @_;
    my $config = decode_json($channel->{config});

    my $email = Email::Simple->create(
        header => [
            To      => $config->{to},
            From    => $config->{from},
            Subject => $config->{subject},
        ],
        body => $message,
    );

    sendmail($email);
}

1;
