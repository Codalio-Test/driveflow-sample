import InspectionFocusHeader from "../components/InspectionFocusHeader";
import { ArrowLeft, ArrowRight, Camera, CloudOff, Flag, Flashlight, Gauge } from "lucide-react";
import React, { useState } from "react";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Progress } from "../components/ui/progress";

function InspectionNewSection0() {
  return (
    <InspectionFocusHeader title="New walkaround inspection" vehicle="2024 Toyota RAV4 • DF-2048 • Stall B12"/>
  );
}

function InspectionNewSection1() {
  const [odometer,setOdometer]=useState("");
  const [fuel,setFuel]=useState("Full");
  return (
    <><div><div className="flex justify-between text-sm"><span className="font-medium">Step 1 of 4 · Odometer & fuel</span><span className="text-muted-foreground">25%</span></div><Progress value={25} className="mt-2"/></div><div className="grid gap-4 lg:grid-cols-2"><Card><CardHeader><CardTitle className="flex items-center gap-2"><Gauge className="size-5"/>Vehicle readings</CardTitle></CardHeader><CardContent className="space-y-4"><Input value={odometer} onChange={e=>setOdometer(e.target.value)} type="number" placeholder="Odometer reading"/><div><p className="mb-2 text-sm text-muted-foreground">Fuel level</p><div className="grid grid-cols-4 gap-2">{["1/4","1/2","3/4","Full"].map(item=><Button key={item} variant={fuel===item?"default":"outline"} onClick={()=>setFuel(item)}>{item}</Button>)}</div></div></CardContent></Card><Card><CardHeader><CardTitle className="flex items-center gap-2"><Camera className="size-5"/>Exterior 360°</CardTitle></CardHeader><CardContent><div className="grid aspect-video place-items-center rounded-lg border-2 border-dashed bg-muted/30 text-muted-foreground"><div className="text-center"><Camera className="mx-auto mb-2 size-8"/><p>Camera ready</p><p className="text-xs">Capture four required angles</p></div></div><div className="mt-3 flex items-center justify-between"><Badge variant="secondary">0 of 4 captured</Badge><span className="flex items-center gap-1 text-xs text-muted-foreground"><CloudOff className="size-3"/>Offline cache on</span></div></CardContent></Card></div></>
  );
}

function InspectionNewSection2() {
  return (
    <div className="flex items-center justify-between"><Button variant="outline"><ArrowLeft className="size-4"/>Back</Button><div className="flex gap-2"><Button variant="ghost" size="icon"><Flashlight className="size-4"/></Button><Button variant="ghost" size="icon"><Flag className="size-4"/></Button><Button>Next <ArrowRight className="size-4"/></Button></div></div>
  );
}

export default function InspectionNew() {
  return (
    <div className="w-full min-w-0 pb-4 overflow-x-hidden">
      <div className="mx-auto max-w-6xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <InspectionNewSection0 />
        <InspectionNewSection1 />
        <InspectionNewSection2 />
      </div>
    </div>
  );
}
