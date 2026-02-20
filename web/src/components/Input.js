export default function Input({
  label,
  id,
  className = "",
  as = "input",
  children,
  ...props
}) {
  const commonClassName = `w-full rounded-lg border border-border bg-background px-3 py-2 text-sm text-text shadow-sm placeholder:text-muted focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/40 ${className}`.trim();

  return (
    <label className="block">
      {label ? <span className="mb-1 block text-sm font-medium text-text">{label}</span> : null}
      {as === "select" ? (
        <select id={id} className={commonClassName} {...props}>
          {children}
        </select>
      ) : (
        <input id={id} className={commonClassName} {...props} />
      )}
    </label>
  );
}
