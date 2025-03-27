import { useState, useEffect } from "react";
import { Card } from "../components/ui";

function LogsPage() {
  const [logs, setLogs] = useState([]);

  useEffect(() => {
    fetchLogs();
  }, []);

  const fetchLogs = async () => {
    const res = await fetch("/api/logs");
    const data = await res.json();
    setLogs(data);
  };

  return (
    <div>
      <h2 className="text-xl font-semibold mb-4">Log</h2>
      <div className="space-y-2">
        {logs.map((log) => (
          <Card key={log.id}>
            <div className="p-2">
              <strong>{log.timestamp}</strong>: {log.message}
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}

export default LogsPage;
