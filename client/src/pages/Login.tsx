import React, { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth, usePasswordRecover } from "@rhino-dev/rhino-react";
import { useAppOwner } from "@/contexts/AppOwnerProvider";
import { roleHomeFor } from "@/routes/guards";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";

function LoginSection0() {
  const navigate = useNavigate();
  const { login, setOrganization } = useAuth();
  const recover = usePasswordRecover();
  const { hasRole, isLoading: resolvingRoles } = useAppOwner();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [signedIn, setSignedIn] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  // Staff and renters land on their own role home once the session's roles
  // have resolved (the organization context loads them after login).
  useEffect(() => {
    if (!signedIn || resolvingRoles) return;
    navigate(roleHomeFor(hasRole), { replace: true });
  }, [signedIn, resolvingRoles, hasRole, navigate]);

  const signIn = async () => {
    setError("");
    setNotice("");
    setSubmitting(true);
    const result = await login(email, password);
    setSubmitting(false);
    if (!result?.success) {
      setError(result?.error ?? "Invalid email or password.");
      return;
    }
    if (result.organization_slug) setOrganization(result.organization_slug);
    setSignedIn(true);
  };

  const forgotPassword = () => {
    setError("");
    if (!email) {
      setNotice("Enter your email address, then choose Forgot password?");
      return;
    }
    recover.mutate({ email }, {
      onSuccess: () => setNotice("If that address exists, password reset instructions are on their way."),
      onError: () => setNotice("If that address exists, password reset instructions are on their way."),
    });
  };

  return (
    <section><Card className="mx-auto max-w-md"><CardHeader><CardTitle>Welcome back</CardTitle><CardDescription>Securely access bookings, receipts, and deposit updates.</CardDescription></CardHeader><CardContent className="space-y-4"><div><Label>Email</Label><Input className="mt-2" type="email" value={email} onChange={(event) => setEmail(event.target.value)} /></div><div><div className="flex justify-between"><Label>Password</Label><button className="text-xs text-primary" onClick={forgotPassword}>Forgot password?</button></div><Input className="mt-2" type="password" value={password} onChange={(event) => setPassword(event.target.value)} /></div>{error && <p className="text-sm text-destructive">{error}</p>}
{notice && <p className="text-sm text-muted-foreground">{notice}</p>}
<Button className="w-full" disabled={submitting} onClick={signIn}>{submitting ? "Signing in…" : "Sign in"}</Button></CardContent><CardFooter className="justify-center text-sm text-muted-foreground">New to DriveFlow? <Link to="/signup" className="ml-1 text-primary">Create account</Link></CardFooter></Card></section>
  );
}

export default function Login() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="w-full min-w-0">
        <LoginSection0 />
      </div>
    </div>
  );
}
