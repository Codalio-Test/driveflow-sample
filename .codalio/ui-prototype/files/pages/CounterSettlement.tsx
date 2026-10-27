import FinancialFormulaBreakdown from "../components/FinancialFormulaBreakdown";
import { AlertTriangle, CheckCircle2 } from "lucide-react";
import React, { useState } from "react";
import { useParams } from "react-router-dom";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";

function CounterSettlementSection0() {
  const {rentalId}=useParams();
  const metrics=[{label:"Return time",value:"11:42 AM",delta:"+1h 42m",flag:true},{label:"Odometer",value:"28,442 mi",delta:"+384 mi",flag:false},{label:"Fuel",value:"5/8 tank",delta:"-3/8 tank",flag:true},{label:"Damage",value:"1 new mark",delta:"Review",flag:true}];
  return (
    <><div><p className="text-sm font-medium text-primary">Settlement</p><h1 className="text-3xl font-bold">Return comparison · {rentalId||"RNT-8817"}</h1></div><div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">{metrics.map(item=><Card key={item.label}><CardContent className="p-5"><div className="flex items-center justify-between"><p className="text-sm text-muted-foreground">{item.label}</p>{item.flag&&<AlertTriangle className="size-4 text-amber-500"/>}</div><p className="mt-2 text-xl font-semibold">{item.value}</p><Badge variant="outline" className="mt-2">{item.delta}</Badge></CardContent></Card>)}</div></>
  );
}

function CounterSettlementSection1() {
  const [finalized,setFinalized]=useState(false);
  return (
    <><div className="space-y-4"><FinancialFormulaBreakdown items={[{label:"Late return",formula:"1.7 hr × $18 = $30.60"},{label:"Fuel replacement",formula:"3 gal × $8 = $24.00"},{label:"Damage recovery",formula:"Assessment pending"}]} total="$54.60"/><Button onClick={()=>setFinalized(true)} disabled={finalized}>{finalized?<><CheckCircle2 className="size-4"/>Settlement finalized</>:"Finalize settlement"}</Button></div><Card><CardHeader><CardTitle>Deposit settlement</CardTitle></CardHeader><CardContent className="space-y-4"><div className="flex items-center justify-between"><span className="text-sm text-muted-foreground">Authorization</span><Badge>Held</Badge></div><p className="text-3xl font-bold">$500.00</p><div className="text-sm"><p className="flex justify-between"><span>Capture</span><span>$54.60</span></p><p className="mt-2 flex justify-between"><span>Release</span><span>$445.40</span></p></div><Button variant="outline" className="w-full">Process with Stripe</Button></CardContent></Card></>
  );
}

export default function CounterSettlement() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-7xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <CounterSettlementSection0 />
        <CounterSettlementSection1 />
      </div>
    </div>
  );
}
