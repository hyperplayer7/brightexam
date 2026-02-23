"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import Button from "./Button";
import { logout } from "../lib/api";
import { useTheme } from "./theme/ThemeProvider";

const THEME_LABELS = {
  light: "Light",
  dark: "Dark",
  stephens: "St. Stephen's",
  up: "UP"
};

export default function TopNav({ user }) {
  const router = useRouter();
  const { theme, themes, setTheme } = useTheme();

  async function handleLogout() {
    try {
      await logout();
    } finally {
      router.push("/login");
    }
  }

  return (
    <header className="mb-6 flex flex-col gap-3 rounded-xl border border-border bg-surface p-4 shadow-sm sm:flex-row sm:items-center sm:justify-between">
      <div>
        <p className="text-xs font-semibold uppercase tracking-wide text-muted">Expense Tracker</p>
        {user ? <p className="text-sm text-text">{user.email} ({user.role})</p> : null}
        {user ? (
          <nav className="mt-2 flex flex-wrap gap-2 text-sm">
            <Link
              href="/expenses"
              className="rounded-md border border-border px-2 py-1 text-text transition hover:bg-accent/20"
            >
              Expenses
            </Link>
            {user.role === "reviewer" ? (
              <>
                <Link
                  href="/categories"
                  className="rounded-md border border-border px-2 py-1 text-text transition hover:bg-accent/20"
                >
                  Categories
                </Link>
                <Link
                  href="/users"
                  className="rounded-md border border-border px-2 py-1 text-text transition hover:bg-accent/20"
                >
                  Users
                </Link>
              </>
            ) : null}
          </nav>
        ) : null}
      </div>

      <div className="flex items-end gap-2">
        <label className="block">
          <span className="mb-1 block text-xs font-semibold uppercase tracking-wide text-muted">
            Theme
          </span>
          <select
            className="rounded-lg border border-border bg-background px-3 py-2 text-sm text-text focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/40"
            value={theme}
            onChange={(event) => setTheme(event.target.value)}
          >
            {themes.map((themeKey) => (
              <option key={themeKey} value={themeKey}>
                {THEME_LABELS[themeKey] || themeKey}
              </option>
            ))}
          </select>
        </label>

        <div className="w-auto">
          <span className="mb-1 block h-5 text-xs font-semibold uppercase tracking-wide opacity-0">
            Logout
          </span>
          <Button variant="secondary" onClick={handleLogout}>Logout</Button>
        </div>
      </div>
    </header>
  );
}
