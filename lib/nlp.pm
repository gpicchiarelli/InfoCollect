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