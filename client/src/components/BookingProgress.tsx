import { Check } from "lucide-react";

export default function BookingProgress({ current = 1 }: { current?: number }) {
  const steps = ["Search", "Configure", "Checkout", "Confirmed"];
  return (
    <div className="flex items-center justify-between" aria-label={`Step ${current} of ${steps.length}`}>{steps.map((step, index) => { const done = index + 1 < current; const active = index + 1 === current; return <div key={step} className="flex flex-1 items-center last:flex-none"><div className="flex flex-col items-center gap-2"><span className={`grid size-8 place-items-center rounded-full text-xs font-semibold ${done ? "bg-emerald-600 text-white" : active ? "bg-primary text-primary-foreground" : "bg-muted text-muted-foreground"}`}>{done ? <Check className="size-4" /> : index + 1}</span><span className={`hidden text-xs sm:block ${active ? "font-semibold text-foreground" : "text-muted-foreground"}`}>{step}</span></div>{index < steps.length - 1 && <div className={`mx-2 h-px flex-1 ${done ? "bg-emerald-600" : "bg-border"}`} />}</div>})}</div>
  );
}

export { BookingProgress };
