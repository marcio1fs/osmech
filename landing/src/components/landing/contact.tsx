"use client";

import { useState } from "react";
import { whatsappNumber } from "@/data/site-content";
import { SectionHeading } from "@/components/ui/section-heading";

function buildWhatsappUrl(name: string, phone: string, message: string) {
  const text = `Olá! Meu nome é *${name}*${phone ? `, meu telefone é ${phone}` : ""}.\n\n${message}`;
  return `https://wa.me/${whatsappNumber}?text=${encodeURIComponent(text)}`;
}

export function Contact() {
  const [form, setForm] = useState({ name: "", phone: "", message: "" });
  const [sent, setSent] = useState(false);

  function handleChange(
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) {
    setForm((prev) => ({ ...prev, [e.target.name]: e.target.value }));
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const url = buildWhatsappUrl(form.name, form.phone, form.message);
    window.open(url, "_blank", "noreferrer");
    setSent(true);
    setForm({ name: "", phone: "", message: "" });
  }

  return (
    <section id="contato" className="bg-white py-20 sm:py-24">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <div className="grid gap-14 lg:grid-cols-2 lg:gap-20">
          {/* Left column */}
          <div>
            <SectionHeading
              eyebrow="Contato"
              title="Tem alguma dúvida? Fale com a gente"
              description="Preencha o formulário e enviaremos a mensagem direto para nosso WhatsApp. Respondemos em minutos durante o horário comercial."
            />

            <div className="mt-10 space-y-6">
              {/* WhatsApp direct */}
              <a
                href={`https://wa.me/${whatsappNumber}?text=${encodeURIComponent(
                  "Olá! Gostaria de saber mais sobre o OSMech."
                )}`}
                target="_blank"
                rel="noreferrer"
                className="inline-flex items-center gap-3 rounded-full bg-emerald-500 px-6 py-3 text-sm font-semibold text-white shadow-lg shadow-emerald-500/30 transition duration-200 hover:bg-emerald-600"
              >
                <svg className="h-5 w-5 shrink-0" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z" />
                  <path d="M12 0C5.373 0 0 5.373 0 12c0 2.126.556 4.122 1.528 5.856L0 24l6.335-1.661A11.945 11.945 0 0012 24c6.627 0 12-5.373 12-12S18.627 0 12 0zm0 21.818a9.803 9.803 0 01-5.001-1.367l-.358-.214-3.762.987.997-3.648-.232-.374A9.818 9.818 0 012.182 12C2.182 6.578 6.578 2.182 12 2.182S21.818 6.578 21.818 12 17.422 21.818 12 21.818z" />
                </svg>
                Chamar no WhatsApp agora
              </a>

              <div className="flex items-center gap-4 text-sm text-slate-400">
                <span className="h-px flex-1 bg-slate-200" />
                ou use o formulário abaixo
                <span className="h-px flex-1 bg-slate-200" />
              </div>
            </div>
          </div>

          {/* Right column — form */}
          <div className="rounded-[2rem] bg-slate-50 p-8 ring-1 ring-slate-200">
            {sent ? (
              <div className="flex h-full flex-col items-center justify-center gap-4 text-center py-10">
                <div className="flex h-16 w-16 items-center justify-center rounded-full bg-emerald-100">
                  <svg className="h-8 w-8 text-emerald-600" viewBox="0 0 24 24" fill="none">
                    <path d="M5 13l4 4L19 7" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                </div>
                <h3 className="text-xl font-semibold text-slate-950">
                  Mensagem enviada!
                </h3>
                <p className="text-slate-600">
                  Uma nova aba do WhatsApp foi aberta com sua mensagem. Em breve entraremos em contato.
                </p>
                <button
                  onClick={() => setSent(false)}
                  className="mt-4 text-sm font-medium text-brand-600 hover:text-brand-700"
                >
                  Enviar outra mensagem
                </button>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="space-y-5">
                <div>
                  <label htmlFor="contact-name" className="mb-1.5 block text-sm font-medium text-slate-700">
                    Seu nome *
                  </label>
                  <input
                    id="contact-name"
                    name="name"
                    type="text"
                    required
                    placeholder="Ex: João Silva"
                    value={form.name}
                    onChange={handleChange}
                    className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-950 outline-none placeholder:text-slate-400 focus:border-brand-500 focus:ring-2 focus:ring-brand-500/20 transition duration-200"
                  />
                </div>

                <div>
                  <label htmlFor="contact-phone" className="mb-1.5 block text-sm font-medium text-slate-700">
                    WhatsApp / Telefone
                  </label>
                  <input
                    id="contact-phone"
                    name="phone"
                    type="tel"
                    placeholder="(77) 99999-9999"
                    value={form.phone}
                    onChange={handleChange}
                    className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-950 outline-none placeholder:text-slate-400 focus:border-brand-500 focus:ring-2 focus:ring-brand-500/20 transition duration-200"
                  />
                </div>

                <div>
                  <label htmlFor="contact-message" className="mb-1.5 block text-sm font-medium text-slate-700">
                    Mensagem *
                  </label>
                  <textarea
                    id="contact-message"
                    name="message"
                    rows={4}
                    required
                    placeholder="Como podemos ajudar sua oficina?"
                    value={form.message}
                    onChange={handleChange}
                    className="w-full resize-none rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-950 outline-none placeholder:text-slate-400 focus:border-brand-500 focus:ring-2 focus:ring-brand-500/20 transition duration-200"
                  />
                </div>

                <button
                  type="submit"
                  className="w-full inline-flex items-center justify-center gap-2 rounded-full bg-brand-600 px-6 py-3.5 text-sm font-semibold text-white shadow-lg shadow-brand-600/30 transition duration-200 hover:bg-brand-700"
                >
                  <svg className="h-4 w-4" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z" />
                    <path d="M12 0C5.373 0 0 5.373 0 12c0 2.126.556 4.122 1.528 5.856L0 24l6.335-1.661A11.945 11.945 0 0012 24c6.627 0 12-5.373 12-12S18.627 0 12 0zm0 21.818a9.803 9.803 0 01-5.001-1.367l-.358-.214-3.762.987.997-3.648-.232-.374A9.818 9.818 0 012.182 12C2.182 6.578 6.578 2.182 12 2.182S21.818 6.578 21.818 12 17.422 21.818 12 21.818z" />
                  </svg>
                  Enviar pelo WhatsApp
                </button>

                <p className="text-center text-xs text-slate-400">
                  Ao enviar, você será redirecionado para o WhatsApp com a mensagem preenchida.
                </p>
              </form>
            )}
          </div>
        </div>
      </div>
    </section>
  );
}
