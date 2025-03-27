import { useState } from "react";
import { Button } from "../components/ui";

function ReportsPage() {
  const [report, setReport] = useState("");

  const generateReport = async () => {
    const res = await fetch("/api/reports");
    const data = await res.text();
    setReport(data);
  };

  return (
    <div>
      <h2 className="text-xl font-semibold mb-4">Report</h2>
      <Button onClick={generateReport}>Genera Report</Button>
      <pre className="mt-4 p-4 bg-gray-100 rounded">{report}</pre>
    </div>
  );
}

export default ReportsPage;
