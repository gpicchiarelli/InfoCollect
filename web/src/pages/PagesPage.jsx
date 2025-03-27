import { useState, useEffect } from "react";
import { Card } from "../components/ui";

function PagesPage() {
  const [pages, setPages] = useState([]);

  useEffect(() => {
    fetchPages();
  }, []);

  const fetchPages = async () => {
    const res = await fetch("/api/pages");
    const data = await res.json();
    setPages(data);
  };

  return (
    <div>
      <h2 className="text-xl font-semibold mb-4">Pagine Raccolte</h2>
      <div className="space-y-2">
        {pages.map((page) => (
          <Card key={page.id}>
            <div className="p-2">
              <strong>{page.url}</strong>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}

export default PagesPage;
