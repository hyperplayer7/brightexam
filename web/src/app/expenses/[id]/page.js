"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import Badge from "../../../components/Badge";
import Button from "../../../components/Button";
import Input from "../../../components/Input";
import TopNav from "../../../components/TopNav";
import { getCurrentUser } from "../../../lib/auth";
import {
  approveExpense,
  deleteExpense,
  getExpense,
  rejectExpense,
  submitExpense
} from "../../../lib/api";

function formatDate(value) {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleString();
}

export default function ExpenseDetailPage() {
  const params = useParams();
  const router = useRouter();
  const expenseId = params.id;

  const [user, setUser] = useState(null);
  const [expense, setExpense] = useState(null);
  const [rejectionReason, setRejectionReason] = useState("");
  const [showReject, setShowReject] = useState(false);
  const [loading, setLoading] = useState(true);
  const [processing, setProcessing] = useState(false);
  const [error, setError] = useState("");

  async function loadData() {
    try {
      setLoading(true);
      setError("");
      const [currentUser, expenseResponse] = await Promise.all([
        getCurrentUser(),
        getExpense(expenseId)
      ]);
      setUser(currentUser);
      setExpense(expenseResponse?.data || null);
    } catch (err) {
      if (err.status === 401) {
        router.push("/login");
        return;
      }
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadData();
  }, [expenseId]);

  async function handleDelete() {
    if (!window.confirm("Delete this draft expense?")) return;

    try {
      setProcessing(true);
      await deleteExpense(expenseId);
      router.push("/expenses");
    } catch (err) {
      setError(err.message);
    } finally {
      setProcessing(false);
    }
  }

  async function handleSubmitExpense() {
    try {
      setProcessing(true);
      setError("");
      await submitExpense(expenseId);
      await loadData();
    } catch (err) {
      setError(err.message);
    } finally {
      setProcessing(false);
    }
  }

  async function handleApprove() {
    try {
      setProcessing(true);
      setError("");
      await approveExpense(expenseId);
      await loadData();
    } catch (err) {
      setError(err.message);
    } finally {
      setProcessing(false);
    }
  }

  async function handleReject() {
    try {
      setProcessing(true);
      setError("");
      await rejectExpense(expenseId, rejectionReason);
      setShowReject(false);
      setRejectionReason("");
      await loadData();
    } catch (err) {
      setError(err.message);
    } finally {
      setProcessing(false);
    }
  }

  const isOwnerDraft =
    user?.role === "employee" && expense?.user_id === user?.id && expense?.status === "drafted";
  const isReviewerSubmitted = user?.role === "reviewer" && expense?.status === "submitted";

  return (
    <div className="space-y-6">
      <TopNav user={user} />

      <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <div className="mb-4 flex items-center justify-between">
          <h1 className="text-2xl font-bold text-slate-900">Expense #{expenseId}</h1>
          <Link href="/expenses" className="text-sm font-medium text-brand-700 hover:text-brand-600">
            Back
          </Link>
        </div>

        {loading ? <p className="text-sm text-slate-600">Loading expense...</p> : null}
        {error ? <p className="mb-4 text-sm font-medium text-rose-700">{error}</p> : null}

        {!loading && expense ? (
          <div className="space-y-4">
            <div className="grid gap-3 text-sm text-slate-700 sm:grid-cols-2">
              <p><span className="font-semibold">Merchant:</span> {expense.merchant}</p>
              <p><span className="font-semibold">Amount:</span> {expense.currency} {(expense.amount_cents / 100).toFixed(2)}</p>
              <p><span className="font-semibold">Incurred on:</span> {expense.incurred_on}</p>
              <p><span className="font-semibold">Status:</span> <Badge status={expense.status}>{expense.status}</Badge></p>
              <p><span className="font-semibold">Submitted at:</span> {formatDate(expense.submitted_at)}</p>
              <p><span className="font-semibold">Reviewed at:</span> {formatDate(expense.reviewed_at)}</p>
            </div>
            <p className="text-sm text-slate-700"><span className="font-semibold">Description:</span> {expense.description}</p>
            {expense.rejection_reason ? (
              <p className="text-sm text-rose-700"><span className="font-semibold">Rejection reason:</span> {expense.rejection_reason}</p>
            ) : null}

            <div className="flex flex-wrap gap-2 pt-2">
              {isOwnerDraft ? (
                <>
                  <Link href={`/expenses/${expense.id}/edit`}>
                    <Button variant="secondary">Edit</Button>
                  </Link>
                  <Button variant="secondary" onClick={handleDelete} disabled={processing}>Delete</Button>
                  <Button onClick={handleSubmitExpense} disabled={processing}>Submit</Button>
                </>
              ) : null}

              {isReviewerSubmitted ? (
                <>
                  <Button onClick={handleApprove} disabled={processing}>Approve</Button>
                  <Button variant="secondary" onClick={() => setShowReject((prev) => !prev)} disabled={processing}>
                    Reject
                  </Button>
                </>
              ) : null}
            </div>

            {showReject ? (
              <div className="mt-3 rounded-lg border border-slate-200 bg-slate-50 p-3">
                <Input
                  id="rejection_reason"
                  label="Rejection reason"
                  value={rejectionReason}
                  onChange={(event) => setRejectionReason(event.target.value)}
                />
                <div className="mt-3 flex gap-2">
                  <Button onClick={handleReject} disabled={processing || !rejectionReason.trim()}>
                    Confirm Reject
                  </Button>
                  <Button variant="secondary" onClick={() => setShowReject(false)} disabled={processing}>
                    Cancel
                  </Button>
                </div>
              </div>
            ) : null}
          </div>
        ) : null}
      </div>
    </div>
  );
}
