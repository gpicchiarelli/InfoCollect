import { BrowserRouter as Router, Routes, Route, Link } from "react-router-dom";
import FeedsPage from "./pages/FeedsPage";
import PagesPage from "./pages/PagesPage";
import SettingsPage from "./pages/SettingsPage";
import LogsPage from "./pages/LogsPage";
import SummariesPage from "./pages/SummariesPage";

function App() {
  return (
    <Router>
      <div className="min-h-screen bg-gray-50 text-gray-800">
        <header className="bg-white shadow">
          <div className="container mx-auto px-4 py-4 flex justify-between items-center">
            <h1 className="text-2xl font-bold">InfoCollect</h1>
            <nav className="space-x-4">
              <Link to="/" className="hover:text-blue-500">Feed RSS</Link>
              <Link to="/pages" className="hover:text-blue-500">Pagine</Link>
              <Link to="/settings" className="hover:text-blue-500">Impostazioni</Link>
              <Link to="/logs" className="hover:text-blue-500">Log</Link>
              <Link to="/summaries" className="hover:text-blue-500">Riassunti</Link>
            </nav>
          </div>
        </header>
        <main className="container mx-auto px-4 py-6">
          <Routes>
            <Route path="/" element={<FeedsPage />} />
            <Route path="/pages" element={<PagesPage />} />
            <Route path="/settings" element={<SettingsPage />} />
            <Route path="/logs" element={<LogsPage />} />
            <Route path="/summaries" element={<SummariesPage />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App;
