import { appUrl } from "@/data/site-content";
import { ButtonLink } from "@/components/ui/button-link";

export function FinalCta() {
  return (
    <section className="bg-slate-950 py-20 text-white sm:py-24">
      <div className="mx-auto max-w-5xl px-6 text-center lg:px-8">
        <span className="inline-flex rounded-full border border-white/10 bg-white/5 px-4 py-2 text-xs font-semibold uppercase tracking-[0.24em] text-brand-300">
          Comece agora
        </span>
        <h2 className="mt-6 text-3xl font-semibold tracking-tight sm:text-5xl">
          Comece agora a organizar sua oficina
        </h2>
        <p className="mx-auto mt-5 max-w-2xl text-lg leading-8 text-slate-300">
          Leve mais controle para o dia a dia da equipe, profissionalize o
          atendimento e centralize a operação em um único sistema.
        </p>
        <div className="mt-10">
          <ButtonLink href={appUrl} external>
            Criar conta grátis
          </ButtonLink>
        </div>
      </div>
    </section>
  );
}
