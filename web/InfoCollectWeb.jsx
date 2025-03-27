
import { useEffect, useState } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Textarea } from "@/components/ui/textarea";

export default function InfoCollectWeb() {
  const [feeds, setFeeds] = useState([]);
  const [pages, setPages] = useState([]);
  const [settings, setSettings] = useState({});
  const [newFeed, setNewFeed] = useState({ title: "", url: "" });
  const [newSetting, setNewSetting] = useState({ key: "", value: "" });

  useEffect(() => {
    fetchFeeds();
    fetchPages();
    fetchSettings();
  }, []);

  const fetchFeeds = async () => {
    const res = await fetch("/api/feeds");
    const data = await res.json();
    setFeeds(data);
  };

  const fetchPages = async () => {
    const res = await fetch("/api/pages");
    const data = await res.json();
    setPages(data);
  };

  const fetchSettings = async () => {
    const res = await fetch("/api/settings");
    const data = await res.json();
    const settingsObj = Object.fromEntries(data.map(s => [s.key, s.value]));
    setSettings(settingsObj);
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

  const addSetting = async () => {
    await fetch("/api/settings", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(newSetting),
    });
    setNewSetting({ key: "", value: "" });
    fetchSettings();
  };

  return (
    <div className="p-6 space-y-4">
      <h1 className="text-2xl font-bold">InfoCollect - Interfaccia Web</h1>
      <Tabs defaultValue="feeds">
        <TabsList>
          <TabsTrigger value="feeds">Feed RSS</TabsTrigger>
          <TabsTrigger value="pages">Pagine Raccolte</TabsTrigger>
          <TabsTrigger value="settings">Impostazioni</TabsTrigger>
        </TabsList>
        <TabsContent value="feeds">
          <div className="space-y-2">
            <div className="flex gap-2">
              <Input placeholder="Titolo" value={newFeed.title} onChange={e => setNewFeed({ ...newFeed, title: e.target.value })} />
              <Input placeholder="URL" value={newFeed.url} onChange={e => setNewFeed({ ...newFeed, url: e.target.value })} />
              <Button onClick={addFeed}>Aggiungi</Button>
            </div>
            {feeds.map(feed => (
              <Card key={feed.id}><CardContent className="p-2">[{feed.title}] {feed.url}</CardContent></Card>
            ))}
          </div>
        </TabsContent>
        <TabsContent value="pages">
          <div className="space-y-2 max-h-[60vh] overflow-y-auto">
            {pages.map(page => (
              <Card key={page.url}>
                <CardContent className="p-2">
                  <div className="font-semibold">{page.title}</div>
                  <div className="text-sm text-gray-600">{page.url}</div>
                  <div className="text-xs mt-1">{page.content?.slice(0, 200)}...</div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>
        <TabsContent value="settings">
          <div className="space-y-2">
            <div className="flex gap-2">
              <Input placeholder="Chiave" value={newSetting.key} onChange={e => setNewSetting({ ...newSetting, key: e.target.value })} />
              <Input placeholder="Valore" value={newSetting.value} onChange={e => setNewSetting({ ...newSetting, value: e.target.value })} />
              <Button onClick={addSetting}>Salva</Button>
            </div>
            {Object.entries(settings).map(([k, v]) => (
              <Card key={k}><CardContent className="p-2 font-mono">{k} = {v}</CardContent></Card>
            ))}
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
}
