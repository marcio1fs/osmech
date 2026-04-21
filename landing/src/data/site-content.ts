export const appUrl = "https://app.osmech.com.br";
export const siteUrl = "https://osmech.com.br";
export const whatsappNumber = "5577988849278";

export const navLinks = [
  { label: "Funcionalidades", href: "#funcionalidades" },
  { label: "Planos", href: "#planos" },
  { label: "Contato", href: "#contato" }
];

export const problems = [
  {
    title: "Perda de controle dos serviços",
    description:
      "Ordens espalhadas em papel, WhatsApp e planilhas atrasam a oficina e aumentam erros operacionais."
  },
  {
    title: "Falta de organização no atendimento",
    description:
      "Sem um fluxo centralizado, fica difícil acompanhar cliente, veículo, prazo e histórico de cada serviço."
  },
  {
    title: "Financeiro sem previsibilidade",
    description:
      "Entradas e saídas desorganizadas dificultam saber o lucro real e tomar decisões com segurança."
  }
];

export const features = [
  {
    title: "Ordens de serviço",
    description:
      "Cadastre, acompanhe e finalize OS com mais agilidade e visão completa do andamento da oficina."
  },
  {
    title: "Gestão de clientes",
    description:
      "Centralize dados, contatos e recorrência de atendimento para vender melhor e fidelizar mais."
  },
  {
    title: "Controle financeiro",
    description:
      "Tenha visão clara das receitas, despesas e fluxo de caixa em um painel simples de usar."
  },
  {
    title: "Histórico de veículos",
    description:
      "Consulte rapidamente tudo o que já foi feito em cada veículo para agilizar diagnósticos e atendimento."
  },
  {
    title: "Relatórios estratégicos",
    description:
      "Acompanhe indicadores da operação e identifique oportunidades de crescimento com mais clareza."
  }
];

export const pricingPlans = [
  {
    name: "BÁSICO",
    price: "R$49,90",
    period: "/mês",
    detail: "Ideal para começar",
    highlight: false,
    features: [
      "Ordens de serviço ilimitadas",
      "Cadastro de clientes e veículos",
      "Controle financeiro básico",
      "Histórico de veículos",
      "Suporte por e-mail"
    ]
  },
  {
    name: "PRO",
    price: "R$79,90",
    period: "/mês",
    detail: "Para oficinas em crescimento",
    highlight: true,
    features: [
      "Tudo do plano Básico",
      "Relatórios estratégicos",
      "Fluxo de caixa detalhado",
      "Dashboard completo",
      "Suporte prioritário"
    ]
  },
  {
    name: "EMPRESARIAL",
    price: "R$149,90",
    period: "/mês",
    detail: "Para redes e frotas",
    highlight: false,
    features: [
      "Tudo do plano Pro",
      "Múltiplos usuários",
      "Gestão de múltiplas filiais",
      "Painel gerencial avançado",
      "Suporte dedicado"
    ]
  }
];

export const testimonials = [
  {
    quote:
      "A oficina ganhou velocidade no atendimento e hoje eu acompanho cada OS sem depender de papel.",
    name: "Carlos Henrique",
    role: "Proprietário de oficina automotiva"
  },
  {
    quote:
      "O financeiro ficou muito mais claro. Agora sei o que entra, o que sai e quais serviços dão mais retorno.",
    name: "Fernanda Souza",
    role: "Gestora administrativa"
  },
  {
    quote:
      "O histórico dos veículos ajuda demais no pós-venda e transmite mais confiança para o cliente.",
    name: "Rafael Martins",
    role: "Mecânico e consultor técnico"
  }
];

export const stats = [
  { value: "3×", label: "Mais agilidade no fechamento de ordens de serviço" },
  { value: "100%", label: "Online, sem instalação, acessível de qualquer dispositivo" },
  { value: "R$0", label: "Sem taxa de setup ou fidelidade para começar" }
];
