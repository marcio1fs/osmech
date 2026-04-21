import Link from "next/link";
import type { ReactNode } from "react";

type ButtonLinkProps = {
  href: string;
  children: ReactNode;
  variant?: "primary" | "secondary" | "ghost";
  external?: boolean;
};

const variants = {
  primary:
    "bg-brand-600 text-white shadow-lg shadow-brand-600/30 hover:bg-brand-700",
  secondary:
    "bg-white text-slate-950 ring-1 ring-slate-200 hover:bg-slate-50",
  ghost:
    "bg-white/10 text-white ring-1 ring-white/20 backdrop-blur hover:bg-white/20"
};

export function ButtonLink({
  href,
  children,
  variant = "primary",
  external = false
}: ButtonLinkProps) {
  return (
    <Link
      href={href}
      target={external ? "_blank" : undefined}
      rel={external ? "noreferrer" : undefined}
      className={`inline-flex items-center justify-center rounded-full px-6 py-3 text-sm font-semibold transition duration-200 ${variants[variant]}`}
    >
      {children}
    </Link>
  );
}
