import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useModelIndex } from "@rhino-dev/rhino-react";
import { apiPath, downloadFile, useOrgSlug } from "@/lib/flow";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Card, CardContent } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Tabs, TabsList, TabsTrigger } from "../components/ui/tabs";

function AccountBookingsSection0({ tab, setTab, search, setSearch }: { tab: string; setTab: (value: string) => void; search: string; setSearch: (value: string) => void }) {
  return (
    <section className="mx-auto max-w-5xl"><h1 className="text-3xl font-bold">My Bookings</h1><div className="mt-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between"><Tabs value={tab} onValueChange={setTab}><TabsList>{["Upcoming", "Active", "Completed", "Cancelled"].map((item) => <TabsTrigger key={item} value={item}>{item}</TabsTrigger>)}</TabsList></Tabs><Input className="sm:w-64" placeholder="Search bookings" value={search} onChange={(event) => setSearch(event.target.value)} /></div></section>
  );
}

function AccountBookingsSection1({ bookings, isLoading }: { bookings: Record<string, any>[]; isLoading: boolean }) {
  const navigate = useNavigate();
  const orgSlug = useOrgSlug();
  return (
    <section className="mx-auto max-w-5xl space-y-4">{bookings.map((item) => <Card key={item.id}><CardContent className="flex flex-col justify-between gap-4 p-5 sm:flex-row sm:items-center"><div><div className="flex items-center gap-2"><p className="font-semibold">{item.vehicle}</p><Badge variant="secondary">{item.status}</Badge></div><p className="mt-1 text-sm text-muted-foreground">{item.dates} • {item.id}</p></div><div className="flex gap-2"><Button variant="outline" onClick={() => downloadFile(apiPath(orgSlug, `/rentals/${item.rawId}/receipt`), `driveflow-receipt-${item.rawId}.pdf`)}>Receipt</Button><Button onClick={() => navigate("/booking/confirmation", { state: { rentalId: item.rawId } })}>Manage</Button></div></CardContent></Card>)}{!isLoading && bookings.length === 0 && <p className="text-sm text-muted-foreground">No bookings in this view yet.</p>}</section>
  );
}

export default function AccountBookings() {
  const [tab, setTab] = useState("Upcoming");
  const [search, setSearch] = useState("");
  const statusByTab: Record<string, string | undefined> = { Upcoming: "reserved,confirmed", Active: "active", Completed: "completed", Cancelled: "cancelled" };
  const { data: response, isLoading } = useModelIndex("rentals", { filters: statusByTab[tab] ? { status: statusByTab[tab] } : undefined, search: search || undefined, perPage: 25 });
  const bookings = (response?.data ?? []).map((rental: Record<string, any>) => ({ id: rental.reference ?? rental.reservation_number ?? `R-${rental.id}`, rawId: rental.id, vehicle: rental.category ?? rental.vehicle ?? "Vehicle", dates: rental.dates ?? "", status: rental.status ?? "" }));
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="w-full min-w-0">
        <AccountBookingsSection0 tab={tab} setTab={setTab} search={search} setSearch={setSearch} />
        <AccountBookingsSection1 bookings={bookings} isLoading={isLoading} />
      </div>
    </div>
  );
}
