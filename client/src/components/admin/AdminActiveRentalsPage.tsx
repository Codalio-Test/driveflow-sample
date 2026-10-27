import { AlertTriangle, Download, Search } from "lucide-react";
import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useModelIndex } from "@rhino-dev/rhino-react";
import { apiPath, downloadFile, useOrgSlug } from "@/lib/flow";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "../components/ui/table";
import { Tabs, TabsList, TabsTrigger } from "../components/ui/tabs";

function AdminActiveRentalsSection0({ tab, setTab, search, setSearch, active, overdue, onExport }: { tab: string; setTab: (value: string) => void; search: string; setSearch: (value: string) => void; active: number; overdue: number; onExport: () => void }) {
  return (
    <><div className="flex flex-wrap items-end justify-between gap-4"><div><p className="text-sm font-medium text-primary">Rental operations</p><h1 className="text-3xl font-bold">Active rentals & overdue</h1><p className="text-muted-foreground">{active} active contracts · {overdue} overdue</p></div><Button variant="outline" onClick={onExport}><Download className="size-4"/>Export</Button></div><div className="flex flex-col gap-3 lg:flex-row"><Tabs value={tab} onValueChange={setTab}><TabsList><TabsTrigger value="all">All active</TabsTrigger><TabsTrigger value="soon">Due soon</TabsTrigger><TabsTrigger value="overdue">Overdue</TabsTrigger></TabsList></Tabs><div className="relative flex-1"><Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"/><Input value={search} onChange={e=>setSearch(e.target.value)} placeholder="Search customer, rental, or plate" className="pl-9"/></div></div></>
  );
}

function AdminActiveRentalsSection1({ rows }: { rows: Record<string, any>[] }) {
  const navigate=useNavigate();
  return (
    <div className="overflow-x-auto"><Table><TableHeader><TableRow><TableHead>Rental</TableHead><TableHead>Customer</TableHead><TableHead>Vehicle</TableHead><TableHead>Due</TableHead><TableHead>Status</TableHead><TableHead>Accrued</TableHead><TableHead/></TableRow></TableHeader><TableBody>{rentals.map(r=><TableRow key={r.id}><TableCell className="font-medium">{r.id}</TableCell><TableCell>{r.customer}</TableCell><TableCell>{r.vehicle}</TableCell><TableCell>{r.due}</TableCell><TableCell><Badge variant={r.status==="Overdue"?"destructive":"secondary"}>{r.status==="Overdue"&&<AlertTriangle className="size-3"/>}{r.status}</Badge></TableCell><TableCell>{r.accrued}</TableCell><TableCell><Button size="sm" variant="outline" onClick={()=>r.status==="Overdue"&&navigate(`/admin/rentals/${r.rawId}/overdue`)}>Open</Button></TableCell></TableRow>)}</TableBody></Table></div>
  );
}

export default function AdminActiveRentals() {
  const orgSlug = useOrgSlug();
  const [tab,setTab]=useState("all");
  const [search,setSearch]=useState("");
  const statusFilter: Record<string, string | undefined> = { all: "active,overdue,confirmed", soon: "active", overdue: "overdue" };
  const { data: response } = useModelIndex("rentals", { filters: { status: statusFilter[tab] }, search: search || undefined, includes: ["customer_profile", "vehicle"], sort: "scheduled_return_datetime", perPage: 50 });
  const rentals = response?.data ?? [];
  const rows = rentals.map((rental: Record<string, any>) => ({ id: rental.reference ?? rental.reservation_number ?? `R-${rental.id}`, rawId: rental.id, customer: rental.customer ?? "Customer", vehicle: rental.vehicle ?? rental.category ?? "Vehicle", due: rental.due ?? "—", status: rental.overdue ? "Overdue" : rental.status === "active" ? "Active" : "Due soon", accrued: rental.accrued ?? "$0.00" }));
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-7xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <AdminActiveRentalsSection0 tab={tab} setTab={setTab} search={search} setSearch={setSearch} active={rentals.length} overdue={rentals.filter((rental: Record<string, any>) => rental.overdue).length} onExport={() => downloadFile(`${apiPath(orgSlug, "/rentals/export")}.csv`, "driveflow-rentals.csv")} />
        <AdminActiveRentalsSection1 rows={rows} />
      </div>
    </div>
  );
}
