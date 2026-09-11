# Guia de configuração — Painel CRM (réplica própria)

Este painel precisa de um banco de dados (Supabase) para login e para salvar
os dados das campanhas. Como você pediu um banco novo e independente do
original, siga os passos abaixo — leva uns 10 minutos, tudo por clique,
sem precisar saber programar.

## 1. Criar o projeto no Supabase

1. Entre em https://supabase.com e crie uma conta (dá para usar login do
   Google/GitHub) ou faça login se já tiver uma.
2. Clique em **New project**.
3. Escolha uma organização (ou crie uma), dê um nome ao projeto (ex:
   `painel-crm-betdasorte`), defina uma **senha do banco** (guarde essa
   senha num lugar seguro — você não vai precisar dela para o dia a dia,
   mas é bom não perder) e escolha a região mais próxima (ex: São Paulo).
4. Clique em **Create new project** e aguarde 1–2 minutos até ele ficar
   pronto.

## 2. Rodar o script que cria as tabelas

1. No menu lateral do projeto, clique no ícone de **SQL Editor**.
2. Clique em **New query**.
3. Abra o arquivo `schema.sql` (que veio junto com este guia), copie todo
   o conteúdo e cole na área de edição.
4. Clique em **Run** (ou Ctrl+Enter). Deve aparecer "Success. No rows
   returned".

Isso cria as três tabelas do painel (`campanhas`, `config`, `perfis`), as
regras de permissão (RLS) e a sincronização em tempo real — replicando
exatamente como o painel original funciona, só que no seu banco.

## 3. Criar o seu usuário de login

1. No menu lateral, vá em **Authentication → Users**.
2. Clique em **Add user → Create new user**.
3. Preencha seu e-mail e uma senha, e marque **Auto Confirm User** (assim
   você não precisa confirmar por e-mail). Clique em **Create user**.
4. Volte no menu lateral, vá em **Table Editor**, abra a tabela **perfis**.
5. Clique em **Insert → Insert row** e preencha:
   - `email`: o mesmo e-mail que você usou no passo 3 (minúsculo)
   - `nome`: seu nome
   - `papel`: `editor`
6. Salve.

Repita os passos 1–5 para cada pessoa da equipe que deve **editar** o
painel. Quem só precisa visualizar também pode logar sem estar em
`perfis` — ou com `papel = leitor` — mas não vai poder editar as células.

## 4. Pegar a URL e a chave do projeto

1. No menu lateral, vá em **Project Settings → API**.
2. Copie o campo **Project URL** (algo como
   `https://xxxxxxxxxxxx.supabase.co`).
3. Copie o campo **anon public** (embaixo de "Project API keys" — é uma
   chave pública, começa com `sb_publishable_...` ou `eyJ...`).

Me mande essas duas informações (Project URL e a chave anon public) para
eu finalizar o `index.html` e publicar o site. Essa chave é feita para
ficar visível no código do site (é assim que o painel original também
funciona) — quem decide o que cada pessoa pode ler ou escrever são as
regras de permissão (RLS) que já ficaram configuradas no passo 2, não a
chave em si.

**Não preciso, e não peço, da senha do banco nem da "service_role key"**
— essas duas são secretas e não precisam sair do seu Supabase.
