-- Paula Estefanato • Schema do sistema de agendamento
-- Rode este arquivo inteiro no SQL Editor do Supabase (Project > SQL Editor > New query)

create extension if not exists "pgcrypto";

-- ========== SERVIÇOS ==========
create table if not exists services (
  id serial primary key,
  name text not null,
  price numeric(10,2) not null,
  duration_minutes int not null,
  active boolean not null default true,
  sort_order int not null default 0
);

insert into services (name, price, duration_minutes, sort_order) values
  ('Manicure e Pedicure', 85, 60, 1),
  ('Alongamento Molde F1', 180, 150, 2),
  ('Blindagem', 120, 90, 3)
on conflict do nothing;

-- ========== AGENDAMENTOS ==========
create table if not exists appointments (
  id uuid primary key default gen_random_uuid(),
  service_id int not null references services(id),
  client_name text not null,
  client_phone text not null,
  appointment_date date not null,
  start_time time not null,
  end_time time not null,
  status text not null default 'pendente' check (status in ('pendente','confirmado','cancelado')),
  created_at timestamptz not null default now()
);

create index if not exists appointments_date_idx on appointments (appointment_date);

-- ========== HORÁRIOS BLOQUEADOS (folgas, almoço, feriados) ==========
create table if not exists blocked_slots (
  id uuid primary key default gen_random_uuid(),
  block_date date not null,
  start_time time not null,
  end_time time not null,
  reason text,
  created_at timestamptz not null default now()
);

create index if not exists blocked_slots_date_idx on blocked_slots (block_date);

-- ========== VIEW PÚBLICA (sem dados pessoais do cliente) ==========
-- Usada pela página de agendamento para saber quais horários já estão ocupados,
-- sem expor nome/telefone de outros clientes.
create or replace view busy_slots as
  select appointment_date as block_date, start_time, end_time
  from appointments
  where status <> 'cancelado'
  union all
  select block_date, start_time, end_time
  from blocked_slots;

-- ========== ROW LEVEL SECURITY ==========
alter table services enable row level security;
alter table appointments enable row level security;
alter table blocked_slots enable row level security;

-- Qualquer pessoa pode ver os serviços ativos (página de vendas / agendamento)
create policy "services_public_read" on services
  for select using (active = true);

-- Qualquer pessoa pode criar um agendamento (fluxo público de agendar)
create policy "appointments_public_insert" on appointments
  for insert with check (status = 'pendente');

-- Só usuários logados (Paula/admin) podem ver, editar ou cancelar agendamentos
create policy "appointments_admin_select" on appointments
  for select using (auth.role() = 'authenticated');

create policy "appointments_admin_update" on appointments
  for update using (auth.role() = 'authenticated');

create policy "appointments_admin_delete" on appointments
  for delete using (auth.role() = 'authenticated');

-- Bloqueios de horário: só admin gerencia
create policy "blocked_slots_admin_all" on blocked_slots
  for all using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

-- A view busy_slots herda RLS das tabelas; para o público conseguir ler os
-- horários ocupados (sem nomes), liberamos select direto nela via RPC abaixo.
create or replace function get_busy_slots(p_date date)
returns table (start_time time, end_time time)
language sql
security definer
set search_path = public
as $$
  select start_time, end_time from busy_slots where block_date = p_date;
$$;

grant execute on function get_busy_slots(date) to anon, authenticated;
