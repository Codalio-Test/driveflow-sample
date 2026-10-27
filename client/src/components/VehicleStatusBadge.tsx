import { Badge } from "./ui/badge";




export default function VehicleStatusBadge({ status = "Available" }: { status?: string }) {
  return (
    <Badge variant="outline" className={status === "Available" ? "border-emerald-200 bg-emerald-50 text-emerald-700 dark:border-emerald-800 dark:bg-emerald-950 dark:text-emerald-300" : status === "Rented" ? "border-blue-200 bg-blue-50 text-blue-700 dark:border-blue-800 dark:bg-blue-950 dark:text-blue-300" : "border-amber-200 bg-amber-50 text-amber-700 dark:border-amber-800 dark:bg-amber-950 dark:text-amber-300"}>{status}</Badge>
  );
}

export { VehicleStatusBadge };
