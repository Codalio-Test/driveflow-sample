import { ArrowUpRight, CarFront, CircleDollarSign, Clock3, Gauge } from "lucide-react";
import React from "react";
import { useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { api, useModelIndex } from "@rhino-dev/rhino-react";
import { apiPath, useOrgSlug } from "@/lib/flow";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Card, CardContent } from "../components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "../components/ui/table";

function AdminSection0({ analytics }: { analytics: Record<string, any> | null }) {
  const icons=[Gauge,CircleDollarSign,CarFront,Clock3];
  const kpis=(analytics?.kpis ?? []).concat([{label:"Overdue balance",value:(analytics?.deposits?.uncollected_claims ?? 0).toLocaleString(undefined,{style:"currency",currency:"USD"}),change:`${analytics?.maintenance?.work_orders ?? 0} orders`}]).slice(0,4).map((kpi: Record<string, any>, index: number) => ({ ...kpi, icon: icons[index % icons.length] }));
  return (
    <><div><p className="text-sm font-medium text-primary">Operations control center</p><h1 className="text-3xl font-bold">Admin portal</h1><p className="text-muted-foreground">Live fleet, rental, and revenue health.</p></div><div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">{kpis.map(item=><Card key={item.label}><CardContent className="p-5"><div className="flex items-start justify-between"><item.icon className="size-5 text-primary"/><Badge variant="secondary"><ArrowUpRight className="size-3"/>{item.change}</Badge></div><p className="mt-4 text-2xl font-bold">{item.value}</p><p className="text-sm text-muted-foreground">{item.label}</p></CardContent></Card>)}</div></>
  );
}

function AdminSection1({ alerts }: { alerts: Record<string, any>[] }) {
  const navigate=useNavigate();
  return (
    <><div className="flex items-center justify-between border-b p-5"><div><h2 className="font-semibold">Operational alerts</h2><p className="text-sm text-muted-foreground">Items requiring attention today</p></div><Badge variant="destructive">{alerts.length} open</Badge></div><div className="overflow-x-auto"><Table><TableHeader><TableRow><TableHead>Type</TableHead><TableHead>Subject</TableHead><TableHead>Age</TableHead><TableHead>Priority</TableHead><TableHead/></TableRow></TableHeader><TableBody>{alerts.map(a=><TableRow key={a.subject}><TableCell>{a.type}</TableCell><TableCell className="font-medium">{a.subject}</TableCell><TableCell>{a.age}</TableCell><TableCell><Badge variant={a.priority==="Critical"?"destructive":"secondary"}>{a.priority}</Badge></TableCell><TableCell><Button size="sm" variant="outline" onClick={()=>navigate(a.route)}>Open</Button></TableCell></TableRow>)}</TableBody></Table></div></>
  );
}

export default function Admin() {
  const orgSlug = useOrgSlug();
  const analytics = useQuery({ queryKey: ["analytics", "30"], enabled: Boolean(orgSlug), queryFn: async () => (await api.get(apiPath(orgSlug, "/analytics"), { params: { range: 30 } })).data });
  const { data: overdue } = useModelIndex("rentals", { filters: { status: "overdue" }, perPage: 10 });
  const { data: serviceDue } = useModelIndex("vehicles", { scope: "serviceDue", perPage: 10 });
  const alerts = [
    ...(overdue?.data ?? []).map((rental: Record<string, any>) => ({ type: "Overdue return", subject: `${rental.reference ?? rental.reservation_number} · ${rental.customer ?? "Customer"}`, age: rental.overdue_duration ?? "—", priority: "Critical", route: `/admin/rentals/${rental.id}/overdue` })),
    ...(serviceDue?.data ?? []).map((vehicle: Record<string, any>) => ({ type: "Maintenance due", subject: `${vehicle.plate} · ${vehicle.name}`, age: "Today", priority: "High", route: "/admin/maintenance" })),
  ];
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-7xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <AdminSection0 analytics={analytics.data ?? null} />
        <AdminSection1 alerts={alerts} />
      </div>
    </div>
  );
}
