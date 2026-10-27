import DepositStatusBadge from "../components/DepositStatusBadge";
import ReservationPriceSummary from "../components/ReservationPriceSummary";
import { Check } from "lucide-react";
import React from "react";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";

function BookingConfirmationSection1() {
  const items = ["Valid driver license", "Payment card", "Deposit pre-authorization", "Digital agreement"];
  return (
    <section className="mx-auto max-w-3xl"><Card><CardHeader><CardTitle>Bring to pickup</CardTitle></CardHeader><CardContent className="grid gap-3 sm:grid-cols-2">{items.map((item) => <div key={item} className="flex items-center gap-2 text-sm"><Check className="size-4 text-emerald-600" />{item}</div>)}</CardContent></Card></section>
  );
}

function BookingConfirmationSection2() {
  return (
    <section className="mx-auto max-w-3xl"><Card><CardHeader><div className="flex items-center justify-between"><CardTitle>Payment record</CardTitle><DepositStatusBadge status="Secured" /></div></CardHeader><CardContent><ReservationPriceSummary /></CardContent></Card></section>
  );
}

export default function BookingConfirmation() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="w-full min-w-0">
        <BookingConfirmationSection1 />
        <BookingConfirmationSection2 />
      </div>
    </div>
  );
}
