"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Badge from "../../components/Badge";
import Button from "../../components/Button";
import Input from "../../components/Input";
import TopNav from "../../components/TopNav";
import { getCurrentUser } from "../../lib/auth";
import { listExpenses } from "../../lib/api";

function formatDate(value) {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleDateString();
}

const STATUS_OPTIONS = ["all", "drafted", "submitted", "approved", "rejected"];

export default function ExpensesPage() {
  const router = useRouter();
  const [user, setUser] = useState(null);
  const [expenses, setExpenses] = useState([]);
  const [pagination, setPagination] = useState(null);
  const [statusFilter, setStatusFilter] = useState("all");
  const [searchTerm, setSearchTerm] = useState("");
  const [page, setPage] = useState(1);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;

    async function loadData() {
      try {
        setLoading(true);
        setError("");
        const normalizedStatus = statusFilter?.trim?.() || "";

        const currentUser = await getCurrentUser();
        const expenseResponse = await listExpenses({
          status: normalizedStatus === "all" || normalizedStatus === "" ? undefined : normalizedStatus,
          page
        });

        if (!cancelled) {
          setUser(currentUser);
          setExpenses(expenseResponse?.data || []);
          setPagination(expenseResponse?.pagination || null);
        }
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
  }, [page, router, statusFilter]);

  function handleStatusChange(event) {
    setStatusFilter(event.target.value);
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
  const filteredExpenses = expenses.filter((expense) => {
    if (!normalizedSearchTerm) return true;

    const merchant = (expense?.merchant || "").toLowerCase();
    const description = (expense?.description || "").toLowerCase();
    return merchant.includes(normalizedSearchTerm) || description.includes(normalizedSearchTerm);
  });

  return (
    <div className="space-y-6">
      <TopNav user={user} />

      <div className="flex flex-col gap-3 rounded-xl border border-slate-200 bg-white p-6 shadow-sm sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Expenses</h1>
          <p className="text-sm text-slate-600">Filter and review submitted and draft expenses.</p>
        </div>

        <div className="flex flex-col gap-1">
          <div className="flex items-end gap-3">
          <div className="w-64">
            <Input
              id="search"
              label="Search"
              placeholder="Merchant or description"
              value={searchTerm}
              onChange={handleSearchChange}
            />
          </div>

          <div className="w-44">
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

          {searchTerm ? (
            <Button variant="secondary" onClick={clearSearch}>
              Clear
            </Button>
          ) : null}

          {user?.role === "employee" ? (
            <Link href="/expenses/new">
              <Button>New Expense</Button>
            </Link>
          ) : null}
          </div>
          <p className="text-xs text-slate-500">Filtering current page only</p>
        </div>
      </div>

      {loading ? <p className="text-sm text-slate-600">Loading expenses...</p> : null}
      {error ? <p className="text-sm font-medium text-rose-700">{error}</p> : null}

      {!loading && !error ? (
        <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white shadow-sm">
          <table className="w-full min-w-[760px] divide-y divide-slate-200 text-sm">
            <thead className="bg-slate-100 text-left text-xs font-semibold uppercase tracking-wide text-slate-600">
              <tr>
                <th className="px-4 py-3">Merchant</th>
                <th className="px-4 py-3">Employee</th>
                <th className="px-4 py-3">Amount</th>
                <th className="px-4 py-3">Incurred On</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredExpenses.map((expense) => (
                <tr key={expense.id} className="hover:bg-slate-50">
                  <td className="px-4 py-3 text-slate-800">
                    {expense.merchant || "-"}
                  </td>
                  <td className="px-4 py-3 text-slate-700">
                    {expense.user?.email || "-"}
                  </td>
                  <td className="px-4 py-3 text-slate-800">
                    {expense.currency} {(expense.amount_cents / 100).toFixed(2)}
                  </td>
                  <td className="px-4 py-3 text-slate-700">{formatDate(expense.incurred_on)}</td>
                  <td className="px-4 py-3">
                    <Badge status={expense.status}>{expense.status}</Badge>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex gap-2">
                      <Link className="font-medium text-brand-700 hover:text-brand-600" href={`/expenses/${expense.id}`}>
                        View
                      </Link>
                      <Link className="font-medium text-slate-700 hover:text-slate-600" href={`/expenses/${expense.id}#audit`}>
                        Audit Logs
                      </Link>
                    </div>
                  </td>
                </tr>
              ))}

              {filteredExpenses.length === 0 ? (
                <tr>
                  <td className="px-4 py-6 text-center text-slate-500" colSpan={6}>
                    {searchTerm ? "No expenses match your search on this page." : "No expenses found."}
                  </td>
                </tr>
              ) : null}
            </tbody>
          </table>
        </div>
      ) : null}

      {pagination ? (
        <div className="flex items-center justify-between rounded-xl border border-slate-200 bg-white p-4 text-sm shadow-sm">
          <p className="text-slate-600">
            Page {pagination.page} of {pagination.pages} • Total {pagination.count}
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
