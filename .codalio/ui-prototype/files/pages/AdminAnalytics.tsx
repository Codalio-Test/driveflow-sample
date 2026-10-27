import { ArrowUpRight, Download, Search } from "lucide-react";
import React, { useState } from "react";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "../components/ui/table";
import { Tabs, TabsList, TabsTrigger } from "../components/ui/tabs";

function AdminAnalyticsSection0() {
  const [range,setRange]=useState("30");
  return (
    <><div className="flex flex-wrap items-end justify-between gap-4"><div><p className="text-sm font-medium text-primary">Business intelligence</p><h1 className="text-3xl font-bold">Analytics & RevPAC</h1><p className="text-muted-foreground">Fleet performance and financial trends.</p></div><Button variant="outline"><Download className="size-4"/>Export report</Button></div><div className="flex flex-wrap gap-2"><Tabs value={range} onValueChange={setRange}><TabsList><TabsTrigger value="7">7 days</TabsTrigger><TabsTrigger value="30">30 days</TabsTrigger><TabsTrigger value="quarter">Quarter</TabsTrigger><TabsTrigger value="year">Year</TabsTrigger></TabsList></Tabs><Select defaultValue="all"><SelectTrigger className="w-44"><SelectValue/></SelectTrigger><SelectContent><SelectItem value="all">All locations</SelectItem><SelectItem value="downtown">Downtown</SelectItem><SelectItem value="airport">Airport</SelectItem></SelectContent></Select></div></>
  );
}

function AdminAnalyticsSection1() {
  const kpis=[{label:"Utilization",value:"78.4%",change:"4.2%"},{label:"RevPAC",value:"$62.18",change:"6.8%"},{label:"Revenue",value:"$418K",change:"9.1%"},{label:"Damage recovery",value:"$18.6K",change:"2.4%"}];
  const charts=[{title:"Utilization trend",values:[52,64,58,71,68,82,78,88]},{title:"Revenue by class",values:[72,48,86,61,44,68,54,79]}];
  return (
    <><div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">{kpis.map(k=><Card key={k.label}><CardContent className="p-5"><div className="flex justify-between"><span className="text-sm text-muted-foreground">{k.label}</span><Badge variant="secondary"><ArrowUpRight className="size-3"/>{k.change}</Badge></div><p className="mt-3 text-2xl font-bold">{k.value}</p></CardContent></Card>)}</div><div className="grid gap-6 xl:grid-cols-2">{charts.map(chart=><Card key={chart.title}><CardHeader><CardTitle className="text-base">{chart.title}</CardTitle></CardHeader><CardContent><div className="flex h-56 items-end gap-3 rounded-lg bg-muted/30 p-4">{chart.values.map((v,i)=><div key={i} className="flex flex-1 flex-col justify-end"><div className="rounded-t bg-primary/80" style={{height:`${v}%`}}/><span className="mt-2 text-center text-[10px] text-muted-foreground">W{i+1}</span></div>)}</div></CardContent></Card>)}</div></>
  );
}

function AdminAnalyticsSection2() {
  const [search,setSearch]=useState("");
  const transactions=[{id:"pi_3N7…A92",rental:"RNT-8821",type:"Release",amount:"$500.00",status:"Succeeded"},{id:"pi_3N7…B18",rental:"RNT-8817",type:"Capture",amount:"$22.14",status:"Pending"},{id:"pi_3N6…F04",rental:"RNT-8802",type:"Refund",amount:"$145.00",status:"Succeeded"}];
  return (
    <><div className="flex flex-wrap items-center justify-between gap-3 border-b p-4"><div><h2 className="font-semibold">Stripe transaction audit</h2><p className="text-sm text-muted-foreground">Recent holds, captures, refunds, and releases</p></div><div className="relative"><Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"/><Input value={search} onChange={e=>setSearch(e.target.value)} placeholder="Search transaction" className="pl-9"/></div></div><div className="overflow-x-auto"><Table><TableHeader><TableRow><TableHead>Transaction</TableHead><TableHead>Rental</TableHead><TableHead>Type</TableHead><TableHead>Amount</TableHead><TableHead>Status</TableHead><TableHead/></TableRow></TableHeader><TableBody>{transactions.map(t=><TableRow key={t.id}><TableCell className="font-mono text-xs">{t.id}</TableCell><TableCell>{t.rental}</TableCell><TableCell>{t.type}</TableCell><TableCell className="font-medium">{t.amount}</TableCell><TableCell><Badge variant="secondary">{t.status}</Badge></TableCell><TableCell><Button size="sm" variant="ghost">Open</Button></TableCell></TableRow>)}</TableBody></Table></div></>
  );
}

export default function AdminAnalytics() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-7xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <AdminAnalyticsSection0 />
        <AdminAnalyticsSection1 />
        <AdminAnalyticsSection2 />
      </div>
    </div>
  );
}
