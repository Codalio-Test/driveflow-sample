import { Plus } from "lucide-react";
import React, { useState } from "react";
import { useModelIndex, useModelStore, useModelUpdate } from "@rhino-dev/rhino-react";
import { errorText } from "@/lib/flow";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../components/ui/select";
import { Switch } from "../components/ui/switch";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "../components/ui/table";
import { Tabs, TabsList, TabsTrigger } from "../components/ui/tabs";

function AdminRatesSection0({ creating, onToggleCreate, tab, setTab, form, setField, categories, onSubmit, editingId, onCancel, submitting, error }: { creating: boolean; onToggleCreate: () => void; tab: string; setTab: (value: string) => void; form: Record<string, any>; setField: (key: string, value: string) => void; categories: Record<string, any>[]; onSubmit: () => void; editingId: number | null; onCancel: () => void; submitting: boolean; error: string }) {
  return (
    <><div className="flex flex-wrap items-end justify-between gap-4"><div><p className="text-sm font-medium text-primary">Revenue management</p><h1 className="text-3xl font-bold">Dynamic pricing & rates</h1><p className="text-muted-foreground">Control base rates, seasonal adjustments, and fees.</p></div><Button onClick={onToggleCreate}><Plus className="size-4"/>Create rule</Button></div><Tabs value={tab} onValueChange={setTab}><TabsList><TabsTrigger value="base">Base rates</TabsTrigger><TabsTrigger value="seasonal">Seasonal</TabsTrigger><TabsTrigger value="fees">Fees & penalties</TabsTrigger></TabsList></Tabs>{creating&&<p className="text-sm text-primary">{editingId ? "Editing the selected rule." : "New rule editor opened below."}</p>}<Card><CardHeader><CardTitle className="text-base">{editingId ? "Edit pricing rule" : "New pricing rule"}</CardTitle></CardHeader><CardContent className="grid gap-4 sm:grid-cols-4"><div><Label>Rule name</Label><Input className="mt-2" value={form.name} onChange={(event) => setField("name", event.target.value)} placeholder="Summer peak" /></div><div><Label>Vehicle class</Label><Select value={String(form.vehicle_category_id ?? "")} onValueChange={(value) => setField("vehicle_category_id", value)}><SelectTrigger className="mt-2"><SelectValue placeholder="Select class" /></SelectTrigger><SelectContent>{categories.map((category) => <SelectItem key={category.id} value={String(category.id)}>{category.name}</SelectItem>)}</SelectContent></Select></div><div><Label>Daily multiplier</Label><Input className="mt-2" type="number" step="0.05" value={form.daily_multiplier} onChange={(event) => setField("daily_multiplier", event.target.value)} /></div><div><Label>Weekend multiplier</Label><Input className="mt-2" type="number" step="0.05" value={form.weekend_multiplier} onChange={(event) => setField("weekend_multiplier", event.target.value)} /></div><div className="sm:col-span-4 flex items-center gap-3">{error && <p className="text-sm text-destructive">{error}</p>}<Button disabled={submitting} onClick={onSubmit}>{editingId ? "Save rule" : "Create rule"}</Button>{editingId && <Button variant="outline" onClick={onCancel}>Cancel</Button>}</div></CardContent></Card></>
  );
}

function AdminRatesSection1({ rules, onToggleRule, onEdit }: { rules: Record<string, any>[]; onToggleRule: (rule: Record<string, any>) => void; onEdit: (rule: Record<string, any>) => void }) {
  return (
    <div className="overflow-x-auto"><Table><TableHeader><TableRow><TableHead>Rule</TableHead><TableHead>Applies to</TableHead><TableHead>Value</TableHead><TableHead>Priority</TableHead><TableHead>Active</TableHead><TableHead/></TableRow></TableHeader><TableBody>{rules.map(rule=><TableRow key={rule.name}><TableCell className="font-medium">{rule.name}</TableCell><TableCell>{rule.scope}</TableCell><TableCell>{rule.value}</TableCell><TableCell><Badge variant="outline">{rule.priority}</Badge></TableCell><TableCell><Switch checked={Boolean(rule.is_active)} onCheckedChange={() => onToggleRule(rule)}/></TableCell><TableCell><Button size="sm" variant="ghost" onClick={() => onEdit(rule)}>Edit</Button></TableCell></TableRow>)}</TableBody></Table></div>
  );
}

export default function AdminRates() {
  const { data: response } = useModelIndex("rate_rules", { includes: ["vehicle_category"], perPage: 50 });
  const { data: categories } = useModelIndex("vehicle_categories", { perPage: 50 });
  const createRule = useModelStore("rate_rules");
  const updateRule = useModelUpdate("rate_rules");
  const [creating, setCreating] = useState(false);
  const [tab, setTab] = useState("base");
  const [editingId, setEditingId] = useState<number | null>(null);
  const [error, setError] = useState("");
  const [form, setForm] = useState<Record<string, any>>({ name: "", vehicle_category_id: "", daily_multiplier: "1", weekend_multiplier: "1" });
  const setField = (key: string, value: string) => setForm((prev) => ({ ...prev, [key]: value }));

  // The season tabs are a display grouping over the same rule set: the API has
  // no rule-type filter, so the list is fetched once and grouped client-side.
  const tabPriority: Record<string, string[]> = { base: ["Base"], seasonal: ["Seasonal"], fees: ["Fee", "Penalty"] };
  const rules = (response?.data ?? [])
    .filter((rule: Record<string, any>) => tabPriority[tab].includes(String(rule.priority ?? "Base")))
    .map((rule: Record<string, any>) => ({ id: rule.id, name: rule.name, scope: rule.scope ?? rule.vehicle_category?.name ?? "All classes", value: rule.value ?? `${rule.daily_multiplier}x`, priority: rule.priority ?? "Base", is_active: rule.is_active ?? true, raw: rule }));

  const submit = () => {
    if (!form.vehicle_category_id) {
      setError("Choose the vehicle class this rule applies to.");
      return;
    }
    if (Number(form.daily_multiplier) <= 0 || Number(form.weekend_multiplier) <= 0) {
      setError("Multipliers must be greater than zero.");
      return;
    }
    setError("");
    const data = { name: form.name || "New rate rule", vehicle_category_id: Number(form.vehicle_category_id), daily_multiplier: Number(form.daily_multiplier), weekend_multiplier: Number(form.weekend_multiplier) };
    if (editingId) {
      updateRule.mutate({ id: editingId, data }, { onSuccess: () => { setEditingId(null); setCreating(false); }, onError: (err: any) => setError(errorText(err, "That rule could not be saved.")) });
    } else {
      createRule.mutate(data, { onSuccess: () => setCreating(false), onError: (err: any) => setError(errorText(err, "That rule could not be created.")) });
    }
  };

  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-7xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <AdminRatesSection0 creating={creating} onToggleCreate={() => { setCreating((prev) => !prev); setEditingId(null); setError(""); }} tab={tab} setTab={setTab} form={form} setField={setField} categories={categories?.data ?? []} onSubmit={submit} editingId={editingId} onCancel={() => { setEditingId(null); setCreating(false); }} submitting={createRule.isPending || updateRule.isPending} error={error} />
        <AdminRatesSection1 rules={rules} onToggleRule={(rule) => updateRule.mutate({ id: rule.id, data: { is_active: !rule.is_active } })} onEdit={(rule) => { setEditingId(rule.id); setCreating(true); setForm({ name: rule.name, vehicle_category_id: String(rule.raw?.vehicle_category_id ?? ""), daily_multiplier: String(rule.raw?.daily_multiplier ?? 1), weekend_multiplier: String(rule.raw?.weekend_multiplier ?? 1) }); }} />
      </div>
    </div>
  );
}
