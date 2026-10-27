import { Save } from "lucide-react";
import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../components/ui/select";

function AdminFleetNewSection0() {
  const [vin,setVin]=useState("");
  const navigate=useNavigate();
  return (
    <><div><p className="text-sm font-medium text-primary">Fleet inventory</p><h1 className="text-3xl font-bold">Add vehicle</h1><p className="text-muted-foreground">Create a fleet record and maintenance baseline.</p></div><Card><CardHeader><CardTitle>Vehicle details</CardTitle></CardHeader><CardContent className="grid gap-5 lg:grid-cols-2"><div className="space-y-2"><Label>VIN</Label><Input value={vin} onChange={e=>setVin(e.target.value)} placeholder="17-character VIN"/></div><div className="space-y-2"><Label>License plate</Label><Input placeholder="DF-0000"/></div><div className="space-y-2"><Label>Make and model</Label><Input placeholder="Toyota RAV4"/></div><div className="space-y-2"><Label>Model year</Label><Input type="number" placeholder="2024"/></div><div className="space-y-2"><Label>Category</Label><Select><SelectTrigger><SelectValue placeholder="Select class"/></SelectTrigger><SelectContent><SelectItem value="compact">Compact</SelectItem><SelectItem value="suv">SUV</SelectItem><SelectItem value="luxury">Luxury</SelectItem></SelectContent></Select></div><div className="space-y-2"><Label>Home location</Label><Select><SelectTrigger><SelectValue placeholder="Select location"/></SelectTrigger><SelectContent><SelectItem value="downtown">Downtown</SelectItem><SelectItem value="airport">Airport</SelectItem></SelectContent></Select></div><div className="space-y-2"><Label>Daily rate</Label><Input type="number" placeholder="79.00"/></div><div className="space-y-2"><Label>Current odometer</Label><Input type="number" placeholder="0"/></div></CardContent></Card><div className="flex justify-end gap-2"><Button variant="outline">Save draft</Button><Button disabled={!vin} onClick={()=>navigate("/admin/fleet")}><Save className="size-4"/>Add vehicle</Button></div></>
  );
}

export default function AdminFleetNew() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-5xl p-4 md:p-6 w-full min-w-0">
        <AdminFleetNewSection0 />
      </div>
    </div>
  );
}
