export default function Input({
  label,
  id,
  className = "",
  as = "input",
  children,
  ...props
}) {
  const commonClassName = `w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/40 ${className}`.trim();

  return (
    <label className="block">
      {label ? <span className="mb-1 block text-sm font-medium text-slate-700">{label}</span> : null}
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
