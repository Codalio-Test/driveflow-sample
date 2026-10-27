import FinancialFormulaBreakdown from "../components/FinancialFormulaBreakdown";
import { AlertTriangle, CreditCard, MessageSquare, Phone } from "lucide-react";
import React, { useState } from "react";
import { useParams } from "react-router-dom";
import { api, useModelIndex, useModelShow } from "@rhino-dev/rhino-react";
import { apiPath, errorText, money, useOrgSlug } from "@/lib/flow";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Textarea } from "../components/ui/textarea";

function AdminRentalOverdueSection0({ rentalId, rental, busy, notice, onMessage, onExpandHold, onCall }: { rentalId?: string; rental: Record<string, any> | null; busy: string; notice: string; onMessage: () => void; onExpandHold: () => void; onCall: () => void }) {
  const phone = rental?.customer_profile?.phone_number ?? rental?.phone_number;
  return (
    <Card className="border-destructive/40"><CardContent className="flex flex-col gap-5 p-6 md:flex-row md:items-center md:justify-between"><div className="flex gap-4"><span className="grid size-12 place-items-center rounded-full bg-destructive/10 text-destructive"><AlertTriangle className="size-6"/></span><div><Badge variant="destructive">Critical overdue</Badge><h1 className="mt-2 text-3xl font-bold">{rental?.overdue_duration ?? "—"} overdue</h1><p className="text-muted-foreground">{rental?.reference ?? rentalId ?? "—"} · {rental?.customer ?? "Customer"} · {rental?.vehicle ?? rental?.category ?? "Vehicle"}</p><p className="text-sm text-muted-foreground">{rental?.late_grace_minutes ?? 60}-minute grace period exceeded {rental?.grace_expires_at ? `at ${new Date(rental.grace_expires_at).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" })}` : ""}</p>{notice && <p className="text-sm text-muted-foreground">{notice}</p>}</div></div><div className="flex gap-2"><Button variant="outline" disabled={!phone} onClick={onCall}><Phone className="size-4"/>Call</Button><Button variant="outline" disabled={busy === "hold"} onClick={onExpandHold}><CreditCard className="size-4"/>Expand hold</Button><Button disabled={busy === "notify"} onClick={onMessage}><MessageSquare className="size-4"/>Message</Button></div></CardContent></Card>
  );
}

function AdminRentalOverdueSection1({ items, total, note, setNote, onAddNote, onEscalate, events, busy }: { items: Array<{ label: string; formula: string }>; total: string; note: string; setNote: (value: string) => void; onAddNote: () => void; onEscalate: () => void; events: Record<string, any>[]; busy: string }) {
  return (
    <><div className="space-y-4"><FinancialFormulaBreakdown items={items} total={total}/><Card><CardHeader><CardTitle>Recovery note</CardTitle></CardHeader><CardContent className="space-y-3"><Textarea value={note} onChange={e=>setNote(e.target.value)} placeholder="Log contact attempts and commitments…"/><Button disabled={!note || busy === "note"} onClick={onAddNote}>Add note</Button></CardContent></Card></div><Card><CardHeader><CardTitle>Activity timeline</CardTitle></CardHeader><CardContent className="space-y-5">{events.map(e=><div key={`${e.time}-${e.label}`} className="border-l-2 border-border pl-3"><div className="flex justify-between"><p className="text-sm font-medium">{e.label}</p><Badge variant="outline">{e.time}</Badge></div><p className="text-xs text-muted-foreground">{e.detail}</p></div>)}{events.length === 0 && <p className="text-xs text-muted-foreground">No contact attempts logged yet.</p>}<Button variant="destructive" className="w-full" disabled={busy === "escalate"} onClick={onEscalate}>Escalate case</Button></CardContent></Card></>
  );
}

export default function AdminRentalOverdue() {
  const { rentalId } = useParams();
  const orgSlug = useOrgSlug();
  const { data: rental, refetch } = useModelShow("rentals", rentalId, { includes: ["customer_profile", "vehicle"] });
  const { data: payments } = useModelIndex("payments", { filters: { rental_id: rentalId }, sort: "-processed_at", perPage: 25 });
  const [note, setNote] = useState("");
  const [busy, setBusy] = useState("");
  const [notice, setNotice] = useState("");

  const hours = rental?.billable_overdue_hours ?? 0;
  const rate = rental?.late_hourly_rate ?? 0;
  const items = [
    { label: "Billable overdue", formula: `${hours} hr after grace` },
    { label: "Hourly penalty", formula: `${hours} × ${money(rate)} = ${money(rental?.late_fee_accrued ?? 0)}` },
    { label: "Daily cap", formula: `${money(rental?.daily_cap ?? 0)} maximum` },
  ];
  const events = [
    ...(rental?.grace_expires_at ? [{ time: new Date(rental.grace_expires_at).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" }), label: "Grace period ended", detail: "Penalty accrual started" }] : []),
    ...(payments?.data ?? []).map((payment: Record<string, any>) => ({ time: payment.processed_at ? new Date(payment.processed_at).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" }) : "—", label: `${payment.type ?? payment.transaction_type ?? "Payment"} · ${payment.status}`, detail: `${money(payment.amount)}${payment.last4 ? ` • card ending ${payment.last4}` : ""}` })),
  ];

  const post = async (path: string, body: Record<string, any> | undefined, key: string, success: string, failure: string) => {
    setBusy(key);
    setNotice("");
    try {
      await api.post(apiPath(orgSlug, path), body ?? {});
      setNotice(success);
      refetch();
    } catch (err) {
      setNotice(errorText(err, failure));
    } finally {
      setBusy("");
    }
  };

  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-7xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <AdminRentalOverdueSection0 rentalId={rentalId} rental={rental ?? null} busy={busy} notice={notice} onMessage={() => post(`/rentals/${rentalId}/notify`, { channel: "sms+email" }, "notify", "Return urgency notice dispatched by SMS and email.", "The notice could not be sent.")} onExpandHold={() => post("/payments/expand_hold", { rental_id: rental?.id, amount: rental?.daily_cap }, "hold", "Pre-authorization hold expanded.", "Stripe declined the incremental hold.")} onCall={() => { const phone = rental?.customer_profile?.phone_number ?? rental?.phone_number; if (phone) window.location.href = `tel:${phone}`; }} />
        <AdminRentalOverdueSection1 items={items} total={money(rental?.late_fee_accrued ?? 0)} note={note} setNote={setNote} onAddNote={() => post(`/rentals/${rentalId}/notes`, { body: note }, "note", "Recovery note added to the timeline.", "The note could not be saved.")} onEscalate={() => post(`/rentals/${rentalId}/escalate`, { reason: "Unreturned asset flagged for recovery" }, "escalate", "Case escalated to the recovery team.", "The case could not be escalated.")} events={events} busy={busy} />
      </div>
    </div>
  );
}
