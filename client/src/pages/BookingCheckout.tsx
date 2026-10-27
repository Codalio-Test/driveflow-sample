import ReservationPriceSummary from "../components/ReservationPriceSummary";
import { Lock } from "lucide-react";
import React, { useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { api, useAuth } from "@rhino-dev/rhino-react";
import { apiPath, errorText, useOrgSlug } from "@/lib/flow";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Checkbox } from "../components/ui/checkbox";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";

function BookingCheckoutSection1() {
  const navigate = useNavigate();
  const { state } = useLocation();
  const { isAuthenticated } = useAuth();
  const orgSlug = useOrgSlug();
  const [accepted, setAccepted] = useState(false);
  const [renter, setRenter] = useState({ full_name: "", email: "", phone_number: "" });
  const [card, setCard] = useState("");
  const [licenseFile, setLicenseFile] = useState<File | null>(null);
  const [licenseNotice, setLicenseNotice] = useState("");
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const rentalId = state?.rentalId;
  const charges = state?.charges ?? [];
  const lines = charges.length
    ? charges.map((charge: Record<string, any>) => ({ label: charge.description ?? charge.label ?? "Charge", amount: Number(charge.amount) }))
    : undefined;

  const uploadLicense = async (file?: File) => {
    if (!file) return;
    setLicenseFile(file);
    if (!isAuthenticated || !orgSlug) {
      // Guest checkout: the counter scans the original at pickup; the
      // reservation itself carries the renter's licence details.
      setLicenseNotice(`${file.name} ready — the counter will scan the original at pickup.`);
      return;
    }
    setLicenseNotice(`${file.name} selected…`);
    try {
      const body = new FormData();
      body.append("file", file);
      body.append("kind", "driver_license");
      if (state?.customer_profile_id) body.append("customer_profile_id", String(state.customer_profile_id));
      await api.post(apiPath(orgSlug, "/documents"), body);
      setLicenseNotice(`${file.name} uploaded.`);
    } catch (err) {
      setLicenseNotice(errorText(err, "We could not upload that file."));
    }
  };

  const confirmAndPay = async () => {
    setError("");
    setSubmitting(true);
    try {
      const { data } = await api.post("/bookings/confirm", {
        rental_id: rentalId,
        full_name: renter.full_name,
        email: renter.email,
        phone_number: renter.phone_number,
        payment_method_last4: card.replace(/\D/g, "").slice(-4) || undefined,
      });
      navigate("/booking/confirmation", { state: { rentalId: data?.rental?.id ?? rentalId, charges } });
    } catch (err) {
      setError(errorText(err, "That card could not be authorized."));
    } finally {
      setSubmitting(false);
    }
  };
  return (
    <section className="mx-auto grid max-w-5xl gap-6 lg:grid-cols-[1fr_320px]"><div className="space-y-6"><Card><CardHeader><CardTitle>Renter details</CardTitle></CardHeader><CardContent className="grid gap-4 sm:grid-cols-2"><div><Label>First name</Label><Input className="mt-2" value={renter.full_name} onChange={(event) => setRenter({ ...renter, full_name: event.target.value })} /></div><div><Label>Last name</Label><Input className="mt-2" value={renter.phone_number} onChange={(event) => setRenter({ ...renter, phone_number: event.target.value })} /></div><div className="sm:col-span-2"><Label>Email</Label><Input className="mt-2" type="email" value={renter.email} onChange={(event) => setRenter({ ...renter, email: event.target.value })} /></div>
<div className="sm:col-span-2"><Label>Driver licence</Label><Input className="mt-2" type="file" accept="image/png,image/jpeg,application/pdf" onChange={(event) => uploadLicense(event.target.files?.[0])} />{licenseNotice && <p className="mt-2 text-xs text-muted-foreground">{licenseNotice}</p>}</div></CardContent></Card><Card><CardHeader><CardTitle className="flex items-center gap-2"><Lock className="size-4" />Secure payment</CardTitle></CardHeader><CardContent className="grid gap-4"><div><Label>Card number</Label><Input className="mt-2" value={card} onChange={(event) => setCard(event.target.value)} placeholder="4242 4242 4242 4242" /></div><div className="grid grid-cols-2 gap-4"><Input placeholder="MM / YY" /><Input placeholder="CVC" /></div></CardContent></Card></div><Card className="h-fit lg:sticky lg:top-24"><CardHeader><CardTitle>Total</CardTitle></CardHeader><CardContent><ReservationPriceSummary lines={lines} /><div className="mt-5 flex items-start gap-2"><Checkbox checked={accepted} onCheckedChange={(v) => setAccepted(Boolean(v))} /><p className="text-xs text-muted-foreground">I accept the rental and deposit terms.</p></div>{error && <p className="mt-3 text-sm text-destructive">{error}</p>}
<Button disabled={!accepted || submitting} className="mt-5 w-full" onClick={confirmAndPay}>{submitting ? "Authorizing…" : "Confirm and pay"}</Button></CardContent></Card></section>
  );
}

export default function BookingCheckout() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="w-full min-w-0">
        <BookingCheckoutSection1 />
      </div>
    </div>
  );
}
