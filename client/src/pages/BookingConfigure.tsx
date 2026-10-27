import BookingProgress from "../components/BookingProgress";
import ReservationPriceSummary from "../components/ReservationPriceSummary";
import { ShieldCheck } from "lucide-react";
import React, { useRef, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { api, useModelDelete, useModelStore, useModelUpdate } from "@rhino-dev/rhino-react";
import { errorText } from "@/lib/flow";
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
  const { state } = useLocation();
  const [tier, setTier] = useState("Standard");
  const [selectedAddons, setSelectedAddons] = useState<Record<string, boolean>>({});
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const updateRental = useModelUpdate("rentals");
  const createCharge = useModelStore("rental_charges");
  const deleteCharge = useModelDelete("rental_charges");
  const createdAddons = useRef<Record<string, number>>({});
  const rentalId = state?.rentalId;
  const tiers = [{ name: "Basic", copy: "Essential coverage", price: 0 }, { name: "Standard", copy: "Balanced protection", price: 12 }, { name: "Premium", copy: "Maximum confidence", price: 24 }];
  const addons = ["Additional driver", "Child seat", "Roadside assistance", "Prepaid fuel"];
  const addonPrices: Record<string, number> = { "Additional driver": 10, "Child seat": 8, "Roadside assistance": 6, "Prepaid fuel": 45 };

  const chooseTier = (name: string) => {
    setTier(name);
    if (rentalId) updateRental.mutate({ id: rentalId, data: { protection_tier: name.toLowerCase() } });
  };

  // Each add-on is a rental_charges line (equipment_addon). Without a draft
  // reservation yet (a guest mid-funnel) the selection is carried forward and
  // written as soon as the reservation exists.
  const toggleAddon = (name: string, checked: boolean) => {
    setSelectedAddons((prev) => ({ ...prev, [name]: checked }));
    if (!rentalId) return;
    if (checked) {
      createCharge.mutate(
        { rental_id: rentalId, charge_type: "equipment_addon", description: name, unit_price: addonPrices[name], quantity: 1, amount: addonPrices[name] },
        { onSuccess: (created: any) => { createdAddons.current[name] = created?.id; } },
      );
    } else if (createdAddons.current[name]) {
      deleteCharge.mutate(createdAddons.current[name]);
      delete createdAddons.current[name];
    }
  };

  const continueToCheckout = async () => {
    setError("");
    setSubmitting(true);
    try {
      if (rentalId) {
        navigate("/booking/checkout", { state: { ...state, protection_tier: tier.toLowerCase(), addons: selectedAddons } });
        return;
      }
      const { data } = await api.post("/bookings", {
        vehicle_category_id: state?.vehicle_category_id,
        pickup_datetime: state?.pickup_datetime,
        scheduled_return_datetime: state?.scheduled_return_datetime,
        protection_tier: tier.toLowerCase(),
      });
      navigate("/booking/checkout", { state: { rentalId: data?.rental?.id, charges: data?.charges ?? [], vehicle_category_id: state?.vehicle_category_id, protection_tier: tier.toLowerCase() } });
    } catch (err) {
      setError(errorText(err, "We could not start that reservation."));
    } finally {
      setSubmitting(false);
    }
  };
  return (
    <section className="mx-auto grid max-w-5xl gap-6 lg:grid-cols-[1fr_320px]"><div className="space-y-6"><div className="grid gap-4 sm:grid-cols-3">{tiers.map((item) => <Card key={item.name} onClick={() => chooseTier(item.name)} className={`cursor-pointer ${tier === item.name ? "ring-2 ring-primary" : ""}`}><CardHeader><ShieldCheck className="size-5 text-primary" /><CardTitle>{item.name}</CardTitle></CardHeader><CardContent><p className="text-sm text-muted-foreground">{item.copy}</p><p className="mt-3 font-bold">+${item.price}/day</p></CardContent></Card>)}</div><Card><CardHeader><CardTitle>Add-ons</CardTitle></CardHeader><CardContent className="grid gap-4 sm:grid-cols-2">{addons.map((item) => <label key={item} className="flex items-center gap-3 rounded-lg border p-3"><Checkbox checked={Boolean(selectedAddons[item])} onCheckedChange={(value) => toggleAddon(item, Boolean(value))} /> <span className="text-sm">{item}</span></label>)}</CardContent></Card></div><Card className="h-fit lg:sticky lg:top-24"><CardHeader><CardTitle>Updated total</CardTitle></CardHeader><CardContent><ReservationPriceSummary />{error && <p className="mt-3 text-sm text-destructive">{error}</p>}
<Button className="mt-5 w-full" disabled={submitting} onClick={continueToCheckout}>{submitting ? "Starting reservation…" : "Continue to checkout"}</Button></CardContent></Card></section>
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
