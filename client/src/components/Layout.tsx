import { useEffect, useState, type MouseEvent as ReactMouseEvent } from "react";
import { NavLink, Outlet, useLocation, useNavigate } from "react-router-dom";
import { CalendarDays, CarFront, CheckCircle2, Gauge, LogIn, LogOut, Moon, Search, ShieldCheck, Sparkles, Sun, UserPlus } from "lucide-react";
import { useAuth } from "@rhino-dev/rhino-react";
import { useAppOwner } from "@/contexts/AppOwnerProvider";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Sidebar, SidebarContent, SidebarFooter, SidebarGroup, SidebarGroupContent, SidebarGroupLabel, SidebarHeader, SidebarInset, SidebarMenu, SidebarMenuButton, SidebarMenuItem, SidebarProvider, SidebarTrigger } from "./ui/sidebar";

const workspaceItems = [
  { to: "/vehicles", label: "Vehicles", icon: CarFront, roles: [] as string[] },
  { to: "/booking", label: "Book a car", icon: CalendarDays, roles: [] as string[] },
  { to: "/counter", label: "Counter", icon: Gauge, roles: ["counter_agent", "fleet_manager"] },
  { to: "/admin", label: "Operations", icon: ShieldCheck, roles: ["fleet_manager"] },
];

const guestAccountItems = [
  { to: "/signup", label: "Create account", icon: UserPlus },
  { to: "/login", label: "Sign in", icon: LogIn },
];

// The design's two Account slots, wired to the session: a signed-out visitor
// sees the prototype's CTAs, a signed-in user sees their own shortcuts.
const memberAccountItems = [
  { to: "/account/bookings", label: "My bookings", icon: CalendarDays },
  { to: "__signout__", label: "Sign out", icon: LogOut },
];

const pageTitles: Record<string, string> = {
  "/": "Overview",
  "/vehicles": "Browse vehicles",
  "/booking": "New booking",
  "/counter": "Rental counter",
  "/admin": "Operations",
  "/signup": "Create account",
  "/login": "Welcome back",
};

export default function Layout() {
  const location = useLocation();
  const navigate = useNavigate();
  const { isAuthenticated, logout } = useAuth();
  const { user, hasRole } = useAppOwner();

  // Positive-only role gate: an item with no roles is visible to everyone.
  const visibleWorkspaceItems = workspaceItems.filter((item) => item.roles.length === 0 || item.roles.some((role) => hasRole(role)));
  const accountItems = isAuthenticated ? memberAccountItems : guestAccountItems;

  // Identity slot: the signed-in user's initials, never a hardcoded pair.
  const initials = (() => {
    const name = user?.full_name || user?.name || [user?.first_name, user?.last_name].filter(Boolean).join(" ") || user?.email || "";
    const parts = String(name).trim().split(/[\s@._-]+/).filter(Boolean);
    if (parts.length === 0) return "DF";
    return (parts[0][0] + (parts[1]?.[0] ?? "")).toUpperCase();
  })();
  const [dark, setDark] = useState(false);
  const [actionMessage, setActionMessage] = useState("");

  useEffect(() => {
    const saved = localStorage.getItem("driveflow-theme");
    const next = saved === "dark" || (!saved && window.matchMedia("(prefers-color-scheme: dark)").matches);
    setDark(next);
    document.documentElement.classList.toggle("dark", next);
  }, []);

  const toggleTheme = () => {
    const next = !dark;
    setDark(next);
    document.documentElement.classList.toggle("dark", next);
    localStorage.setItem("driveflow-theme", next ? "dark" : "light");
  };

  const currentTitle = pageTitles[location.pathname] ?? (location.pathname.startsWith("/admin") ? "Operations" : location.pathname.startsWith("/account") ? "My account" : "DriveFlow");

  const renderNav = (items: typeof workspaceItems) => items.map((item) => (
    <SidebarMenuItem key={item.to}>
      <SidebarMenuButton asChild tooltip={item.label} className="h-10 rounded-xl transition-all duration-200">
        {item.to === "__signout__"
          ? <button type="button" onClick={() => logout()} className="text-sidebar-foreground/70 hover:text-sidebar-foreground">
              <item.icon className="size-4" />
              <span>{item.label}</span>
            </button>
          : <NavLink to={item.to} className={({ isActive }) => isActive ? "bg-sidebar-accent font-medium text-sidebar-accent-foreground shadow-sm" : "text-sidebar-foreground/70 hover:text-sidebar-foreground"}>
              <item.icon className="size-4" />
              <span>{item.label}</span>
            </NavLink>}
      </SidebarMenuButton>
    </SidebarMenuItem>
  ));

  return (
    <SidebarProvider>
      <Sidebar collapsible="icon" className="border-r border-sidebar-border/70 bg-sidebar/95 backdrop-blur-xl">
        <SidebarHeader className="border-b border-sidebar-border/60 p-4">
          <NavLink to="/" className="flex items-center gap-3 font-bold text-sidebar-foreground">
            <span className="grid size-10 shrink-0 place-items-center rounded-2xl bg-gradient-to-br from-blue-500 to-indigo-600 text-white shadow-lg shadow-blue-500/20"><CarFront className="size-5" /></span>
            <span className="text-[17px] tracking-tight group-data-[collapsible=icon]:hidden">DriveFlow</span>
          </NavLink>
        </SidebarHeader>
        <SidebarContent className="px-2 py-3">
          <SidebarGroup>
            <SidebarGroupLabel className="text-[10px] font-semibold uppercase tracking-[0.16em] text-muted-foreground">Workspace</SidebarGroupLabel>
            <SidebarGroupContent><SidebarMenu className="gap-1">{renderNav(visibleWorkspaceItems)}</SidebarMenu></SidebarGroupContent>
          </SidebarGroup>
          <SidebarGroup>
            <SidebarGroupLabel className="text-[10px] font-semibold uppercase tracking-[0.16em] text-muted-foreground">Account</SidebarGroupLabel>
            <SidebarGroupContent><SidebarMenu className="gap-1">{renderNav(accountItems)}</SidebarMenu></SidebarGroupContent>
          </SidebarGroup>
        </SidebarContent>
        <SidebarFooter className="p-3">
          <div className="rounded-2xl border border-sidebar-border/70 bg-sidebar-accent/50 p-3 group-data-[collapsible=icon]:hidden">
            <div className="flex items-center gap-2 text-xs font-semibold text-sidebar-accent-foreground"><Sparkles className="size-3.5" /> Smart mobility</div>
            <p className="mt-1 text-[11px] leading-4 text-muted-foreground">Clear pricing. Faster handoffs.</p>
          </div>
        </SidebarFooter>
      </Sidebar>
      <SidebarInset className="min-w-0 bg-background">
        <header className="sticky top-0 z-40 flex h-16 items-center gap-3 border-b border-border/60 bg-background/80 px-4 backdrop-blur-xl md:px-6">
          <SidebarTrigger className="rounded-xl" />
          <div className="min-w-0 flex-1">
            <p className="text-[11px] font-medium uppercase tracking-[0.14em] text-muted-foreground">DriveFlow</p>
            <h1 className="truncate text-sm font-semibold text-foreground">{currentTitle}</h1>
          </div>
          <div className="relative hidden w-full max-w-xs md:block">
            <Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
            <Input aria-label="Search" placeholder="Search vehicles, bookings…" className="h-9 rounded-xl border-border/70 bg-muted/60 pl-9 shadow-none" />
          </div>
          <Button variant="ghost" size="icon" onClick={toggleTheme} aria-label="Toggle theme" className="rounded-xl border border-border/60 bg-card/70 shadow-sm">
            {dark ? <Sun className="size-4" /> : <Moon className="size-4" />}
          </Button>
          <div className="grid size-9 place-items-center rounded-xl bg-gradient-to-br from-slate-700 to-slate-900 text-xs font-semibold text-white shadow-sm">{initials}</div>
        </header>
        <main className="w-full min-w-0 flex-1"><Outlet /></main>
        {actionMessage && (
          <div role="status" aria-live="polite" className="fixed bottom-5 right-5 z-50 flex max-w-sm items-center gap-2 rounded-xl border border-emerald-500/25 bg-card px-4 py-3 text-sm font-medium text-foreground shadow-xl">
            <CheckCircle2 className="size-4 shrink-0 text-emerald-500" />
            {actionMessage}
          </div>
        )}
      </SidebarInset>
    </SidebarProvider>
  );
}

export { Layout };
