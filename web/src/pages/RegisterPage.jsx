import { useState } from "react";
import { Input, Button } from "../components/ui";

function RegisterPage() {
  const [formData, setFormData] = useState({ username: "", password: "", confirmPassword: "" });

  const handleRegister = async () => {
    if (formData.password !== formData.confirmPassword) {
      alert("Le password non corrispondono.");
      return;
    }
    const res = await fetch("/api/register", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: formData.username, password: formData.password }),
    });
    if (res.ok) {
      alert("Registrazione completata con successo!");
      window.location.href = "/login";
    } else {
      alert("Errore durante la registrazione.");
    }
  };

  return (
    <div className="flex flex-col items-center justify-center min-h-screen">
      <h2 className="text-xl font-semibold mb-4">Registrazione</h2>
      <div className="space-y-2">
        <Input
          placeholder="Username"
          value={formData.username}
          onChange={(e) => setFormData({ ...formData, username: e.target.value })}
        />
        <Input
          type="password"
          placeholder="Password"
          value={formData.password}
          onChange={(e) => setFormData({ ...formData, password: e.target.value })}
        />
        <Input
          type="password"
          placeholder="Conferma Password"
          value={formData.confirmPassword}
          onChange={(e) => setFormData({ ...formData, confirmPassword: e.target.value })}
        />
        <Button onClick={handleRegister}>Registrati</Button>
      </div>
    </div>
  );
}

export default RegisterPage;
