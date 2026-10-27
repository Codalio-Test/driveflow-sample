import React, { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { api } from "@rhino-dev/rhino-react";
import { errorText } from "@/lib/flow";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "../components/ui/card";
import { Checkbox } from "../components/ui/checkbox";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";

function SignupSection0() {
  const navigate = useNavigate();
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [terms, setTerms] = useState(false);
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const createAccount = async () => {
    setError("");
    setSubmitting(true);
    try {
      await api.post("/auth/register", { name, email, password, password_confirmation: password });
      navigate("/login");
    } catch (err) {
      setError(errorText(err, "We could not create that account."));
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <section><Card className="mx-auto max-w-md"><CardHeader><CardTitle>Create your account</CardTitle><CardDescription>Book faster and keep every rental record in one place.</CardDescription></CardHeader><CardContent className="space-y-4"><div><Label>Name</Label><Input className="mt-2" value={name} onChange={(e) => setName(e.target.value)} /></div><div><Label>Email</Label><Input className="mt-2" type="email" value={email} onChange={(e) => setEmail(e.target.value)} /></div><div><Label>Password</Label><Input className="mt-2" type="password" value={password} onChange={(e) => setPassword(e.target.value)} /></div><div className="flex items-start gap-2"><Checkbox id="terms" checked={terms} onCheckedChange={(value) => setTerms(Boolean(value))} /><Label htmlFor="terms" className="text-xs leading-5">I agree to the terms and privacy policy.</Label></div>{error && <p className="text-sm text-destructive">{error}</p>}
<Button className="w-full" disabled={!terms || submitting} onClick={createAccount}>{submitting ? "Creating account…" : "Create account"}</Button></CardContent><CardFooter className="justify-center text-sm text-muted-foreground">Already registered? <Link to="/login" className="ml-1 text-primary">Sign in</Link></CardFooter></Card></section>
  );
}

export default function Signup() {
  return (
    <div className="w-full min-w-0 overflow-x-hidden">
      <div className="w-full min-w-0">
        <SignupSection0 />
      </div>
    </div>
  );
}
