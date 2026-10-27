import { AlertTriangle, Download, Search } from "lucide-react";
import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "../components/ui/table";
import { Tabs, TabsList, TabsTrigger } from "../components/ui/tabs";

function AdminActiveRentalsSection0() {
  const [tab,setTab]=useState("all");
  const [search,setSearch]=useState("");
  return (
    <><div className="flex flex-wrap items-end justify-between gap-4"><div><p className="text-sm font-medium text-primary">Rental operations</p><h1 className="text-3xl font-bold">Active rentals & overdue</h1><p className="text-muted-foreground">126 active contracts · 3 overdue</p></div><Button variant="outline"><Download className="size-4"/>Export</Button></div><div className="flex flex-col gap-3 lg:flex-row"><Tabs value={tab} onValueChange={setTab}><TabsList><TabsTrigger value="all">All active</TabsTrigger><TabsTrigger value="soon">Due soon</TabsTrigger><TabsTrigger value="overdue">Overdue</TabsTrigger></TabsList></Tabs><div className="relative flex-1"><Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"/><Input value={search} onChange={e=>setSearch(e.target.value)} placeholder="Search customer, rental, or plate" className="pl-9"/></div></div></>
  );
}

function AdminActiveRentalsSection1() {
  const navigate=useNavigate();
  const rentals=[{id:"RNT-8817",customer:"Sophia Turner",vehicle:"Toyota Camry · DF-2011",due:"Today 8:00 AM",status:"Overdue",accrued:"$22.14"},{id:"RNT-8821",customer:"Noah Wilson",vehicle:"Ford Escape · DF-1874",due:"Today 9:30 AM",status:"Due soon",accrued:"$0.00"},{id:"RNT-8838",customer:"Mia Adams",vehicle:"Honda Civic · DF-1998",due:"Tomorrow 2:00 PM",status:"Active",accrued:"$0.00"}];
  return (
    <div className="overflow-x-auto"><Table><TableHeader><TableRow><TableHead>Rental</TableHead><TableHead>Customer</TableHead><TableHead>Vehicle</TableHead><TableHead>Due</TableHead><TableHead>Status</TableHead><TableHead>Accrued</TableHead><TableHead/></TableRow></TableHeader><TableBody>{rentals.map(r=><TableRow key={r.id}><TableCell className="font-medium">{r.id}</TableCell><TableCell>{r.customer}</TableCell><TableCell>{r.vehicle}</TableCell><TableCell>{r.due}</TableCell><TableCell><Badge variant={r.status==="Overdue"?"destructive":"secondary"}>{r.status==="Overdue"&&<AlertTriangle className="size-3"/>}{r.status}</Badge></TableCell><TableCell>{r.accrued}</TableCell><TableCell><Button size="sm" variant="outline" onClick={()=>r.status==="Overdue"&&navigate(`/admin/rentals/${r.id}/overdue`)}>Open</Button></TableCell></TableRow>)}</TableBody></Table></div>
  );
}

export default function AdminActiveRentals() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-7xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <AdminActiveRentalsSection0 />
        <AdminActiveRentalsSection1 />
      </div>
    </div>
  );
}
