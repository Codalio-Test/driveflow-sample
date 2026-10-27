import { useState } from "react";
import { Search, CarFront, User, FileText } from "lucide-react";
import { Button } from "./ui/button";
import { Card } from "./ui/card";
import { Input } from "./ui/input";

export default function GlobalOperationsSearch({ onSelect }: { onSelect?: (value: string) => void }) {
  const [query, setQuery] = useState("");
  const allResults = [{ label: "RSV-10428 · Maya Chen", type: "Reservation" }, { label: "DF-2048 · Toyota RAV4", type: "Vehicle" }, { label: "Jordan Ellis", type: "Customer" }];
  const results = allResults.filter((item) => item.label.toLowerCase().includes(query.toLowerCase()));
  return (
    <div className="relative w-full max-w-xl"><div className="relative"><Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" /><Input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search reservation, customer, plate…" className="pl-9" /></div>{query && <Card className="absolute inset-x-0 top-12 z-50 p-2 shadow-md">{results.map((result) => <Button key={result.label} variant="ghost" className="w-full justify-start gap-3" onClick={() => { onSelect?.(result.label); setQuery(""); }}>{result.type === "Vehicle" ? <CarFront className="size-4" /> : result.type === "Customer" ? <User className="size-4" /> : <FileText className="size-4" />}<span>{result.label}</span><span className="ml-auto text-xs text-muted-foreground">{result.type}</span></Button>)}</Card>}</div>
  );
}

export { GlobalOperationsSearch };
