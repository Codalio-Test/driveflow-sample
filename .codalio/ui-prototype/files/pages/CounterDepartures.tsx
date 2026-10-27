import { AlertTriangle, ArrowRight, RefreshCw, Search } from "lucide-react";
import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "../components/ui/table";

function CounterDeparturesSection0() {
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("all");
  return (
    <><div className="flex flex-wrap items-end justify-between gap-4"><div><p className="text-sm font-medium text-primary">Counter</p><h1 className="text-3xl font-bold">Departures queue</h1><p className="text-muted-foreground">Today · 8 scheduled handovers</p></div><Badge variant="secondary">3 due in 60 min</Badge></div><div className="flex flex-col gap-2 sm:flex-row"><div className="relative flex-1"><Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"/><Input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Search reservation or customer" className="pl-9"/></div><Select value={status} onValueChange={setStatus}><SelectTrigger className="sm:w-44"><SelectValue/></SelectTrigger><SelectContent><SelectItem value="all">All statuses</SelectItem><SelectItem value="ready">Ready</SelectItem><SelectItem value="blocked">Blocked</SelectItem></SelectContent></Select><Button variant="outline"><RefreshCw className="size-4"/>Refresh</Button></div></>
  );
}

function CounterDeparturesSection1() {
  const navigate = useNavigate();
  const rows = [{ id: "RSV-10428", time: "10:00", customer: "Maya Chen", vehicle: "Toyota RAV4 · DF-2048", gates: "Complete", status: "Ready" }, { id: "RSV-10431", time: "10:30", customer: "Liam Brooks", vehicle: "Unassigned · Compact", gates: "Vehicle needed", status: "Blocked" }, { id: "RSV-10436", time: "11:15", customer: "Ava Martin", vehicle: "Honda CR-V · DF-1922", gates: "Signature needed", status: "Due now" }];
  return (
    <div className="overflow-x-auto"><Table><TableHeader><TableRow><TableHead>Time</TableHead><TableHead>Customer</TableHead><TableHead>Vehicle</TableHead><TableHead>Gates</TableHead><TableHead>Status</TableHead><TableHead/></TableRow></TableHeader><TableBody>{rows.map((row) => <TableRow key={row.id}><TableCell className="font-medium">{row.time}</TableCell><TableCell><div className="font-medium">{row.customer}</div><div className="text-xs text-muted-foreground">{row.id}</div></TableCell><TableCell>{row.vehicle}</TableCell><TableCell><span className={row.gates === "Complete" ? "text-emerald-600" : "flex items-center gap-1 text-amber-600"}>{row.gates !== "Complete" && <AlertTriangle className="size-3"/>}{row.gates}</span></TableCell><TableCell><Badge variant={row.status === "Ready" ? "secondary" : "outline"}>{row.status}</Badge></TableCell><TableCell><Button size="sm" onClick={() => navigate(`/counter/check-out/${row.id}`)}>Start <ArrowRight className="size-4"/></Button></TableCell></TableRow>)}</TableBody></Table></div>
  );
}

export default function CounterDepartures() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-7xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <CounterDeparturesSection0 />
        <CounterDeparturesSection1 />
      </div>
    </div>
  );
}
