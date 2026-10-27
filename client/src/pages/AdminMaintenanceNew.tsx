import { Wrench } from "lucide-react";
import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useModelIndex, useModelStore } from "@rhino-dev/rhino-react";
import { useAppOwner } from "@/contexts/AppOwnerProvider";
import { errorText, saveDraft } from "@/lib/flow";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../components/ui/select";
import { Textarea } from "../components/ui/textarea";

function AdminMaintenanceNewSection0({ form, setField, vehicles, onSubmit, onSaveDraft, submitting, error, notice }: { form: Record<string, any>; setField: (key: string, value: string) => void; vehicles: Record<string, any>[]; onSubmit: () => void; onSaveDraft: () => void; submitting: boolean; error: string; notice: string }) {
  const vehicle = form.vehicle_id;
  const navigate=useNavigate();
  return (
    <><div><p className="text-sm font-medium text-primary">Maintenance</p><h1 className="text-3xl font-bold">New work order</h1><p className="text-muted-foreground">Schedule service and record the estimated cost.</p></div><Card><CardHeader><CardTitle className="flex items-center gap-2"><Wrench className="size-5"/>Work order details</CardTitle></CardHeader><CardContent className="grid gap-5 md:grid-cols-2"><div className="space-y-2"><Label>Vehicle</Label><Select value={String(vehicle ?? "")} onValueChange={(value) => setField("vehicle_id", value)}><SelectTrigger><SelectValue placeholder="Select vehicle"/></SelectTrigger><SelectContent>{vehicles.map((item) => <SelectItem key={item.id} value={String(item.id)}>{`${item.plate ?? item.name} · ${item.name ?? ""}`}</SelectItem>)}</SelectContent></Select></div><div className="space-y-2"><Label>Service type</Label><Input value={form.service_type} onChange={(e) => setField("service_type", e.target.value)} placeholder="Oil & filter"/></div><div className="space-y-2"><Label>Priority</Label><Select><SelectTrigger><SelectValue placeholder="Select priority"/></SelectTrigger><SelectContent><SelectItem value="routine">Routine</SelectItem><SelectItem value="high">High</SelectItem><SelectItem value="critical">Critical</SelectItem></SelectContent></Select></div><div className="space-y-2"><Label>Odometer</Label><Input type="number" value={form.odometer_at_service} onChange={(e) => setField("odometer_at_service", e.target.value)} placeholder="42120"/></div><div className="space-y-2"><Label>Vendor</Label><Input value={form.vendor_name} onChange={(e) => setField("vendor_name", e.target.value)} placeholder="Preferred service partner"/></div><div className="space-y-2"><Label>Scheduled date</Label><Input type="date" value={form.service_date} onChange={(e) => setField("service_date", e.target.value)}/></div><div className="space-y-2"><Label>Estimate</Label><Input type="number" value={form.cost} onChange={(e) => setField("cost", e.target.value)} placeholder="0.00"/></div><div className="space-y-2 md:col-span-2"><Label>Notes</Label><Textarea value={form.notes} onChange={(e) => setField("notes", e.target.value)} placeholder="Service instructions and observed issues"/></div></CardContent></Card>{error && <p className="text-sm text-destructive">{error}</p>}{notice && <p className="text-sm text-muted-foreground">{notice}</p>}<div className="flex justify-end gap-2"><Button variant="outline" onClick={onSaveDraft}>Save draft</Button><Button disabled={!vehicle || submitting} onClick={onSubmit}>{submitting ? "Creating…" : "Create work order"}</Button></div></>
  );
}

export default function AdminMaintenanceNew() {
  const navigate = useNavigate();
  const { user } = useAppOwner();
  const { data: vehicles } = useModelIndex("vehicles", { perPage: 100 });
  const createLog = useModelStore("vehicle_maintenance_logs");
  const [form, setForm] = useState<Record<string, any>>({ vehicle_id: "", service_type: "", priority: "", odometer_at_service: "", vendor_name: "", service_date: "", cost: "", notes: "" });
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const setField = (key: string, value: string) => setForm((prev) => ({ ...prev, [key]: value }));

  const submit = () => {
    setError("");
    createLog.mutate(
      {
        vehicle_id: form.vehicle_id ? Number(form.vehicle_id) : undefined,
        user_id: user?.id,
        service_type: form.service_type || "scheduled_service",
        service_date: form.service_date || new Date().toISOString().slice(0, 10),
        odometer_at_service: form.odometer_at_service ? Number(form.odometer_at_service) : undefined,
        cost: form.cost ? Number(form.cost) : 0,
        vendor_name: form.vendor_name,
        status: "scheduled",
        notes: form.notes,
      },
      {
        onSuccess: () => navigate("/admin/maintenance"),
        onError: (err: any) => setError(errorText(err, "The work order could not be created.")),
      },
    );
  };

  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-5xl p-4 md:p-6 w-full min-w-0">
        <AdminMaintenanceNewSection0 form={form} setField={setField} vehicles={vehicles?.data ?? []} onSubmit={submit} onSaveDraft={() => { saveDraft("maintenance-new", form); setNotice("Draft saved on this device."); }} submitting={createLog.isPending} error={error} notice={notice} />
      </div>
    </div>
  );
}
