import Link from "next/link";
import Button from "./Button";

export default function ForbiddenState({ title = "Forbidden", message = "You do not have access to this page." }) {
  return (
    <div className="rounded-xl border border-border bg-surface p-6 shadow-sm">
      <h1 className="text-2xl font-bold text-text">{title}</h1>
      <p className="mt-2 text-sm text-muted">{message}</p>
      <div className="mt-4">
        <Link href="/expenses">
          <Button variant="secondary">Back to Expenses</Button>
        </Link>
      </div>
    </div>
  );
}
