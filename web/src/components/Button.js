export default function Button({ children, className = "", variant = "primary", ...props }) {
  const baseClassName =
    "inline-flex items-center justify-center rounded-lg px-4 py-2 text-sm font-medium transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-60";

  const variantClassName =
    variant === "secondary"
      ? "border border-slate-300 bg-white text-slate-700 hover:bg-slate-100"
      : "bg-brand-600 text-white hover:bg-brand-700";

  return (
    <button className={`${baseClassName} ${variantClassName} ${className}`.trim()} {...props}>
      {children}
    </button>
  );
}
