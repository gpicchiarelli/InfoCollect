import { BrowserRouter as Router, Routes, Route, Link } from "react-router-dom";
import FeedsPage from "./pages/FeedsPage";
import PagesPage from "./pages/PagesPage";
import SettingsPage from "./pages/SettingsPage";
import LogsPage from "./pages/LogsPage";
import SummariesPage from "./pages/SummariesPage";
import LoginPage from "./pages/LoginPage";
import RegisterPage from "./pages/RegisterPage";
import { useEffect } from "react";

function App() {
  useEffect(() => {
    const socket = new WebSocket("ws://localhost:8080");
    socket.onmessage = (event) => {
      const notification = JSON.parse(event.data);
      alert(`Notifica: ${notification.message}`);
    };
    return () => socket.close();
  }, []);

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
            <Route path="/login" element={<LoginPage />} />
            <Route path="/register" element={<RegisterPage />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App;
