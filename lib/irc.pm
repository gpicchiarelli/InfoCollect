package irc;

use strict;
use warnings;
use IO::Socket::INET;
use IO::Select;
use JSON qw(decode_json);

sub send_notification {
    my ($channel, $message) = @_;
    my $cfg = ref $channel->{config} eq 'HASH' ? $channel->{config} : decode_json($channel->{config});

    my $server  = $cfg->{server}   or die "IRC server mancante";
    my $port    = $cfg->{port}     || 6667;
    my $nick    = $cfg->{nick}     || 'infocollect';
    my $ircname = $cfg->{ircname}  || 'InfoCollect';
    my $chan    = $cfg->{channel}  or die "IRC channel mancante";
    my $pass    = $cfg->{password};
    my $use_ssl = $cfg->{use_ssl}  || 0;

    my $sock;
    if ($use_ssl) {
        eval { require IO::Socket::SSL; IO::Socket::SSL->import(); 1 } or die "IO::Socket::SSL non installato";
        $sock = IO::Socket::SSL->new(
            PeerAddr => $server,
            PeerPort => $port,
            SSL_verify_mode => 0,
            Timeout  => 10,
        ) or die "Connessione IRC SSL fallita: $!";
    } else {
        $sock = IO::Socket::INET->new(
            PeerAddr => $server,
            PeerPort => $port,
            Proto    => 'tcp',
            Timeout  => 10,
        ) or die "Connessione IRC fallita: $!";
    }

    $sock->autoflush(1);
    _send($sock, "PASS $pass") if defined $pass && length $pass;
    _send($sock, "NICK $nick");
    _send($sock, "USER $nick 0 * :$ircname");

    _wait_ready($sock, 15);
    _send($sock, "JOIN $chan");
    _send($sock, "PRIVMSG $chan :$message");
    _send($sock, "QUIT :InfoCollect");
    close $sock;
}

sub _send {
    my ($sock, $line) = @_;
    print $sock $line . "\r\n";
}

sub _wait_ready {
    my ($sock, $timeout) = @_;
    my $sel = IO::Select->new($sock);
    my $start = time;
    while ((time - $start) < $timeout) {
        my @r = $sel->can_read(1);
        for my $fh (@r) {
            my $buf = '';
            my $n = sysread($fh, $buf, 4096);
            next unless $n;
            for my $line (split /\r?\n/, $buf) {
                if ($line =~ /^PING\s*:(.+)/i) {
                    _send($sock, 'PONG :' . $1);
                }
                if ($line =~ /\s(001|376|422)\s/) { # welcome or end of MOTD
                    return 1;
                }
            }
        }
    }
    return 0;
}

1;
