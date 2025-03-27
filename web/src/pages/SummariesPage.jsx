import { useState, useEffect } from "react";
import { Input, Button, Card } from "../components/ui";

function SummariesPage() {
  const [summaries, setSummaries] = useState([]);
  const [newSummary, setNewSummary] = useState({ pageId: "", summary: "" });
  const [recipient, setRecipient] = useState("");

  useEffect(() => {
    fetchSummaries();
  }, []);

  const fetchSummaries = async () => {
    const res = await fetch("/api/summaries");
    const data = await res.json();
    setSummaries(data);
  };

  const addSummary = async () => {
    await fetch("/api/summaries", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(newSummary),
    });
    setNewSummary({ pageId: "", summary: "" });
    fetchSummaries();
  };

  const shareSummary = async (id) => {
    await fetch(`/api/summaries/${id}/share`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ recipient }),
    });
    setRecipient("");
    alert("Riassunto condiviso!");
  };

  return (
    <div>
      <h2 className="text-xl font-semibold mb-4">Gestione Riassunti</h2>
      <div className="flex gap-2 mb-4">
        <Input
          placeholder="ID Pagina"
          value={newSummary.pageId}
          onChange={(e) => setNewSummary({ ...newSummary, pageId: e.target.value })}
        />
        <Input
          placeholder="Riassunto"
          value={newSummary.summary}
          onChange={(e) => setNewSummary({ ...newSummary, summary: e.target.value })}
        />
        <Button onClick={addSummary}>Aggiungi</Button>
      </div>
      <div className="space-y-2">
        {summaries.map((summary) => (
          <Card key={summary.id}>
            <div className="p-2">
              <strong>{summary.summary}</strong>
              <div className="text-sm text-gray-600">Creato: {summary.created_at}</div>
              <div className="flex gap-2 mt-2">
                <Input
                  placeholder="Destinatario"
                  value={recipient}
                  onChange={(e) => setRecipient(e.target.value)}
                />
                <Button onClick={() => shareSummary(summary.id)}>Condividi</Button>
              </div>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}

export default SummariesPage;
