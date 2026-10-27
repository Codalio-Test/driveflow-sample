import InspectionFocusHeader from "../components/InspectionFocusHeader";
import PhotoEvidenceMetadata from "../components/PhotoEvidenceMetadata";
import { ArrowLeft, Camera, Check, Flag, Flashlight, MapPin } from "lucide-react";
import React, { useState } from "react";
import { useParams } from "react-router-dom";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Card, CardContent } from "../components/ui/card";
import { Progress } from "../components/ui/progress";

function InspectionReturnSection0() {
  return (
    <InspectionFocusHeader title="Return inspection" vehicle="2024 Toyota RAV4 • DF-2048 • Stall B12"/>
  );
}

function InspectionReturnSection1() {
  const [angle,setAngle]=useState(0);
  const angles=["Front","Driver Side","Rear","Passenger Side"];
  const images=["/images/ui-prototype/8891625.jpg","/images/ui-prototype/5190050.jpg","/images/ui-prototype/1400243.jpg","/images/ui-prototype/790722.jpg"];
  return (
    <><div><div className="flex justify-between text-sm"><span className="font-medium">Step 2 of 4 · Exterior comparison</span><span className="text-muted-foreground">50%</span></div><Progress value={50} className="mt-2"/></div><div className="flex flex-wrap gap-2">{angles.map((item,i)=><Button key={item} size="sm" variant={angle===i?"default":"outline"} onClick={()=>setAngle(i)}>{item}</Button>)}</div><div className="grid gap-4 lg:grid-cols-2">{[{label:"Departure",src:images[angle]},{label:"Return",src:images[(angle+1)%images.length]}].map(item=><Card key={item.label}><CardContent className="p-3"><div className="mb-3 flex items-center justify-between"><Badge variant="secondary">{item.label}</Badge><span className="flex items-center gap-1 text-xs text-muted-foreground"><MapPin className="size-3"/>Downtown lot</span></div><img src={item.src} alt={`${item.label} vehicle evidence`} className="aspect-video w-full rounded-lg object-cover"/><div className="mt-3"><PhotoEvidenceMetadata/></div></CardContent></Card>)}</div><div className="flex flex-wrap gap-2"><Button><Camera className="size-4"/>Capture return photo</Button><Button variant="outline">Mark new damage</Button><Button variant="ghost">Save draft</Button></div></>
  );
}

function InspectionReturnSection2() {
  return (
    <div className="flex items-center justify-between gap-2"><Button variant="outline"><ArrowLeft className="size-4"/>Back</Button><div className="flex gap-2"><Button variant="ghost" size="icon" aria-label="Flashlight"><Flashlight className="size-4"/></Button><Button variant="ghost" size="icon" aria-label="Flag note"><Flag className="size-4"/></Button><Button><Check className="size-4"/>Complete & review</Button></div></div>
  );
}

export default function InspectionReturn() {
  return (
    <div className="w-full min-w-0 pb-4 overflow-x-hidden">
      <div className="mx-auto max-w-6xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <InspectionReturnSection0 />
        <InspectionReturnSection1 />
        <InspectionReturnSection2 />
      </div>
    </div>
  );
}
