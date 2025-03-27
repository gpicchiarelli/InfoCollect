import { useState, useEffect } from "react";
import { Input, Button, Card } from "../components/ui";

function SettingsPage() {
  const [settings, setSettings] = useState([]);
  const [newSetting, setNewSetting] = useState({ key: "", value: "" });
  const [channels, setChannels] = useState([]);
  const [newChannel, setNewChannel] = useState({ name: "", type: "", config: "" });

  useEffect(() => {
    fetchSettings();
    fetchChannels();
  }, []);

  const fetchSettings = async () => {
    const res = await fetch("/api/settings");
    const data = await res.json();
    setSettings(data);
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

  const fetchChannels = async () => {
    const res = await fetch("/api/notification_channels");
    const data = await res.json();
    setChannels(data);
  };

  const addChannel = async () => {
    await fetch("/api/notification_channels", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(newChannel),
    });
    setNewChannel({ name: "", type: "", config: "" });
    fetchChannels();
  };

  return (
    <div>
      <h2 className="text-xl font-semibold mb-4">Impostazioni</h2>
      <div className="flex gap-2 mb-4">
        <Input
          placeholder="Chiave"
          value={newSetting.key}
          onChange={(e) => setNewSetting({ ...newSetting, key: e.target.value })}
        />
        <Input
          placeholder="Valore"
          value={newSetting.value}
          onChange={(e) => setNewSetting({ ...newSetting, value: e.target.value })}
        />
        <Button onClick={addSetting}>Salva</Button>
      </div>
      <div className="space-y-2">
        {settings.map((setting) => (
          <Card key={setting.key}>
            <div className="p-2">
              <strong>{setting.key}</strong>: {setting.value}
            </div>
          </Card>
        ))}
      </div>
      <div className="space-y-2">
        <h3 className="text-lg font-semibold">Canali di Notifica</h3>
        <div className="flex gap-2">
          <Input placeholder="Nome" value={newChannel.name} onChange={(e) => setNewChannel({ ...newChannel, name: e.target.value })} />
          <Input placeholder="Tipo (RSS/Mail/Teams/IRC)" value={newChannel.type} onChange={(e) => setNewChannel({ ...newChannel, type: e.target.value })} />
          <Input placeholder="Config (JSON)" value={newChannel.config} onChange={(e) => setNewChannel({ ...newChannel, config: e.target.value })} />
          <Button onClick={addChannel}>Aggiungi</Button>
        </div>
        <div className="space-y-2">
          {channels.map((channel) => (
            <Card key={channel.id}>
              <div className="p-2">
                <strong>{channel.name}</strong> - {channel.type}
              </div>
            </Card>
          ))}
        </div>
      </div>
    </div>
  );
}

export default SettingsPage;
