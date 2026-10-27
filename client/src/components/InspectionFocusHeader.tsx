import { ArrowLeft, CarFront } from "lucide-react";
import { Button } from "./ui/button";

export default function InspectionFocusHeader({ title = "Vehicle inspection", vehicle = "2024 Toyota RAV4 • DF-2048", onBack = () => window.history.back() }: { title?: string; vehicle?: string; onBack?: () => void }) {
  return (
    <header className="flex flex-col gap-4 border-b border-border bg-card p-4 sm:flex-row sm:items-center sm:justify-between"><div className="flex items-center gap-3"><Button variant="ghost" size="icon" onClick={onBack}><ArrowLeft className="size-4" /></Button><span className="grid size-10 place-items-center rounded-lg bg-accent text-accent-foreground"><CarFront className="size-5" /></span><div><h1 className="font-semibold text-foreground">{title}</h1><p className="text-sm text-muted-foreground">{vehicle}</p></div></div><span className="rounded-full bg-blue-100 px-3 py-1 text-xs font-semibold text-blue-700 dark:bg-blue-950 dark:text-blue-300">Inspection in progress</span></header>
  );
}

export { InspectionFocusHeader };
