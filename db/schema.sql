CREATE TABLE IF NOT EXISTS peer_requests (
    peer_id TEXT PRIMARY KEY,
    public_key TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS accepted_peers (
    peer_id TEXT PRIMARY KEY,
    public_key TEXT NOT NULL
);
