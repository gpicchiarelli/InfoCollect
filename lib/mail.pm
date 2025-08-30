package mail;

use strict;
use warnings;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP;
use Email::Simple;
use Email::Simple::Creator;
use JSON qw(decode_json);

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

    # Prefer SMTP transport if configurato, altrimenti fallback a sendmail
    if ($config->{smtp_host}) {
        my %opts = (
            host => $config->{smtp_host},
            port => $config->{smtp_port} || 25,
            timeout => $config->{smtp_timeout} || 10,
        );
        $opts{ssl} = 1 if $config->{smtp_ssl};
        if ($config->{smtp_user} && $config->{smtp_pass}) {
            $opts{sasl_username} = $config->{smtp_user};
            $opts{sasl_password} = $config->{smtp_pass};
        }
        my $transport = Email::Sender::Transport::SMTP->new(%opts);
        sendmail($email, { transport => $transport });
    } else {
        sendmail($email);
    }
}

1;
