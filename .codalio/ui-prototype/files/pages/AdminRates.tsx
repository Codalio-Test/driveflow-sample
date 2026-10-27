import { Plus } from "lucide-react";
import React, { useState } from "react";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Switch } from "../components/ui/switch";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "../components/ui/table";
import { Tabs, TabsList, TabsTrigger } from "../components/ui/tabs";

function AdminRatesSection0() {
  const [creating,setCreating]=useState(false);
  return (
    <><div className="flex flex-wrap items-end justify-between gap-4"><div><p className="text-sm font-medium text-primary">Revenue management</p><h1 className="text-3xl font-bold">Dynamic pricing & rates</h1><p className="text-muted-foreground">Control base rates, seasonal adjustments, and fees.</p></div><Button onClick={()=>setCreating(true)}><Plus className="size-4"/>Create rule</Button></div><Tabs defaultValue="base"><TabsList><TabsTrigger value="base">Base rates</TabsTrigger><TabsTrigger value="seasonal">Seasonal</TabsTrigger><TabsTrigger value="fees">Fees & penalties</TabsTrigger></TabsList></Tabs>{creating&&<p className="text-sm text-primary">New rule editor opened below.</p>}</>
  );
}

function AdminRatesSection1() {
  const [enabled,setEnabled]=useState<Record<string,boolean>>({});
  const rules=[{name:"Compact daily",scope:"Compact · All locations",value:"$49/day",priority:"Base"},{name:"Weekend demand",scope:"All classes",value:"+12%",priority:"Seasonal"},{name:"Fuel replacement",scope:"All rentals",value:"$8/gal",priority:"Fee"},{name:"Late return",scope:"All rentals",value:"$18/hr",priority:"Penalty"}];
  return (
    <div className="overflow-x-auto"><Table><TableHeader><TableRow><TableHead>Rule</TableHead><TableHead>Applies to</TableHead><TableHead>Value</TableHead><TableHead>Priority</TableHead><TableHead>Active</TableHead><TableHead/></TableRow></TableHeader><TableBody>{rules.map(rule=><TableRow key={rule.name}><TableCell className="font-medium">{rule.name}</TableCell><TableCell>{rule.scope}</TableCell><TableCell>{rule.value}</TableCell><TableCell><Badge variant="outline">{rule.priority}</Badge></TableCell><TableCell><Switch checked={enabled[rule.name]??true} onCheckedChange={v=>setEnabled({...enabled,[rule.name]:v})}/></TableCell><TableCell><Button size="sm" variant="ghost">Edit</Button></TableCell></TableRow>)}</TableBody></Table></div>
  );
}

export default function AdminRates() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="mx-auto max-w-7xl space-y-6 p-4 md:p-6 w-full min-w-0">
        <AdminRatesSection0 />
        <AdminRatesSection1 />
      </div>
    </div>
  );
}
