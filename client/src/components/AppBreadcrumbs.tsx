import { Link, useLocation } from "react-router-dom";
import { Breadcrumb, BreadcrumbItem, BreadcrumbLink, BreadcrumbList, BreadcrumbPage, BreadcrumbSeparator } from "./ui/breadcrumb";

export default function AppBreadcrumbs({}) {
  const { pathname } = useLocation();
  const segments = pathname.split("/").filter(Boolean);
  const parts = segments.map((segment, index) => ({ label: segment.replace(/-/g, " ").replace(/\b\w/g, (letter) => letter.toUpperCase()), path: `/${segments.slice(0, index + 1).join("/")}` }));
  return (
    <Breadcrumb><BreadcrumbList><BreadcrumbItem><BreadcrumbLink asChild><Link to="/">DriveFlow</Link></BreadcrumbLink></BreadcrumbItem>{parts.map((part, index) => <span key={part.path} className="contents"><BreadcrumbSeparator /><BreadcrumbItem>{index === parts.length - 1 ? <BreadcrumbPage>{part.label}</BreadcrumbPage> : <BreadcrumbLink asChild><Link to={part.path}>{part.label}</Link></BreadcrumbLink>}</BreadcrumbItem></span>)}</BreadcrumbList></Breadcrumb>
  );
}

export { AppBreadcrumbs };
