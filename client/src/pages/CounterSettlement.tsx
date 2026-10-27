import FinancialFormulaBreakdown from "../components/FinancialFormulaBreakdown";
import { AlertTriangle, CheckCircle2 } from "lucide-react";
import React, { useState } from "react";
import { useParams } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { api, useModelIndex, useModelShow } from "@rhino-dev/rhino-react";
import { apiPath, errorText, money, useOrgSlug } from "@/lib/flow";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";

function CounterSettlementSection0({ rentalId, metrics }: { rentalId?: string; metrics: Record<string, any>[] }) {
  return (
    <><div><p className="text-sm font-medium text-primary">Settlement</p><h1 className="text-3xl font-bold">Return comparison · {rentalId||"RNT-8817"}</h1></div><div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">{metrics.map(item=><Card key={item.label}><CardContent className="p-5"><div className="flex items-center justify-between"><p className="text-sm text-muted-foreground">{item.label}</p>{item.flag&&<AlertTriangle className="size-4 text-amber-500"/>}</div><p className="mt-2 text-xl font-semibold">{item.value}</p><Badge variant="outline" className="mt-2">{item.delta}</Badge></CardContent></Card>)}</div></>
  );
}

function CounterSettlementSection1({ items, total, depositHold, captureAmount, releaseAmount, depositStatus, finalized, busy, notice, onFinalize, onProcess }: { items: Array<{ label: string; formula: string }>; total: string; depositHold: number; captureAmount: number; releaseAmount: number; depositStatus: string; finalized: boolean; busy: boolean; notice: string; onFinalize: () => void; onProcess: () => void }) {
  return (
    <><div className="space-y-4"><FinancialFormulaBreakdown items={items} total={total}/><Button onClick={onFinalize} disabled={finalized || busy}>{finalized?<><CheckCircle2 className="size-4"/>Settlement finalized</>:"Finalize settlement"}</Button>{notice && <p className="text-sm text-muted-foreground">{notice}</p>}</div><Card><CardHeader><CardTitle>Deposit settlement</CardTitle></CardHeader><CardContent className="space-y-4"><div className="flex items-center justify-between"><span className="text-sm text-muted-foreground">Authorization</span><Badge>{depositStatus}</Badge></div><p className="text-3xl font-bold">{money(depositHold)}</p><div className="text-sm"><p className="flex justify-between"><span>Capture</span><span>{money(captureAmount)}</span></p><p className="mt-2 flex justify-between"><span>Release</span><span>{money(releaseAmount)}</span></p></div><Button variant="outline" className="w-full" disabled={finalized || busy} onClick={onProcess}>Process with Stripe</Button></CardContent></Card></>
  );
}

export default function CounterSettlement() {
  const { rentalId } = useParams();
  const orgSlug = useOrgSlug();
  const { data: rental, refetch } = useModelShow("rentals", rentalId);
  const preview = useQuery({ queryKey: ["settlementPreview", rentalId], enabled: Boolean(orgSlug && rentalId), queryFn: async () => (await api.get(apiPath(orgSlug, `/rentals/${rentalId}/settlement_preview`))).data });
  const comparison = useQuery({ queryKey: ["settlementComparison", rentalId], enabled: Boolean(orgSlug && rentalId), queryFn: async () => (await api.get(apiPath(orgSlug, `/rentals/${rentalId}/inspection_comparison`))).data });
  const { data: charges } = useModelIndex("rental_charges", { filters: { rental_id: rentalId }, perPage: 50 });
  const [finalized, setFinalized] = useState(false);
  const [busy, setBusy] = useState(false);
  const [notice, setNotice] = useState("");

  const settlement = preview.data?.settlement ?? {};
  const deltas = comparison.data?.deltas ?? {};
  const newDamage = deltas.new_damage_count ?? 0;
  const metrics = [
    { label: "Return time", value: rental?.overdue_duration ? `${rental.late_fee_accrued ? rental.overdue_duration : rental.overdue_duration}` : "On time", delta: rental?.overdue ? `+${rental.overdue_duration}` : "within grace", flag: Boolean(rental?.overdue) },
    { label: "Odometer", value: `${(rental?.final_odometer ?? 0).toLocaleString()} mi`, delta: `${(deltas.odometer_delta ?? 0) >= 0 ? "+" : ""}${deltas.odometer_delta ?? 0} mi`, flag: false },
    { label: "Fuel", value: `${rental?.final_fuel_percentage ?? 0}%`, delta: `${(deltas.fuel_variance_percentage ?? 0) > 0 ? "-" : "+"}${Math.abs(deltas.fuel_variance_percentage ?? 0)}%`, flag: (deltas.fuel_variance_percentage ?? 0) > 0 },
    { label: "Damage", value: `${newDamage} new mark${newDamage === 1 ? "" : "s"}`, delta: newDamage > 0 ? "Review" : "Clear", flag: newDamage > 0 },
  ];

  const settle = async () => {
    setBusy(true);
    setNotice("");
    try {
      await api.post(apiPath(orgSlug, "/payments/settle"), { rental_id: rental?.id, capture_amount: settlement.capture_amount, release_amount: settlement.release_amount });
      setFinalized(true);
      setNotice("Deposit captured and the balance released. Receipt emailed to the renter.");
      refetch();
    } catch (err) {
      setNotice(errorText(err, "The settlement could not be completed."));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-7xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <CounterSettlementSection0 rentalId={rentalId} metrics={metrics} />
        <CounterSettlementSection1 items={settlement.formulas ?? []} total={money(settlement.surcharges_total ?? settlement.grand_total ?? 0)} depositHold={settlement.deposit_hold ?? 0} captureAmount={settlement.capture_amount ?? 0} releaseAmount={settlement.release_amount ?? 0} depositStatus={rental?.deposit_status ?? "Unsecured"} finalized={finalized} busy={busy} notice={notice || `${(charges?.data ?? []).length} charge line(s) on this rental`} onFinalize={settle} onProcess={settle} />
      </div>
    </div>
  );
}
