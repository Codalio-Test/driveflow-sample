import { useState } from "react";
import { ArrowRight, CalendarDays, Camera, Check, ChevronRight, Clock3, Gauge, MapPin, ShieldCheck, Sparkles } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Card, CardContent } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../components/ui/select";

const heroImage = "/images/ui-prototype/8891625.jpg";

function LandingHero() {
  const navigate = useNavigate();
  const [location, setLocation] = useState("Airport Terminal");
  const [date, setDate] = useState("2025-08-24");
  const [time, setTime] = useState("09:00");

  return (
    <section className="relative overflow-hidden border-b border-border/60 px-4 py-12 sm:px-6 lg:px-8 lg:py-20">
      <div className="absolute inset-0 -z-10 bg-[radial-gradient(circle_at_20%_10%,rgba(59,130,246,0.13),transparent_32%),radial-gradient(circle_at_90%_30%,rgba(99,102,241,0.12),transparent_30%)]" />
      <div className="mx-auto grid max-w-7xl items-center gap-12 lg:grid-cols-[1.05fr_0.95fr]">
        <div>
          <Badge variant="secondary" className="rounded-full border border-primary/15 bg-primary/10 px-3 py-1 text-primary"><Sparkles className="mr-1.5 size-3.5" />A clearer way to rent</Badge>
          <h2 className="mt-6 max-w-3xl text-4xl font-extrabold leading-[1.05] tracking-[-0.045em] text-foreground sm:text-5xl lg:text-7xl">Rent with proof,<br /><span className="bg-gradient-to-r from-blue-600 to-indigo-500 bg-clip-text text-transparent dark:from-blue-400 dark:to-cyan-300">not surprises.</span></h2>
          <p className="mt-6 max-w-xl text-base leading-7 text-muted-foreground sm:text-lg">Guaranteed vehicle classes, upfront totals, and photo-backed inspections from pickup to return.</p>
          <div className="mt-6 flex flex-wrap gap-x-5 gap-y-2 text-sm text-muted-foreground">
            {["No hidden fees", "Instant confirmation", "Digital inspection"].map((item) => <span key={item} className="flex items-center gap-1.5"><span className="grid size-5 place-items-center rounded-full bg-emerald-500/15 text-emerald-600 dark:text-emerald-400"><Check className="size-3" /></span>{item}</span>)}
          </div>
          <Card className="mt-8 overflow-hidden border-white/70 bg-card/85 shadow-2xl shadow-slate-900/10 backdrop-blur-xl dark:border-white/10">
            <CardContent className="grid gap-4 p-4 sm:grid-cols-2 sm:p-5">
              <div className="sm:col-span-2"><Label htmlFor="location" className="text-xs font-semibold text-muted-foreground">PICKUP LOCATION</Label><div className="relative mt-2"><MapPin className="absolute left-3.5 top-1/2 size-4 -translate-y-1/2 text-primary" /><Input id="location" value={location} onChange={(event) => setLocation(event.target.value)} className="h-12 rounded-xl bg-background/80 pl-10" /></div></div>
              <div><Label htmlFor="pickup-date" className="text-xs font-semibold text-muted-foreground">DATE</Label><div className="relative mt-2"><CalendarDays className="pointer-events-none absolute left-3.5 top-1/2 size-4 -translate-y-1/2 text-primary" /><Input id="pickup-date" type="date" value={date} onChange={(event) => setDate(event.target.value)} className="h-12 rounded-xl bg-background/80 pl-10" /></div></div>
              <div><Label className="text-xs font-semibold text-muted-foreground">TIME</Label><Select value={time} onValueChange={setTime}><SelectTrigger className="mt-2 h-12 w-full rounded-xl bg-background/80"><Clock3 className="size-4 text-primary" /><SelectValue /></SelectTrigger><SelectContent><SelectItem value="09:00">9:00 AM</SelectItem><SelectItem value="12:00">12:00 PM</SelectItem><SelectItem value="15:00">3:00 PM</SelectItem></SelectContent></Select></div>
              <Button size="lg" className="h-12 rounded-xl shadow-lg shadow-blue-500/20 sm:col-span-2" onClick={() => navigate("/vehicles", { state: { location, date, time } })}>Find my vehicle<ArrowRight className="ml-2 size-4" /></Button>
            </CardContent>
          </Card>
        </div>
        <div className="relative mx-auto w-full max-w-xl lg:max-w-none">
          <div className="absolute -inset-6 -z-10 rounded-[3rem] bg-gradient-to-br from-blue-500/20 to-indigo-500/10 blur-2xl" />
          <div className="relative overflow-hidden rounded-[2rem] border border-white/40 bg-card p-2 shadow-2xl shadow-slate-900/15 dark:border-white/10">
            <img src={heroImage} alt="Modern rental car ready for pickup" className="aspect-[4/3] w-full rounded-[1.55rem] object-cover" />
            <div className="absolute bottom-6 left-6 right-6 flex items-center justify-between rounded-2xl border border-white/50 bg-white/85 p-4 shadow-lg backdrop-blur-xl dark:border-white/10 dark:bg-slate-950/80">
              <div><p className="text-xs font-medium text-muted-foreground">Your total, always clear</p><p className="mt-0.5 font-semibold text-foreground">Protected from pickup to return</p></div>
              <span className="grid size-10 place-items-center rounded-xl bg-emerald-500 text-white"><ShieldCheck className="size-5" /></span>
            </div>
          </div>
          <div className="absolute -right-3 top-8 hidden rounded-2xl border border-border/70 bg-card/90 px-4 py-3 shadow-xl backdrop-blur-xl sm:block"><p className="text-xs text-muted-foreground">Average handover</p><p className="mt-1 text-xl font-bold text-foreground">90 sec</p></div>
        </div>
      </div>
    </section>
  );
}

function TrustFeatures() {
  const features = [
    { title: "Transparent pricing", icon: Gauge, copy: "Every fee, protection option, and deposit is explained before you pay.", tone: "bg-blue-500/10 text-blue-600 dark:text-blue-400" },
    { title: "Photo-backed inspections", icon: Camera, copy: "Time-stamped condition records protect both you and the vehicle.", tone: "bg-violet-500/10 text-violet-600 dark:text-violet-400" },
    { title: "Fast deposit release", icon: ShieldCheck, copy: "Follow the status of every hold, release, and refund in real time.", tone: "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400" },
  ];
  return (
    <section className="px-4 py-16 sm:px-6 lg:px-8 lg:py-24">
      <div className="mx-auto max-w-7xl">
        <div className="max-w-2xl"><p className="text-sm font-bold uppercase tracking-[0.18em] text-primary">Built for certainty</p><h2 className="mt-3 text-3xl font-bold text-foreground sm:text-4xl">Trust at every handoff</h2><p className="mt-4 leading-7 text-muted-foreground">The details that usually feel complicated, made refreshingly simple.</p></div>
        <div className="mt-10 grid gap-5 md:grid-cols-3">{features.map((feature) => <Card key={feature.title} className="group border-border/70 bg-card/80 transition-all duration-300 hover:-translate-y-1 hover:shadow-xl"><CardContent className="p-7"><span className={`grid size-12 place-items-center rounded-2xl ${feature.tone}`}><feature.icon className="size-5" /></span><h3 className="mt-6 text-lg font-bold text-foreground">{feature.title}</h3><p className="mt-3 text-sm leading-6 text-muted-foreground">{feature.copy}</p><div className="mt-6 flex items-center text-sm font-semibold text-primary opacity-70 transition-opacity group-hover:opacity-100">Learn more<ChevronRight className="ml-1 size-4" /></div></CardContent></Card>)}</div>
      </div>
    </section>
  );
}

function BookingSteps() {
  const steps = ["Choose a vehicle", "Confirm your total", "Inspect and drive"];
  return (
    <section className="border-y border-border/60 bg-card/50 px-4 py-16 sm:px-6 lg:px-8 lg:py-24">
      <div className="mx-auto max-w-7xl"><div className="text-center"><Badge variant="outline" className="rounded-full">Three simple steps</Badge><h2 className="mt-4 text-3xl font-bold text-foreground sm:text-4xl">From search to road, faster.</h2></div><div className="relative mt-12 grid gap-6 md:grid-cols-3"><div className="absolute left-[16%] right-[16%] top-6 hidden h-px bg-gradient-to-r from-transparent via-primary/35 to-transparent md:block" />{steps.map((step, index) => <div key={step} className="relative text-center"><span className="relative mx-auto grid size-12 place-items-center rounded-2xl border border-primary/20 bg-background text-sm font-bold text-primary shadow-lg shadow-blue-500/10">0{index + 1}</span><h3 className="mt-5 font-bold text-foreground">{step}</h3><p className="mx-auto mt-2 max-w-xs text-sm leading-6 text-muted-foreground">{index === 0 ? "Compare the right class for your trip." : index === 1 ? "Review every charge before checkout." : "Sign digitally and receive your condition record."}</p></div>)}</div></div>
    </section>
  );
}

function FinalCta() {
  const navigate = useNavigate();
  return (
    <section className="px-4 py-16 sm:px-6 lg:px-8 lg:py-24"><div className="relative mx-auto max-w-7xl overflow-hidden rounded-[2rem] bg-slate-950 px-6 py-12 text-white shadow-2xl shadow-blue-950/20 sm:px-10 lg:px-14 lg:py-16"><div className="absolute inset-0 bg-[radial-gradient(circle_at_85%_20%,rgba(59,130,246,0.45),transparent_35%),linear-gradient(120deg,transparent,rgba(30,64,175,0.25))]" /><div className="relative flex flex-col items-start justify-between gap-8 lg:flex-row lg:items-center"><div className="max-w-2xl"><p className="text-sm font-semibold uppercase tracking-[0.18em] text-blue-300">Your next drive starts here</p><h2 className="mt-3 text-3xl font-bold sm:text-4xl">Find the right vehicle without the guesswork.</h2><p className="mt-4 text-slate-300">Clear prices, verified condition, and a checkout that takes minutes.</p></div><Button size="lg" className="h-12 shrink-0 rounded-xl bg-white px-6 text-slate-950 hover:bg-blue-50" onClick={() => navigate("/vehicles")}>Browse the fleet<ArrowRight className="ml-2 size-4" /></Button></div></div></section>
  );
}

export default function Landing() {
  return <div className="w-full min-w-0 overflow-x-hidden bg-background"><LandingHero /><TrustFeatures /><BookingSteps /><FinalCta /></div>;
}
