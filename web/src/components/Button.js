export default function Button({ children, className = "", variant = "primary", ...props }) {
  const baseClassName =
    "inline-flex items-center justify-center rounded-lg px-4 py-2 text-sm font-medium transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 focus-visible:ring-offset-background disabled:cursor-not-allowed disabled:opacity-60";

  const variantClassName =
    variant === "secondary"
      ? "border border-border bg-surface text-text hover:bg-accent/20"
      : "bg-primary text-primary-foreground hover:bg-primary/90";

  return (
    <button className={`${baseClassName} ${variantClassName} ${className}`.trim()} {...props}>
      {children}
    </button>
  );
}
