import { ScanLine } from "lucide-react";
import React, { useEffect, useState } from "react";
import { api, useModelIndex, useModelUpdate, usePasswordRecover } from "@rhino-dev/rhino-react";
import { apiPath, errorText, useOrgSlug } from "@/lib/flow";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { Switch } from "../components/ui/switch";

function AccountProfileSection0({ profile, saving, notice, onSave }: { profile: Record<string, any> | null; saving: boolean; notice: string; onSave: (data: Record<string, any>) => void }) {
  const [form, setForm] = useState({ full_name: "", email: "", phone_number: "" });
  useEffect(() => {
    if (profile) setForm({ full_name: profile.full_name ?? "", email: profile.email ?? "", phone_number: profile.phone_number ?? "" });
  }, [profile?.id]);
  return (
    <section className="mx-auto max-w-5xl"><h1 className="mb-6 text-3xl font-bold">Profile & Verification</h1><Card><CardHeader><CardTitle>Personal details</CardTitle></CardHeader><CardContent className="grid gap-4 sm:grid-cols-2"><div><Label>Full name</Label><Input className="mt-2" value={form.full_name} onChange={(event) => setForm({ ...form, full_name: event.target.value })} /></div><div><Label>Email</Label><Input className="mt-2" value={form.email} onChange={(event) => setForm({ ...form, email: event.target.value })} /></div><div><Label>Phone</Label><Input className="mt-2" value={form.phone_number} onChange={(event) => setForm({ ...form, phone_number: event.target.value })} /></div><div className="flex items-end gap-3"><Button disabled={!profile || saving} onClick={() => onSave({ full_name: form.full_name, email: form.email, phone_number: form.phone_number })}>{saving ? "Saving…" : "Save changes"}</Button>{notice && <span className="text-xs text-muted-foreground">{notice}</span>}</div></CardContent></Card></section>
  );
}

function AccountProfileSection1({ profile, onScan, notice }: { profile: Record<string, any> | null; onScan: (file?: File) => void; notice: string }) {
  const licenseNumber = profile?.license_number ? `•••• ${String(profile.license_number).slice(-4)}` : "Not on file";
  return (
    <section className="mx-auto max-w-5xl"><Card><CardHeader className="flex-row items-center justify-between"><CardTitle>Driver license</CardTitle>{profile?.license_verified ? <Badge>Verified</Badge> : <Badge variant="secondary">Pending</Badge>}</CardHeader><CardContent className="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"><div><p className="font-medium">{profile?.license_state ?? "—"} {licenseNumber}</p><p className="text-sm text-muted-foreground">Valid through {profile?.license_expiry_date ?? "—"}</p>{notice && <p className="text-xs text-muted-foreground">{notice}</p>}</div><Button variant="outline" asChild><label><ScanLine className="mr-2 size-4" />Scan new license<input type="file" accept="image/png,image/jpeg,application/pdf" className="hidden" onChange={(event) => onScan(event.target.files?.[0])} /></label></Button></CardContent></Card></section>
  );
}

function AccountProfileSection2({ onChangePassword, notice }: { onChangePassword: () => void; notice: string }) {
  const prefs = ["SMS updates", "Email receipts", "Two-factor authentication"];
  const [enabled, setEnabled] = useState<Record<string, boolean>>({ "Email receipts": true });
  return (
    <section className="mx-auto max-w-5xl"><Card><CardHeader><CardTitle>Security and preferences</CardTitle></CardHeader><CardContent className="space-y-4">{prefs.map((item) => <div key={item} className="flex items-center justify-between border-b pb-4 last:border-0"><span>{item}</span><Switch checked={enabled[item] ?? false} onCheckedChange={(value) => setEnabled({ ...enabled, [item]: value })} /></div>)}<Button variant="outline" onClick={onChangePassword}>Change password</Button>
{notice && <p className="text-xs text-muted-foreground">{notice}</p>}</CardContent></Card></section>
  );
}

export default function AccountProfile() {
  const orgSlug = useOrgSlug();
  const { data: response } = useModelIndex("customer_profiles", { perPage: 1 });
  const updateProfile = useModelUpdate("customer_profiles");
  const recover = usePasswordRecover();
  const profile = (response?.data ?? [])[0] ?? null;
  const [notice, setNotice] = useState("");
  const [licenseNotice, setLicenseNotice] = useState("");
  const [passwordNotice, setPasswordNotice] = useState("");

  const save = (data: Record<string, any>) => {
    if (!profile) return;
    setNotice("");
    updateProfile.mutate({ id: profile.id, data }, { onSuccess: () => setNotice("Profile saved."), onError: (err) => setNotice(errorText(err, "We could not save your profile.")) });
  };

  const scanLicense = async (file?: File) => {
    if (!file || !profile) return;
    setLicenseNotice(`${file.name} uploading…`);
    try {
      const body = new FormData();
      body.append("file", file);
      body.append("kind", "driver_license");
      body.append("customer_profile_id", String(profile.id));
      await api.post(apiPath(orgSlug, "/documents"), body);
      setLicenseNotice(`${file.name} uploaded — verification pending.`);
    } catch (err) {
      setLicenseNotice(errorText(err, "We could not upload that file."));
    }
  };

  const changePassword = () => {
    if (!profile?.email) {
      setPasswordNotice("Add an email address first.");
      return;
    }
    recover.mutate({ email: profile.email }, { onSuccess: () => setPasswordNotice("Password reset instructions sent."), onError: () => setPasswordNotice("Password reset instructions sent.") });
  };

  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="w-full min-w-0">
        <AccountProfileSection0 profile={profile} saving={updateProfile.isPending} notice={notice} onSave={save} />
        <AccountProfileSection1 profile={profile} onScan={scanLicense} notice={licenseNotice} />
        <AccountProfileSection2 onChangePassword={changePassword} notice={passwordNotice} />
      </div>
    </div>
  );
}
