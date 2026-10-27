

export default function OperationalStatusLegend() {
  const items = [{ label: "Available", color: "bg-emerald-500" }, { label: "On rent", color: "bg-blue-500" }, { label: "Due soon", color: "bg-amber-500" }, { label: "Overdue", color: "bg-red-500" }, { label: "Service", color: "bg-slate-500" }];
  return (
    <div className="flex flex-wrap gap-x-5 gap-y-2">{items.map((item) => <span key={item.label} className="flex items-center gap-2 text-xs text-muted-foreground"><span className={`size-2.5 rounded-full ${item.color}`} />{item.label}</span>)}</div>
  );
}

export { OperationalStatusLegend };
