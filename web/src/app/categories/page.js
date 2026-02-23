"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Button from "../../components/Button";
import Input from "../../components/Input";
import TopNav from "../../components/TopNav";
import { getCurrentUser } from "../../lib/auth";
import { createCategory, listCategories } from "../../lib/api";

function formatDateTime(value) {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleString();
}

function parseValidationError(error) {
  if (!error) return "Unable to create category.";
  if (error.status !== 422) return error.message || "Unable to create category.";

  try {
    const parsed = JSON.parse(error.body || "{}");
    const messages = [];

    if (Array.isArray(parsed?.errors)) {
      messages.push(...parsed.errors.map(String));
    } else if (parsed?.errors && typeof parsed.errors === "object") {
      Object.entries(parsed.errors).forEach(([field, fieldErrors]) => {
        if (Array.isArray(fieldErrors)) {
          fieldErrors.forEach((message) => messages.push(`${field} ${message}`));
        } else if (fieldErrors) {
          messages.push(`${field} ${String(fieldErrors)}`);
        }
      });
    } else if (parsed?.message) {
      messages.push(String(parsed.message));
    }

    return messages.length > 0 ? messages.join(", ") : error.message;
  } catch (_parseError) {
    return error.message || "Validation failed.";
  }
}

function getCategoryCreatedValue(category) {
  return category?.created_at || category?.createdAt || null;
}

export default function CategoriesPage() {
  const router = useRouter();
  const [user, setUser] = useState(null);
  const [categories, setCategories] = useState([]);
  const [name, setName] = useState("");
  const [error, setError] = useState("");
  const [submitError, setSubmitError] = useState("");
  const [loading, setLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    let cancelled = false;

    async function loadData() {
      try {
        setLoading(true);
        setError("");

        const currentUser = await getCurrentUser();
        let categoriesResponse = null;

        if (currentUser?.role === "reviewer") {
          categoriesResponse = await listCategories();
        }

        if (!cancelled) {
          setUser(currentUser);
          setCategories(categoriesResponse?.data || []);
        }
      } catch (err) {
        if (cancelled) return;

        if (err.status === 401) {
          router.push("/login");
          return;
        }

        setError(err.message || "Failed to load categories.");
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

  async function refreshCategories() {
    const response = await listCategories();
    setCategories(response?.data || []);
  }

  async function handleSubmit(event) {
    event.preventDefault();
    const trimmedName = name.trim();

    if (!trimmedName) {
      setSubmitError("Name is required.");
      return;
    }

    setIsSubmitting(true);
    setSubmitError("");

    try {
      await createCategory(trimmedName);
      setName("");
      await refreshCategories();
    } catch (err) {
      setSubmitError(parseValidationError(err));
    } finally {
      setIsSubmitting(false);
    }
  }

  const isReviewer = user?.role === "reviewer";
  const showCreatedColumn = categories.some((category) => Boolean(getCategoryCreatedValue(category)));

  return (
    <div className="space-y-6">
      <TopNav user={user} />

      {loading ? <p className="text-sm text-muted">Loading categories...</p> : null}
      {!loading && error ? <p className="text-sm font-medium text-badge-rejected-foreground">{error}</p> : null}

      {!loading && !error && user && !isReviewer ? (
        <div className="rounded-xl border border-border bg-surface p-6 shadow-sm">
          <h1 className="text-2xl font-bold text-text">Forbidden</h1>
          <p className="mt-2 text-sm text-muted">Only reviewers can manage categories.</p>
          <div className="mt-4">
            <Link href="/expenses">
              <Button variant="secondary">Back to Expenses</Button>
            </Link>
          </div>
        </div>
      ) : null}

      {!loading && !error && isReviewer ? (
        <>
          <div className="rounded-xl border border-border bg-surface p-6 shadow-sm">
            <h1 className="text-2xl font-bold text-text">Categories</h1>
            <p className="mt-1 text-sm text-muted">Create and review expense categories.</p>

            <form className="mt-5 flex flex-col gap-3 sm:flex-row sm:items-end" onSubmit={handleSubmit}>
              <div className="w-full sm:max-w-md">
                <Input
                  id="category-name"
                  label="Name"
                  placeholder="e.g. Meals"
                  value={name}
                  onChange={(event) => setName(event.target.value)}
                  disabled={isSubmitting}
                />
              </div>

              <Button type="submit" disabled={isSubmitting}>
                {isSubmitting ? "Adding..." : "Add Category"}
              </Button>
            </form>

            {submitError ? (
              <p className="mt-3 text-sm font-medium text-badge-rejected-foreground">{submitError}</p>
            ) : null}
          </div>

          <div className="overflow-x-auto rounded-xl border border-border bg-surface shadow-sm">
            <table className="w-full min-w-[420px] divide-y divide-border text-sm">
              <thead className="bg-accent/25 text-left text-xs font-semibold uppercase tracking-wide text-muted">
                <tr>
                  <th className="px-4 py-3">Name</th>
                  {showCreatedColumn ? <th className="px-4 py-3">Created</th> : null}
                </tr>
              </thead>
              <tbody className="divide-y divide-border/70">
                {categories.map((category) => (
                  <tr key={category.id} className="hover:bg-accent/10">
                    <td className="px-4 py-3 text-text">{category.name}</td>
                    {showCreatedColumn ? (
                      <td className="px-4 py-3 text-muted">
                        {formatDateTime(getCategoryCreatedValue(category))}
                      </td>
                    ) : null}
                  </tr>
                ))}
                {categories.length === 0 ? (
                  <tr>
                    <td colSpan={showCreatedColumn ? 2 : 1} className="px-4 py-6 text-center text-muted">
                      No categories yet.
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
