import DepositStatusBadge from "../components/DepositStatusBadge";
import { CalendarDays, CreditCard, UserRound } from "lucide-react";
import React from "react";
import { useNavigate } from "react-router-dom";
import { Avatar, AvatarFallback } from "../components/ui/avatar";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";

function AccountDashboardSection0() {
  return (
    <section className="mx-auto flex max-w-5xl items-center gap-4"><Avatar className="size-14"><AvatarFallback>AM</AvatarFallback></Avatar><div><h1 className="text-3xl font-bold">Welcome back, Alex</h1><div className="mt-2 flex gap-2"><Badge>Identity verified</Badge><Badge variant="secondary">License current</Badge></div></div></section>
  );
}

function AccountDashboardSection1() {
  return (
    <section className="mx-auto max-w-5xl"><Card><CardHeader><CardTitle>Upcoming rental</CardTitle></CardHeader><CardContent className="flex flex-col justify-between gap-4 sm:flex-row sm:items-end"><div><p className="font-semibold">Comfort Sedan • DF-82941</p><p className="mt-1 text-sm text-muted-foreground">Aug 24, 9:00 AM • Airport Terminal</p></div><div className="flex gap-2"><Button variant="outline">Pickup details</Button><Button>Manage booking</Button></div></CardContent></Card></section>
  );
}

function AccountDashboardSection2() {
  const navigate = useNavigate();
  const actions = [{ label: "My Bookings", to: "/account/bookings", icon: CalendarDays }, { label: "Billing", to: "/account/billing", icon: CreditCard }, { label: "Profile and Verification", to: "/account/profile", icon: UserRound }];
  return (
    <section className="mx-auto grid max-w-5xl gap-4 sm:grid-cols-3">{actions.map((item) => <Card key={item.label} className="cursor-pointer transition-shadow hover:shadow-md" onClick={() => navigate(item.to)}><CardContent className="flex items-center gap-3 p-5"><item.icon className="size-5 text-primary" /><span className="font-medium">{item.label}</span></CardContent></Card>)}</section>
  );
}

function AccountDashboardSection3() {
  return (
    <section className="mx-auto max-w-5xl"><Card><CardHeader><CardTitle>Latest deposit activity</CardTitle></CardHeader><CardContent className="flex items-center justify-between"><div><p className="font-medium">$300.00 pre-authorization</p><p className="text-sm text-muted-foreground">Visa ending 4242 • Aug 22</p></div><DepositStatusBadge status="Secured" /></CardContent></Card></section>
  );
}

export default function AccountDashboard() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="w-full min-w-0">
        <AccountDashboardSection0 />
        <AccountDashboardSection1 />
        <AccountDashboardSection2 />
        <AccountDashboardSection3 />
      </div>
    </div>
  );
}
