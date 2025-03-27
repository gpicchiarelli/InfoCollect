package backup;

use strict;
use warnings;
use DBI;
use File::Copy;

sub export_backup {
    my $backup_file = "backup_" . time() . ".db";
    copy("infocollect.db", $backup_file) or die "Errore durante il backup: $!";
    print "Backup esportato: $backup_file\n";
}

sub import_backup {
    my ($backup_file) = @_;
    copy($backup_file, "infocollect.db") or die "Errore durante l'importazione del backup: $!";
    print "Backup importato con successo.\n";
}

sub export_backup_utenti {
    my $backup_file = "backup_utenti_" . time() . ".db";
    copy("infocollect_utenti.db", $backup_file) or die "Errore durante il backup della tabella utenti: $!";
    print "Backup della tabella utenti esportato: $backup_file\n";
}

sub import_backup_utenti {
    my ($backup_file) = @_;
    copy($backup_file, "infocollect_utenti.db") or die "Errore durante l'importazione del backup della tabella utenti: $!";
    print "Backup della tabella utenti importato con successo.\n";
}

1;
