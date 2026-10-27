import { ChevronLeft, ChevronRight, Search } from "lucide-react";
import React, { useState } from "react";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../components/ui/select";

function AdminFleetMatrixSection0() {
  const [view,setView]=useState("week");
  return (
    <><div><p className="text-sm font-medium text-primary">Fleet planning</p><h1 className="text-3xl font-bold">Live fleet matrix</h1><p className="text-muted-foreground">Availability and rental schedule · June 14–20</p></div><div className="flex flex-wrap gap-2"><Button variant="outline" size="icon"><ChevronLeft className="size-4"/></Button><Button variant="outline">Today</Button><Button variant="outline" size="icon"><ChevronRight className="size-4"/></Button><Select value={view} onValueChange={setView}><SelectTrigger className="w-32"><SelectValue/></SelectTrigger><SelectContent><SelectItem value="day">Day</SelectItem><SelectItem value="3days">3 Days</SelectItem><SelectItem value="week">Week</SelectItem></SelectContent></Select><div className="relative min-w-56 flex-1"><Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"/><Input placeholder="Search vehicle" className="pl-9"/></div></div></>
  );
}

function AdminFleetMatrixSection1() {
  const days=["Fri 14","Sat 15","Sun 16","Mon 17","Tue 18","Wed 19","Thu 20"];
  const rows=[{vehicle:"Toyota RAV4",plate:"DF-2048",blocks:["Rented","Rented","Rented","Rented","Available","Available","Rented"]},{vehicle:"Ford Escape",plate:"DF-1874",blocks:["Service","Service","Available","Available","Rented","Rented","Rented"]},{vehicle:"Honda Civic",plate:"DF-1998",blocks:["Available","Rented","Rented","Available","Available","Available","Available"]}];
  return (
    <div className="min-w-[1000px]"><div className="grid grid-cols-[220px_repeat(7,_1fr)] border-b bg-muted/50 text-sm font-medium"><div className="p-3">Vehicle</div>{days.map(d=><div key={d} className="border-l p-3 text-center">{d}</div>)}</div>{rows.map(row=><div key={row.vehicle} className="grid grid-cols-[220px_repeat(7,_1fr)] border-b last:border-0"><div className="p-3"><p className="font-medium">{row.vehicle}</p><p className="text-xs text-muted-foreground">{row.plate}</p></div>{days.map((d,i)=><div key={d} className="min-h-16 border-l p-2">{row.blocks[i]&&<Badge className={row.blocks[i]==="Available"?"bg-emerald-600 text-white":row.blocks[i]==="Service"?"bg-amber-500 text-white":"bg-blue-600 text-white"}>{row.blocks[i]}</Badge>}</div>)}</div>)}</div>
  );
}

export default function AdminFleetMatrix() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="w-full space-y-6 p-4 md:p-6 min-w-0">
        <AdminFleetMatrixSection0 />
        <AdminFleetMatrixSection1 />
      </div>
    </div>
  );
}
