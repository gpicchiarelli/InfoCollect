import { useEffect, useState } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Textarea } from "@/components/ui/textarea";

interface Feed {
  title: string;
  url: string;
}

interface Page {
  id: number;
  content: string;
}

interface Setting {
  key: string;
  value: string;
}

export default function InfoCollectWeb() {
  const [feeds, setFeeds] = useState<Feed[]>([]);
  const [pages, setPages] = useState<Page[]>([]);
  const [settings, setSettings] = useState<Record<string, string>>({});
  const [newFeed, setNewFeed] = useState<Feed>({ title: "", url: "" });
  const [newSetting, setNewSetting] = useState<Setting>({ key: "", value: "" });

  useEffect(() => {
    fetchFeeds();
    fetchPages();
    fetchSettings();
  }, []);

  const fetchFeeds = async () => {
    const res = await fetch("/api/feeds");
    const data: Feed[] = await res.json();
    setFeeds(data);
  };

  const fetchPages = async () => {
    const res = await fetch("/api/pages");
    const data: Page[] = await res.json();
    setPages(data);
  };

  const fetchSettings = async () => {
    const res = await fetch("/api/settings");
    const data: Setting[] = await res.json();
    const settingsObj = Object.fromEntries(data.map(s => [s.key, s.value]));
    setSettings(settingsObj);
  };

  return (
    <div>
      {/* ...existing JSX code... */}
    </div>
  );
}
