import React, { useState } from "react";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Card, CardContent } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Tabs, TabsList, TabsTrigger } from "../components/ui/tabs";

function AccountBookingsSection0() {
  const [tab, setTab] = useState("Upcoming");
  return (
    <section className="mx-auto max-w-5xl"><h1 className="text-3xl font-bold">My Bookings</h1><div className="mt-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between"><Tabs value={tab} onValueChange={setTab}><TabsList>{["Upcoming", "Active", "Completed", "Cancelled"].map((item) => <TabsTrigger key={item} value={item}>{item}</TabsTrigger>)}</TabsList></Tabs><Input className="sm:w-64" placeholder="Search bookings" /></div></section>
  );
}

function AccountBookingsSection1() {
  const bookings = [{ id: "DF-82941", vehicle: "Comfort Sedan", dates: "Aug 24–28", status: "Confirmed" }, { id: "DF-70123", vehicle: "Adventure SUV", dates: "Jun 2–6", status: "Completed" }];
  return (
    <section className="mx-auto max-w-5xl space-y-4">{bookings.map((item) => <Card key={item.id}><CardContent className="flex flex-col justify-between gap-4 p-5 sm:flex-row sm:items-center"><div><div className="flex items-center gap-2"><p className="font-semibold">{item.vehicle}</p><Badge variant="secondary">{item.status}</Badge></div><p className="mt-1 text-sm text-muted-foreground">{item.dates} • {item.id}</p></div><div className="flex gap-2"><Button variant="outline">Receipt</Button><Button>Manage</Button></div></CardContent></Card>)}</section>
  );
}

export default function AccountBookings() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="w-full min-w-0">
        <AccountBookingsSection0 />
        <AccountBookingsSection1 />
      </div>
    </div>
  );
}
