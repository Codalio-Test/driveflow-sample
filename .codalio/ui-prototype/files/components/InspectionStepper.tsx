import { Check } from "lucide-react";

export default function InspectionStepper({ current = 1 }: { current?: number }) {
  const steps = ["Details", "Condition", "Evidence", "Review"];
  return (
    <ol className="grid gap-3 sm:grid-cols-4">{steps.map((step, index) => <li key={step} className={`flex items-center gap-3 rounded-lg border p-3 ${index + 1 === current ? "border-primary bg-accent" : "border-border bg-card"}`}><span className={`grid size-7 shrink-0 place-items-center rounded-full text-xs font-bold ${index + 1 < current ? "bg-emerald-600 text-white" : index + 1 === current ? "bg-primary text-primary-foreground" : "bg-muted text-muted-foreground"}`}>{index + 1 < current ? <Check className="size-4" /> : index + 1}</span><span className="text-sm font-medium text-foreground">{step}</span></li>)}</ol>
  );
}

export { InspectionStepper };
