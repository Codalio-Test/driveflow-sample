import { CheckCircle2, PenLine, Search } from "lucide-react";
import React, { useState } from "react";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Checkbox } from "../components/ui/checkbox";
import { Input } from "../components/ui/input";

function CounterAgreementSection0() {
  const [query, setQuery] = useState("");
  const [found, setFound] = useState(false);
  return (
    <><div><p className="text-sm font-medium text-primary">Counter operations</p><h1 className="text-3xl font-bold tracking-tight">Agreement signing</h1><p className="mt-1 text-muted-foreground">Find a reservation and complete the rental contract.</p></div><div className="flex max-w-2xl gap-2"><div className="relative flex-1"><Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" /><Input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Reservation, customer, or plate" className="pl-9" /></div><Button onClick={() => setFound(true)}>Search</Button></div>{found && <p className="text-sm text-emerald-600">Reservation RSV-10428 selected · Maya Chen</p>}</>
  );
}

function CounterAgreementSection1() {
  const [accepted, setAccepted] = useState(false);
  const [complete, setComplete] = useState(false);
  return (
    <><Card><CardHeader><CardTitle>Rental agreement · RSV-10428</CardTitle></CardHeader><CardContent className="space-y-4"><div className="h-72 overflow-y-auto rounded-lg border bg-muted/30 p-5 text-sm leading-6 text-muted-foreground"><h3 className="mb-3 font-semibold text-foreground">DriveFlow Rental Terms</h3><p>The renter accepts responsibility for the vehicle from key handover through confirmed return. Authorized drivers, mileage, fuel, tolls, damage, and late-return charges are governed by this agreement.</p><p className="mt-4">Vehicle: 2024 Toyota RAV4 · DF-2048<br/>Rental period: Jun 14, 10:00 AM – Jun 18, 10:00 AM<br/>Deposit authorization: $500.00</p></div><label className="flex items-start gap-3 text-sm"><Checkbox checked={accepted} onCheckedChange={(v) => setAccepted(Boolean(v))}/><span>I have reviewed and accept the rental terms and vehicle condition.</span></label></CardContent></Card><Card><CardHeader><CardTitle className="flex items-center gap-2"><PenLine className="size-5"/>Customer signature</CardTitle></CardHeader><CardContent className="space-y-4"><div className="grid h-36 place-items-center rounded-lg border-2 border-dashed bg-muted/30 text-sm text-muted-foreground">Sign in this area</div><Button className="w-full" disabled={!accepted || complete} onClick={() => setComplete(true)}>{complete ? <><CheckCircle2 className="size-4"/>Agreement complete</> : "Complete agreement"}</Button><Button variant="outline" className="w-full">Clear signature</Button></CardContent></Card></>
  );
}

export default function CounterAgreement() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-7xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <CounterAgreementSection0 />
        <CounterAgreementSection1 />
      </div>
    </div>
  );
}
