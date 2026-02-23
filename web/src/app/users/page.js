"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Button from "../../components/Button";
import ForbiddenState from "../../components/ForbiddenState";
import Input from "../../components/Input";
import TopNav from "../../components/TopNav";
import { isForbiddenError, isUnauthorizedError, requireCurrentUser } from "../../lib/auth";
import { listUsers, updateUserRole } from "../../lib/api";

const ROLE_OPTIONS = ["employee", "reviewer"];

function formatDateTime(value) {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleString();
}

function parseErrorMessage(error, fallback) {
  if (!error) return fallback;

  try {
    const parsed = JSON.parse(error.body || "{}");
    if (Array.isArray(parsed?.errors) && parsed.errors.length > 0) {
      return parsed.errors.join(", ");
    }
  } catch (_parseError) {
    // Fall back to generic error message
  }

  return error.message || fallback;
}

export default function UsersPage() {
  const router = useRouter();
  const [user, setUser] = useState(null);
  const [users, setUsers] = useState([]);
  const [draftRoles, setDraftRoles] = useState({});
  const [savingById, setSavingById] = useState({});
  const [rowMessages, setRowMessages] = useState({});
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

        const currentUser = await requireCurrentUser();
        if (currentUser?.role !== "reviewer") {
          if (!cancelled) {
            setUser(currentUser);
            setUsers([]);
          }
          return;
        }

        const response = await listUsers();
        const rows = response?.data || [];

        if (!cancelled) {
          setUser(currentUser);
          setUsers(rows);
          setDraftRoles(
            rows.reduce((acc, row) => {
              acc[row.id] = row.role;
              return acc;
            }, {})
          );
        }
      } catch (err) {
        if (cancelled) return;
        if (isUnauthorizedError(err)) {
          router.push("/login");
          return;
        }
        if (isForbiddenError(err)) {
          setForbidden(true);
          return;
        }
        setError(err.message || "Failed to load users.");
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
  }, [router]);

  function handleRoleDraftChange(userId, nextRole) {
    setDraftRoles((current) => ({ ...current, [userId]: nextRole }));
    setRowMessages((current) => ({
      ...current,
      [userId]: current[userId]?.type === "success" ? null : current[userId]
    }));
  }

  async function handleSave(userRow) {
    const nextRole = draftRoles[userRow.id];
    if (!nextRole || nextRole === userRow.role) return;

    setSavingById((current) => ({ ...current, [userRow.id]: true }));
    setRowMessages((current) => ({ ...current, [userRow.id]: null }));

    try {
      const response = await updateUserRole(userRow.id, nextRole);
      const updated = response?.data;

      setUsers((current) =>
        current.map((row) => (row.id === userRow.id ? { ...row, role: updated?.role || nextRole } : row))
      );
      setDraftRoles((current) => ({ ...current, [userRow.id]: updated?.role || nextRole }));
      setRowMessages((current) => ({
        ...current,
        [userRow.id]: { type: "success", text: "Saved" }
      }));
    } catch (err) {
      setRowMessages((current) => ({
        ...current,
        [userRow.id]: {
          type: "error",
          text: parseErrorMessage(err, "Failed to update role.")
        }
      }));
    } finally {
      setSavingById((current) => ({ ...current, [userRow.id]: false }));
    }
  }

  const isReviewer = user?.role === "reviewer";

  return (
    <div className="space-y-6">
      <TopNav user={user} />

      {loading ? <p className="text-sm text-muted">Loading users...</p> : null}
      {!loading && error ? <p className="text-sm font-medium text-badge-rejected-foreground">{error}</p> : null}
      {!loading && !error && forbidden ? (
        <ForbiddenState message="Only reviewers can manage user roles." />
      ) : null}

      {!loading && !error && !forbidden && user && !isReviewer ? (
        <ForbiddenState message="Only reviewers can manage user roles." />
      ) : null}

      {!loading && !error && !forbidden && isReviewer ? (
        <>
          <div className="rounded-xl border border-border bg-surface p-6 shadow-sm">
            <h1 className="text-2xl font-bold text-text">Users</h1>
            <p className="mt-1 text-sm text-muted">Assign employee and reviewer roles.</p>
          </div>

          <div className="overflow-x-auto rounded-xl border border-border bg-surface shadow-sm">
            <table className="w-full min-w-[760px] divide-y divide-border text-sm">
              <thead className="bg-accent/25 text-left text-xs font-semibold uppercase tracking-wide text-muted">
                <tr>
                  <th className="px-4 py-3">Email</th>
                  <th className="px-4 py-3">Current Role</th>
                  <th className="px-4 py-3">Role</th>
                  <th className="px-4 py-3">Created</th>
                  <th className="px-4 py-3">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/70">
                {users.map((userRow) => {
                  const draftRole = draftRoles[userRow.id] || userRow.role;
                  const changed = draftRole !== userRow.role;
                  const saving = Boolean(savingById[userRow.id]);
                  const message = rowMessages[userRow.id];
                  const isSelf = user?.id === userRow.id;

                  return (
                    <tr key={userRow.id} className="align-top hover:bg-accent/10">
                      <td className="px-4 py-3 text-text">
                        <div>{userRow.email}</div>
                        {isSelf ? <div className="text-xs text-muted">(you)</div> : null}
                      </td>
                      <td className="px-4 py-3 text-text">{userRow.role}</td>
                      <td className="px-4 py-3">
                        <div className="w-40">
                          <Input
                            as="select"
                            aria-label={`Role for ${userRow.email}`}
                            label={null}
                            value={draftRole}
                            onChange={(event) => handleRoleDraftChange(userRow.id, event.target.value)}
                            disabled={saving}
                          >
                            {ROLE_OPTIONS.map((role) => (
                              <option key={role} value={role}>
                                {role}
                              </option>
                            ))}
                          </Input>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-muted">{formatDateTime(userRow.created_at)}</td>
                      <td className="px-4 py-3">
                        <div className="flex items-start gap-3">
                          <Button onClick={() => handleSave(userRow)} disabled={!changed || saving}>
                            {saving ? "Saving..." : "Save"}
                          </Button>
                          {message ? (
                            <p
                              className={`pt-2 text-xs ${
                                message.type === "error"
                                  ? "text-badge-rejected-foreground"
                                  : "text-muted"
                              }`}
                            >
                              {message.text}
                            </p>
                          ) : null}
                        </div>
                      </td>
                    </tr>
                  );
                })}

                {users.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="px-4 py-6 text-center text-muted">
                      No users found.
                    </td>
                  </tr>
                ) : null}
              </tbody>
            </table>
          </div>
        </>
      ) : null}
    </div>
  );
}
