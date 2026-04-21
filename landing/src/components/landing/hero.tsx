import Link from "next/link";

import { appUrl } from "@/data/site-content";
import { ButtonLink } from "@/components/ui/button-link";

export function Hero() {
  return (
    <section className="relative overflow-hidden bg-slate-950 text-white">
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_left,_rgba(37,99,235,0.35),_transparent_35%),radial-gradient(circle_at_bottom_right,_rgba(14,165,233,0.2),_transparent_30%)]" />
      <div className="absolute inset-0 bg-hero-grid bg-[size:56px_56px] opacity-20" />

      <div className="relative mx-auto grid max-w-7xl gap-14 px-6 py-20 lg:grid-cols-[1.1fr_0.9fr] lg:px-8 lg:py-28">
        <div className="max-w-2xl">
          <span className="inline-flex rounded-full border border-white/15 bg-white/10 px-4 py-2 text-xs font-semibold uppercase tracking-[0.28em] text-brand-200">
            Sistema SaaS para oficinas mecânicas
          </span>
          <h1 className="mt-8 text-4xl font-semibold tracking-tight sm:text-5xl lg:text-6xl">
            Sistema completo para oficinas mecânicas
          </h1>
          <p className="mt-6 max-w-xl text-lg leading-8 text-slate-300">
            Gerencie ordens de serviço, clientes e finanças em um só lugar,
            com uma operação mais organizada, profissional e pronta para
            crescer.
          </p>

          <div className="mt-10 flex flex-col gap-4 sm:flex-row">
            <ButtonLink href={appUrl} external>
              Testar grátis
            </ButtonLink>
            <ButtonLink href="#planos" variant="ghost">
              Ver planos
            </ButtonLink>
          </div>

          <div className="mt-10 flex flex-wrap items-center gap-6 text-sm text-slate-300">
            <span>Sem instalação complicada</span>
            <span className="h-1.5 w-1.5 rounded-full bg-brand-400" />
            <span>Acesso online</span>
            <span className="h-1.5 w-1.5 rounded-full bg-brand-400" />
            <span>Pronto para usar na rotina da oficina</span>
          </div>
        </div>

        <div className="relative">
          <div className="rounded-[2rem] border border-white/10 bg-white/10 p-3 shadow-glow backdrop-blur">
            <div className="overflow-hidden rounded-[1.5rem] bg-slate-900 ring-1 ring-white/10">
              <div className="border-b border-white/10 px-5 py-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-semibold text-white">
                      Painel OSMech
                    </p>
                    <p className="text-xs text-slate-400">
                      Controle da operação em tempo real
                    </p>
                  </div>
                  <Link
                    href={appUrl}
                    target="_blank"
                    rel="noreferrer"
                    className="rounded-full bg-brand-500 px-3 py-1 text-xs font-semibold text-white"
                  >
                    Acessar sistema
                  </Link>
                </div>
              </div>

              <div className="grid gap-4 p-5 sm:grid-cols-2">
                <div className="rounded-2xl bg-slate-800 p-5">
                  <p className="text-sm text-slate-400">Ordens abertas</p>
                  <p className="mt-3 text-3xl font-semibold">18</p>
                  <p className="mt-2 text-sm text-emerald-400">
                    +12% de produtividade nesta semana
                  </p>
                </div>
                <div className="rounded-2xl bg-slate-800 p-5">
                  <p className="text-sm text-slate-400">Fluxo mensal</p>
                  <p className="mt-3 text-3xl font-semibold">R$ 28,4 mil</p>
                  <p className="mt-2 text-sm text-brand-300">
                    Visão rápida de receitas e despesas
                  </p>
                </div>
                <div className="rounded-2xl bg-slate-800 p-5 sm:col-span-2">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium text-white">
                        Histórico recente de veículos
                      </p>
                      <p className="text-xs text-slate-400">
                        Atendimento com contexto e agilidade
                      </p>
                    </div>
                    <span className="rounded-full bg-emerald-400/15 px-3 py-1 text-xs font-semibold text-emerald-300">
                      Atualizado
                    </span>
                  </div>
                  <div className="mt-4 space-y-3">
                    {[
                      "Fiat Strada 2021 • Revisão completa",
                      "Onix 2020 • Troca de freios",
                      "Hilux 2022 • Diagnóstico elétrico"
                    ].map((item) => (
                      <div
                        key={item}
                        className="rounded-2xl border border-white/5 bg-slate-900/70 px-4 py-3 text-sm text-slate-300"
                      >
                        {item}
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
