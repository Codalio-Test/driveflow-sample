import FinancialFormulaBreakdown from "../components/FinancialFormulaBreakdown";
import { AlertTriangle, MessageSquare, Phone } from "lucide-react";
import React, { useState } from "react";
import { useParams } from "react-router-dom";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Textarea } from "../components/ui/textarea";

function AdminRentalOverdueSection0() {
  const {rentalId}=useParams();
  return (
    <Card className="border-destructive/40"><CardContent className="flex flex-col gap-5 p-6 md:flex-row md:items-center md:justify-between"><div className="flex gap-4"><span className="grid size-12 place-items-center rounded-full bg-destructive/10 text-destructive"><AlertTriangle className="size-6"/></span><div><Badge variant="destructive">Critical overdue</Badge><h1 className="mt-2 text-3xl font-bold">2h 14m overdue</h1><p className="text-muted-foreground">{rentalId||"RNT-8817"} · Sophia Turner · Toyota Camry DF-2011</p><p className="text-sm text-muted-foreground">60-minute grace period exceeded at 9:00 AM</p></div></div><div className="flex gap-2"><Button variant="outline"><Phone className="size-4"/>Call</Button><Button><MessageSquare className="size-4"/>Message</Button></div></CardContent></Card>
  );
}

function AdminRentalOverdueSection1() {
  const [note,setNote]=useState("");
  const events=[{time:"11:14",label:"Automatic SMS sent",detail:"Delivery confirmed"},{time:"10:45",label:"Payment retry failed",detail:"Card declined"},{time:"9:00",label:"Grace period ended",detail:"Penalty accrual started"}];
  return (
    <><div className="space-y-4"><FinancialFormulaBreakdown items={[{label:"Billable overdue",formula:"1.23 hr after grace"},{label:"Hourly penalty",formula:"1.23 × $18 = $22.14"},{label:"Daily cap",formula:"$79.00 maximum"}]} total="$22.14"/><Card><CardHeader><CardTitle>Recovery note</CardTitle></CardHeader><CardContent className="space-y-3"><Textarea value={note} onChange={e=>setNote(e.target.value)} placeholder="Log contact attempts and commitments…"/><Button disabled={!note}>Add note</Button></CardContent></Card></div><Card><CardHeader><CardTitle>Activity timeline</CardTitle></CardHeader><CardContent className="space-y-5">{events.map(e=><div key={e.time} className="border-l-2 border-border pl-3"><div className="flex justify-between"><p className="text-sm font-medium">{e.label}</p><Badge variant="outline">{e.time}</Badge></div><p className="text-xs text-muted-foreground">{e.detail}</p></div>)}<Button variant="destructive" className="w-full">Escalate case</Button></CardContent></Card></>
  );
}

export default function AdminRentalOverdue() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-7xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <AdminRentalOverdueSection0 />
        <AdminRentalOverdueSection1 />
      </div>
    </div>
  );
}
