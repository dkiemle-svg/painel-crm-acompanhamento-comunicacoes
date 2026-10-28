-- ============================================================================
-- Painel de Campanhas CRM — Bet dá Sorte
-- Script de criação do banco (novo projeto Supabase, independente do original)
--
-- Como usar:
-- 1. No painel do Supabase, abra o seu projeto novo.
-- 2. Vá em "SQL Editor" (ícone de terminal na barra lateral) > "New query".
-- 3. Cole este arquivo inteiro e clique em "Run".
-- 4. Pode rodar mais de uma vez sem problema — o script é seguro para
--    reexecução (usa "IF NOT EXISTS" / "ON CONFLICT" onde possível).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) TABELAS
-- ---------------------------------------------------------------------------

create table if not exists public.campanhas (
  id           text primary key,                 -- gerado no navegador (ex: "c_...")
  data         date,
  hora         text,
  nome         text,
  tipo         text,                              -- "Cassino" | "Esportes" | "Gamificação" | "Institucional" | vazio
  resp         text,                              -- "Sacra" | "LV" | texto livre
  obs          text,
  link         text,
  canais       jsonb not null default '{}'::jsonb,  -- {flow: "status", email: "status", ...}
  notas        jsonb not null default '{}'::jsonb,  -- {flow: "observação do status", ...}
  excluida_em  timestamptz,                       -- soft delete: null = ativa
  criado_em    timestamptz not null default now(),
  alterado_em  timestamptz not null default now(),
  alterado_por text
);

create table if not exists public.config (
  id          integer primary key default 1,
  colunas     jsonb not null default '{}'::jsonb,     -- overrides das colunas/status por canal
  status_defs jsonb not null default '{}'::jsonb,      -- overrides de rótulo/cor dos status
  constraint config_singleton check (id = 1)
);

create table if not exists public.perfis (
  email text primary key,
  nome  text,
  papel text not null default 'leitor' check (papel in ('editor', 'leitor'))
);

-- Linha única obrigatória da tabela de configuração
insert into public.config (id) values (1)
  on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- 2) TRIGGER: carimba quem alterou e quando (equivalente ao "alterado_por"/
--    "alterado_em" que o app espera que o banco preencha sozinho)
-- ---------------------------------------------------------------------------

create or replace function public.campanhas_stamp()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    new.criado_em := coalesce(new.criado_em, now());
  end if;
  new.alterado_em := now();
  new.alterado_por := coalesce(auth.jwt() ->> 'email', new.alterado_por, 'sistema');
  return new;
end;
$$;

drop trigger if exists trg_campanhas_stamp on public.campanhas;
create trigger trg_campanhas_stamp
  before insert or update on public.campanhas
  for each row execute function public.campanhas_stamp();

-- ---------------------------------------------------------------------------
-- 3) ROW LEVEL SECURITY
--    Regra do app original: qualquer usuário autenticado pode LER; só quem
--    tem uma linha em "perfis" com papel = 'editor' pode ESCREVER.
-- ---------------------------------------------------------------------------

alter table public.campanhas enable row level security;
alter table public.config    enable row level security;
alter table public.perfis    enable row level security;

-- helper: o usuário logado é editor?
create or replace function public.sou_editor()
returns boolean
language sql
security definer set search_path = public
stable
as $$
  select exists (
    select 1 from public.perfis p
    where lower(p.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
      and p.papel = 'editor'
  );
$$;

-- campanhas: leitura para qualquer autenticado, escrita só para editor
drop policy if exists campanhas_select on public.campanhas;
create policy campanhas_select on public.campanhas
  for select to authenticated using (true);

drop policy if exists campanhas_insert on public.campanhas;
create policy campanhas_insert on public.campanhas
  for insert to authenticated with check (public.sou_editor());

drop policy if exists campanhas_update on public.campanhas;
create policy campanhas_update on public.campanhas
  for update to authenticated using (public.sou_editor()) with check (public.sou_editor());

-- config: leitura para qualquer autenticado, escrita só para editor
drop policy if exists config_select on public.config;
create policy config_select on public.config
  for select to authenticated using (true);

drop policy if exists config_update on public.config;
create policy config_update on public.config
  for update to authenticated using (public.sou_editor()) with check (public.sou_editor());

-- perfis: qualquer autenticado pode ler todos os perfis (o app usa isso pra
-- saber os nomes/papéis de todo mundo); ninguém escreve pelo app — só você,
-- direto no painel do Supabase (Table Editor ou SQL Editor).
drop policy if exists perfis_select on public.perfis;
create policy perfis_select on public.perfis
  for select to authenticated using (true);

-- ---------------------------------------------------------------------------
-- 4) REALTIME (o painel escuta mudanças ao vivo em campanhas e config)
-- ---------------------------------------------------------------------------

do $$
begin
  begin
    alter publication supabase_realtime add table public.campanhas;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.config;
  exception when duplicate_object then null;
  end;
end $$;

-- ---------------------------------------------------------------------------
-- 5) GRANTS (garantia extra; o Supabase normalmente já concede isso por
--    padrão a projetos novos, mas não custa deixar explícito)
-- ---------------------------------------------------------------------------

grant usage on schema public to authenticated;
grant select, insert, update on public.campanhas to authenticated;
grant select, update on public.config to authenticated;
grant select on public.perfis to authenticated;

-- ============================================================================
-- Pronto. Próximo passo: criar o primeiro usuário (você) como editor —
-- veja o guia GUIA-CONFIGURACAO.md, passo "Criar seu usuário".
-- ============================================================================
