import "./globals.css";
import ThemeProvider from "../components/theme/ThemeProvider";

export const metadata = {
  title: "Expense Tracker",
  description: "Expense Tracker frontend"
};

export default function RootLayout({ children }) {
  return (
    <html lang="en" data-theme="light">
      <body className="min-h-screen bg-background text-text antialiased">
        <ThemeProvider>
          <main>{children}</main>
        </ThemeProvider>
      </body>
    </html>
  );
}
