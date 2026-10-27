import React, { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "../components/ui/card";
import { Checkbox } from "../components/ui/checkbox";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";

function SignupSection0() {
  const navigate = useNavigate();
  const [name, setName] = useState("");
  return (
    <section><Card className="mx-auto max-w-md"><CardHeader><CardTitle>Create your account</CardTitle><CardDescription>Book faster and keep every rental record in one place.</CardDescription></CardHeader><CardContent className="space-y-4"><div><Label>Name</Label><Input className="mt-2" value={name} onChange={(e) => setName(e.target.value)} /></div><div><Label>Email</Label><Input className="mt-2" type="email" /></div><div><Label>Password</Label><Input className="mt-2" type="password" /></div><div className="flex items-start gap-2"><Checkbox id="terms" /><Label htmlFor="terms" className="text-xs leading-5">I agree to the terms and privacy policy.</Label></div><Button className="w-full" onClick={() => navigate("/account/dashboard")}>Create account</Button></CardContent><CardFooter className="justify-center text-sm text-muted-foreground">Already registered? <Link to="/login" className="ml-1 text-primary">Sign in</Link></CardFooter></Card></section>
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
