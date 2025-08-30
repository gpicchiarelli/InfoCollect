package backup;

use strict;
use warnings;
use File::Copy qw(copy);
use FindBin;
use lib "$FindBin::Bin/.."; # consente 'use db' quando richiamato da script/
use lib './lib';
use db;

sub _db_path {
    my $st = db::get_db_status();
    my $path = $st->{path} || 'var/infocollect.db';
    return $path;
}

sub export_backup {
    my $backup_file = "backup_" . time() . ".db";
    my $src = _db_path();
    copy($src, $backup_file) or die "Errore durante il backup da '$src' a '$backup_file': $!";
    print "Backup esportato: $backup_file\n";
}

sub import_backup {
    my ($backup_file) = @_;
    my $dst = _db_path();
    copy($backup_file, $dst) or die "Errore durante l'importazione del backup su '$dst': $!";
    print "Backup importato con successo su $dst.\n";
}

# Per compatibilità: esegue il backup dell'intero DB (include anche utenti nella stessa base dati)
sub export_backup_utenti { export_backup() }
sub import_backup_utenti { my ($f)=@_; import_backup($f) }

1;
