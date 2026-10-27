import { ScanLine } from "lucide-react";
import React, { useState } from "react";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { Switch } from "../components/ui/switch";

function AccountProfileSection0() {
  return (
    <section className="mx-auto max-w-5xl"><h1 className="mb-6 text-3xl font-bold">Profile & Verification</h1><Card><CardHeader><CardTitle>Personal details</CardTitle></CardHeader><CardContent className="grid gap-4 sm:grid-cols-2"><div><Label>Full name</Label><Input className="mt-2" defaultValue="Alex Morgan" /></div><div><Label>Email</Label><Input className="mt-2" defaultValue="alex@example.com" /></div><div><Label>Phone</Label><Input className="mt-2" defaultValue="+1 555 013 4421" /></div><div className="flex items-end"><Button>Save changes</Button></div></CardContent></Card></section>
  );
}

function AccountProfileSection1() {
  return (
    <section className="mx-auto max-w-5xl"><Card><CardHeader className="flex-row items-center justify-between"><CardTitle>Driver license</CardTitle><Badge>Verified</Badge></CardHeader><CardContent className="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"><div><p className="font-medium">California •••• 4921</p><p className="text-sm text-muted-foreground">Valid through May 2028</p></div><Button variant="outline"><ScanLine className="mr-2 size-4" />Scan new license</Button></CardContent></Card></section>
  );
}

function AccountProfileSection2() {
  const prefs = ["SMS updates", "Email receipts", "Two-factor authentication"];
  const [enabled, setEnabled] = useState<Record<string, boolean>>({ "Email receipts": true });
  return (
    <section className="mx-auto max-w-5xl"><Card><CardHeader><CardTitle>Security and preferences</CardTitle></CardHeader><CardContent className="space-y-4">{prefs.map((item) => <div key={item} className="flex items-center justify-between border-b pb-4 last:border-0"><span>{item}</span><Switch checked={enabled[item] ?? false} onCheckedChange={(value) => setEnabled({ ...enabled, [item]: value })} /></div>)}<Button variant="outline">Change password</Button></CardContent></Card></section>
  );
}

export default function AccountProfile() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="w-full min-w-0">
        <AccountProfileSection0 />
        <AccountProfileSection1 />
        <AccountProfileSection2 />
      </div>
    </div>
  );
}
