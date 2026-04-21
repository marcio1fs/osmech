import type { Metadata } from "next";
import { Manrope, Space_Grotesk } from "next/font/google";

import { siteUrl } from "@/data/site-content";

import "./globals.css";

const manrope = Manrope({
  subsets: ["latin"],
  variable: "--font-manrope"
});

const spaceGrotesk = Space_Grotesk({
  subsets: ["latin"],
  variable: "--font-space-grotesk"
});

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: "Sistema para oficina mecânica | OSMech",
  description:
    "Gerencie sua oficina mecânica com controle de ordens de serviço, clientes e financeiro.",
  keywords: [
    "sistema oficina mecânica",
    "ordem de serviço mecânica",
    "software para oficina"
  ],
  openGraph: {
    title: "Sistema para oficina mecânica | OSMech",
    description:
      "Gerencie sua oficina mecânica com controle de ordens de serviço, clientes e financeiro.",
    url: siteUrl,
    siteName: "OSMech",
    locale: "pt_BR",
    type: "website"
  },
  twitter: {
    card: "summary_large_image",
    title: "Sistema para oficina mecânica | OSMech",
    description:
      "Gerencie sua oficina mecânica com controle de ordens de serviço, clientes e financeiro."
  },
  alternates: {
    canonical: "/"
  },
  robots: {
    index: true,
    follow: true
  }
};

export default function RootLayout({
  children
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="pt-BR" className="scroll-smooth">
      <body
        className={`${manrope.variable} ${spaceGrotesk.variable} bg-white font-sans text-slate-950 antialiased`}
      >
        {children}
      </body>
    </html>
  );
}
