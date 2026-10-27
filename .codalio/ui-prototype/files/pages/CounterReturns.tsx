import { Search } from "lucide-react";
import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "../components/ui/table";

function CounterReturnsSection0() {
  const [search,setSearch]=useState("");
  const [filter,setFilter]=useState("all");
  return (
    <><div className="flex flex-wrap items-end justify-between gap-4"><div><p className="text-sm font-medium text-primary">Counter</p><h1 className="text-3xl font-bold">Returns queue</h1><p className="text-muted-foreground">Track arrivals, grace periods, and inspections.</p></div><Badge variant="destructive">2 overdue</Badge></div><div className="flex gap-2"><div className="relative flex-1"><Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"/><Input value={search} onChange={(e)=>setSearch(e.target.value)} placeholder="Search customer, rental, or plate" className="pl-9"/></div><Select value={filter} onValueChange={setFilter}><SelectTrigger className="w-40"><SelectValue/></SelectTrigger><SelectContent><SelectItem value="all">All returns</SelectItem><SelectItem value="arrived">Arrived</SelectItem><SelectItem value="overdue">Overdue</SelectItem></SelectContent></Select></div></>
  );
}

function CounterReturnsSection1() {
  const navigate=useNavigate();
  const rows=[{id:"RNT-8821",due:"9:30 AM",customer:"Noah Wilson",vehicle:"Ford Escape · DF-1874",status:"Arrived",balance:"$0.00"},{id:"RNT-8817",due:"8:00 AM",customer:"Sophia Turner",vehicle:"Toyota Camry · DF-2011",status:"Overdue",balance:"$36.00"},{id:"RNT-8830",due:"11:00 AM",customer:"Ethan Clark",vehicle:"Honda Civic · DF-1998",status:"Due soon",balance:"$0.00"}];
  return (
    <div className="overflow-x-auto"><Table><TableHeader><TableRow><TableHead>Due</TableHead><TableHead>Customer</TableHead><TableHead>Vehicle</TableHead><TableHead>Status</TableHead><TableHead>Balance</TableHead><TableHead/></TableRow></TableHeader><TableBody>{rows.map(row=><TableRow key={row.id}><TableCell>{row.due}</TableCell><TableCell><div className="font-medium">{row.customer}</div><div className="text-xs text-muted-foreground">{row.id}</div></TableCell><TableCell>{row.vehicle}</TableCell><TableCell><Badge variant={row.status==="Overdue"?"destructive":"secondary"}>{row.status}</Badge></TableCell><TableCell>{row.balance}</TableCell><TableCell><Button size="sm" onClick={()=>navigate(`/inspections/return/${row.id}`)}>Start inspection</Button></TableCell></TableRow>)}</TableBody></Table></div>
  );
}

export default function CounterReturns() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-7xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <CounterReturnsSection0 />
        <CounterReturnsSection1 />
      </div>
    </div>
  );
}
