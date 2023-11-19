import { Inter } from "next/font/google";
import "./globals.css";

import { cn } from "@/lib/utils";
import RootProviders from "./rootProviders";

const inter = Inter({ subsets: ["latin"] });

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={cn("min-h-screen antialiased", inter.className)}>
        <RootProviders>{children}</RootProviders>
      </body>
    </html>
  );
}
