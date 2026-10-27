import InspectionFocusHeader from "../components/InspectionFocusHeader";
import PhotoEvidenceMetadata from "../components/PhotoEvidenceMetadata";
import { ArrowLeft, Camera, Check, Flag, Flashlight, MapPin } from "lucide-react";
import React, { useRef, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { api, useModelIndex, useModelShow, useModelStore } from "@rhino-dev/rhino-react";
import { useAppOwner } from "@/contexts/AppOwnerProvider";
import { apiPath, errorText, saveDraft, useOrgSlug } from "@/lib/flow";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Card, CardContent } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { Progress } from "../components/ui/progress";

function InspectionReturnSection0({ vehicle }: { vehicle: string }) {
  return (
    <InspectionFocusHeader title="Return inspection" vehicle={vehicle}/>
  );
}

function InspectionReturnSection1({ angle, setAngle, images, odometer, setOdometer, fuel, setFuel, onCapture, onMarkDamage }: { angle: number; setAngle: (value: number) => void; images: string[]; odometer: string; setOdometer: (value: string) => void; fuel: string; setFuel: (value: string) => void; onCapture: () => void; onMarkDamage: () => void }) {
  const angles=["Front","Driver Side","Rear","Passenger Side"];
  return (
    <><div><div className="flex justify-between text-sm"><span className="font-medium">Step 2 of 4 · Exterior comparison</span><span className="text-muted-foreground">50%</span></div><Progress value={50} className="mt-2"/></div><div className="flex flex-wrap gap-2">{angles.map((item,i)=><Button key={item} size="sm" variant={angle===i?"default":"outline"} onClick={()=>setAngle(i)}>{item}</Button>)}</div><div className="grid gap-4 lg:grid-cols-2">{[{label:"Departure",src:images[angle]},{label:"Return",src:images[(angle+1)%images.length]}].map(item=><Card key={item.label}><CardContent className="p-3"><div className="mb-3 flex items-center justify-between"><Badge variant="secondary">{item.label}</Badge><span className="flex items-center gap-1 text-xs text-muted-foreground"><MapPin className="size-3"/>Downtown lot</span></div><img src={item.src} alt={`${item.label} vehicle evidence`} className="aspect-video w-full rounded-lg object-cover"/><div className="mt-3"><PhotoEvidenceMetadata/></div></CardContent></Card>)}</div><div className="flex flex-wrap items-end gap-3 rounded-lg border p-3"><div className="min-w-44 flex-1"><Label htmlFor="return-odometer" className="text-xs font-semibold text-muted-foreground">RETURN ODOMETER</Label><Input id="return-odometer" className="mt-2" type="number" value={odometer} onChange={(event) => setOdometer(event.target.value)} placeholder="Odometer reading" /></div><div><p className="mb-2 text-xs font-semibold text-muted-foreground">FUEL LEVEL</p><div className="flex gap-2">{["1/4","1/2","3/4","Full"].map((item) => <Button key={item} size="sm" variant={fuel === item ? "default" : "outline"} onClick={() => setFuel(item)}>{item}</Button>)}</div></div></div><div className="flex flex-wrap gap-2"><Button onClick={onCapture}><Camera className="size-4"/>Capture return photo</Button><Button variant="outline" onClick={onMarkDamage}>Mark new damage</Button><Button variant="ghost" onClick={() => saveDraft(`inspection-return-${angle}`, { odometer, fuel })}>Save draft</Button></div></>
  );
}

function InspectionReturnSection2({ onComplete, busy, notice }: { onComplete: () => void; busy: boolean; notice: string }) {
  const navigate = useNavigate();
  return (
    <div className="flex items-center justify-between gap-2"><Button variant="outline" onClick={() => navigate("/counter/returns")}><ArrowLeft className="size-4"/>Back</Button><div className="flex items-center gap-2">{notice && <span className="text-xs text-muted-foreground">{notice}</span>}<Button variant="ghost" size="icon" aria-label="Flashlight"><Flashlight className="size-4"/></Button><Button variant="ghost" size="icon" aria-label="Flag note"><Flag className="size-4"/></Button><Button disabled={busy} onClick={onComplete}><Check className="size-4"/>Complete & review</Button></div></div>
  );
}

export default function InspectionReturn() {
  const { rentalId } = useParams();
  const orgSlug = useOrgSlug();
  const { user } = useAppOwner();
  const fileRef = useRef<HTMLInputElement>(null);
  const { data: rental } = useModelShow("rentals", rentalId);
  const comparison = useQuery({ queryKey: ["inspectionComparison", rentalId], enabled: Boolean(orgSlug && rentalId), queryFn: async () => (await api.get(apiPath(orgSlug, `/rentals/${rentalId}/inspection_comparison`))).data });
  const { data: inspections } = useModelIndex("inspections", { filters: { rental_id: rentalId }, perPage: 25 });
  const createInspection = useModelStore("inspections");
  const createDamage = useModelStore("damage_records");
  const [angle, setAngle] = useState(0);
  const [odometer, setOdometer] = useState("");
  const [fuel, setFuel] = useState("Full");
  const [busy, setBusy] = useState(false);
  const [notice, setNotice] = useState("");

  const placeholders = ["/images/ui-prototype/8891625.jpg", "/images/ui-prototype/5190050.jpg", "/images/ui-prototype/1400243.jpg", "/images/ui-prototype/790722.jpg"];
  const departurePhotos = (comparison.data?.departure?.attachments ?? []).map((item: Record<string, any>) => item.photo_url).filter(Boolean);
  const returnPhotos = (comparison.data?.return?.attachments ?? []).map((item: Record<string, any>) => item.photo_url).filter(Boolean);
  const images = [departurePhotos[angle] ?? placeholders[angle], returnPhotos[angle] ?? placeholders[(angle + 1) % placeholders.length]];
  const existingReturn = (inspections?.data ?? []).find((item: Record<string, any>) => item.inspection_type === "check_in") ?? null;
  const vehicleLabel = rental ? [rental.vehicle, rental.license_plate].filter(Boolean).join(" • ") : "Vehicle on return";
  const fuelPercent = { "1/4": 25, "1/2": 50, "3/4": 75, Full: 100 }[fuel] ?? 100;

  const ensureInspection = () => new Promise<Record<string, any> | null>((resolve) => {
    if (existingReturn?.id) {
      resolve(existingReturn);
      return;
    }
    if (!rental?.id) {
      setNotice("This return has no rental to record against.");
      resolve(null);
      return;
    }
    createInspection.mutate(
      {
        rental_id: rental.id,
        vehicle_id: rental.vehicle_id,
        user_id: user?.id,
        inspection_type: "check_in",
        odometer_reading: odometer ? Number(odometer) : rental.final_odometer,
        fuel_percentage: fuelPercent,
        cleanliness_status: "clean",
        performed_at: new Date().toISOString(),
      },
      {
        onSuccess: (created: any) => resolve(created ?? null),
        onError: (err: any) => { setNotice(errorText(err, "We could not save the return inspection.")); resolve(null); },
      },
    );
  });

  const capture = async (file?: File) => {
    if (!file) return;
    const inspection = await ensureInspection();
    if (!inspection?.id) return;
    try {
      const body = new FormData();
      body.append("file", file);
      body.append("kind", "inspection_photo");
      body.append("inspection_id", String(inspection.id));
      await api.post(apiPath(orgSlug, "/documents"), body);
      setNotice(`${file.name} attached to the return evidence.`);
      comparison.refetch();
    } catch (err) {
      setNotice(errorText(err, "The photo could not be uploaded."));
    }
  };

  const markDamage = async () => {
    const inspection = await ensureInspection();
    if (!inspection?.id) return;
    createDamage.mutate(
      {
        inspection_id: inspection.id,
        vehicle_id: rental?.vehicle_id,
        panel_location: ["front_bumper", "driver_side", "rear_bumper", "passenger_side"][angle],
        severity: "minor_scratch",
        description: `New damage reported on the ${["front", "driver side", "rear", "passenger side"][angle]} during the return walkaround.`,
        is_pre_existing: false,
      },
      {
        onSuccess: () => { setNotice("New damage marked on the return walkaround."); comparison.refetch(); },
        onError: (err: any) => setNotice(errorText(err, "The damage record could not be saved.")),
      },
    );
  };

  const complete = async () => {
    setBusy(true);
    const inspection = await ensureInspection();
    setBusy(false);
    if (inspection?.id) navigate(`/counter/settlement/${rentalId}`);
  };

  const navigate = useNavigate();

  return (
    <div className="w-full min-w-0 pb-4 overflow-x-hidden">
      <div className="mx-auto max-w-6xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <InspectionReturnSection0 vehicle={vehicleLabel} />
        <InspectionReturnSection1 angle={angle} setAngle={setAngle} images={images} odometer={odometer} setOdometer={setOdometer} fuel={fuel} setFuel={setFuel} onCapture={() => fileRef.current?.click()} onMarkDamage={markDamage} />
        <input ref={fileRef} type="file" accept="image/*" capture="environment" className="hidden" onChange={(event) => capture(event.target.files?.[0])} />
        <InspectionReturnSection2 onComplete={complete} busy={busy} notice={notice} />
      </div>
    </div>
  );
}
