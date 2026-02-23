"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import Button from "../../../../components/Button";
import Input from "../../../../components/Input";
import TopNav from "../../../../components/TopNav";
import { getCurrentUser } from "../../../../lib/auth";
import { getExpense, listCategories, updateExpense } from "../../../../lib/api";

const CURRENCY_OPTIONS = ["PHP", "USD"];

function toAmount(amountCents) {
  return (amountCents / 100).toFixed(2);
}

function toCents(amount) {
  const parsed = Number.parseFloat(amount);
  if (!Number.isFinite(parsed) || parsed <= 0) return null;
  return Math.round(parsed * 100);
}

export default function EditExpensePage() {
  const params = useParams();
  const router = useRouter();
  const expenseId = params.id;

  const [user, setUser] = useState(null);
  const [expense, setExpense] = useState(null);
  const [categories, setCategories] = useState([]);
  const [form, setForm] = useState({
    amount: "",
    currency: "PHP",
    merchant: "",
    description: "",
    incurred_on: "",
    category_id: ""
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    let cancelled = false;

    async function loadData() {
      try {
        setLoading(true);
        setError("");
        const [currentUser, expenseResponse, categoriesResponse] = await Promise.all([
          getCurrentUser(),
          getExpense(expenseId),
          listCategories()
        ]);

        if (cancelled) return;

        const data = expenseResponse?.data;
        setUser(currentUser);
        setExpense(data);
        setCategories(categoriesResponse?.data || []);
        setForm({
          amount: toAmount(data.amount_cents),
          currency: data.currency || "PHP",
          merchant: data.merchant || "",
          description: data.description || "",
          incurred_on: data.incurred_on || "",
          category_id: data?.category?.id ? String(data.category.id) : ""
        });
      } catch (err) {
        if (!cancelled) {
          if (err.status === 401) {
            router.push("/login");
            return;
          }
          setError(err.message);
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    loadData();

    return () => {
      cancelled = true;
    };
  }, [expenseId, router]);

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

    try {
      setSaving(true);
      await updateExpense(expenseId, {
        amount_cents,
        currency: form.currency,
        merchant: form.merchant,
        description: form.description,
        incurred_on: form.incurred_on,
        category_id: form.category_id || null,
        lock_version: expense.lock_version
      });
      router.push(`/expenses/${expenseId}`);
    } catch (err) {
      if (err.status === 401) {
        router.push("/login");
        return;
      }
      setError(err.message);
    } finally {
      setSaving(false);
    }
  }

  const canEdit =
    user?.role === "employee" &&
    expense?.user_id === user?.id &&
    expense?.status === "drafted";

  return (
    <div className="space-y-6">
      <TopNav user={user} />

      <div className="rounded-xl border border-border bg-surface p-6 shadow-sm">
        <div className="mb-6 flex items-center justify-between">
          <h1 className="text-2xl font-bold text-text">Edit Expense #{expenseId}</h1>
          <Link href={`/expenses/${expenseId}`} className="text-sm font-medium text-primary hover:text-primary/80">
            Back
          </Link>
        </div>

        {loading ? <p className="text-sm text-muted">Loading expense...</p> : null}
        {error ? <p className="mb-4 text-sm font-medium text-badge-rejected-foreground">{error}</p> : null}

        {!loading && !canEdit ? (
          <div className="rounded-lg border border-badge-submitted bg-badge-submitted/40 p-4 text-sm text-badge-submitted-foreground">
            Draft expenses owned by you are the only records that can be edited.
            <div className="mt-2">
              <Link href={`/expenses/${expenseId}`} className="font-medium text-badge-submitted-foreground underline">
                Return to expense detail
              </Link>
            </div>
          </div>
        ) : null}

        {!loading && canEdit ? (
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
              as="select"
              id="category_id"
              label="Category (optional)"
              value={form.category_id}
              onChange={(event) => setField("category_id", event.target.value)}
            >
              <option value="">No category</option>
              {categories.map((category) => (
                <option key={category.id} value={String(category.id)}>
                  {category.name}
                </option>
              ))}
            </Input>

            <Input
              id="incurred_on"
              label="Incurred on"
              type="date"
              required
              value={form.incurred_on}
              onChange={(event) => setField("incurred_on", event.target.value)}
            />

            <Button type="submit" disabled={saving}>
              {saving ? "Saving..." : "Save changes"}
            </Button>
          </form>
        ) : null}
      </div>
    </div>
  );
}
