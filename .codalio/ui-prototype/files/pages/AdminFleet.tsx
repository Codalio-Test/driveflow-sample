import { Plus, Search } from "lucide-react";
import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Checkbox } from "../components/ui/checkbox";
import { Input } from "../components/ui/input";
import { Progress } from "../components/ui/progress";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "../components/ui/table";

function AdminFleetSection0() {
  const navigate=useNavigate();
  const [search,setSearch]=useState("");
  const [status,setStatus]=useState("all");
  return (
    <><div className="flex flex-wrap items-end justify-between gap-4"><div><p className="text-sm font-medium text-primary">Administration</p><h1 className="text-3xl font-bold">Fleet inventory</h1><p className="text-muted-foreground">Manage 248 vehicles across 4 locations.</p></div><Button onClick={()=>navigate("/admin/fleet/new")}><Plus className="size-4"/>Add vehicle</Button></div><div className="flex flex-col gap-2 sm:flex-row"><div className="relative flex-1"><Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"/><Input value={search} onChange={e=>setSearch(e.target.value)} placeholder="Search plate, VIN, make, or model" className="pl-9"/></div><Select value={status} onValueChange={setStatus}><SelectTrigger className="sm:w-44"><SelectValue/></SelectTrigger><SelectContent><SelectItem value="all">All statuses</SelectItem><SelectItem value="available">Available</SelectItem><SelectItem value="rented">Rented</SelectItem><SelectItem value="service">In service</SelectItem></SelectContent></Select></div></>
  );
}

function AdminFleetSection1() {
  const vehicles=[{name:"2024 Toyota RAV4",plate:"DF-2048",location:"Downtown",status:"Rented",miles:"28,442 mi",health:72},{name:"2023 Ford Escape",plate:"DF-1874",location:"Airport",status:"Maintenance",miles:"42,120 mi",health:96},{name:"2024 Honda Civic",plate:"DF-1998",location:"Downtown",status:"Available",miles:"18,904 mi",health:44}];
  return (
    <div className="overflow-x-auto"><Table><TableHeader><TableRow><TableHead><Checkbox/></TableHead><TableHead>Vehicle</TableHead><TableHead>Location</TableHead><TableHead>Status</TableHead><TableHead>Odometer</TableHead><TableHead>Service life</TableHead><TableHead/></TableRow></TableHeader><TableBody>{vehicles.map(v=><TableRow key={v.plate}><TableCell><Checkbox/></TableCell><TableCell><div className="font-medium">{v.name}</div><div className="text-xs text-muted-foreground">{v.plate}</div></TableCell><TableCell>{v.location}</TableCell><TableCell><Badge variant={v.status==="Maintenance"?"destructive":"secondary"}>{v.status}</Badge></TableCell><TableCell>{v.miles}</TableCell><TableCell className="min-w-36"><Progress value={v.health}/><span className="text-xs text-muted-foreground">{v.health}% to service</span></TableCell><TableCell><Button variant="ghost" size="sm">Open</Button></TableCell></TableRow>)}</TableBody></Table></div>
  );
}

export default function AdminFleet() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-7xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <AdminFleetSection0 />
        <AdminFleetSection1 />
      </div>
    </div>
  );
}
