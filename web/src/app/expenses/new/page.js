"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Button from "../../../components/Button";
import Input from "../../../components/Input";
import TopNav from "../../../components/TopNav";
import { getCurrentUser } from "../../../lib/auth";
import { createExpense } from "../../../lib/api";

const CURRENCY_OPTIONS = ["PHP", "USD"];

function toCents(amount) {
  const parsed = Number.parseFloat(amount);
  if (!Number.isFinite(parsed) || parsed <= 0) return null;
  return Math.round(parsed * 100);
}

function todayDateString() {
  return new Date().toISOString().slice(0, 10);
}

export default function NewExpensePage() {
  const router = useRouter();
  const [user, setUser] = useState(null);
  const [form, setForm] = useState({
    amount: "",
    currency: "PHP",
    merchant: "",
    description: "",
    incurred_on: todayDateString()
  });
  const [error, setError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const isEmployee = user?.role === "employee";

  useEffect(() => {
    let cancelled = false;

    async function loadUser() {
      try {
        const currentUser = await getCurrentUser();
        if (!cancelled) {
          setUser(currentUser);
          if (currentUser.role === "reviewer") {
            setError("Forbidden: reviewers cannot create expenses.");
          }
        }
      } catch (err) {
        if (!cancelled) {
          if (err.status === 401) {
            router.push("/login");
            return;
          }
          setError(err.message);
        }
      }
    }

    loadUser();

    return () => {
      cancelled = true;
    };
  }, [router]);

  function setField(field, value) {
    setForm((prev) => ({ ...prev, [field]: value }));
  }

  async function handleSubmit(event) {
    event.preventDefault();
    setError("");

    const amount_cents = toCents(form.amount);
    if (!amount_cents) {
      setError("Amount must be greater than 0.");
      return;
    }

    setIsSubmitting(true);

    try {
      const response = await createExpense({
        amount_cents,
        currency: form.currency,
        merchant: form.merchant,
        description: form.description,
        incurred_on: form.incurred_on
      });
      router.push(`/expenses/${response.data.id}`);
    } catch (err) {
      if (err.status === 401) {
        router.push("/login");
        return;
      }
      setError(err.message);
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="space-y-6">
      <TopNav user={user} />

      <div className="rounded-xl border border-border bg-surface p-6 shadow-sm">
        <div className="mb-6 flex items-center justify-between">
          <h1 className="text-2xl font-bold text-text">New Expense</h1>
          <Link href="/expenses" className="text-sm font-medium text-primary hover:text-primary/80">
            Back to expenses
          </Link>
        </div>

        {!isEmployee && user ? (
          <div className="rounded-lg border border-badge-submitted bg-badge-submitted/40 p-4 text-sm text-badge-submitted-foreground">
            Forbidden: reviewers cannot create expenses.
            <div className="mt-2">
              <Link href="/expenses" className="font-medium text-badge-submitted-foreground underline">
                Return to expenses
              </Link>
            </div>
          </div>
        ) : null}

        {!user || isEmployee ? (
          <form className="space-y-4" onSubmit={handleSubmit}>
            <Input
              id="amount"
              label="Amount"
              type="number"
              step="0.01"
              min="0"
              required
              value={form.amount}
              onChange={(event) => setField("amount", event.target.value)}
            />

            <Input as="select" id="currency" label="Currency" required value={form.currency} onChange={(event) => setField("currency", event.target.value)}>
              {CURRENCY_OPTIONS.map((currency) => (
                <option key={currency} value={currency}>
                  {currency}
                </option>
              ))}
            </Input>

            <Input
              id="merchant"
              label="Merchant"
              required
              value={form.merchant}
              onChange={(event) => setField("merchant", event.target.value)}
            />

            <Input
              id="description"
              label="Description"
              required
              value={form.description}
              onChange={(event) => setField("description", event.target.value)}
            />

            <Input
              id="incurred_on"
              label="Incurred on"
              type="date"
              required
              value={form.incurred_on}
              onChange={(event) => setField("incurred_on", event.target.value)}
            />

            {error ? <p className="text-sm font-medium text-badge-rejected-foreground">{error}</p> : null}

            <Button type="submit" disabled={isSubmitting || !isEmployee}>
              {isSubmitting ? "Creating..." : "Create Draft"}
            </Button>
          </form>
        ) : null}
      </div>
    </div>
  );
}
