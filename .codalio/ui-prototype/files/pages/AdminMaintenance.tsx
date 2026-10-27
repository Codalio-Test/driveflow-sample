import { Plus, Search } from "lucide-react";
import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Progress } from "../components/ui/progress";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "../components/ui/table";
import { Tabs, TabsList, TabsTrigger } from "../components/ui/tabs";

function AdminMaintenanceSection0() {
  const navigate=useNavigate();
  const [tab,setTab]=useState("due");
  return (
    <><div className="flex flex-wrap items-end justify-between gap-4"><div><p className="text-sm font-medium text-primary">Fleet operations</p><h1 className="text-3xl font-bold">Maintenance hub</h1><p className="text-muted-foreground">Service thresholds, alerts, and work orders.</p></div><Button onClick={()=>navigate("/admin/maintenance/new")}><Plus className="size-4"/>New work order</Button></div><div className="flex flex-col gap-3 lg:flex-row"><Tabs value={tab} onValueChange={setTab}><TabsList><TabsTrigger value="due">Due now</TabsTrigger><TabsTrigger value="upcoming">Upcoming</TabsTrigger><TabsTrigger value="orders">Work orders</TabsTrigger><TabsTrigger value="history">History</TabsTrigger></TabsList></Tabs><div className="relative flex-1"><Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"/><Input placeholder="Search vehicle or work order" className="pl-9"/></div></div></>
  );
}

function AdminMaintenanceSection1() {
  const items=[{vehicle:"2023 Ford Escape",plate:"DF-1874",service:"Oil & filter",progress:100,detail:"620 mi overdue",priority:"Critical",status:"In service"},{vehicle:"2024 Toyota RAV4",plate:"DF-2048",service:"Tire rotation",progress:88,detail:"540 mi remaining",priority:"High",status:"Unscheduled"},{vehicle:"2024 Honda Civic",plate:"DF-1998",service:"Annual inspection",progress:76,detail:"12 days remaining",priority:"Medium",status:"Scheduled"}];
  return (
    <div className="overflow-x-auto"><Table><TableHeader><TableRow><TableHead>Vehicle</TableHead><TableHead>Service</TableHead><TableHead>Threshold</TableHead><TableHead>Priority</TableHead><TableHead>Status</TableHead><TableHead/></TableRow></TableHeader><TableBody>{items.map(item=><TableRow key={item.plate}><TableCell><div className="font-medium">{item.vehicle}</div><div className="text-xs text-muted-foreground">{item.plate}</div></TableCell><TableCell>{item.service}</TableCell><TableCell className="min-w-44"><Progress value={item.progress}/><span className="text-xs text-muted-foreground">{item.detail}</span></TableCell><TableCell><Badge variant={item.priority==="Critical"?"destructive":"secondary"}>{item.priority}</Badge></TableCell><TableCell>{item.status}</TableCell><TableCell><Button size="sm" variant="outline">Open</Button></TableCell></TableRow>)}</TableBody></Table></div>
  );
}

export default function AdminMaintenance() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-7xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <AdminMaintenanceSection0 />
        <AdminMaintenanceSection1 />
      </div>
    </div>
  );
}
