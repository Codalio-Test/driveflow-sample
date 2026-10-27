import { Camera } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";

export default function PhotoEvidenceComparison({ before, after }: { before?: string; after?: string }) {
  return (
    <div className="grid gap-4 md:grid-cols-2">{[{ label: "Before", src: before }, { label: "After", src: after }].map((item) => <Card key={item.label}><CardHeader className="pb-3"><CardTitle className="text-sm">{item.label}</CardTitle></CardHeader><CardContent>{item.src ? <img src={item.src} alt={`${item.label} inspection evidence`} className="aspect-video w-full rounded-lg object-cover" /> : <div className="grid aspect-video place-items-center rounded-lg bg-muted text-muted-foreground"><Camera className="size-8" /></div>}</CardContent></Card>)}</div>
  );
}

export { PhotoEvidenceComparison };
