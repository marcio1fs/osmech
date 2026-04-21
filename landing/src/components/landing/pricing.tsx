import { appUrl, pricingPlans } from "@/data/site-content";
import { SectionHeading } from "@/components/ui/section-heading";
import { ButtonLink } from "@/components/ui/button-link";

export function Pricing() {
  return (
    <section id="planos" className="bg-white py-20 sm:py-24">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <SectionHeading
          eyebrow="Planos"
          title="Escolha o plano ideal para a sua oficina"
          description="Comece hoje mesmo e escolha o plano que acompanha o crescimento da sua operação. Sem taxa de adesão, sem fidelidade — cancele quando quiser."
          center
        />

        <p className="mt-4 text-center text-sm text-brand-700 font-medium">
          ✓ 7 dias grátis em todos os planos
        </p>

        <div className="mt-12 grid gap-6 lg:grid-cols-3">
          {pricingPlans.map((plan) => (
            <article
              key={plan.name}
              className={`relative rounded-[2rem] p-8 ring-1 flex flex-col ${
                plan.highlight
                  ? "bg-slate-950 text-white ring-slate-950 shadow-glow"
                  : "bg-slate-50 text-slate-950 ring-slate-200"
              }`}
            >
              {plan.highlight && (
                <span className="absolute -top-3.5 left-1/2 -translate-x-1/2 rounded-full bg-brand-500 px-4 py-1.5 text-xs font-semibold uppercase tracking-[0.18em] text-white shadow-lg">
                  Mais escolhido
                </span>
              )}

              <div>
                <h3 className="text-lg font-semibold">{plan.name}</h3>
                <p
                  className={`mt-1 text-sm ${
                    plan.highlight ? "text-slate-400" : "text-slate-500"
                  }`}
                >
                  {plan.detail}
                </p>
              </div>

              <div className="mt-8 flex items-baseline gap-1">
                <p className="text-4xl font-semibold tracking-tight">
                  {plan.price}
                </p>
                <span
                  className={`text-sm ${
                    plan.highlight ? "text-slate-400" : "text-slate-500"
                  }`}
                >
                  {plan.period}
                </span>
              </div>

              <ul
                className={`mt-8 space-y-3 text-sm flex-1 ${
                  plan.highlight ? "text-slate-300" : "text-slate-600"
                }`}
              >
                {plan.features.map((feature) => (
                  <li key={feature} className="flex items-start gap-2.5">
                    <svg
                      className={`mt-0.5 h-4 w-4 shrink-0 ${
                        plan.highlight ? "text-brand-400" : "text-brand-600"
                      }`}
                      viewBox="0 0 16 16"
                      fill="none"
                    >
                      <path
                        d="M3 8l3.5 3.5L13 4.5"
                        stroke="currentColor"
                        strokeWidth="2"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                      />
                    </svg>
                    {feature}
                  </li>
                ))}
              </ul>

              <div className="mt-8">
                <ButtonLink
                  href={appUrl}
                  external
                  variant={plan.highlight ? "primary" : "secondary"}
                >
                  Começar agora
                </ButtonLink>
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
