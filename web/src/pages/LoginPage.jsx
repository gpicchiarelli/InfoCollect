import { useState } from "react";
import { Input, Button } from "../components/ui";

function LoginPage() {
  const [credentials, setCredentials] = useState({ username: "", password: "" });

  const handleLogin = async () => {
    const res = await fetch("/api/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(credentials),
    });
    if (res.ok) {
      alert("Login effettuato con successo!");
      window.location.href = "/";
    } else {
      alert("Credenziali non valide.");
    }
  };

  return (
    <div className="flex flex-col items-center justify-center min-h-screen">
      <h2 className="text-xl font-semibold mb-4">Login</h2>
      <div className="space-y-2">
        <Input
          placeholder="Username"
          value={credentials.username}
          onChange={(e) => setCredentials({ ...credentials, username: e.target.value })}
        />
        <Input
          type="password"
          placeholder="Password"
          value={credentials.password}
          onChange={(e) => setCredentials({ ...credentials, password: e.target.value })}
        />
        <Button onClick={handleLogin}>Accedi</Button>
        <p className="text-sm text-gray-600">
          Non hai un account? <a href="/register" className="text-blue-500 hover:underline">Registrati</a>
        </p>
      </div>
    </div>
  );
}

export default LoginPage;
