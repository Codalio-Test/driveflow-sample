import { Plus, Search } from "lucide-react";
import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useModelIndex } from "@rhino-dev/rhino-react";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Checkbox } from "../components/ui/checkbox";
import { Input } from "../components/ui/input";
import { Progress } from "../components/ui/progress";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "../components/ui/table";

function AdminFleetSection0({ search, setSearch, status, setStatus, total }: { search: string; setSearch: (value: string) => void; status: string; setStatus: (value: string) => void; total: number }) {
  const navigate=useNavigate();
  return (
    <><div className="flex flex-wrap items-end justify-between gap-4"><div><p className="text-sm font-medium text-primary">Administration</p><h1 className="text-3xl font-bold">Fleet inventory</h1><p className="text-muted-foreground">Manage {total} vehicles across every location.</p></div><Button onClick={()=>navigate("/admin/fleet/new")}><Plus className="size-4"/>Add vehicle</Button></div><div className="flex flex-col gap-2 sm:flex-row"><div className="relative flex-1"><Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"/><Input value={search} onChange={e=>setSearch(e.target.value)} placeholder="Search plate, VIN, make, or model" className="pl-9"/></div><Select value={status} onValueChange={setStatus}><SelectTrigger className="sm:w-44"><SelectValue/></SelectTrigger><SelectContent><SelectItem value="all">All statuses</SelectItem><SelectItem value="available">Available</SelectItem><SelectItem value="rented">Rented</SelectItem><SelectItem value="service">In service</SelectItem></SelectContent></Select></div></>
  );
}

function AdminFleetSection1({ vehicles, selected, onToggle, onToggleAll }: { vehicles: Record<string, any>[]; selected: number[]; onToggle: (id: number) => void; onToggleAll: () => void }) {
  const navigate = useNavigate();
  return (
    <div className="overflow-x-auto"><Table><TableHeader><TableRow><TableHead><Checkbox checked={vehicles.length > 0 && selected.length === vehicles.length} onCheckedChange={onToggleAll}/></TableHead><TableHead>Vehicle</TableHead><TableHead>Location</TableHead><TableHead>Status</TableHead><TableHead>Odometer</TableHead><TableHead>Service life</TableHead><TableHead/></TableRow></TableHeader><TableBody>{vehicles.map(v=><TableRow key={v.plate}><TableCell><Checkbox checked={selected.includes(v.id)} onCheckedChange={() => onToggle(v.id)}/></TableCell><TableCell><div className="font-medium">{v.name}</div><div className="text-xs text-muted-foreground">{v.plate}</div></TableCell><TableCell>{v.location}</TableCell><TableCell><Badge variant={v.status==="Maintenance"?"destructive":"secondary"}>{v.status}</Badge></TableCell><TableCell>{v.miles}</TableCell><TableCell className="min-w-36"><Progress value={v.health}/><span className="text-xs text-muted-foreground">{v.health}% to service</span></TableCell><TableCell><Button variant="ghost" size="sm" onClick={() => navigate("/admin/fleet/matrix")}>Open</Button></TableCell></TableRow>)}</TableBody></Table></div>
  );
}

export default function AdminFleet() {
  const [search,setSearch]=useState("");
  const [status,setStatus]=useState("all");
  const [selected,setSelected]=useState<number[]>([]);
  const statusFilter: Record<string, string | undefined> = { all: undefined, available: "available", rented: "rented", service: "maintenance" };
  const { data: response } = useModelIndex("vehicles", { filters: statusFilter[status] ? { status: statusFilter[status] } : undefined, search: search || undefined, includes: ["location", "vehicle_category"], perPage: 50 });
  const vehicles = (response?.data ?? []).map((vehicle: Record<string, any>) => ({ id: vehicle.id, name: vehicle.name ?? [vehicle.year, vehicle.make, vehicle.model].filter(Boolean).join(" "), plate: vehicle.plate ?? vehicle.license_plate, location: vehicle.location ?? "—", status: vehicle.maintenance_active ? "Maintenance" : vehicle.status ?? "—", miles: vehicle.miles ?? `${vehicle.current_odometer ?? 0} mi`, health: vehicle.health ?? 0 }));
  const toggle = (id: number) => setSelected((prev) => (prev.includes(id) ? prev.filter((value) => value !== id) : [...prev, id]));
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-7xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <AdminFleetSection0 search={search} setSearch={setSearch} status={status} setStatus={setStatus} total={vehicles.length} />
        <AdminFleetSection1 vehicles={vehicles} selected={selected} onToggle={toggle} onToggleAll={() => setSelected(selected.length === vehicles.length ? [] : vehicles.map((vehicle: Record<string, any>) => vehicle.id))} />
      </div>
    </div>
  );
}
