import React from "react";
import { Link, useNavigate } from "react-router-dom";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";

function LoginSection0() {
  const navigate = useNavigate();
  return (
    <section><Card className="mx-auto max-w-md"><CardHeader><CardTitle>Welcome back</CardTitle><CardDescription>Securely access bookings, receipts, and deposit updates.</CardDescription></CardHeader><CardContent className="space-y-4"><div><Label>Email</Label><Input className="mt-2" type="email" /></div><div><div className="flex justify-between"><Label>Password</Label><button className="text-xs text-primary">Forgot password?</button></div><Input className="mt-2" type="password" /></div><Button className="w-full" onClick={() => navigate("/account/dashboard")}>Sign in</Button></CardContent><CardFooter className="justify-center text-sm text-muted-foreground">New to DriveFlow? <Link to="/signup" className="ml-1 text-primary">Create account</Link></CardFooter></Card></section>
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
