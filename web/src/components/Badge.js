const STATUS_STYLES = {
  drafted: "bg-badge-drafted text-badge-drafted-foreground",
  submitted: "bg-badge-submitted text-badge-submitted-foreground",
  approved: "bg-badge-approved text-badge-approved-foreground",
  rejected: "bg-badge-rejected text-badge-rejected-foreground"
};

export default function Badge({ children, status }) {
  const colorClassName = STATUS_STYLES[status] || "bg-badge-drafted text-badge-drafted-foreground";

  return (
    <span className={`inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold capitalize ${colorClassName}`}>
      {children}
    </span>
  );
}
