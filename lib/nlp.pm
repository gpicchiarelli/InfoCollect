package nlp;

use strict;
use warnings;
use utf8;

use Text::Summarizer;
use Lingua::Identify qw/langof/;
use Lingua::IT::Stemmer;
use Lingua::EN::Tagger;
use Text::Extract::Words;

use Exporter 'import';
our @EXPORT_OK = qw(riassumi_contenuto rilevanza_per_interessi);

# Istanza per stemming italiano
my $stem_it = Lingua::IT::Stemmer->new();

# Istanza per tagging inglese
my $tagger_en = Lingua::EN::Tagger->new();

# Riassume un testo in base alla lingua
sub riassumi_contenuto {
    my ($testo) = @_;
    my $lingua = langof($testo);

    my $sommario;
    eval {
        my $summarizer = Text::Summarizer->new();
        $sommario = $summarizer->summary($testo);
    };

    if ($@ or !$sommario) {
        # Fallback semplice se il modulo fallisce
        my @frasi = split(/(?<=[.!?])\s+/, $testo);
        $sommario = join(" ", @frasi[0..$#frasi > 2 ? 2 : $#frasi]);
    }

    return ($sommario, $lingua);
}

# Valuta se il testo è rilevante in base agli interessi
sub rilevanza_per_interessi {
    my ($testo, $interessi_ref) = @_;
    my $testo_lower = lc($testo);

    foreach my $interesse (@$interessi_ref) {
        my $i = lc($interesse);
        return 1 if $testo_lower =~ /\b\Q$i\E\b/;
    }

    return 0;
}

1;

# Licenza BSD
# -----------------------------------------------------------------------------
# Copyright (c) 2024, Giacomo Picchiarelli
# All rights reserved.
#
# Ridistribuzione e uso nel formato sorgente e binario, con o senza modifiche,
# sono consentiti purché siano soddisfatte le seguenti condizioni:
#
# 1. Le ridistribuzioni del codice sorgente devono conservare l'avviso di copyright
#    di cui sopra, questo elenco di condizioni e il seguente disclaimer.
# 2. Le ridistribuzioni in formato binario devono riprodurre l'avviso di copyright,
#    questo elenco di condizioni e il seguente disclaimer nella documentazione
#    e/o nei materiali forniti con la distribuzione.
# 3. Né il nome dell'autore né i nomi dei suoi collaboratori possono essere utilizzati
#    per promuovere prodotti derivati da questo software senza un'autorizzazione
#    specifica scritta.
#
# QUESTO SOFTWARE È FORNITO "COSÌ COM'È" E QUALSIASI GARANZIA ESPRESSA O IMPLICITA
# È ESCLUSA. IN NESSUN CASO L'AUTORE SARÀ RESPONSABILE PER DANNI DERIVANTI
# DALL'USO DEL SOFTWARE.
# -----------------------------------------------------------------------------