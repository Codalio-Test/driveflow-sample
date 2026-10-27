import InspectionFocusHeader from "../components/InspectionFocusHeader";
import { ArrowLeft, ArrowRight, Camera, CloudOff, Flag, Flashlight, Gauge } from "lucide-react";
import React, { useRef, useState } from "react";
import { api, useModelIndex, useModelShow, useModelStore, useModelUpdate } from "@rhino-dev/rhino-react";
import { useAppOwner } from "@/contexts/AppOwnerProvider";
import { apiPath, errorText, saveDraft, useOrgSlug } from "@/lib/flow";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Progress } from "../components/ui/progress";

function InspectionNewSection0({ vehicle }: { vehicle: string }) {
  return (
    <InspectionFocusHeader title="New walkaround inspection" vehicle={vehicle}/>
  );
}

function InspectionNewSection1({ odometer, setOdometer, fuel, setFuel, photoCount, onCapture }: { odometer: string; setOdometer: (value: string) => void; fuel: string; setFuel: (value: string) => void; photoCount: number; onCapture: () => void }) {
  return (
    <><div><div className="flex justify-between text-sm"><span className="font-medium">Step 1 of 4 · Odometer & fuel</span><span className="text-muted-foreground">25%</span></div><Progress value={25} className="mt-2"/></div><div className="grid gap-4 lg:grid-cols-2"><Card><CardHeader><CardTitle className="flex items-center gap-2"><Gauge className="size-5"/>Vehicle readings</CardTitle></CardHeader><CardContent className="space-y-4"><Input value={odometer} onChange={e=>setOdometer(e.target.value)} type="number" placeholder="Odometer reading"/><div><p className="mb-2 text-sm text-muted-foreground">Fuel level</p><div className="grid grid-cols-4 gap-2">{["1/4","1/2","3/4","Full"].map(item=><Button key={item} variant={fuel===item?"default":"outline"} onClick={()=>setFuel(item)}>{item}</Button>)}</div></div></CardContent></Card><Card><CardHeader><CardTitle className="flex items-center gap-2"><Camera className="size-5"/>Exterior 360°</CardTitle></CardHeader><CardContent><div onClick={onCapture} className="grid aspect-video cursor-pointer place-items-center rounded-lg border-2 border-dashed bg-muted/30 text-muted-foreground"><div className="text-center"><Camera className="mx-auto mb-2 size-8"/><p>Camera ready</p><p className="text-xs">Capture four required angles</p></div></div><div className="mt-3 flex items-center justify-between"><Badge variant="secondary">{photoCount} of 4 captured</Badge><span className="flex items-center gap-1 text-xs text-muted-foreground"><CloudOff className="size-3"/>Offline cache on</span></div></CardContent></Card></div></>
  );
}

function InspectionNewSection2({ onSaveDraft, onNext, notice, busy }: { onSaveDraft: () => void; onNext: () => void; notice: string; busy: boolean }) {
  return (
    <div className="flex items-center justify-between"><Button variant="outline" onClick={onSaveDraft}><ArrowLeft className="size-4"/>Back</Button><div className="flex items-center gap-2">{notice && <span className="text-xs text-muted-foreground">{notice}</span>}<Button variant="ghost" size="icon"><Flashlight className="size-4"/></Button><Button variant="ghost" size="icon"><Flag className="size-4"/></Button><Button disabled={busy} onClick={onNext}>Next <ArrowRight className="size-4"/></Button></div></div>
  );
}

export default function InspectionNew() {
  const orgSlug = useOrgSlug();
  const { user } = useAppOwner();
  const fileRef = useRef<HTMLInputElement>(null);
  const { data: rentals } = useModelIndex("rentals", { filters: { status: "reserved,confirmed" }, includes: ["vehicle"], sort: "pickup_datetime", perPage: 1 });
  const rental = (rentals?.data ?? [])[0] ?? null;
  const { data: liveInspection, refetch } = useModelShow("inspections", inspection?.id);
  const createInspection = useModelStore("inspections");
  const updateInspection = useModelUpdate("inspections");
  const [odometer, setOdometer] = useState("");
  const [fuel, setFuel] = useState("Full");
  const [inspection, setInspection] = useState<Record<string, any> | null>(null);
  const [busy, setBusy] = useState(false);
  const [notice, setNotice] = useState("");

  const fuelPercent = { "1/4": 25, "1/2": 50, "3/4": 75, Full: 100 }[fuel] ?? 100;
  const vehicleLabel = rental ? [rental.vehicle, rental.license_plate].filter(Boolean).join(" • ") : "No vehicle waiting for inspection";

  const persist = () => {
    if (!rental?.id) {
      setNotice("No reservation is waiting for a pickup inspection.");
      return;
    }
    if (!odometer) {
      setNotice("Odometer reading is required.");
      return;
    }
    setBusy(true);
    setNotice("");
    const payload: Record<string, any> = {
      rental_id: rental.id,
      vehicle_id: rental.vehicle_id,
      user_id: user?.id,
      inspection_type: "check_out",
      odometer_reading: Number(odometer),
      fuel_percentage: fuelPercent,
      cleanliness_status: "clean",
      performed_at: new Date().toISOString(),
    };
    const onSuccess = (created: any) => {
      setInspection(created ?? inspection);
      setBusy(false);
      setNotice("Inspection saved. Capture the four required angles.");
    };
    const onError = (err: any) => { setBusy(false); setNotice(errorText(err, "We could not save the inspection.")); };
    if (inspection?.id) updateInspection.mutate({ id: inspection.id, data: payload }, { onSuccess, onError });
    else createInspection.mutate(payload, { onSuccess, onError });
  };

  const capture = async (file?: File) => {
    if (!file) return;
    if (!inspection?.id) {
      setNotice("Save the odometer and fuel readings before capturing photos.");
      return;
    }
    try {
      const body = new FormData();
      body.append("file", file);
      body.append("kind", "inspection_photo");
      body.append("inspection_id", String(inspection.id));
      await api.post(apiPath(orgSlug, "/documents"), body);
      setNotice(`${file.name} attached to the inspection.`);
      refetch();
    } catch (err) {
      setNotice(errorText(err, "The photo could not be uploaded."));
    }
  };

  return (
    <div className="w-full min-w-0 pb-4 overflow-x-hidden">
      <div className="mx-auto max-w-6xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <InspectionNewSection0 vehicle={vehicleLabel} />
        <InspectionNewSection1 odometer={odometer} setOdometer={setOdometer} fuel={fuel} setFuel={setFuel} photoCount={liveInspection?.photo_count ?? inspection?.photo_count ?? 0} onCapture={() => fileRef.current?.click()} />
        <input ref={fileRef} type="file" accept="image/*" capture="environment" className="hidden" onChange={(event) => capture(event.target.files?.[0])} />
        <InspectionNewSection2 onSaveDraft={() => { saveDraft(`inspection-new-${rental?.id ?? "none"}`, { odometer, fuel }); setNotice("Draft saved on this device."); }} onNext={persist} notice={notice} busy={busy} />
      </div>
    </div>
  );
}
