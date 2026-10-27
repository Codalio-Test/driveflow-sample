import { ArrowUpRight, Download, Search } from "lucide-react";
import React, { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { api, useModelIndex } from "@rhino-dev/rhino-react";
import { useNavigate } from "react-router-dom";
import { apiPath, downloadFile, money, useOrgSlug } from "@/lib/flow";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "../components/ui/table";
import { Tabs, TabsList, TabsTrigger } from "../components/ui/tabs";

function AdminAnalyticsSection0({ range, setRange, location, setLocation, locations, onExport }: { range: string; setRange: (value: string) => void; location: string; setLocation: (value: string) => void; locations: Record<string, any>[]; onExport: () => void }) {
  return (
    <><div className="flex flex-wrap items-end justify-between gap-4"><div><p className="text-sm font-medium text-primary">Business intelligence</p><h1 className="text-3xl font-bold">Analytics & RevPAC</h1><p className="text-muted-foreground">Fleet performance and financial trends.</p></div><Button variant="outline" onClick={onExport}><Download className="size-4"/>Export report</Button></div><div className="flex flex-wrap gap-2"><Tabs value={range} onValueChange={setRange}><TabsList><TabsTrigger value="7">7 days</TabsTrigger><TabsTrigger value="30">30 days</TabsTrigger><TabsTrigger value="quarter">Quarter</TabsTrigger><TabsTrigger value="year">Year</TabsTrigger></TabsList></Tabs><Select value={location || "all"} onValueChange={(value) => setLocation(value === "all" ? "" : value)}><SelectTrigger className="w-44"><SelectValue/></SelectTrigger><SelectContent><SelectItem value="all">All locations</SelectItem>{(locations ?? []).map((item) => <SelectItem key={item.code ?? item.id} value={item.code ?? String(item.id)}>{item.name}</SelectItem>)}</SelectContent></Select></div></>
  );
}

function AdminAnalyticsSection1({ kpis, charts }: { kpis: Record<string, any>[]; charts: Record<string, any>[] }) {
  return (
    <><div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">{kpis.map(k=><Card key={k.label}><CardContent className="p-5"><div className="flex justify-between"><span className="text-sm text-muted-foreground">{k.label}</span><Badge variant="secondary"><ArrowUpRight className="size-3"/>{k.change}</Badge></div><p className="mt-3 text-2xl font-bold">{k.value}</p></CardContent></Card>)}</div><div className="grid gap-6 xl:grid-cols-2">{charts.map(chart=><Card key={chart.title}><CardHeader><CardTitle className="text-base">{chart.title}</CardTitle></CardHeader><CardContent><div className="flex h-56 items-end gap-3 rounded-lg bg-muted/30 p-4">{chart.values.map((v,i)=><div key={i} className="flex flex-1 flex-col justify-end"><div className="rounded-t bg-primary/80" style={{height:`${v}%`}}/><span className="mt-2 text-center text-[10px] text-muted-foreground">W{i+1}</span></div>)}</div></CardContent></Card>)}</div></>
  );
}

function AdminAnalyticsSection2({ transactions, search, setSearch }: { transactions: Record<string, any>[]; search: string; setSearch: (value: string) => void }) {
  return (
    <><div className="flex flex-wrap items-center justify-between gap-3 border-b p-4"><div><h2 className="font-semibold">Stripe transaction audit</h2><p className="text-sm text-muted-foreground">Recent holds, captures, refunds, and releases</p></div><div className="relative"><Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"/><Input value={search} onChange={e=>setSearch(e.target.value)} placeholder="Search transaction" className="pl-9"/></div></div><div className="overflow-x-auto"><Table><TableHeader><TableRow><TableHead>Transaction</TableHead><TableHead>Rental</TableHead><TableHead>Type</TableHead><TableHead>Amount</TableHead><TableHead>Status</TableHead><TableHead/></TableRow></TableHeader><TableBody>{transactions.map(t=><TableRow key={t.id}><TableCell className="font-mono text-xs">{t.id}</TableCell><TableCell>{t.rental}</TableCell><TableCell>{t.type}</TableCell><TableCell className="font-medium">{t.amount}</TableCell><TableCell><Badge variant="secondary">{t.status}</Badge></TableCell><TableCell><Button size="sm" variant="ghost" onClick={() => t.rentalId && navigate(`/admin/rentals/${t.rentalId}/overdue`)}>Open</Button></TableCell></TableRow>)}</TableBody></Table></div></>
  );
}

export default function AdminAnalytics() {
  const navigate = useNavigate();
  const orgSlug = useOrgSlug();
  const [range, setRange] = useState("30");
  const [location, setLocation] = useState("");
  const [search, setSearch] = useState("");
  const { data: locations } = useModelIndex("locations", { perPage: 50 });
  const analytics = useQuery({ queryKey: ["analytics", range, location], enabled: Boolean(orgSlug), queryFn: async () => (await api.get(apiPath(orgSlug, "/analytics"), { params: { range, location: location || undefined } })).data });
  const { data: payments } = useModelIndex("payments", { search: search || undefined, sort: "-processed_at", perPage: 25 });
  const transactions = (payments?.data ?? []).map((payment: Record<string, any>) => ({ id: payment.reference ?? `pi_${payment.id}`, rentalId: payment.rental_id, rental: payment.rental, type: payment.type ?? payment.transaction_type, amount: money(payment.amount), status: payment.status }));
  // Charts arrive as labelled series over very different magnitudes; the
  // prototype draws percentage-height bars, so each series is normalised.
  const charts = (analytics.data?.charts ?? []).map((chart: Record<string, any>) => {
    const values = (chart.values ?? []).map((point: any) => Number(point?.value ?? point ?? 0));
    const peak = Math.max(...values, 1);
    return { title: chart.title, values: values.map((value: number) => Math.round((value / peak) * 100)) };
  });
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-7xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <AdminAnalyticsSection0 range={range} setRange={setRange} location={location} setLocation={setLocation} locations={locations?.data ?? []} onExport={() => downloadFile(`${apiPath(orgSlug, "/analytics/export")}.csv?range=${range}${location ? `&location=${location}` : ""}`, "driveflow-analytics.csv")} />
        <AdminAnalyticsSection1 kpis={analytics.data?.kpis ?? []} charts={charts} />
        <AdminAnalyticsSection2 transactions={transactions} search={search} setSearch={setSearch} />
      </div>
    </div>
  );
}
