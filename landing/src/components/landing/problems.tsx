import { problems } from "@/data/site-content";
import { SectionHeading } from "@/components/ui/section-heading";

export function Problems() {
  return (
    <section className="bg-white py-20 sm:py-24">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <SectionHeading
          eyebrow="Desafios da oficina"
          title="Os gargalos que travam o crescimento aparecem todos os dias"
          description="A rotina de uma oficina fica mais cara e menos previsível quando a operação depende de processos manuais e informações descentralizadas."
        />

        <div className="mt-12 grid gap-6 lg:grid-cols-3">
          {problems.map((problem, index) => (
            <article
              key={problem.title}
              className="rounded-3xl border border-slate-200 bg-slate-50 p-8"
            >
              <span className="text-sm font-semibold uppercase tracking-[0.24em] text-brand-700">
                0{index + 1}
              </span>
              <h3 className="mt-5 text-2xl font-semibold text-slate-950">
                {problem.title}
              </h3>
              <p className="mt-4 text-base leading-7 text-slate-600">
                {problem.description}
              </p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
