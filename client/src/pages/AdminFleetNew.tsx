import { Save } from "lucide-react";
import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { api, useModelIndex, useModelStore } from "@rhino-dev/rhino-react";
import { apiPath, errorText, saveDraft, useOrgSlug } from "@/lib/flow";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../components/ui/select";

function AdminFleetNewSection0({ form, setField, categories, locations, submitting, error, notice, onCreate, onUpload, onSaveDraft }: { form: Record<string, any>; setField: (key: string, value: string) => void; categories: Record<string, any>[]; locations: Record<string, any>[]; submitting: boolean; error: string; notice: string; onCreate: () => void; onUpload: (file?: File) => void; onSaveDraft: () => void }) {
  const vin = form.vin;
  const navigate = useNavigate();
  return (
    <><div><p className="text-sm font-medium text-primary">Fleet inventory</p><h1 className="text-3xl font-bold">Add vehicle</h1><p className="text-muted-foreground">Create a fleet record and maintenance baseline.</p></div><Card><CardHeader><CardTitle>Vehicle details</CardTitle></CardHeader><CardContent className="grid gap-5 lg:grid-cols-2"><div className="space-y-2"><Label>VIN</Label><Input value={vin} onChange={e=>setField("vin", e.target.value)} placeholder="17-character VIN"/></div><div className="space-y-2"><Label>License plate</Label><Input value={form.license_plate} onChange={e=>setField("license_plate", e.target.value)} placeholder="DF-0000"/></div><div className="space-y-2"><Label>Make and model</Label><Input value={form.make_model} onChange={e=>setField("make_model", e.target.value)} placeholder="Toyota RAV4"/></div><div className="space-y-2"><Label>Model year</Label><Input type="number" value={form.year} onChange={e=>setField("year", e.target.value)} placeholder="2024"/></div><div className="space-y-2"><Label>Category</Label><Select value={String(form.vehicle_category_id ?? "")} onValueChange={(value) => setField("vehicle_category_id", value)}><SelectTrigger><SelectValue placeholder="Select class"/></SelectTrigger><SelectContent>{categories.map((category) => <SelectItem key={category.id} value={String(category.id)}>{category.name}</SelectItem>)}</SelectContent></Select></div><div className="space-y-2"><Label>Home location</Label><Select value={String(form.location_id ?? "")} onValueChange={(value) => setField("location_id", value)}><SelectTrigger><SelectValue placeholder="Select location"/></SelectTrigger><SelectContent>{locations.map((location) => <SelectItem key={location.id} value={String(location.id)}>{location.name}</SelectItem>)}</SelectContent></Select></div><div className="space-y-2"><Label>Registration document</Label><input type="file" accept="application/pdf,image/png,image/jpeg" className="block w-full text-sm text-muted-foreground" onChange={(event) => onUpload(event.target.files?.[0])} />{notice && <p className="text-xs text-muted-foreground">{notice}</p>}</div><div className="space-y-2"><Label>Current odometer</Label><Input type="number" value={form.current_odometer} onChange={e=>setField("current_odometer", e.target.value)} placeholder="0"/></div></CardContent></Card>{error && <p className="text-sm text-destructive">{error}</p>}<div className="flex justify-end gap-2"><Button variant="outline" onClick={onSaveDraft}>Save draft</Button><Button disabled={!vin || submitting} onClick={onCreate}><Save className="size-4"/>{submitting ? "Adding…" : "Add vehicle"}</Button></div></>
  );
}

export default function AdminFleetNew() {
  const navigate = useNavigate();
  const orgSlug = useOrgSlug();
  const { data: categories } = useModelIndex("vehicle_categories", { perPage: 50 });
  const { data: locations } = useModelIndex("locations", { perPage: 50 });
  const createVehicle = useModelStore("vehicles");
  const [form, setForm] = useState<Record<string, any>>({ vin: "", license_plate: "", make_model: "", year: "", vehicle_category_id: "", location_id: "", current_odometer: "" });
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const setField = (key: string, value: string) => setForm((prev) => ({ ...prev, [key]: value }));

  const create = () => {
    setError("");
    const parts = String(form.make_model).trim().split(/\s+/);
    const make = parts.shift() ?? "";
    createVehicle.mutate(
      {
        vin: form.vin,
        license_plate: form.license_plate,
        make,
        model: parts.join(" ") || make,
        year: form.year ? Number(form.year) : undefined,
        vehicle_category_id: form.vehicle_category_id ? Number(form.vehicle_category_id) : undefined,
        location_id: form.location_id ? Number(form.location_id) : undefined,
        current_odometer: form.current_odometer ? Number(form.current_odometer) : 0,
        fuel_percentage: 100,
        status: "available",
      },
      {
        onSuccess: () => navigate("/admin/fleet"),
        onError: (err: any) => setError(errorText(err, "That VIN or license plate is already registered.")),
      },
    );
  };

  const upload = async (file?: File) => {
    if (!file) return;
    setNotice(`${file.name} uploading…`);
    try {
      const body = new FormData();
      body.append("file", file);
      body.append("kind", "registration_document");
      await api.post(apiPath(orgSlug, "/documents"), body);
      setNotice(`${file.name} uploaded.`);
    } catch (err) {
      setNotice(errorText(err, "The document could not be uploaded."));
    }
  };

  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-5xl p-4 md:p-6 w-full min-w-0">
        <AdminFleetNewSection0 form={form} setField={setField} categories={categories?.data ?? []} locations={locations?.data ?? []} submitting={createVehicle.isPending} error={error} notice={notice} onCreate={create} onUpload={upload} onSaveDraft={() => { saveDraft("fleet-new", form); setNotice("Draft saved on this device."); }} />
      </div>
    </div>
  );
}
