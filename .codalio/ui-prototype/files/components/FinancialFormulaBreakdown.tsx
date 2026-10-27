import { Calculator } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { Separator } from "./ui/separator";

export default function FinancialFormulaBreakdown({ items = [{ label: "Late return", formula: "2.5 hr × $18 = $45.00" }, { label: "Fuel", formula: "3 gal × $8 = $24.00" }], total = "$69.00" }: { items?: Array<{ label: string; formula: string }>; total?: string }) {
  return (
    <Card><CardHeader><CardTitle className="flex items-center gap-2 text-base"><Calculator className="size-4 text-primary" />Charge calculation</CardTitle></CardHeader><CardContent className="space-y-3">{items.map((item) => <div key={item.label} className="flex items-center justify-between gap-4 text-sm"><span className="text-muted-foreground">{item.label}</span><span className="font-medium text-foreground">{item.formula}</span></div>)}<Separator /><div className="flex items-center justify-between font-semibold"><span>Total due</span><span>{total}</span></div></CardContent></Card>
  );
}

export { FinancialFormulaBreakdown };
