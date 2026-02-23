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
  getExpenseAuditLogs,
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
  const [auditLoading, setAuditLoading] = useState(true);
  const [auditLogs, setAuditLogs] = useState([]);
  const [auditError, setAuditError] = useState("");
  const [processing, setProcessing] = useState(false);
  const [error, setError] = useState("");

  function renderMetadata(metadata) {
    if (!metadata || (typeof metadata === "object" && Object.keys(metadata).length === 0)) {
      return <span className="text-muted">-</span>;
    }

    return (
      <pre className="overflow-x-auto rounded bg-accent/25 p-2 text-xs text-text">
        {JSON.stringify(metadata, null, 2)}
      </pre>
    );
  }

  async function loadExpense() {
    try {
      setLoading(true);
      setError("");
      const [currentUser, expenseResponse] = await Promise.all([getCurrentUser(), getExpense(expenseId)]);
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

  async function loadAuditLogs() {
    try {
      setAuditLoading(true);
      setAuditError("");
      const response = await getExpenseAuditLogs(expenseId);
      setAuditLogs(response?.data || []);
    } catch (err) {
      if (err.status === 401) {
        router.push("/login");
        return;
      }
      setAuditError(err.message);
    } finally {
      setAuditLoading(false);
    }
  }

  async function loadAll() {
    await Promise.all([loadExpense(), loadAuditLogs()]);
  }

  useEffect(() => {
    loadAll();
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
      await loadAll();
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
      await loadAll();
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
      await loadAll();
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

      <div className="rounded-xl border border-border bg-surface p-6 shadow-sm">
        <div className="mb-4 flex items-center justify-between">
          <h1 className="text-2xl font-bold text-text">Expense #{expenseId}</h1>
          <Link href="/expenses" className="text-sm font-medium text-primary hover:text-primary/80">
            Back
          </Link>
        </div>

        {loading ? <p className="text-sm text-muted">Loading expense...</p> : null}
        {error ? <p className="mb-4 text-sm font-medium text-badge-rejected-foreground">{error}</p> : null}

        {!loading && expense ? (
          <div className="space-y-4">
            <div className="grid gap-3 text-sm text-text sm:grid-cols-2">
              <p><span className="font-semibold">Employee:</span> {expense.user?.email || "-"}</p>
              <p><span className="font-semibold">Reviewer:</span> {expense.reviewer?.email || "-"}</p>
              <p><span className="font-semibold">Merchant:</span> {expense.merchant}</p>
              <p><span className="font-semibold">Category:</span> {expense.category?.name || "-"}</p>
              <p><span className="font-semibold">Amount:</span> {expense.currency} {(expense.amount_cents / 100).toFixed(2)}</p>
              <p><span className="font-semibold">Incurred on:</span> {expense.incurred_on}</p>
              <p><span className="font-semibold">Status:</span> <Badge status={expense.status}>{expense.status}</Badge></p>
              <p><span className="font-semibold">Submitted at:</span> {formatDate(expense.submitted_at)}</p>
              <p><span className="font-semibold">Reviewed at:</span> {formatDate(expense.reviewed_at)}</p>
            </div>
            <p className="text-sm text-text"><span className="font-semibold">Description:</span> {expense.description}</p>
            {expense.rejection_reason ? (
              <p className="text-sm text-badge-rejected-foreground"><span className="font-semibold">Rejection reason:</span> {expense.rejection_reason}</p>
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
              <div className="mt-3 rounded-lg border border-border bg-accent/20 p-3">
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

      <div id="audit" className="rounded-xl border border-border bg-surface p-6 shadow-sm">
        <h2 className="mb-3 text-xl font-semibold text-text">Activity / Audit Logs</h2>
        {auditLoading ? <p className="text-sm text-muted">Loading audit logs...</p> : null}
        {auditError ? <p className="mb-4 text-sm font-medium text-badge-rejected-foreground">{auditError}</p> : null}

        {!auditLoading && !auditError ? (
          <div className="space-y-3">
            {auditLogs.map((log) => (
              <div key={log.id} className="rounded-lg border border-border p-3">
                <div className="mb-2 flex flex-wrap items-center gap-2 text-xs text-muted">
                  <span>{formatDate(log.created_at)}</span>
                  <span className="rounded bg-accent/30 px-2 py-1 font-semibold text-text">{log.action}</span>
                  <span>
                    Actor: {log.actor?.email || "-"} ({log.actor?.role || "-"})
                  </span>
                </div>
                <p className="mb-2 text-sm text-text">
                  <span className="font-semibold">Status change:</span> {log.from_status || "-"} → {log.to_status || "-"}
                </p>
                {renderMetadata(log.metadata)}
              </div>
            ))}
            {auditLogs.length === 0 ? <p className="text-sm text-muted">No audit logs yet.</p> : null}
          </div>
        ) : null}
      </div>
    </div>
  );
}
