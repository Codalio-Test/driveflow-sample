import { CheckCircle2, CreditCard, KeyRound, ScanLine } from "lucide-react";
import React, { useState } from "react";
import { useParams } from "react-router-dom";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Progress } from "../components/ui/progress";

function CounterCheckoutSection0() {
  const { reservationId } = useParams();
  return (
    <><div className="flex flex-wrap items-end justify-between gap-3"><div><p className="text-sm font-medium text-primary">Rapid handover</p><h1 className="text-3xl font-bold">Check-out · {reservationId || "RSV-10428"}</h1><p className="text-muted-foreground">Target completion: under 90 seconds</p></div><Badge className="bg-emerald-600 text-white">3 of 5 gates ready</Badge></div><Progress value={60}/><div className="grid grid-cols-2 gap-2 text-xs text-muted-foreground sm:grid-cols-5">{["Vehicle assigned","Payment hold","Walkaround","Signature","Key handover"].map((step, i)=><span key={step} className={i<3 ? "font-medium text-primary" : ""}>{i+1}. {step}</span>)}</div></>
  );
}

function CounterCheckoutSection1() {
  const [authorized, setAuthorized] = useState(false);
  const [released, setReleased] = useState(false);
  return (
    <><Card><CardHeader><CardTitle>Customer & vehicle verification</CardTitle></CardHeader><CardContent className="space-y-5"><div className="grid gap-4 sm:grid-cols-2"><div><p className="text-xs text-muted-foreground">Customer</p><p className="font-semibold">Maya Chen</p><p className="text-sm text-muted-foreground">License ending 4821</p></div><div><p className="text-xs text-muted-foreground">Assigned vehicle</p><p className="font-semibold">2024 Toyota RAV4</p><p className="text-sm text-muted-foreground">DF-2048 · Stall B12</p></div></div><div className="flex gap-2"><Input placeholder="Scan or enter license"/><Button variant="outline"><ScanLine className="size-4"/>Scan</Button></div><Button onClick={() => setAuthorized(true)} disabled={authorized}><CreditCard className="size-4"/>{authorized ? "Deposit authorized" : "Authorize $500 hold"}</Button></CardContent></Card><Card><CardHeader><CardTitle>Release gates</CardTitle></CardHeader><CardContent className="space-y-3">{["Vehicle assigned", authorized ? "Stripe hold active" : "Stripe hold pending", "Inspection complete", "Agreement signed"].map((gate,i)=><div key={gate} className="flex items-center gap-2 text-sm"><CheckCircle2 className={i===1&&!authorized ? "size-4 text-muted-foreground" : "size-4 text-emerald-600"}/>{gate}</div>)}<Button className="mt-3 w-full" disabled={!authorized} onClick={() => setReleased(true)}><KeyRound className="size-4"/>{released ? "Keys released" : "Release keys"}</Button>{released&&<Badge className="w-full justify-center bg-emerald-600 text-white">Handover complete</Badge>}</CardContent></Card></>
  );
}

export default function CounterCheckout() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-7xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <CounterCheckoutSection0 />
        <CounterCheckoutSection1 />
      </div>
    </div>
  );
}
