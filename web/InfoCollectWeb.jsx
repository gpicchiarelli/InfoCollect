import { useEffect, useState } from "react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

export default function InfoCollectWeb() {
  const [rssData, setRssData] = useState([]);
  const [webData, setWebData] = useState([]);
  const [settings, setSettings] = useState([]);
  const [p2pStatus, setP2pStatus] = useState([]);

  useEffect(() => {
    fetchRssData();
    fetchWebData();
    fetchSettings();
    fetchP2pStatus();
  }, []);

  const fetchRssData = async () => {
    const res = await fetch("/api/rss_data");
    const data = await res.json();
    setRssData(data);
  };

  const fetchWebData = async () => {
    const res = await fetch("/api/web_data");
    const data = await res.json();
    setWebData(data);
  };

  const fetchSettings = async () => {
    const res = await fetch("/api/settings");
    const data = await res.json();
    setSettings(data);
  };

  const fetchP2pStatus = async () => {
    const res = await fetch("/api/p2p_status");
    const data = await res.json();
    setP2pStatus(data);
  };

  const updateSetting = async (key, value) => {
    await fetch("/api/settings", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ key, value }),
    });
    fetchSettings();
  };

  return (
    <div className="p-6 space-y-4">
      <h1 className="text-2xl font-bold">InfoCollect - Dashboard</h1>
      <Tabs defaultValue="rss">
        <TabsList>
          <TabsTrigger value="rss">Dati RSS</TabsTrigger>
          <TabsTrigger value="web">Dati Web</TabsTrigger>
          <TabsTrigger value="settings">Impostazioni</TabsTrigger>
          <TabsTrigger value="p2p">Sincronizzazione P2P</TabsTrigger>
        </TabsList>
        <TabsContent value="rss">
          <h2>Dati RSS</h2>
          <ul>{rssData.map((item, idx) => <li key={idx}>{item.title}</li>)}</ul>
        </TabsContent>
        <TabsContent value="web">
          <h2>Dati Web</h2>
          <ul>{webData.map((item, idx) => <li key={idx}>{item.url}</li>)}</ul>
        </TabsContent>
        <TabsContent value="settings">
          <h2>Impostazioni</h2>
          <ul>
            {settings.map((setting, idx) => (
              <li key={idx}>
                {setting.key}: {setting.value}
                <button onClick={() => updateSetting(setting.key, "newValue")}>Aggiorna</button>
              </li>
            ))}
          </ul>
        </TabsContent>
        <TabsContent value="p2p">
          <h2>Sincronizzazione P2P</h2>
          <pre>{JSON.stringify(p2pStatus, null, 2)}</pre>
        </TabsContent>
      </Tabs>
    </div>
  );
}
