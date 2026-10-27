import { Plus, Search } from "lucide-react";
import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useModelIndex } from "@rhino-dev/rhino-react";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Progress } from "../components/ui/progress";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "../components/ui/table";
import { Tabs, TabsList, TabsTrigger } from "../components/ui/tabs";

function AdminMaintenanceSection0({ tab, setTab, search, setSearch }: { tab: string; setTab: (value: string) => void; search: string; setSearch: (value: string) => void }) {
  const navigate=useNavigate();
  return (
    <><div className="flex flex-wrap items-end justify-between gap-4"><div><p className="text-sm font-medium text-primary">Fleet operations</p><h1 className="text-3xl font-bold">Maintenance hub</h1><p className="text-muted-foreground">Service thresholds, alerts, and work orders.</p></div><Button onClick={()=>navigate("/admin/maintenance/new")}><Plus className="size-4"/>New work order</Button></div><div className="flex flex-col gap-3 lg:flex-row"><Tabs value={tab} onValueChange={setTab}><TabsList><TabsTrigger value="due">Due now</TabsTrigger><TabsTrigger value="upcoming">Upcoming</TabsTrigger><TabsTrigger value="orders">Work orders</TabsTrigger><TabsTrigger value="history">History</TabsTrigger></TabsList></Tabs><div className="relative flex-1"><Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"/><Input placeholder="Search vehicle or work order" className="pl-9" value={search} onChange={(event) => setSearch(event.target.value)}/></div></div></>
  );
}

function AdminMaintenanceSection1({ items, onOpen }: { items: Record<string, any>[]; onOpen: () => void }) {
  return (
    <div className="overflow-x-auto"><Table><TableHeader><TableRow><TableHead>Vehicle</TableHead><TableHead>Service</TableHead><TableHead>Threshold</TableHead><TableHead>Priority</TableHead><TableHead>Status</TableHead><TableHead/></TableRow></TableHeader><TableBody>{items.map(item=><TableRow key={item.plate}><TableCell><div className="font-medium">{item.vehicle}</div><div className="text-xs text-muted-foreground">{item.plate}</div></TableCell><TableCell>{item.service}</TableCell><TableCell className="min-w-44"><Progress value={item.progress}/><span className="text-xs text-muted-foreground">{item.detail}</span></TableCell><TableCell><Badge variant={item.priority==="Critical"?"destructive":"secondary"}>{item.priority}</Badge></TableCell><TableCell>{item.status}</TableCell><TableCell><Button size="sm" variant="outline" onClick={onOpen}>Open</Button></TableCell></TableRow>)}</TableBody></Table></div>
  );
}

export default function AdminMaintenance() {
  const navigate = useNavigate();
  const [tab,setTab]=useState("due");
  const [search,setSearch]=useState("");
  const { data: dueVehicles } = useModelIndex("vehicles", { scope: "serviceDue", search: search || undefined, perPage: 50 });
  const { data: allVehicles } = useModelIndex("vehicles", { search: search || undefined, perPage: 50 });
  const { data: logs } = useModelIndex("vehicle_maintenance_logs", { includes: ["vehicle"], search: search || undefined, sort: "-service_date", perPage: 50 });
  const statuses = ["scheduled", "in_progress", "completed"];
  const items = tab === "orders" || tab === "history"
    ? (logs?.data ?? []).filter((log: Record<string, any>) => (tab === "orders" ? statuses.slice(0, 2).includes(String(log.status)) : log.status === "completed")).map((log: Record<string, any>) => ({ vehicle: log.vehicle ?? "Vehicle", plate: log.plate ?? "", service: log.service ?? log.service_type ?? "Service", progress: log.progress ?? 0, detail: log.detail ?? log.notes ?? "", priority: log.priority ?? "Medium", status: log.status_label ?? log.status ?? "" }))
    : (tab === "due" ? (dueVehicles?.data ?? []) : (allVehicles?.data ?? []).filter((vehicle: Record<string, any>) => !vehicle.service_due)).map((vehicle: Record<string, any>) => ({ vehicle: vehicle.name ?? "Vehicle", plate: vehicle.plate ?? "", service: vehicle.service_label ?? "Scheduled service", progress: vehicle.service_progress ?? 0, detail: vehicle.miles_until_service != null ? `${vehicle.miles_until_service} mi remaining` : "Service threshold", priority: (vehicle.service_progress ?? 0) >= 100 ? "Critical" : "High", status: vehicle.maintenance_active ? "In service" : "Unscheduled" }));
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-7xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <AdminMaintenanceSection0 tab={tab} setTab={setTab} search={search} setSearch={setSearch} />
        <AdminMaintenanceSection1 items={items} onOpen={() => navigate("/admin/maintenance/new")} />
      </div>
    </div>
  );
}
