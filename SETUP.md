# Sistema de Agendamento — Paula Estefanato (protótipo)

Frontend estático (sem servidor próprio) + Supabase (banco + login) + Render (hospedagem).
Feito pra você mostrar funcionando de verdade pro cliente antes de fechar produção.

## O que já existe

- `index.html` — página de vendas
- `agendamento.html` — fluxo de agendamento (serviço → data → horário → dados → WhatsApp)
- `admin/index.html` + `admin/dashboard.html` — painel da Paula (login, ver/confirmar/cancelar agendamentos, bloquear horário)
- `sql/schema.sql` — cria as tabelas no Supabase
- `js/supabase-config.js` — onde você cola as chaves do Supabase e configura horário de funcionamento

**Como funciona o "WhatsApp" nesse protótipo:** ao confirmar, o sistema salva o agendamento no banco (status `pendente`) e abre o WhatsApp da Paula com a mensagem já preenchida. Não é um bot automático ainda — é o suficiente pra demonstrar o fluxo. Automatizar confirmação/lembrete via WhatsApp real é o próximo passo, depois que o cliente aprovar o protótipo.

## Passo 1 — Criar o projeto no Supabase

1. Crie conta em [supabase.com](https://supabase.com) e um novo projeto (grátis).
2. Anote a senha do banco que você definir.
3. Vá em **SQL Editor > New query**, cole todo o conteúdo de `sql/schema.sql` e rode.
4. Vá em **Project Settings > API** e copie:
   - `Project URL`
   - `anon public key`
5. Abra `js/supabase-config.js` e cole os dois valores em `SUPABASE_CONFIG`.
6. No mesmo arquivo, ajuste `SALON_CONFIG.whatsappNumber` para o número real da Paula.

## Passo 2 — Criar o login da Paula

1. No Supabase, vá em **Authentication > Users > Add user**.
2. Crie um usuário com o e-mail e senha que a Paula vai usar pra entrar no painel (`admin/index.html`).
3. Pronto — o RLS do banco já libera acesso total aos agendamentos pra qualquer usuário autenticado.

## Passo 3 — Testar local

Abrir o `index.html` direto no navegador (duplo clique) já funciona pra ver o layout. Para o fluxo de agendamento (que puxa dados do Supabase), o ideal é servir os arquivos por um servidor local em vez de abrir como `file://`:

```
cd "Projetos/Paula Estefanato"
npx serve .
```

(ou qualquer servidor estático — Python: `python -m http.server 8000`)

## Passo 4 — Publicar no Render (pra mostrar pro cliente)

1. Suba a pasta `Projetos/Paula Estefanato` pra um repositório no GitHub.
2. No [Render](https://render.com), crie um **Static Site** apontando pro repositório.
3. Build command: (vazio) — Publish directory: `.`
4. Deploy. Você recebe uma URL tipo `paula-estefanato.onrender.com` pra mandar pro cliente.

## Depois que o cliente aprovar

Próximos passos naturais: enviar confirmação/lembrete automático por WhatsApp (Cloud API oficial ou Baileys), notificar a Paula quando cair um agendamento novo, e talvez SMS/e-mail de backup. Podemos evoluir esse mesmo banco sem quebrar nada do que já existe.
