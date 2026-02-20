"use client";

import { useRouter } from "next/navigation";
import Button from "./Button";
import { logout } from "../lib/api";

export default function TopNav({ user }) {
  const router = useRouter();

  async function handleLogout() {
    try {
      await logout();
    } finally {
      router.push("/login");
    }
  }

  return (
    <header className="mb-6 flex items-center justify-between rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
      <div>
        <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">Expense Tracker</p>
        {user ? <p className="text-sm text-slate-700">{user.email} ({user.role})</p> : null}
      </div>
      <Button variant="secondary" onClick={handleLogout}>Logout</Button>
    </header>
  );
}
