import BookingProgress from "../components/BookingProgress";
import ReservationPriceSummary from "../components/ReservationPriceSummary";
import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";

function BookingSection0() {
  return (
    <section className="mx-auto max-w-5xl"><BookingProgress current={1} /></section>
  );
}

function BookingSection1() {
  return (
    <section className="mx-auto max-w-5xl"><Card><CardHeader><CardTitle>Trip details</CardTitle></CardHeader><CardContent className="grid gap-4 sm:grid-cols-3"><div><Label>Pickup</Label><Input className="mt-2" value="Airport Terminal" readOnly /></div><div><Label>From</Label><Input className="mt-2" type="date" defaultValue="2025-08-24" /></div><div><Label>To</Label><Input className="mt-2" type="date" defaultValue="2025-08-28" /></div></CardContent></Card></section>
  );
}

function BookingSection2() {
  const navigate = useNavigate();
  const [selected, setSelected] = useState("Comfort Sedan");
  const vehicles = [{ name: "Comfort Sedan", rate: 69, image: "/images/ui-prototype/584b964a859f.jpg" }, { name: "Adventure SUV", rate: 89, image: "/images/ui-prototype/1ad0d1427c56.jpg" }];
  return (
    <section className="mx-auto grid max-w-5xl gap-6 lg:grid-cols-[1fr_320px]"><div className="grid gap-4 sm:grid-cols-2">{vehicles.map((vehicle) => <Card key={vehicle.name} onClick={() => setSelected(vehicle.name)} className={`cursor-pointer overflow-hidden ${selected === vehicle.name ? "ring-2 ring-primary" : ""}`}><img src={vehicle.image} alt={vehicle.name} className="aspect-video w-full object-cover" /><CardHeader><CardTitle className="text-lg">{vehicle.name}</CardTitle></CardHeader><CardContent><p className="font-bold">${vehicle.rate}/day</p></CardContent></Card>)}</div><Card className="h-fit lg:sticky lg:top-24"><CardHeader><CardTitle>Price summary</CardTitle></CardHeader><CardContent><ReservationPriceSummary /><Button className="mt-6 w-full" onClick={() => navigate("/booking/configure")}>Continue</Button></CardContent></Card></section>
  );
}

export default function Booking() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="w-full min-w-0">
        <BookingSection0 />
        <BookingSection1 />
        <BookingSection2 />
      </div>
    </div>
  );
}
