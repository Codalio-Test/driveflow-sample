import { Wrench } from "lucide-react";
import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../components/ui/select";
import { Textarea } from "../components/ui/textarea";

function AdminMaintenanceNewSection0() {
  const navigate=useNavigate();
  const [vehicle,setVehicle]=useState("");
  return (
    <><div><p className="text-sm font-medium text-primary">Maintenance</p><h1 className="text-3xl font-bold">New work order</h1><p className="text-muted-foreground">Schedule service and record the estimated cost.</p></div><Card><CardHeader><CardTitle className="flex items-center gap-2"><Wrench className="size-5"/>Work order details</CardTitle></CardHeader><CardContent className="grid gap-5 md:grid-cols-2"><div className="space-y-2"><Label>Vehicle</Label><Select value={vehicle} onValueChange={setVehicle}><SelectTrigger><SelectValue placeholder="Select vehicle"/></SelectTrigger><SelectContent><SelectItem value="DF-1874">DF-1874 · Ford Escape</SelectItem><SelectItem value="DF-2048">DF-2048 · Toyota RAV4</SelectItem></SelectContent></Select></div><div className="space-y-2"><Label>Service type</Label><Input placeholder="Oil & filter"/></div><div className="space-y-2"><Label>Priority</Label><Select><SelectTrigger><SelectValue placeholder="Select priority"/></SelectTrigger><SelectContent><SelectItem value="routine">Routine</SelectItem><SelectItem value="high">High</SelectItem><SelectItem value="critical">Critical</SelectItem></SelectContent></Select></div><div className="space-y-2"><Label>Odometer</Label><Input type="number" placeholder="42120"/></div><div className="space-y-2"><Label>Vendor</Label><Input placeholder="Preferred service partner"/></div><div className="space-y-2"><Label>Scheduled date</Label><Input type="date"/></div><div className="space-y-2"><Label>Estimate</Label><Input type="number" placeholder="0.00"/></div><div className="space-y-2 md:col-span-2"><Label>Notes</Label><Textarea placeholder="Service instructions and observed issues"/></div></CardContent></Card><div className="flex justify-end gap-2"><Button variant="outline">Save draft</Button><Button disabled={!vehicle} onClick={()=>navigate("/admin/maintenance")}>Create work order</Button></div></>
  );
}

export default function AdminMaintenanceNew() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-5xl p-4 md:p-6 w-full min-w-0">
        <AdminMaintenanceNewSection0 />
      </div>
    </div>
  );
}
