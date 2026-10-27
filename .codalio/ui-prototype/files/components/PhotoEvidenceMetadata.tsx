import { Clock, MapPin, ShieldCheck } from "lucide-react";
import { Badge } from "./ui/badge";

export default function PhotoEvidenceMetadata({ timestamp = "Today, 10:42 AM", location = "Downtown lot · Stall B12" }: { timestamp?: string; location?: string }) {
  return (
    <div className="flex flex-wrap items-center gap-2 text-xs text-muted-foreground"><Badge variant="secondary" className="gap-1"><Clock className="size-3" />{timestamp}</Badge><Badge variant="secondary" className="gap-1"><MapPin className="size-3" />{location}</Badge><Badge variant="outline" className="gap-1 text-emerald-700 dark:text-emerald-300"><ShieldCheck className="size-3" />Immutable evidence</Badge></div>
  );
}

export { PhotoEvidenceMetadata };
