import { useState } from "react";
import { Plus, X } from "lucide-react";
import React from "react";
import { Button } from "./ui/button";

export default function DamagePinEditor() {
  const [pins, setPins] = useState<Array<{ id: number; x: number; y: number }>>([]);
  const addPin = (event: React.MouseEvent<HTMLDivElement>) => { const rect = event.currentTarget.getBoundingClientRect(); setPins([...pins, { id: Date.now(), x: ((event.clientX - rect.left) / rect.width) * 100, y: ((event.clientY - rect.top) / rect.height) * 100 }]); };
  const removePin = (event: React.MouseEvent, id: number) => { event.stopPropagation(); setPins(pins.filter((pin) => pin.id !== id)); };
  return (
    <div><div onClick={addPin} className="relative grid aspect-[2/1] cursor-crosshair place-items-center overflow-hidden rounded-xl border border-dashed border-border bg-muted"><span className="text-sm text-muted-foreground">Click to mark damage</span>{pins.map((pin) => <button key={pin.id} type="button" onClick={(event) => removePin(event, pin.id)} style={{ left: `${pin.x}%`, top: `${pin.y}%` }} className="absolute grid size-7 -translate-x-1/2 -translate-y-1/2 place-items-center rounded-full bg-destructive text-destructive-foreground shadow-md"><X className="size-3" /></button>)}</div><Button variant="ghost" size="sm" className="mt-2" onClick={() => setPins([...pins, { id: Date.now(), x: 50, y: 50 }])}><Plus className="mr-2 size-4" />Add center marker</Button></div>
  );
}

export { DamagePinEditor };
