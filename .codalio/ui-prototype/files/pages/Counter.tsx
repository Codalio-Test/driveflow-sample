import { AlertTriangle } from "lucide-react";
import React from "react";
import { useNavigate } from "react-router-dom";
import { Alert, AlertDescription, AlertTitle } from "../components/ui/alert";
import { Button } from "../components/ui/button";
import { Card, CardContent } from "../components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "../components/ui/table";

function CounterSection0() {
  const items = [{ label: "Pending departures", value: 8 }, { label: "Arrived returns", value: 3 }, { label: "Overdue", value: 2 }, { label: "Ready vehicles", value: 14 }];
  return (
    <section className="mx-auto max-w-7xl"><h1 className="mb-6 text-3xl font-bold">Counter Operations</h1><div className="grid gap-4 md:grid-cols-4">{items.map((x) => <Card key={x.label}><CardContent className="p-5"><p className="text-sm text-muted-foreground">{x.label}</p><p className="mt-2 text-3xl font-bold">{x.value}</p></CardContent></Card>)}</div></section>
  );
}

function CounterSection1() {
  const navigate = useNavigate();
  const rows = [{ id: "DF-82941", time: "09:00", name: "Alex Morgan", car: "Comfort Sedan" }, { id: "DF-83002", time: "09:15", name: "Priya Shah", car: "Adventure SUV" }];
  return (
    <section className="mx-auto max-w-7xl overflow-hidden rounded-lg border"><Table><TableHeader><TableRow><TableHead>Time</TableHead><TableHead>Customer</TableHead><TableHead>Vehicle</TableHead><TableHead className="text-right">Action</TableHead></TableRow></TableHeader><TableBody>{rows.map((r) => <TableRow key={r.id}><TableCell>{r.time}</TableCell><TableCell>{r.name}</TableCell><TableCell>{r.car}</TableCell><TableCell className="text-right"><Button size="sm" onClick={() => navigate(`/counter/check-out/${r.id}`)}>Start handover</Button></TableCell></TableRow>)}</TableBody></Table></section>
  );
}

function CounterSection2() {
  return (
    <section className="mx-auto max-w-7xl space-y-3"><Alert><AlertTriangle className="size-4" /><AlertTitle>2 items need attention</AlertTitle><AlertDescription>One failed pre-authorization and one overdue return require action.</AlertDescription></Alert></section>
  );
}

export default function Counter() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="w-full min-w-0">
        <CounterSection0 />
        <CounterSection1 />
        <CounterSection2 />
      </div>
    </div>
  );
}
