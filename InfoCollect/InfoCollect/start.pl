#!/usr/bin/env perl
use strict;
use warnings;
use LWP::Simple;
use XML::RSS;
use Term::ANSIColor;

# URL del feed RSS di esempio
my $url = 'https://www.repubblica.it/rss/homepage/rss2.0.xml';

# Scarica il contenuto del feed
my $content = get($url) or die "Impossibile scaricare il feed: $url\n";

# Crea un nuovo parser RSS
my $rss = XML::RSS->new;
$rss->parse($content);

# Mostra i titoli delle news
foreach my $item (@{$rss->{items}}) {
    print colored("Titolo: ", 'bold green'), $item->{title}, "\n";
    print colored("Link: ", 'bold blue'), $item->{link}, "\n";
    print "-" x 40, "\n";
}

__END__

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

