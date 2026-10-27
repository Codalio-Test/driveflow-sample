import React, { useState } from "react";
import { api, useModelIndex } from "@rhino-dev/rhino-react";
import { useAppOwner } from "@/contexts/AppOwnerProvider";
import { apiPath, downloadFile, errorText, money, useOrgSlug } from "@/lib/flow";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "../components/ui/table";

function AccountBillingSection1({ deposits, onAddCard, adding, notice }: { deposits: Record<string, any>[]; onAddCard: () => void; adding: boolean; notice: string }) {
  return (
    <section className="mx-auto max-w-5xl"><Card><CardHeader className="flex-row items-center justify-between"><CardTitle>Security deposit status</CardTitle><Button variant="outline" size="sm" disabled={adding} onClick={onAddCard}>{adding ? "Saving card…" : "Add card"}</Button></CardHeader><CardContent className="space-y-3">{deposits.length === 0 && <p className="text-sm text-muted-foreground">No deposit holds on record.</p>}{deposits.map((item) => <div key={item.id} className="flex items-center justify-between border-b pb-3 text-sm last:border-0"><div><p className="font-medium">{money(item.amount)}</p><p className="text-muted-foreground">{item.type ?? item.transaction_type}{item.last4 ? ` • ending ${item.last4}` : ""} • {item.date ?? ""}</p></div><Badge variant="secondary">{item.status}</Badge></div>)}{notice && <p className="text-xs text-muted-foreground">{notice}</p>}</CardContent></Card></section>
  );
}

function AccountBillingSection2({ rows, onDownload }: { rows: Record<string, any>[]; onDownload: (rentalId: number | string | null) => void }) {
  return (
    <section className="mx-auto max-w-5xl overflow-hidden rounded-lg border"><Table><TableHeader><TableRow><TableHead>Invoice</TableHead><TableHead>Date</TableHead><TableHead>Amount</TableHead><TableHead className="text-right">Action</TableHead></TableRow></TableHeader><TableBody>{rows.map((row) => <TableRow key={row.id}><TableCell className="font-medium">{row.id}</TableCell><TableCell>{row.date}</TableCell><TableCell>{row.amount}</TableCell><TableCell className="text-right"><Button variant="ghost" size="sm" disabled={!row.rentalId} onClick={() => onDownload(row.rentalId)}>Download</Button></TableCell></TableRow>)}</TableBody></Table></section>
  );
}

export default function AccountBilling() {
  const orgSlug = useOrgSlug();
  const { customerProfileId } = useAppOwner();
  const { data: response } = useModelIndex("payments", { sort: "-processed_at", includes: ["rental"], perPage: 25 });
  const [notice, setNotice] = useState("");
  const [adding, setAdding] = useState(false);
  const payments = response?.data ?? [];
  const rows = payments.filter((payment: Record<string, any>) => payment.transaction_type !== "deposit_hold").map((payment: Record<string, any>) => ({ id: payment.reference ?? payment.invoice_number ?? `PAY-${payment.id}`, date: payment.date ?? "", amount: payment.amount_display ?? money(payment.amount), rentalId: payment.rental_id }));
  const deposits = payments.filter((payment: Record<string, any>) => String(payment.transaction_type ?? "").startsWith("deposit"));

  const addCard = async () => {
    setAdding(true);
    setNotice("");
    try {
      await api.post(apiPath(orgSlug, "/payments/methods"), { customer_profile_id: customerProfileId, stripe_payment_method: "pm_card_visa" });
      setNotice("Card saved to your customer profile.");
    } catch (err) {
      setNotice(errorText(err, "We could not save that card."));
    } finally {
      setAdding(false);
    }
  };

  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="w-full min-w-0">
        <AccountBillingSection1 deposits={deposits} onAddCard={addCard} adding={adding} notice={notice} />
        <AccountBillingSection2 rows={rows} onDownload={(rentalId) => rentalId && downloadFile(apiPath(orgSlug, `/rentals/${rentalId}/receipt`), `driveflow-receipt-${rentalId}.pdf`)} />
      </div>
    </div>
  );
}
