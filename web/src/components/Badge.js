const STATUS_STYLES = {
  drafted: "bg-slate-100 text-slate-700",
  submitted: "bg-amber-100 text-amber-800",
  approved: "bg-emerald-100 text-emerald-800",
  rejected: "bg-rose-100 text-rose-800"
};

export default function Badge({ children, status }) {
  const colorClassName = STATUS_STYLES[status] || "bg-slate-100 text-slate-700";

  return (
    <span className={`inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold capitalize ${colorClassName}`}>
      {children}
    </span>
  );
}
