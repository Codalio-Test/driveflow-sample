import DepositStatusBadge from "../components/DepositStatusBadge";
import { CalendarDays, CreditCard, UserRound } from "lucide-react";
import React from "react";
import { useNavigate } from "react-router-dom";
import { useModelIndex, useModelShow } from "@rhino-dev/rhino-react";
import { useAppOwner } from "@/contexts/AppOwnerProvider";
import { apiPath, downloadFile, money, useOrgSlug } from "@/lib/flow";
import { Avatar, AvatarFallback } from "../components/ui/avatar";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";

function AccountDashboardSection0({ user }: { user?: Record<string, any> | null }) {
  const name = user?.full_name || user?.name || [user?.first_name, user?.last_name].filter(Boolean).join(" ") || "";
  const initials = name.trim().split(/[\s@._-]+/).filter(Boolean).slice(0, 2).map((part: string) => part[0]).join("").toUpperCase() || "DF";
  return (
    <section className="mx-auto flex max-w-5xl items-center gap-4"><Avatar className="size-14"><AvatarFallback>{initials}</AvatarFallback></Avatar><div><h1 className="text-3xl font-bold">Welcome back{name ? `, ${name.split(" ")[0]}` : ""}</h1><div className="mt-2 flex gap-2"><Badge>Identity verified</Badge><Badge variant="secondary">License current</Badge></div></div></section>
  );
}

function AccountDashboardSection1({ upcoming, isLoading }: { upcoming: Record<string, any> | null; isLoading: boolean }) {
  const navigate = useNavigate();
  const orgSlug = useOrgSlug();
  const { data: rental } = useModelShow("rentals", upcoming?.id);
  return (
    <section className="mx-auto max-w-5xl"><Card><CardHeader><CardTitle>Upcoming rental</CardTitle></CardHeader><CardContent className="flex flex-col justify-between gap-4 sm:flex-row sm:items-end">{upcoming ? <div><p className="font-semibold">{upcoming.category ?? upcoming.vehicle ?? "Vehicle"} • {upcoming.reference ?? upcoming.reservation_number}</p><p className="mt-1 text-sm text-muted-foreground">{upcoming.dates ?? ""}{upcoming.due ? ` • ${upcoming.due}` : ""}</p></div> : <div><p className="font-semibold">{isLoading ? "Loading your bookings…" : "No upcoming rental"}</p><p className="mt-1 text-sm text-muted-foreground">{isLoading ? "" : "Reserve a vehicle to see it here."}</p></div>}<div className="flex gap-2"><Button variant="outline" disabled={!upcoming} onClick={() => upcoming && downloadFile(apiPath(orgSlug, `/rentals/${upcoming.id}/receipt`), `driveflow-voucher-${upcoming.id}.pdf`)}>Pickup details</Button><Button disabled={!upcoming} onClick={() => navigate(upcoming ? "/account/bookings" : "/vehicles")}>Manage booking</Button></div></CardContent></Card></section>
  );
}

function AccountDashboardSection2() {
  const navigate = useNavigate();
  const actions = [{ label: "My Bookings", to: "/account/bookings", icon: CalendarDays }, { label: "Billing", to: "/account/billing", icon: CreditCard }, { label: "Profile and Verification", to: "/account/profile", icon: UserRound }];
  return (
    <section className="mx-auto grid max-w-5xl gap-4 sm:grid-cols-3">{actions.map((item) => <Card key={item.label} className="cursor-pointer transition-shadow hover:shadow-md" onClick={() => navigate(item.to)}><CardContent className="flex items-center gap-3 p-5"><item.icon className="size-5 text-primary" /><span className="font-medium">{item.label}</span></CardContent></Card>)}</section>
  );
}

function AccountDashboardSection3({ payment }: { payment: Record<string, any> | null }) {
  return (
    <section className="mx-auto max-w-5xl"><Card><CardHeader><CardTitle>Latest deposit activity</CardTitle></CardHeader><CardContent className="flex items-center justify-between"><div><p className="font-medium">{payment ? money(payment.amount) : "No deposit activity yet"}</p><p className="text-sm text-muted-foreground">{payment ? `${payment.type ?? payment.transaction_type ?? "Deposit"} • ${payment.last4 ? `ending ${payment.last4}` : "card on file"} • ${payment.date ?? ""}` : "Deposits appear here after your first rental."}</p></div><DepositStatusBadge status={payment?.status === "succeeded" ? "Secured" : payment?.status ?? "Pending"} /></CardContent></Card></section>
  );
}

export default function AccountDashboard() {
  const { user } = useAppOwner();
  const { data: rentals, isLoading } = useModelIndex("rentals", { filters: { status: "confirmed,reserved" }, sort: "pickup_datetime", perPage: 1 });
  const { data: payments } = useModelIndex("payments", { sort: "-processed_at", perPage: 1 });
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="w-full min-w-0">
        <AccountDashboardSection0 user={user} />
        <AccountDashboardSection1 upcoming={(rentals?.data ?? [])[0] ?? null} isLoading={isLoading} />
        <AccountDashboardSection2 />
        <AccountDashboardSection3 payment={(payments?.data ?? [])[0] ?? null} />
      </div>
    </div>
  );
}
