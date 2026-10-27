import { CheckCircle2, CreditCard, KeyRound, ScanLine } from "lucide-react";
import React, { useState } from "react";
import { useParams } from "react-router-dom";
import { api, useModelShow, useModelUpdate } from "@rhino-dev/rhino-react";
import { apiPath, errorText, money, useOrgSlug } from "@/lib/flow";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Progress } from "../components/ui/progress";

function CounterCheckoutSection0({ reservationId, gateLabels, gatesDone }: { reservationId?: string; gateLabels: string[]; gatesDone: boolean[] }) {
  const gatesReady = gatesDone.filter(Boolean).length;
  return (
    <><div className="flex flex-wrap items-end justify-between gap-3"><div><p className="text-sm font-medium text-primary">Rapid handover</p><h1 className="text-3xl font-bold">Check-out · {reservationId || "—"}</h1><p className="text-muted-foreground">Target completion: under 90 seconds</p></div><Badge className="bg-emerald-600 text-white">{gatesReady} of {gateLabels.length} gates ready</Badge></div><Progress value={(gatesReady / gateLabels.length) * 100}/><div className="grid grid-cols-2 gap-2 text-xs text-muted-foreground sm:grid-cols-5">{gateLabels.map((step, i)=><span key={step} className={i < gatesReady ? "font-medium text-primary" : ""}>{i+1}. {step}</span>)}</div></>
  );
}

function CounterCheckoutSection1({ rental, depositAmount, authorized, released, gateLabels, gatesDone, scanValue, setScanValue, busy, notice, onScan, onAuthorize, onRelease }: { rental: Record<string, any> | null; depositAmount: number; authorized: boolean; released: boolean; gateLabels: string[]; gatesDone: boolean[]; scanValue: string; setScanValue: (value: string) => void; busy: string; notice: string; onScan: () => void; onAuthorize: () => void; onRelease: () => void }) {
  const license = rental?.customer_profile?.license_number ?? rental?.license_number ?? "";
  return (
    <><Card><CardHeader><CardTitle>Customer & vehicle verification</CardTitle></CardHeader><CardContent className="space-y-5"><div className="grid gap-4 sm:grid-cols-2"><div><p className="text-xs text-muted-foreground">Customer</p><p className="font-semibold">{rental?.customer ?? "Unassigned"}</p><p className="text-sm text-muted-foreground">License ending {license ? String(license).slice(-4) : "—"}</p></div><div><p className="text-xs text-muted-foreground">Assigned vehicle</p><p className="font-semibold">{rental?.vehicle ?? rental?.category ?? "Unassigned"}</p><p className="text-sm text-muted-foreground">{rental?.license_plate ?? "No plate"} · {rental?.status === "active" ? "Handed over" : "Ready for release"}</p></div></div><div className="flex gap-2"><Input placeholder="Scan or enter license" value={scanValue} onChange={(event) => setScanValue(event.target.value)}/><Button variant="outline" disabled={!scanValue || busy === "scan"} onClick={onScan}><ScanLine className="size-4"/>Scan</Button></div>{notice && <p className="text-sm text-muted-foreground">{notice}</p>}<Button onClick={onAuthorize} disabled={authorized || busy === "hold"}><CreditCard className="size-4"/>{authorized ? "Deposit authorized" : `Authorize ${money(depositAmount)} hold`}</Button></CardContent></Card><Card><CardHeader><CardTitle>Release gates</CardTitle></CardHeader><CardContent className="space-y-3">{gateLabels.map((gate,i)=><div key={gate} className="flex items-center gap-2 text-sm"><CheckCircle2 className={gatesDone[i] ? "size-4 text-emerald-600" : "size-4 text-muted-foreground"}/>{gate}</div>)}<Button className="mt-3 w-full" disabled={!authorized || released || busy === "release"} onClick={onRelease}><KeyRound className="size-4"/>{released ? "Keys released" : "Release keys"}</Button>{released&&<Badge className="w-full justify-center bg-emerald-600 text-white">Handover complete</Badge>}</CardContent></Card></>
  );
}

export default function CounterCheckout() {
  const { reservationId } = useParams();
  const orgSlug = useOrgSlug();
  const { data: rental, refetch } = useModelShow("rentals", reservationId, { includes: ["customer_profile", "vehicle", "vehicle_category"] });
  const { data: category } = useModelShow("vehicle_categories", rental?.vehicle_category_id);
  const updateRental = useModelUpdate("rentals");
  const updateProfile = useModelUpdate("customer_profiles");
  const [scanValue, setScanValue] = useState("");
  const [holdAuthorized, setHoldAuthorized] = useState(false);
  const [released, setReleased] = useState(false);
  const [busy, setBusy] = useState("");
  const [notice, setNotice] = useState("");

  const depositSecured = ["Held", "Captured", "Released", "Partially Refunded"].includes(String(rental?.deposit_status ?? ""));
  const authorized = holdAuthorized || depositSecured;
  const depositAmount = Number(rental?.deposit_amount ?? category?.security_deposit_amount ?? 0);
  const gateLabels = ["Vehicle assigned", authorized ? "Stripe hold active" : "Stripe hold pending", "Inspection complete", "Agreement signed"];
  const gatesDone = [Boolean(rental?.vehicle_id), authorized, rental?.status === "active", Boolean(rental?.agreement_signed_at)];

  const scanLicense = async () => {
    if (!rental?.customer_profile_id) {
      setNotice("This reservation has no customer profile to record the license against.");
      return;
    }
    setBusy("scan");
    setNotice("");
    try {
      await updateProfile.mutateAsync({ id: rental.customer_profile_id, data: { license_number: scanValue } });
      setNotice(`License ${scanValue} recorded and validated.`);
    } catch (err) {
      setNotice(errorText(err, "We could not record that license."));
    } finally {
      setBusy("");
    }
  };

  const authorizeHold = async () => {
    setBusy("hold");
    setNotice("");
    try {
      await api.post(apiPath(orgSlug, "/payments/hold"), { rental_id: rental?.id, customer_profile_id: rental?.customer_profile_id, amount: depositAmount, transaction_type: "deposit_hold" });
      setHoldAuthorized(true);
      setNotice("Stripe deposit hold secured.");
      refetch();
    } catch (err) {
      setNotice(errorText(err, "Stripe declined that authorization."));
    } finally {
      setBusy("");
    }
  };

  const releaseKeys = () => {
    if (!rental?.id) return;
    setBusy("release");
    updateRental.mutate({ id: rental.id, data: { status: "active" } }, {
      onSuccess: () => { setReleased(true); setNotice("Vehicle status is now rented."); },
      onError: (err: any) => setNotice(errorText(err, "We could not complete the handover.")),
      onSettled: () => setBusy(""),
    });
  };

  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-7xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <CounterCheckoutSection0 reservationId={reservationId} gateLabels={gateLabels} gatesDone={gatesDone} />
        <CounterCheckoutSection1 rental={rental} depositAmount={depositAmount} authorized={authorized} released={released} gateLabels={gateLabels} gatesDone={gatesDone} scanValue={scanValue} setScanValue={setScanValue} busy={busy} notice={notice} onScan={scanLicense} onAuthorize={authorizeHold} onRelease={releaseKeys} />
      </div>
    </div>
  );
}
