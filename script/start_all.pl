#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use POSIX qw(setsid);
use lib "$FindBin::Bin/../lib";

=pod

=head1 NAME

start_all.pl - Avvia i servizi principali (Web + Daemon) e la console CLI

=head1 SYNOPSIS

  perl script/start_all.pl [--port 3000]

Avvia:
- server web Mojolicious (web/api_server.pl) in background
- daemon P2P (daemon.pl) in background
- console CLI interattiva in foreground

=cut

my $port = 3000;
if (@ARGV && $ARGV[0] eq '--port' && $ARGV[1]) { $port = $ARGV[1] }

sub spawn_bg {
  my (@cmd) = @_;
  my $pid = fork();
  die "fork failed" unless defined $pid;
  if ($pid == 0) {
    setsid();
    open STDIN,  '<', '/dev/null';
    open STDOUT, '>', '/dev/null';
    open STDERR, '>', '/dev/null';
    exec @cmd or die "exec @cmd failed: $!";
  }
  return $pid;
}

my $root = "$FindBin::Bin/..";

print "[start_all] Avvio server web su http://localhost:$port ...\n";
my $web_pid = spawn_bg($^X, "$root/web/api_server.pl", 'daemon', '-l', "http://*:$port");

print "[start_all] Avvio daemon P2P ...\n";
my $daemon_pid = spawn_bg($^X, "$root/daemon.pl");

print "[start_all] PIDs: web=$web_pid, daemon=$daemon_pid\n";
print "[start_all] Avvio console interattiva...\n";

require interactive_cli;
interactive_cli::avvia_cli();

print "[start_all] Uscita dalla console. I processi in background restano attivi.\n";
exit 0;

