import { Save, ArrowRight } from "lucide-react";
import { Button } from "./ui/button";

export default function InspectionActionBar({ onSave = () => undefined, onContinue = () => undefined }: { onSave?: () => void; onContinue?: () => void }) {
  return (
    <div className="sticky bottom-0 z-30 flex items-center justify-between gap-3 border-t border-border bg-background/95 p-4 backdrop-blur"><Button variant="outline" onClick={onSave}><Save className="mr-2 size-4" />Save draft</Button><Button onClick={onContinue}>Continue<ArrowRight className="ml-2 size-4" /></Button></div>
  );
}

export { InspectionActionBar };
