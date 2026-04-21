import { testimonials } from "@/data/site-content";
import { SectionHeading } from "@/components/ui/section-heading";

export function SocialProof() {
  return (
    <section className="bg-slate-100 py-20 sm:py-24">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <SectionHeading
          eyebrow="O que dizem nossos clientes"
          title="Quem usa o OSMech transforma a rotina da oficina"
          description="Veja como donos de oficina e gestores estão ganhando mais controle, reduzindo erros e fechando mais serviços com o OSMech."
          center
        />

        <div className="mt-14 grid gap-6 lg:grid-cols-[1.05fr_0.95fr]">
          <div className="rounded-[2rem] bg-white p-8 shadow-sm ring-1 ring-slate-200">
            <div className="grid gap-4 md:grid-cols-2">
              <div className="rounded-3xl bg-slate-950 p-6 text-white">
                <p className="text-sm text-slate-400">Tela de ordens</p>
                <div className="mt-6 space-y-3">
                  {["OS #3021", "OS #3022", "OS #3023"].map((item) => (
                    <div
                      key={item}
                      className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm"
                    >
                      {item}
                    </div>
                  ))}
                </div>
              </div>
              <div className="rounded-3xl bg-brand-50 p-6">
                <p className="text-sm text-brand-700">Resumo financeiro</p>
                <div className="mt-6 space-y-4">
                  <div className="rounded-2xl bg-white p-4 shadow-sm ring-1 ring-brand-100">
                    <p className="text-xs uppercase tracking-[0.18em] text-slate-500">
                      Receitas
                    </p>
                    <p className="mt-2 text-2xl font-semibold text-slate-950">
                      R$ 18.240
                    </p>
                  </div>
                  <div className="rounded-2xl bg-white p-4 shadow-sm ring-1 ring-brand-100">
                    <p className="text-xs uppercase tracking-[0.18em] text-slate-500">
                      Despesas
                    </p>
                    <p className="mt-2 text-2xl font-semibold text-slate-950">
                      R$ 6.910
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div className="grid gap-6">
            {testimonials.map((testimonial) => (
              <blockquote
                key={testimonial.name}
                className="rounded-[2rem] bg-white p-8 shadow-sm ring-1 ring-slate-200"
              >
                <p className="text-lg leading-8 text-slate-700">
                  &ldquo;{testimonial.quote}&rdquo;
                </p>
                <footer className="mt-6">
                  <p className="font-semibold text-slate-950">
                    {testimonial.name}
                  </p>
                  <p className="text-sm text-slate-500">{testimonial.role}</p>
                </footer>
              </blockquote>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
