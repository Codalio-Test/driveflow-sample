import ReservationPriceSummary from "../components/ReservationPriceSummary";
import { Lock } from "lucide-react";
import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Checkbox } from "../components/ui/checkbox";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";

function BookingCheckoutSection1() {
  const navigate = useNavigate();
  const [accepted, setAccepted] = useState(false);
  return (
    <section className="mx-auto grid max-w-5xl gap-6 lg:grid-cols-[1fr_320px]"><div className="space-y-6"><Card><CardHeader><CardTitle>Renter details</CardTitle></CardHeader><CardContent className="grid gap-4 sm:grid-cols-2"><div><Label>First name</Label><Input className="mt-2" /></div><div><Label>Last name</Label><Input className="mt-2" /></div><div className="sm:col-span-2"><Label>Email</Label><Input className="mt-2" type="email" /></div></CardContent></Card><Card><CardHeader><CardTitle className="flex items-center gap-2"><Lock className="size-4" />Secure payment</CardTitle></CardHeader><CardContent className="grid gap-4"><div><Label>Card number</Label><Input className="mt-2" placeholder="4242 4242 4242 4242" /></div><div className="grid grid-cols-2 gap-4"><Input placeholder="MM / YY" /><Input placeholder="CVC" /></div></CardContent></Card></div><Card className="h-fit lg:sticky lg:top-24"><CardHeader><CardTitle>Total</CardTitle></CardHeader><CardContent><ReservationPriceSummary /><div className="mt-5 flex items-start gap-2"><Checkbox checked={accepted} onCheckedChange={(v) => setAccepted(Boolean(v))} /><p className="text-xs text-muted-foreground">I accept the rental and deposit terms.</p></div><Button disabled={!accepted} className="mt-5 w-full" onClick={() => navigate("/booking/confirmation")}>Confirm and pay</Button></CardContent></Card></section>
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
