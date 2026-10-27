import DepositStatusBadge from "../components/DepositStatusBadge";
import ReservationPriceSummary from "../components/ReservationPriceSummary";
import { Check, Download } from "lucide-react";
import React from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { useModelShow } from "@rhino-dev/rhino-react";
import { apiPath, downloadFile, useOrgSlug } from "@/lib/flow";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";

function BookingConfirmationSection0({ rentalId }: { rentalId?: number | string }) {
  const navigate = useNavigate();
  const orgSlug = useOrgSlug();
  const { data: rental } = useModelShow("rentals", rentalId);
  return (
    <section className="mx-auto max-w-3xl"><Card><CardHeader><div className="flex items-center justify-between"><CardTitle>Reservation confirmed</CardTitle><DepositStatusBadge status={rental?.deposit_status ?? "Pending"} /></div></CardHeader><CardContent className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between"><div className="flex items-center gap-4">{rental?.qr_code_url && <img src={rental.qr_code_url} alt="Booking QR code" className="size-24 rounded-lg border object-contain" />}<div><p className="font-semibold">{rental?.reference ?? rentalId ?? "Reservation"}</p><p className="text-sm text-muted-foreground">{rental?.vehicle ?? rental?.category ?? "Vehicle assigned at pickup"}</p><p className="text-sm text-muted-foreground">{rental?.dates ?? ""}</p></div></div><div className="flex gap-2"><Button variant="outline" onClick={() => rentalId && downloadFile(apiPath(orgSlug, `/rentals/${rentalId}/receipt`), `driveflow-receipt-${rentalId}.pdf`)}><Download className="mr-2 size-4" />Download receipt</Button><Button onClick={() => navigate("/account/bookings")}>View booking</Button></div></CardContent></Card></section>
  );
}

function BookingConfirmationSection1() {
  const items = ["Valid driver license", "Payment card", "Deposit pre-authorization", "Digital agreement"];
  return (
    <section className="mx-auto max-w-3xl"><Card><CardHeader><CardTitle>Bring to pickup</CardTitle></CardHeader><CardContent className="grid gap-3 sm:grid-cols-2">{items.map((item) => <div key={item} className="flex items-center gap-2 text-sm"><Check className="size-4 text-emerald-600" />{item}</div>)}</CardContent></Card></section>
  );
}

function BookingConfirmationSection2({ depositStatus, lines }: { depositStatus: string; lines?: Array<{ label: string; amount: number }> }) {
  return (
    <section className="mx-auto max-w-3xl"><Card><CardHeader><div className="flex items-center justify-between"><CardTitle>Payment record</CardTitle><DepositStatusBadge status={depositStatus} /></div></CardHeader><CardContent><ReservationPriceSummary lines={lines} /></CardContent></Card></section>
  );
}

export default function BookingConfirmation() {
  const { state } = useLocation();
  const rentalId = state?.rentalId;
  const { data: rental } = useModelShow("rentals", rentalId);
  const charges = state?.charges ?? [];
  const lines = charges.length
    ? charges.map((charge: Record<string, any>) => ({ label: charge.description ?? charge.label ?? "Charge", amount: Number(charge.amount) }))
    : undefined;
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="w-full min-w-0">
        <BookingConfirmationSection0 rentalId={rentalId} />
        <BookingConfirmationSection1 />
        <BookingConfirmationSection2 depositStatus={rental?.deposit_status ?? "Pending"} lines={lines} />
      </div>
    </div>
  );
}
