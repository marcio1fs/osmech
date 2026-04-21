# OSMech Landing

Landing page institucional do OSMech feita em Next.js, TypeScript e TailwindCSS.

## Requisitos

- Node.js 18+ (recomendado Node 20+)

## Rodando localmente

```bash
npm install
npm run dev
```

Abra `http://localhost:3000`.

## Build de produção

```bash
npm run build
npm run start
```

## Estrutura

- `src/app`: rotas App Router, metadata, sitemap e robots
- `src/components`: seções e componentes reutilizáveis da landing
- `src/data/site-content.ts`: conteúdo centralizado da página

## Integração

Todos os CTAs e botões direcionam para o sistema existente:

- `https://app.osmech.com.br`
