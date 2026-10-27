import { ReceiptText, Search, SlidersHorizontal } from "lucide-react";
import React, { useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { useModelIndex } from "@rhino-dev/rhino-react";
import { Alert, AlertDescription, AlertTitle } from "../components/ui/alert";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../components/ui/select";

function VehiclesSection0({ query, setQuery, category, setCategory }: { query: string; setQuery: (value: string) => void; category: string; setCategory: (value: string) => void }) {
  return (
    <section className="mx-auto grid max-w-7xl gap-3 lg:grid-cols-4"><div className="relative lg:col-span-2"><Search className="absolute left-3 top-3 size-4 text-muted-foreground" /><Input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Airport or city" className="pl-9" /></div><Select value={category} onValueChange={setCategory}><SelectTrigger><SelectValue /></SelectTrigger><SelectContent><SelectItem value="all">All classes</SelectItem><SelectItem value="suv">SUV</SelectItem><SelectItem value="compact">Compact</SelectItem></SelectContent></Select><Button variant="outline" onClick={() => { setQuery(""); setCategory("all"); }}><SlidersHorizontal className="mr-2 size-4" />Clear filters</Button></section>
  );
}

function VehiclesSection1({ results, isLoading, isError }: { results: Record<string, any>[]; isLoading: boolean; isError: boolean }) {
  const navigate = useNavigate();
  const images = ["/images/ui-prototype/584b964a859f.jpg", "/images/ui-prototype/1ad0d1427c56.jpg", "/images/ui-prototype/5190050.jpg", "/images/ui-prototype/790722.jpg", "/images/ui-prototype/1400243.jpg", "/images/ui-prototype/8891625.jpg"];
  return (
    <section className="mx-auto max-w-7xl">
      {isLoading && <p className="text-sm text-muted-foreground">Loading available classes…</p>}
      {isError && <p className="text-sm text-destructive">The fleet catalog could not be loaded. Try again shortly.</p>}
      {!isLoading && !isError && results.length === 0 && <p className="text-sm text-muted-foreground">No vehicle classes match that search.</p>}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {results.map((item, index) => (
          <Card key={item.id} onClick={() => navigate("/booking", { state: { vehicle_category_id: item.id, name: item.name } })} className="cursor-pointer overflow-hidden transition-shadow hover:shadow-md">
            <img src={item.image ?? images[index % images.length]} alt={item.name} className="aspect-video w-full object-cover" />
            <CardHeader><div className="flex items-start justify-between gap-2"><CardTitle className="text-lg">{item.name}</CardTitle><Badge variant="secondary">{item.available_vehicle_count ?? (item.vehicles ?? []).length} available</Badge></div></CardHeader>
            <CardContent className="space-y-2">
              <p className="font-bold">${Number(item.rate ?? item.base_daily_rate ?? 0).toFixed(2)}/day</p>
              <p className="text-sm text-muted-foreground">{item.passenger_capacity} seats • {item.baggage_capacity} bags • {item.transmission}</p>
            </CardContent>
          </Card>
        ))}
      </div>
    </section>
  );
}

function VehiclesSection2() {
  return (
    <section className="mx-auto max-w-7xl"><Alert><ReceiptText className="size-4" /><AlertTitle>Nothing hidden at checkout</AlertTitle><AlertDescription>Taxes, protection, add-ons, and deposit hold are shown before checkout.</AlertDescription></Alert></section>
  );
}

export default function Vehicles() {
  const { state } = useLocation();
  const [query, setQuery] = useState(state?.location ?? "");
  const [category, setCategory] = useState("all");
  const search = [query, category === "all" ? "" : category].filter(Boolean).join(" ") || undefined;
  const { data: response, isLoading, isError } = useModelIndex("vehicle_categories", { search, includes: ["vehicles"], perPage: 24 });
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="w-full min-w-0">
        <VehiclesSection0 query={query} setQuery={setQuery} category={category} setCategory={setCategory} />
        <VehiclesSection1 results={response?.data ?? []} isLoading={isLoading} isError={isError} />
        <VehiclesSection2 />
      </div>
    </div>
  );
}
