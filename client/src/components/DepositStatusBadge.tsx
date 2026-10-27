import { Badge } from "./ui/badge";




export default function DepositStatusBadge({ status = "Pending" }: { status?: string }) {
  return (
    <Badge variant="secondary" className={status === "Secured" ? "bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-200" : "bg-amber-100 text-amber-800 dark:bg-amber-950 dark:text-amber-200"}>{status}</Badge>
  );
}

export { DepositStatusBadge };
