import Link from "next/link";

import { appUrl } from "@/data/site-content";

export function Footer() {
  return (
    <footer className="border-t border-slate-200 bg-white py-10 text-sm text-slate-600">
      <div className="mx-auto flex max-w-7xl flex-col gap-6 px-6 lg:flex-row lg:items-center lg:justify-between lg:px-8">
        <div>
          <p className="text-base font-semibold text-slate-950">OSMech</p>
          <p className="mt-2 max-w-md leading-6">
            Sistema de gestão para oficinas mecânicas. Controle de OS, clientes,
            financeiro e muito mais em um só lugar.
          </p>
        </div>

        <div className="flex flex-wrap gap-5">
          <Link href={appUrl} target="_blank" rel="noreferrer">
            Acessar sistema
          </Link>
          <Link href="#planos">Planos</Link>
          <Link href="mailto:contato@osmech.com.br">Contato</Link>
        </div>
      </div>
    </footer>
  );
}
