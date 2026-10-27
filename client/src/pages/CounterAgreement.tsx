import { CheckCircle2, PenLine, Search } from "lucide-react";
import React, { useState } from "react";
import { api } from "@rhino-dev/rhino-react";
import { apiPath, errorText, money, useOrgSlug } from "@/lib/flow";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Checkbox } from "../components/ui/checkbox";
import { Input } from "../components/ui/input";

function CounterAgreementSection0({ query, setQuery, onSearch, found }: { query: string; setQuery: (value: string) => void; onSearch: () => void; found: Record<string, any> | null }) {
  return (
    <><div><p className="text-sm font-medium text-primary">Counter operations</p><h1 className="text-3xl font-bold tracking-tight">Agreement signing</h1><p className="mt-1 text-muted-foreground">Find a reservation and complete the rental contract.</p></div><div className="flex max-w-2xl gap-2"><div className="relative flex-1"><Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" /><Input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Reservation, customer, or plate" className="pl-9" /></div><Button onClick={onSearch}>Search</Button></div>{found && <p className="text-sm text-emerald-600">Reservation {found.reference ?? found.reservation_number} selected · {found.customer ?? "customer"}</p>}</>
  );
}

function CounterAgreementSection1({ rental, accepted, setAccepted, complete, busy, notice, onComplete, onClear }: { rental: Record<string, any> | null; accepted: boolean; setAccepted: (value: boolean) => void; complete: boolean; busy: boolean; notice: string; onComplete: () => void; onClear: () => void }) {
  return (
    <><Card><CardHeader><CardTitle>Rental agreement · {rental?.reference ?? rental?.reservation_number ?? "—"}</CardTitle></CardHeader><CardContent className="space-y-4"><div className="h-72 overflow-y-auto rounded-lg border bg-muted/30 p-5 text-sm leading-6 text-muted-foreground"><h3 className="mb-3 font-semibold text-foreground">DriveFlow Rental Terms</h3><p>The renter accepts responsibility for the vehicle from key handover through confirmed return. Authorized drivers, mileage, fuel, tolls, damage, and late-return charges are governed by this agreement.</p><p className="mt-4">Vehicle: {rental?.vehicle ?? rental?.category ?? "—"}<br/>Rental period: {rental?.dates ?? "—"}<br/>Deposit authorization: {money(rental?.deposit_amount ?? 0)}</p></div><label className="flex items-start gap-3 text-sm"><Checkbox checked={accepted} onCheckedChange={(v) => setAccepted(Boolean(v))}/><span>I have reviewed and accept the rental terms and vehicle condition.</span></label></CardContent></Card><Card><CardHeader><CardTitle className="flex items-center gap-2"><PenLine className="size-5"/>Customer signature</CardTitle></CardHeader><CardContent className="space-y-4"><div className="grid h-36 place-items-center rounded-lg border-2 border-dashed bg-muted/30 text-sm text-muted-foreground">Sign in this area</div><Button className="w-full" disabled={!accepted || complete || busy} onClick={onComplete}>{complete ? <><CheckCircle2 className="size-4"/>Agreement complete</> : "Complete agreement"}</Button>{notice && <p className="text-sm text-muted-foreground">{notice}</p>}<Button variant="outline" className="w-full" onClick={onClear}>Clear signature</Button></CardContent></Card></>
  );
}

export default function CounterAgreement() {
  const orgSlug = useOrgSlug();
  const [query, setQuery] = useState("");
  const [found, setFound] = useState<Record<string, any> | null>(null);
  const [accepted, setAccepted] = useState(false);
  const [complete, setComplete] = useState(false);
  const [busy, setBusy] = useState(false);
  const [notice, setNotice] = useState("");

  const search = async () => {
    if (!query) return;
    setNotice("");
    try {
      const { data } = await api.get(apiPath(orgSlug, "/counter/lookup"), { params: { q: query } });
      const match = (data?.data ?? [])[0] ?? null;
      setFound(match);
      setComplete(false);
      setAccepted(false);
      if (!match) setNotice(`No reservation matched ${query}.`);
    } catch (err) {
      setNotice(errorText(err, "The reservation lookup failed."));
    }
  };

  const sign = async () => {
    if (!found?.id) return;
    setBusy(true);
    try {
      const signature = `signature://driveflow/${found.id}/${Date.now()}`;
      await api.post(apiPath(orgSlug, `/rentals/${found.id}/finalize`), { customer_signature_url: signature, customer_signature_timestamp: new Date().toISOString() });
      setComplete(true);
      setNotice("Signature captured. Agreement PDF emailed; the vehicle is now rented.");
    } catch (err) {
      setNotice(errorText(err, "We could not complete the agreement."));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-7xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <CounterAgreementSection0 query={query} setQuery={setQuery} onSearch={search} found={found} />
        <CounterAgreementSection1 rental={found} accepted={accepted} setAccepted={setAccepted} complete={complete} busy={busy} notice={notice} onComplete={sign} onClear={() => setAccepted(false)} />
      </div>
    </div>
  );
}
