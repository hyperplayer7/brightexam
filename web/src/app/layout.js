import "./globals.css";

export const metadata = {
  title: "Expense Tracker",
  description: "Expense Tracker frontend"
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>
        <main>{children}</main>
      </body>
    </html>
  );
}
