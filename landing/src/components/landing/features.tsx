import { features, stats } from "@/data/site-content";
import { SectionHeading } from "@/components/ui/section-heading";

export function Features() {
  return (
    <section
      id="funcionalidades"
      className="bg-slate-100 py-20 sm:py-24"
    >
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <SectionHeading
          eyebrow="Funcionalidades"
          title="Tudo o que a oficina precisa para operar com mais controle"
          description="Do atendimento ao financeiro, o OSMech centraliza cada etapa da operação em um só lugar — para você ter mais clareza, menos retrabalho e mais tempo focado no que importa."
        />

        <div className="mt-12 grid gap-6 lg:grid-cols-[1.15fr_0.85fr]">
          <div className="grid gap-6 md:grid-cols-2">
            {features.map((feature) => (
              <article
                key={feature.title}
                className="rounded-3xl bg-white p-8 shadow-sm ring-1 ring-slate-200"
              >
                <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-brand-50 text-lg font-semibold text-brand-700">
                  {feature.title.charAt(0)}
                </div>
                <h3 className="mt-5 text-xl font-semibold text-slate-950">
                  {feature.title}
                </h3>
                <p className="mt-3 text-base leading-7 text-slate-600">
                  {feature.description}
                </p>
              </article>
            ))}
          </div>

          <aside className="rounded-[2rem] bg-slate-950 p-8 text-white">
            <p className="text-sm font-semibold uppercase tracking-[0.24em] text-brand-300">
              Por que isso importa
            </p>
            <h3 className="mt-5 text-3xl font-semibold tracking-tight">
              Menos improviso, mais gestão
            </h3>
            <p className="mt-4 text-base leading-7 text-slate-300">
              Quando tudo fica concentrado em um sistema só, a oficina ganha
              velocidade no atendimento, reduz falhas de comunicação e melhora
              a leitura financeira da operação.
            </p>

            <div className="mt-8 space-y-4">
              {stats.map((stat) => (
                <div
                  key={stat.label}
                  className="rounded-3xl border border-white/10 bg-white/5 p-5"
                >
                  <p className="text-2xl font-semibold text-white">{stat.value}</p>
                  <p className="mt-2 text-sm leading-6 text-slate-300">
                    {stat.label}
                  </p>
                </div>
              ))}
            </div>
          </aside>
        </div>
      </div>
    </section>
  );
}
