#!/usr/bin/env perl

use strict;
use warnings;
use IO::Socket::INET;
use lib './lib';
use p2p;

my $port = 5001;
my $server = IO::Socket::INET->new(
    LocalPort => $port,
    Proto     => 'tcp',
    Listen    => 5,
    Reuse     => 1
) or die "Impossibile avviare il server: $!\n";

print "Daemon in ascolto sulla porta $port...\n";

while (my $client = $server->accept()) {
    while (<$client>) {
        chomp;
        if (/^PING$/) {
            print $client "PONG\n";
        } elsif (/^SYNC$/) {
            p2p::sync_data($client);
        } elsif (/^TASK:(.+)$/) {
            my $result = p2p::receive_task($_);
            print $client "RESULT:$result\n";
        }
    }
    close $client;
}
