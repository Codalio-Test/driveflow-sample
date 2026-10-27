import BookingProgress from "../components/BookingProgress";
import ReservationPriceSummary from "../components/ReservationPriceSummary";
import React, { useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { useModelIndex } from "@rhino-dev/rhino-react";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";

function BookingSection0() {
  return (
    <section className="mx-auto max-w-5xl"><BookingProgress current={1} /></section>
  );
}

function BookingSection1({ location, from, setFrom, to, setTo }: { location: string; from: string; setFrom: (value: string) => void; to: string; setTo: (value: string) => void }) {
  return (
    <section className="mx-auto max-w-5xl"><Card><CardHeader><CardTitle>Trip details</CardTitle></CardHeader><CardContent className="grid gap-4 sm:grid-cols-3"><div><Label>Pickup</Label><Input className="mt-2" value={location} readOnly /></div><div><Label>From</Label><Input className="mt-2" type="date" value={from} onChange={(event) => setFrom(event.target.value)} /></div><div><Label>To</Label><Input className="mt-2" type="date" value={to} onChange={(event) => setTo(event.target.value)} /></div></CardContent></Card></section>
  );
}

function BookingSection2({ pickup, from, to }: { pickup: string; from: string; to: string }) {
  const navigate = useNavigate();
  const [selected, setSelected] = useState("");
  const { data: response } = useModelIndex("vehicle_categories", { perPage: 24 });
  const images = ["/images/ui-prototype/584b964a859f.jpg", "/images/ui-prototype/1ad0d1427c56.jpg", "/images/ui-prototype/5190050.jpg", "/images/ui-prototype/790722.jpg", "/images/ui-prototype/1400243.jpg", "/images/ui-prototype/8891625.jpg"];
  const vehicles = (response?.data ?? []).map((item: Record<string, any>, index: number) => ({ id: item.id, name: item.name, rate: Number(item.rate ?? item.base_daily_rate ?? 0), image: images[index % images.length] }));
  const activeName = selected || vehicles[0]?.name || "";
  return (
    <section className="mx-auto grid max-w-5xl gap-6 lg:grid-cols-[1fr_320px]"><div className="grid gap-4 sm:grid-cols-2">{vehicles.map((vehicle) => <Card key={vehicle.name} onClick={() => setSelected(vehicle.name)} className={`cursor-pointer overflow-hidden ${activeName === vehicle.name ? "ring-2 ring-primary" : ""}`}><img src={vehicle.image} alt={vehicle.name} className="aspect-video w-full object-cover" /><CardHeader><CardTitle className="text-lg">{vehicle.name}</CardTitle></CardHeader><CardContent><p className="font-bold">${vehicle.rate}/day</p></CardContent></Card>)}</div><Card className="h-fit lg:sticky lg:top-24"><CardHeader><CardTitle>Price summary</CardTitle></CardHeader><CardContent><ReservationPriceSummary /><Button className="mt-6 w-full" disabled={!vehicles.length} onClick={() => navigate("/booking/configure", { state: { vehicle_category_id: vehicles.find((vehicle) => vehicle.name === activeName)?.id, name: activeName, location: pickup, pickup_datetime: `${from}T09:00:00`, scheduled_return_datetime: `${to}T09:00:00` } })}>Continue</Button></CardContent></Card></section>
  );
}

export default function Booking() {
  const { state } = useLocation();
  const [from, setFrom] = useState(state?.date ?? "2025-08-24");
  const [to, setTo] = useState("2025-08-28");
  const pickupLocation = state?.location ?? "Airport Terminal";
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="w-full min-w-0">
        <BookingSection0 />
        <BookingSection1 location={pickupLocation} from={from} setFrom={setFrom} to={to} setTo={setTo} />
        <BookingSection2 pickup={pickupLocation} from={from} to={to} />
      </div>
    </div>
  );
}
