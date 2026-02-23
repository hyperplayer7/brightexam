"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Badge from "../../components/Badge";
import Button from "../../components/Button";
import ForbiddenState from "../../components/ForbiddenState";
import Input from "../../components/Input";
import TopNav from "../../components/TopNav";
import { isForbiddenError, isUnauthorizedError, requireCurrentUser } from "../../lib/auth";
import { getExpensesSummary, listCategories, listExpenses } from "../../lib/api";

function formatDate(value) {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleDateString();
}

function formatCount(value) {
  return new Intl.NumberFormat("en-US").format(Number(value || 0));
}

function formatCents(value) {
  const amount = Number(value || 0) / 100;
  return new Intl.NumberFormat("en-US", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(amount);
}

function formatMoney(currency, amountCents) {
  return `${currency || ""} ${formatCents(amountCents)}`.trim();
}

const STATUS_OPTIONS = ["all", "drafted", "submitted", "approved", "rejected"];

export default function ExpensesPage() {
  const router = useRouter();
  const [user, setUser] = useState(null);
  const [expenses, setExpenses] = useState([]);
  const [summary, setSummary] = useState(null);
  const [categories, setCategories] = useState([]);
  const [pagination, setPagination] = useState(null);
  const [statusFilter, setStatusFilter] = useState("all");
  const [categoryFilter, setCategoryFilter] = useState("all");
  const [searchTerm, setSearchTerm] = useState("");
  const [page, setPage] = useState(1);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const [forbidden, setForbidden] = useState(false);

  useEffect(() => {
    let cancelled = false;

    async function loadData() {
      try {
        setLoading(true);
        setError("");
        setForbidden(false);
        const normalizedStatus = statusFilter?.trim?.() || "";

        const [currentUser, expenseResponse, categoriesResponse] = await Promise.all([
          requireCurrentUser(),
          listExpenses({
            status: normalizedStatus === "all" || normalizedStatus === "" ? undefined : normalizedStatus,
            category_id: categoryFilter === "all" ? undefined : categoryFilter,
            page
          }),
          listCategories()
        ]);

        let summaryResponse = null;
        try {
          summaryResponse = await getExpensesSummary();
        } catch (_summaryError) {
          summaryResponse = null;
        }

        if (!cancelled) {
          setUser(currentUser);
          setExpenses(expenseResponse?.data || []);
          setCategories(categoriesResponse?.data || []);
          setSummary(summaryResponse?.data || null);
          setPagination(expenseResponse?.pagination || null);
        }
      } catch (err) {
        if (!cancelled) {
          if (isUnauthorizedError(err)) {
            router.push("/login");
            return;
          }
          if (isForbiddenError(err)) {
            setForbidden(true);
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
  }, [categoryFilter, page, router, statusFilter]);

  function handleStatusChange(event) {
    setStatusFilter(event.target.value);
    setPage(1);
  }

  function handleCategoryChange(event) {
    setCategoryFilter(event.target.value);
    setPage(1);
  }

  function handleSearchChange(event) {
    setSearchTerm(event.target.value);
    setPage(1);
  }

  function clearSearch() {
    setSearchTerm("");
    setPage(1);
  }

  const normalizedSearchTerm = searchTerm.trim().toLowerCase();
  const now = new Date();
  const currentMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
  const currentMonthTotals = (summary?.monthly || []).filter((entry) => entry.month === currentMonth);
  const filteredExpenses = expenses.filter((expense) => {
    if (!normalizedSearchTerm) return true;

    const merchant = (expense?.merchant || "").toLowerCase();
    const description = (expense?.description || "").toLowerCase();
    return merchant.includes(normalizedSearchTerm) || description.includes(normalizedSearchTerm);
  });

  return (
    <div className="space-y-6">
      <TopNav user={user} />

      <div className="rounded-xl border border-border bg-surface p-6 shadow-sm">
        <div className="grid gap-4 lg:grid-cols-[1fr_auto] lg:items-end">
          <div>
            <h1 className="text-2xl font-bold text-text">Expenses</h1>
            <p className="text-sm text-muted">Filter and review submitted and draft expenses.</p>
          </div>

          <div className="flex flex-col gap-1 lg:items-end">
            <div className="flex flex-wrap items-end gap-3 lg:justify-end">
              <div className="w-full sm:w-64">
                <div className="mb-1 flex items-center justify-between">
                  <label htmlFor="search" className="text-sm font-medium text-text">
                    Search
                  </label>
                  <span className="text-[11px] text-muted">current page only</span>
                </div>
                <Input
                  id="search"
                  placeholder="Merchant or description"
                  value={searchTerm}
                  onChange={handleSearchChange}
                />
              </div>

              <div className="w-full sm:w-44">
                <Input
                  as="select"
                  id="status-filter"
                  label="Status"
                  value={statusFilter}
                  onChange={handleStatusChange}
                >
                  {STATUS_OPTIONS.map((status) => (
                    <option key={status} value={status}>
                      {status}
                    </option>
                  ))}
                </Input>
              </div>

              <div className="w-full sm:w-52">
                <Input
                  as="select"
                  id="category-filter"
                  label="Category"
                  value={categoryFilter}
                  onChange={handleCategoryChange}
                >
                  <option value="all">all</option>
                  {categories.map((category) => (
                    <option key={category.id} value={String(category.id)}>
                      {category.name}
                    </option>
                  ))}
                </Input>
              </div>

              {searchTerm ? (
                <div className="w-full sm:w-auto">
                  <span className="mb-1 block h-5 text-xs font-semibold uppercase tracking-wide opacity-0">
                    Clear
                  </span>
                  <Button variant="secondary" className="w-full sm:w-auto" onClick={clearSearch}>
                    Clear
                  </Button>
                </div>
              ) : null}

              {user?.role === "employee" ? (
                <div className="w-full sm:w-auto">
                  <span className="mb-1 block h-5 text-xs font-semibold uppercase tracking-wide opacity-0">
                    New
                  </span>
                  <Link href="/expenses/new">
                    <Button className="w-full sm:w-auto">New Expense</Button>
                  </Link>
                </div>
              ) : null}
            </div>
          </div>
        </div>
      </div>

      {loading ? <p className="text-sm text-muted">Loading expenses...</p> : null}
      {error ? <p className="text-sm font-medium text-badge-rejected-foreground">{error}</p> : null}
      {!loading && !error && forbidden ? (
        <ForbiddenState message="You do not have access to view expenses." />
      ) : null}

      {!loading && !error && !forbidden && summary ? (
        <div className="rounded-xl border border-border bg-surface p-5 shadow-sm">
          <h2 className="text-sm font-semibold uppercase tracking-wide text-muted">Summary</h2>
          <div className="mt-3 grid gap-3 sm:grid-cols-3">
            <div className="rounded-lg border border-border/70 bg-accent/20 p-3">
              <p className="text-xs uppercase tracking-wide text-muted">All-time count</p>
              <p className="mt-1 text-2xl font-semibold text-text">{formatCount(summary?.all_time?.count)}</p>
            </div>
            <div className="rounded-lg border border-border/70 bg-accent/20 p-3">
              <p className="text-xs uppercase tracking-wide text-muted">All-time totals</p>
              <div className="mt-2 space-y-1 text-sm text-text">
                {(summary?.all_time?.totals || []).map((total) => (
                  <div
                    key={`all-time-${total.currency}`}
                    className="flex items-center justify-between rounded border border-border/50 bg-surface/60 px-2 py-1"
                  >
                    <span className="font-medium">{total.currency}</span>
                    <span>{formatCents(total.amount_cents)}</span>
                  </div>
                ))}
                {(summary?.all_time?.totals || []).length === 0 ? <p>-</p> : null}
              </div>
            </div>
            <div className="rounded-lg border border-border/70 bg-accent/20 p-3">
              <p className="text-xs uppercase tracking-wide text-muted">Current month totals</p>
              <div className="mt-2 space-y-1 text-sm text-text">
                {currentMonthTotals.map((total) => (
                  <div
                    key={`month-${total.month}-${total.currency}`}
                    className="flex items-center justify-between rounded border border-border/50 bg-surface/60 px-2 py-1"
                  >
                    <span className="font-medium">{total.currency}</span>
                    <span>{formatCents(total.amount_cents)}</span>
                  </div>
                ))}
                {currentMonthTotals.length === 0 ? <p>-</p> : null}
              </div>
            </div>
          </div>
        </div>
      ) : null}

      {!loading && !error && !forbidden ? (
        <div className="overflow-x-auto rounded-xl border border-border bg-surface shadow-sm">
          <table className="w-full min-w-[760px] divide-y divide-border text-sm">
            <thead className="bg-accent/25 text-left text-xs font-semibold uppercase tracking-wide text-muted">
              <tr>
                <th className="px-4 py-3">Merchant</th>
                <th className="px-4 py-3">Employee</th>
                <th className="px-4 py-3">Category</th>
                <th className="px-4 py-3">Amount</th>
                <th className="px-4 py-3">Incurred On</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border/60">
              {filteredExpenses.map((expense) => (
                <tr key={expense.id} className="hover:bg-accent/20">
                  <td className="px-4 py-3 text-text">
                    {expense.merchant || "-"}
                  </td>
                  <td className="px-4 py-3 text-text">
                    {expense.user?.email || "-"}
                  </td>
                  <td className="px-4 py-3 text-text">
                    {expense.category?.name || "-"}
                  </td>
                  <td className="px-4 py-3 text-text">
                    {formatMoney(expense.currency, expense.amount_cents)}
                  </td>
                  <td className="px-4 py-3 text-text">{formatDate(expense.incurred_on)}</td>
                  <td className="px-4 py-3">
                    <Badge status={expense.status}>{expense.status}</Badge>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex gap-2">
                      <Link className="font-medium text-primary hover:text-primary/80" href={`/expenses/${expense.id}`}>
                        View
                      </Link>
                      <Link className="font-medium text-text hover:text-muted" href={`/expenses/${expense.id}#audit`}>
                        Audit Logs
                      </Link>
                    </div>
                  </td>
                </tr>
              ))}

              {filteredExpenses.length === 0 ? (
                <tr>
                  <td className="px-4 py-6 text-center text-muted" colSpan={7}>
                    {searchTerm ? "No expenses match your search on this page." : "No expenses found."}
                  </td>
                </tr>
              ) : null}
            </tbody>
          </table>
        </div>
      ) : null}

      {!forbidden && pagination ? (
        <div className="flex items-center justify-between rounded-xl border border-border bg-surface p-4 text-sm shadow-sm">
          <p className="text-muted">
            Page {formatCount(pagination.page)} of {formatCount(pagination.pages)} • Total {formatCount(pagination.count)}
          </p>
          <div className="flex gap-2">
            <Button
              variant="secondary"
              disabled={page <= 1}
              onClick={() => setPage((prev) => Math.max(prev - 1, 1))}
            >
              Previous
            </Button>
            <Button
              variant="secondary"
              disabled={page >= pagination.pages}
              onClick={() => setPage((prev) => Math.min(prev + 1, pagination.pages))}
            >
              Next
            </Button>
          </div>
        </div>
      ) : null}
    </div>
  );
}
