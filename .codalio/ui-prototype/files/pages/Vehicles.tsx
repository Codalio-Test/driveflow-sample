import { ReceiptText, Search, SlidersHorizontal } from "lucide-react";
import React, { useState } from "react";
import { Alert, AlertDescription, AlertTitle } from "../components/ui/alert";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../components/ui/select";

function VehiclesSection0() {
  const [query, setQuery] = useState("");
  const [category, setCategory] = useState("all");
  return (
    <section className="mx-auto grid max-w-7xl gap-3 lg:grid-cols-4"><div className="relative lg:col-span-2"><Search className="absolute left-3 top-3 size-4 text-muted-foreground" /><Input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Airport or city" className="pl-9" /></div><Select value={category} onValueChange={setCategory}><SelectTrigger><SelectValue /></SelectTrigger><SelectContent><SelectItem value="all">All classes</SelectItem><SelectItem value="suv">SUV</SelectItem><SelectItem value="compact">Compact</SelectItem></SelectContent></Select><Button variant="outline" onClick={() => { setQuery(""); setCategory("all"); }}><SlidersHorizontal className="mr-2 size-4" />Clear filters</Button></section>
  );
}

function VehiclesSection2() {
  return (
    <section className="mx-auto max-w-7xl"><Alert><ReceiptText className="size-4" /><AlertTitle>Nothing hidden at checkout</AlertTitle><AlertDescription>Taxes, protection, add-ons, and deposit hold are shown before checkout.</AlertDescription></Alert></section>
  );
}

export default function Vehicles() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="w-full min-w-0">
        <VehiclesSection0 />
        <VehiclesSection2 />
      </div>
    </div>
  );
}
