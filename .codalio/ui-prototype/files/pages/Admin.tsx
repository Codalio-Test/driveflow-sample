import { ArrowUpRight, CarFront, CircleDollarSign, Clock3, Gauge } from "lucide-react";
import React from "react";
import { useNavigate } from "react-router-dom";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Card, CardContent } from "../components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "../components/ui/table";

function AdminSection0() {
  const kpis=[{label:"Fleet utilization",value:"78.4%",change:"4.2%",icon:Gauge},{label:"RevPAC",value:"$62.18",change:"6.8%",icon:CircleDollarSign},{label:"Active rentals",value:"126",change:"12",icon:CarFront},{label:"Overdue balance",value:"$2,840",change:"3 cases",icon:Clock3}];
  return (
    <><div><p className="text-sm font-medium text-primary">Operations control center</p><h1 className="text-3xl font-bold">Admin portal</h1><p className="text-muted-foreground">Live fleet, rental, and revenue health.</p></div><div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">{kpis.map(item=><Card key={item.label}><CardContent className="p-5"><div className="flex items-start justify-between"><item.icon className="size-5 text-primary"/><Badge variant="secondary"><ArrowUpRight className="size-3"/>{item.change}</Badge></div><p className="mt-4 text-2xl font-bold">{item.value}</p><p className="text-sm text-muted-foreground">{item.label}</p></CardContent></Card>)}</div></>
  );
}

function AdminSection1() {
  const navigate=useNavigate();
  const alerts=[{type:"Overdue return",subject:"RNT-8817 · Sophia Turner",age:"2h 14m",priority:"Critical",route:"/admin/rentals/RNT-8817/overdue"},{type:"Maintenance due",subject:"DF-1874 · Ford Escape",age:"Today",priority:"High",route:"/admin/maintenance"},{type:"Failed hold",subject:"RSV-10431 · Liam Brooks",age:"18m",priority:"High",route:"/counter/departures"}];
  return (
    <><div className="flex items-center justify-between border-b p-5"><div><h2 className="font-semibold">Operational alerts</h2><p className="text-sm text-muted-foreground">Items requiring attention today</p></div><Badge variant="destructive">7 open</Badge></div><div className="overflow-x-auto"><Table><TableHeader><TableRow><TableHead>Type</TableHead><TableHead>Subject</TableHead><TableHead>Age</TableHead><TableHead>Priority</TableHead><TableHead/></TableRow></TableHeader><TableBody>{alerts.map(a=><TableRow key={a.subject}><TableCell>{a.type}</TableCell><TableCell className="font-medium">{a.subject}</TableCell><TableCell>{a.age}</TableCell><TableCell><Badge variant={a.priority==="Critical"?"destructive":"secondary"}>{a.priority}</Badge></TableCell><TableCell><Button size="sm" variant="outline" onClick={()=>navigate(a.route)}>Open</Button></TableCell></TableRow>)}</TableBody></Table></div></>
  );
}

export default function Admin() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-7xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <AdminSection0 />
        <AdminSection1 />
      </div>
    </div>
  );
}
