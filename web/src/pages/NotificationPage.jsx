import { useState, useEffect } from "react";
import { Input, Button, Card } from "../components/ui";

function NotificationPage() {
  const [notifications, setNotifications] = useState([]);
  const [newNotification, setNewNotification] = useState({ recipientId: "", message: "" });
  const [recipients, setRecipients] = useState([]);

  useEffect(() => {
    fetchNotifications();
    fetchRecipients();
  }, []);

  const fetchNotifications = async () => {
    const res = await fetch("/api/notifications");
    const data = await res.json();
    setNotifications(data);
  };

  const fetchRecipients = async () => {
    const res = await fetch("/api/recipients");
    const data = await res.json();
    setRecipients(data);
  };

  const sendNotification = async () => {
    await fetch("/api/notifications", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(newNotification),
    });
    setNewNotification({ recipientId: "", message: "" });
    fetchNotifications();
  };

  return (
    <div>
      <h2 className="text-xl font-semibold mb-4">Gestione Notifiche</h2>
      <div className="flex gap-2 mb-4">
        <select
          value={newNotification.recipientId}
          onChange={(e) => setNewNotification({ ...newNotification, recipientId: e.target.value })}
          className="border rounded px-2 py-1 w-full"
        >
          <option value="">Seleziona Destinatario</option>
          {recipients.map((recipient) => (
            <option key={recipient.id} value={recipient.id}>
              {recipient.name} - {recipient.contact}
            </option>
          ))}
        </select>
        <Input
          placeholder="Messaggio"
          value={newNotification.message}
          onChange={(e) => setNewNotification({ ...newNotification, message: e.target.value })}
        />
        <Button onClick={sendNotification}>Invia</Button>
      </div>
      <div className="space-y-2">
        {notifications.map((notification) => (
          <Card key={notification.id}>
            <div className="p-2">
              <strong>Destinatario:</strong> {notification.recipientName} - {notification.recipientContact}
              <div className="mt-2">{notification.message}</div>
              <div className="text-sm text-gray-600">Inviato: {notification.sentAt}</div>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}

export default NotificationPage;
