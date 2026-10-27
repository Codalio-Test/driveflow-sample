import { Separator } from "./ui/separator";




export default function ReservationPriceSummary({ lines }: { lines?: Array<{ label: string; amount: number }> }) {
  const items = lines ?? [{ label: "Vehicle rental", amount: 284 }, { label: "Protection", amount: 48 }, { label: "Taxes & fees", amount: 39.84 }];
  return (
    <div className="space-y-3">{items.map((item) => <div key={item.label} className="flex justify-between gap-4 text-sm"><span className="text-muted-foreground">{item.label}</span><span className="font-medium text-foreground">${item.amount.toFixed(2)}</span></div>)}<Separator /><div className="flex justify-between text-base font-bold text-foreground"><span>Total</span><span>${items.reduce((sum, item) => sum + item.amount, 0).toFixed(2)}</span></div></div>
  );
}

export { ReservationPriceSummary };
