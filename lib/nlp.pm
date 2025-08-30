package nlp;

use strict;
use warnings;
use utf8;
use LWP::UserAgent;
use JSON;
use Lingua::Identify qw/langof/;
use Lingua::Stem::It; # Sostituito Lingua::IT::Stemmer
use Lingua::EN::Tagger;
use Text::Extract::Words;
use Encode qw(decode);
use lib './lib';
use config_manager;
use Exporter 'import';

our @EXPORT_OK = qw(riassumi_contenuto rilevanza_per_interessi estrai_parole_chiave);

# Istanza per stemming italiano
# Rimosso: Lingua::Stem::It non ha un metodo new

# Istanza per tagging inglese
my $tagger_en = Lingua::EN::Tagger->new();

# Configurazione API per il riassunto
my $api_url = 'https://api-inference.huggingface.co/models/facebook/bart-large-cnn';
# Token letto dalle impostazioni, con fallback
my $api_token = eval { config_manager::get_setting('HUGGINGFACE_API_TOKEN') } // 'YOUR_HUGGINGFACE_API_TOKEN';

=pod

=head1 NAME

nlp - Utilità NLP per riassunto, interessi e parole chiave

=head1 DESCRIPTION

Fornisce riassunto via API (con fallback locale), valutazione di rilevanza in base ad interessi
e estrazione di parole chiave. Parametrizza modelli e token API.

Cross-reference: docs/REFERENCE.md (NLP).

=cut

=head1 FUNCTIONS

=over 4

=item riassumi_contenuto($content)

Ritorna un riassunto del testo passato. Usa l'API HuggingFace se è impostato
il token C<HUGGINGFACE_API_TOKEN> in settings; altrimenti usa un fallback locale.

=item rilevanza_per_interessi($testo, \@interessi)

Ritorna 1/0 in base alla presenza di parole degli interessi nel testo.

=item estrai_parole_chiave($testo, $lingua)

Estrae parole chiave dal testo (stemming IT, tagging EN, fallback generico).

=back

=cut

# Riassume un testo in base alla lingua
sub riassumi_contenuto {
    my ($content) = @_;
    die "Errore: contenuto vuoto o non definito" unless $content;

    # Fallback locale se il token non è configurato
    if (!$api_token || $api_token eq 'YOUR_HUGGINGFACE_API_TOKEN') {
        my $clean = $content;
        $clean =~ s/\s+/ /g;
        $clean = substr($clean, 0, 320);
        return length($clean) ? $clean . '…' : 'Riassunto non disponibile';
    }

    my $ua = LWP::UserAgent->new;
    my $response = $ua->post(
        $api_url,
        'Content-Type'  => 'application/json',
        'Authorization' => "Bearer $api_token",
        Content         => encode_json({ inputs => $content })
    );

    if ($response->is_success) {
        my $result = decode_json($response->decoded_content);
        return $result->{summary_text} || "Riassunto non disponibile";
    } else {
        warn "Errore durante la richiesta di riassunto: " . $response->status_line;
        return "Riassunto non disponibile";
    }
}

# Valuta se il testo è rilevante in base agli interessi
sub rilevanza_per_interessi {
    my ($testo, $interessi_ref) = @_;
    return 0 unless $testo && $interessi_ref && @$interessi_ref;  # Gestione di input vuoto

    my $testo_lower = lc($testo);

    foreach my $interesse (@$interessi_ref) {
        my $i = lc($interesse);

        # Usa una regex robusta per evitare falsi positivi
        return 1 if $testo_lower =~ /\b\Q$i\E\b/;
    }

    return 0;
}

# Estrae parole chiave dal testo
sub estrai_parole_chiave {
    my ($testo, $lingua) = @_;
    return [] unless $testo;  # Gestione di input vuoto

    my @parole_chiave;

    if ($lingua && $lingua eq 'it') {
        # Stemming per l'italiano con Lingua::Stem::It
        my @parole = Text::Extract::Words::extract($testo);
        @parole_chiave = Lingua::Stem::It::stem(@parole);
    } elsif ($lingua && $lingua eq 'en') {
        # Tagging per l'inglese
        my $tagged_text = $tagger_en->add_tags($testo);
        @parole_chiave = $tagged_text =~ /<nn>(.*?)<\/nn>/g;  # Estrai i sostantivi
    } else {
        # Fallback: estrai parole senza elaborazione
        @parole_chiave = Text::Extract::Words::extract($testo);
    }

    # Rimuove duplicati e restituisce le parole chiave
    my %seen;
    return [grep { !$seen{$_}++ } @parole_chiave];
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
