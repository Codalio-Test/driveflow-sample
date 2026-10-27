import { ChevronLeft, ChevronRight, Search } from "lucide-react";
import React, { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { api } from "@rhino-dev/rhino-react";
import { apiPath, useOrgSlug } from "@/lib/flow";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../components/ui/select";

function AdminFleetMatrixSection0({ view, setView, search, setSearch, onShift, onToday, rangeLabel }: { view: string; setView: (value: string) => void; search: string; setSearch: (value: string) => void; onShift: (direction: number) => void; onToday: () => void; rangeLabel: string }) {
  return (
    <><div><p className="text-sm font-medium text-primary">Fleet planning</p><h1 className="text-3xl font-bold">Live fleet matrix</h1><p className="text-muted-foreground">Availability and rental schedule · {rangeLabel}</p></div><div className="flex flex-wrap gap-2"><Button variant="outline" size="icon" onClick={() => onShift(-1)}><ChevronLeft className="size-4"/></Button><Button variant="outline" onClick={onToday}>Today</Button><Button variant="outline" size="icon" onClick={() => onShift(1)}><ChevronRight className="size-4"/></Button><Select value={view} onValueChange={setView}><SelectTrigger className="w-32"><SelectValue/></SelectTrigger><SelectContent><SelectItem value="day">Day</SelectItem><SelectItem value="3days">3 Days</SelectItem><SelectItem value="week">Week</SelectItem></SelectContent></Select><div className="relative min-w-56 flex-1"><Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"/><Input placeholder="Search vehicle" className="pl-9" value={search} onChange={(event) => setSearch(event.target.value)}/></div></div></>
  );
}

function AdminFleetMatrixSection1({ days, rows }: { days: string[]; rows: Record<string, any>[] }) {
  return (
    <div className="min-w-[1000px]"><div className="grid grid-cols-[220px_repeat(7,_1fr)] border-b bg-muted/50 text-sm font-medium"><div className="p-3">Vehicle</div>{days.map(d=><div key={d} className="border-l p-3 text-center">{d}</div>)}</div>{rows.map(row=><div key={row.vehicle} className="grid grid-cols-[220px_repeat(7,_1fr)] border-b last:border-0"><div className="p-3"><p className="font-medium">{row.vehicle}</p><p className="text-xs text-muted-foreground">{row.plate}</p></div>{days.map((d,i)=><div key={d} className="min-h-16 border-l p-2">{row.blocks[i]&&<Badge className={row.blocks[i]==="Available"?"bg-emerald-600 text-white":row.blocks[i]==="Service"?"bg-amber-500 text-white":"bg-blue-600 text-white"}>{row.blocks[i]}</Badge>}</div>)}</div>)}</div>
  );
}

export default function AdminFleetMatrix() {
  const orgSlug = useOrgSlug();
  const [view, setView] = useState("week");
  const [offset, setOffset] = useState(0);
  const [search, setSearch] = useState("");
  const span = view === "day" ? 1 : view === "3days" ? 3 : 7;
  const iso = (date: Date) => date.toISOString().slice(0, 10);
  const start = new Date(Date.now() + (offset * span - Math.floor(span / 2)) * 86400000);
  const end = new Date(start.getTime() + (span - 1) * 86400000);
  const from = iso(start);
  const to = iso(end);
  const { data } = useQuery({ queryKey: ["fleetMatrix", from, to], enabled: Boolean(orgSlug), queryFn: async () => (await api.get(apiPath(orgSlug, "/fleet_matrix"), { params: { from, to } })).data });
  const days = (data?.days ?? []).map((day: string) => new Date(`${day}T00:00:00`).toLocaleDateString(undefined, { weekday: "short", day: "numeric" }));
  const rows = (data?.vehicles ?? [])
    .filter((vehicle: Record<string, any>) => !search || `${vehicle.name} ${vehicle.plate}`.toLowerCase().includes(search.toLowerCase()))
    .map((vehicle: Record<string, any>) => ({
      vehicle: vehicle.name,
      plate: vehicle.plate,
      blocks: (data?.days ?? []).map((day: string) => {
        const booked = (vehicle.blocks ?? []).find((block: Record<string, any>) => block.start_day <= day && day <= block.end_day);
        if (booked) return "Rented";
        return vehicle.status === "maintenance" ? "Service" : "Available";
      }),
    }));
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="w-full space-y-6 p-4 md:p-6 min-w-0">
        <AdminFleetMatrixSection0 view={view} setView={setView} search={search} setSearch={setSearch} onShift={(direction) => setOffset((prev) => prev + direction)} onToday={() => setOffset(0)} rangeLabel={`${from} to ${to}`} />
        <AdminFleetMatrixSection1 days={days} rows={rows} />
      </div>
    </div>
  );
}
