import { useState, useEffect } from "react";
import { Input, Button, Card } from "../components/ui";

function SettingsPage() {
  const [settings, setSettings] = useState([]);
  const [newSetting, setNewSetting] = useState({ key: "", value: "" });

  useEffect(() => {
    fetchSettings();
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
    </div>
  );
}

export default SettingsPage;
