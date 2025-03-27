import { useState, useEffect } from "react";
import { Input, Button, Card } from "../components/ui";

function FeedsPage() {
  const [feeds, setFeeds] = useState([]);
  const [newFeed, setNewFeed] = useState({ title: "", url: "" });

  useEffect(() => {
    fetchFeeds();
  }, []);

  const fetchFeeds = async () => {
    const res = await fetch("/api/feeds");
    const data = await res.json();
    setFeeds(data);
  };

  const addFeed = async () => {
    await fetch("/api/feeds", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(newFeed),
    });
    setNewFeed({ title: "", url: "" });
    fetchFeeds();
  };

  return (
    <div>
      <h2 className="text-xl font-semibold mb-4">Gestione Feed RSS</h2>
      <div className="flex gap-2 mb-4">
        <Input
          placeholder="Titolo"
          value={newFeed.title}
          onChange={(e) => setNewFeed({ ...newFeed, title: e.target.value })}
        />
        <Input
          placeholder="URL"
          value={newFeed.url}
          onChange={(e) => setNewFeed({ ...newFeed, url: e.target.value })}
        />
        <Button onClick={addFeed}>Aggiungi</Button>
      </div>
      <div className="space-y-2">
        {feeds.map((feed) => (
          <Card key={feed.id}>
            <div className="p-2">
              <strong>{feed.title}</strong> - {feed.url}
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}

export default FeedsPage;
