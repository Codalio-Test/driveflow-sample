import React from "react";
import { Button } from "../components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "../components/ui/table";

function AccountBillingSection2() {
  const rows = [{ id: "INV-1042", date: "Jun 6, 2025", amount: "$381.84" }, { id: "INV-0984", date: "Mar 18, 2025", amount: "$242.10" }];
  return (
    <section className="mx-auto max-w-5xl overflow-hidden rounded-lg border"><Table><TableHeader><TableRow><TableHead>Invoice</TableHead><TableHead>Date</TableHead><TableHead>Amount</TableHead><TableHead className="text-right">Action</TableHead></TableRow></TableHeader><TableBody>{rows.map((row) => <TableRow key={row.id}><TableCell className="font-medium">{row.id}</TableCell><TableCell>{row.date}</TableCell><TableCell>{row.amount}</TableCell><TableCell className="text-right"><Button variant="ghost" size="sm">Download</Button></TableCell></TableRow>)}</TableBody></Table></section>
  );
}

export default function AccountBilling() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="w-full min-w-0">
        <AccountBillingSection2 />
      </div>
    </div>
  );
}
