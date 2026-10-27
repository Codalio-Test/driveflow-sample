import BookingProgress from "../components/BookingProgress";
import ReservationPriceSummary from "../components/ReservationPriceSummary";
import { ShieldCheck } from "lucide-react";
import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Checkbox } from "../components/ui/checkbox";

function BookingConfigureSection0() {
  return (
    <section className="mx-auto max-w-5xl"><BookingProgress current={2} /></section>
  );
}

function BookingConfigureSection1() {
  const navigate = useNavigate();
  const [tier, setTier] = useState("Standard");
  const tiers = [{ name: "Basic", copy: "Essential coverage", price: 0 }, { name: "Standard", copy: "Balanced protection", price: 12 }, { name: "Premium", copy: "Maximum confidence", price: 24 }];
  const addons = ["Additional driver", "Child seat", "Roadside assistance", "Prepaid fuel"];
  return (
    <section className="mx-auto grid max-w-5xl gap-6 lg:grid-cols-[1fr_320px]"><div className="space-y-6"><div className="grid gap-4 sm:grid-cols-3">{tiers.map((item) => <Card key={item.name} onClick={() => setTier(item.name)} className={`cursor-pointer ${tier === item.name ? "ring-2 ring-primary" : ""}`}><CardHeader><ShieldCheck className="size-5 text-primary" /><CardTitle>{item.name}</CardTitle></CardHeader><CardContent><p className="text-sm text-muted-foreground">{item.copy}</p><p className="mt-3 font-bold">+${item.price}/day</p></CardContent></Card>)}</div><Card><CardHeader><CardTitle>Add-ons</CardTitle></CardHeader><CardContent className="grid gap-4 sm:grid-cols-2">{addons.map((item) => <label key={item} className="flex items-center gap-3 rounded-lg border p-3"><Checkbox /> <span className="text-sm">{item}</span></label>)}</CardContent></Card></div><Card className="h-fit lg:sticky lg:top-24"><CardHeader><CardTitle>Updated total</CardTitle></CardHeader><CardContent><ReservationPriceSummary /><Button className="mt-5 w-full" onClick={() => navigate("/booking/checkout")}>Continue to checkout</Button></CardContent></Card></section>
  );
}

export default function BookingConfigure() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="w-full min-w-0">
        <BookingConfigureSection0 />
        <BookingConfigureSection1 />
      </div>
    </div>
  );
}
