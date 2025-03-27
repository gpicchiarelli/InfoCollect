import { useState, useEffect } from "react";
import { Input, Button, Card } from "../components/ui";

function SettingsPage() {
  const [settings, setSettings] = useState([]);
  const [newSetting, setNewSetting] = useState({ key: "", value: "" });
  const [channels, setChannels] = useState([]);
  const [newChannel, setNewChannel] = useState({ name: "", type: "", config: "" });
  const [senders, setSenders] = useState([]);
  const [newSender, setNewSender] = useState({ name: "", type: "", config: "", active: true });
  const [recipients, setRecipients] = useState([]);
  const [newRecipient, setNewRecipient] = useState({ name: "", contact: "" });

  useEffect(() => {
    fetchSettings();
    fetchChannels();
    fetchSenders();
    fetchRecipients();
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

  const fetchSenders = async () => {
    const res = await fetch("/api/senders");
    const data = await res.json();
    setSenders(data);
  };

  const addSender = async () => {
    await fetch("/api/senders", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(newSender),
    });
    setNewSender({ name: "", type: "", config: "", active: true });
    fetchSenders();
  };

  const fetchRecipients = async () => {
    const res = await fetch("/api/recipients");
    const data = await res.json();
    setRecipients(data);
  };

  const addRecipient = async () => {
    await fetch("/api/recipients", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(newRecipient),
    });
    setNewRecipient({ name: "", contact: "" });
    fetchRecipients();
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
      <div className="space-y-2">
        <h3 className="text-lg font-semibold">Mittenti</h3>
        <div className="flex gap-2">
          <Input placeholder="Nome" value={newSender.name} onChange={(e) => setNewSender({ ...newSender, name: e.target.value })} />
          <Input placeholder="Tipo (Mail/RSS/WhatsApp/IRC)" value={newSender.type} onChange={(e) => setNewSender({ ...newSender, type: e.target.value })} />
          <Input placeholder="Config (JSON)" value={newSender.config} onChange={(e) => setNewSender({ ...newSender, config: e.target.value })} />
          <Button onClick={addSender}>Aggiungi</Button>
        </div>
        <div className="space-y-2">
          {senders.map((sender) => (
            <Card key={sender.id}>
              <div className="p-2">
                <strong>{sender.name}</strong> - {sender.type} (Attivo: {sender.active ? "Sì" : "No"})
              </div>
            </Card>
          ))}
        </div>
      </div>
      <div className="space-y-2">
        <h3 className="text-lg font-semibold">Destinatari</h3>
        <div className="flex gap-2">
          <Input placeholder="Nome" value={newRecipient.name} onChange={(e) => setNewRecipient({ ...newRecipient, name: e.target.value })} />
          <Input placeholder="Contatto (Email/Telefono)" value={newRecipient.contact} onChange={(e) => setNewRecipient({ ...newRecipient, contact: e.target.value })} />
          <Button onClick={addRecipient}>Aggiungi</Button>
        </div>
        <div className="space-y-2">
          {recipients.map((recipient) => (
            <Card key={recipient.id}>
              <div className="p-2">
                <strong>{recipient.name}</strong> - {recipient.contact}
              </div>
            </Card>
          ))}
        </div>
      </div>
    </div>
  );
}

export default SettingsPage;
