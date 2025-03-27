package rss_crawler;

use strict;
use warnings;
use LWP::UserAgent;
use XML::RSS;
use db;

sub esegui_crawler_rss {
    my $feeds = db::get_all_rss_feeds();

    foreach my $feed (@$feeds) {
        my $url = $feed->{url};
        my $ua = LWP::UserAgent->new(timeout => 10);

        my $response = $ua->get($url);
        if ($response->is_success) {
            my $rss = XML::RSS->new();
            $rss->parse($response->decoded_content);

            foreach my $item (@{$rss->{items}}) {
                db::insert_article(
                    $feed->{id},
                    $item->{title},
                    $item->{link},
                    $item->{pubDate},
                    $item->{description},
                    $item->{author}
                );
            }
        } else {
            warn "Errore nel recupero del feed $url: " . $response->status_line;
        }
    }
}

1;