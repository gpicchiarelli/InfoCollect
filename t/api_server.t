use strict;
use warnings;
use Test::More;
use Test::Mojo;
use FindBin;
require "$FindBin::Bin/../web/api_server.pl";
my $t = Test::Mojo->new;

# Test dell'endpoint /api/send_task
$t->post_ok('/api/send_task' => json => { peer_id => 'test_peer', task_data => 'test_task' })
  ->status_is(200)
  ->json_is('/success' => 1);

# Test dell'endpoint /api/import_opml
$t->post_ok('/api/import_opml' => form => { file_path => "$FindBin::Bin/../script/test_data/test.opml" })
  ->status_is(200)
  ->json_is('/success' => 1);

done_testing();
