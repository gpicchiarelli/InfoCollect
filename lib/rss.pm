package rss;

use strict;
use warnings;
use XML::RSS;
use JSON qw(decode_json);

sub send_notification {
    my ($channel, $message) = @_;
    my $config = decode_json($channel->{config});

    my $rss = XML::RSS->new(version => '2.0');
    $rss->channel(
        title       => $config->{title},
        link        => $config->{link},
        description => $config->{description},
    );

    $rss->add_item(
        title       => $config->{item_title},
        link        => $config->{item_link},
        description => $message,
    );

    open my $fh, '>', $config->{output_file} or die "Errore: $!";
    print $fh $rss->as_string;
    close $fh;
}

1;
