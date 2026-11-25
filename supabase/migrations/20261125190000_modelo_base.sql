-- Palenque · Migración 1: modelo de datos, funciones auxiliares y permisos (RLS)
-- Basado en la sección 5 de docs/ESPECIFICACION-PALENQUE.md.
-- Ajustes respecto de la especificación (sin cambiar la lógica de permisos):
--   * Llaves foráneas compuestas (id, org_id) para que un evento, costo o chukker
--     no pueda apuntar a un caballo o partido de otra organización.
--   * La veterinaria puede actualizar caballos, pero un disparador le impide tocar
--     algo que no sea el estado (matriz 5.2: "Cambiar estado de un caballo").
--   * Al crear una organización se cargan solos sus umbrales y reglas de agenda.

-- ───────────────────────── Tipos ─────────────────────────
create type public.member_role  as enum ('dueno','encargado','petisero','vet','herrero');
create type public.horse_status as enum ('en_juego','en_doma','lesionado','descanso','cria','potrillo','vendido','retirado');
create type public.event_type   as enum ('vet','sanidad','herreria','dientes','alimento','conducta','trabajo','partido','lesion','cria','traslado','nota');
create type public.event_source as enum ('app','whatsapp','sistema');

-- ───────────────────── Organizaciones ─────────────────────
create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table public.memberships (
  user_id uuid not null references auth.users(id) on delete cascade,
  org_id  uuid not null references public.organizations(id) on delete cascade,
  role public.member_role not null,
  display_name text not null,
  phone_e164 text check (phone_e164 is null or phone_e164 ~ '^\+[1-9][0-9]{7,14}$'),
  created_at timestamptz not null default now(),
  primary key (user_id, org_id)
);
create unique index memberships_phone_uidx on public.memberships(phone_e164) where phone_e164 is not null;
create index memberships_org_idx on public.memberships(org_id);

create table public.org_settings (
  org_id uuid primary key references public.organizations(id) on delete cascade,
  load_chukkers_14d  int not null default 4 check (load_chukkers_14d > 0),   -- VALIDAR con gente del rubro
  no_eat_count_7d    int not null default 2 check (no_eat_count_7d > 0),
  injury_window_days int not null default 3 check (injury_window_days > 0)
);

-- ───────────────────────── Caballos ─────────────────────────
create table public.horses (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  number int not null,
  name text not null,
  aliases text[] not null default '{}',
  sex text not null check (sex in ('padrillo','yegua','macho_castrado','potranca','potrillo','caballo')),
  coat text,
  birth_date date,
  birth_place text,
  sire_id uuid references public.horses(id) on delete set null,
  dam_id  uuid references public.horses(id) on delete set null,
  sire_name text,
  dam_name text,
  registry_code text,
  breeder text,
  status public.horse_status not null default 'en_juego',
  location text,
  photo_path text,
  qr_token text not null unique default replace(gen_random_uuid()::text, '-', ''),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (org_id, number),
  unique (id, org_id)
);

-- ─────────────── Mensajes de WhatsApp (solo servidor) ───────────────
create table public.whatsapp_messages (
  id uuid primary key default gen_random_uuid(),
  wa_message_id text not null unique,
  org_id  uuid references public.organizations(id) on delete set null,
  user_id uuid references auth.users(id) on delete set null,
  from_phone text not null,
  direction text not null check (direction in ('in','out')),
  msg_type text not null,
  body text,
  media_id text,
  media_path text,
  transcript text,
  raw jsonb not null,
  status text not null default 'received'
    check (status in ('received','processing','awaiting_confirmation','done','rejected','failed','ignored')),
  proposal jsonb,
  error text,
  attempts int not null default 0,
  created_at timestamptz not null default now(),
  processed_at timestamptz
);
create index whatsapp_messages_status_idx on public.whatsapp_messages(status, created_at);

-- ───────────────────────── Partidos ─────────────────────────
create table public.matches (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  played_on date not null,
  tournament text,
  rival text,
  result text,
  created_at timestamptz not null default now(),
  unique (id, org_id)
);
create index matches_org_idx on public.matches(org_id, played_on desc);

create table public.match_chukkers (
  match_id uuid not null,
  org_id uuid not null,
  chukker_no smallint not null check (chukker_no between 1 and 8),
  horse_id uuid not null,
  primary key (match_id, chukker_no),
  foreign key (match_id, org_id) references public.matches(id, org_id) on delete cascade,
  foreign key (horse_id, org_id) references public.horses(id, org_id) on delete cascade
);

-- ───────────── Eventos: registro de todo lo que le pasa a un caballo ─────────────
create table public.events (
  id uuid primary key default gen_random_uuid(),   -- el cliente puede generarlo (cola offline)
  org_id   uuid not null references public.organizations(id) on delete cascade,
  horse_id uuid not null,
  type public.event_type not null,
  title text not null check (length(trim(title)) > 0),
  note text,
  occurred_on date not null,
  chukkers smallint check (chukkers is null or chukkers between 0 and 8),
  match_id uuid references public.matches(id) on delete set null,
  source public.event_source not null default 'app',
  inbound_message_id uuid references public.whatsapp_messages(id) on delete set null,
  created_by uuid references auth.users(id) on delete set null,
  created_by_name text,
  photo_path text,
  created_at timestamptz not null default now(),
  unique (id, org_id),
  foreign key (horse_id, org_id) references public.horses(id, org_id) on delete cascade
);
create index events_horse_idx    on public.events(horse_id, occurred_on desc);
create index events_org_type_idx on public.events(org_id, type, occurred_on desc);

-- Costos en tabla aparte: RLS filtra filas, no columnas. Petisero, vet y herrero no los ven nunca.
create table public.event_costs (
  event_id uuid primary key,
  org_id uuid not null,
  amount numeric(14,2) not null check (amount >= 0),
  currency char(3) not null default 'ARS',
  foreign key (event_id, org_id) references public.events(id, org_id) on delete cascade
);

-- ─────────────────── Reglas de agenda por organización ───────────────────
create table public.care_rules (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  key text not null,
  label text not null,
  event_type public.event_type not null,
  title_pattern text not null,
  every_days int not null check (every_days > 0),
  default_title text not null,
  skip_statuses public.horse_status[] not null default '{}',
  require_previous boolean not null default false,
  enabled boolean not null default true,
  unique (org_id, key)
);

-- ───────────────────────── Avisos ─────────────────────────
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  org_id  uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null,
  horse_id uuid references public.horses(id) on delete cascade,
  title text not null,
  body text,
  dedupe_key text not null,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  unique (user_id, dedupe_key)
);
create index notifications_user_idx on public.notifications(user_id, created_at desc);

create table public.push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  endpoint text not null unique,
  p256dh text not null,
  auth text not null,
  created_at timestamptz not null default now()
);

-- ─────────────────── Funciones auxiliares de permisos ───────────────────
-- security definer para evitar recursión de políticas sobre memberships.
create function public.is_member(_org uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.memberships m
                 where m.org_id = _org and m.user_id = (select auth.uid()))
$$;

create function public.has_role(_org uuid, _roles public.member_role[]) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.memberships m
                 where m.org_id = _org and m.user_id = (select auth.uid()) and m.role = any(_roles))
$$;

revoke execute on function public.is_member(uuid) from public, anon;
revoke execute on function public.has_role(uuid, public.member_role[]) from public, anon;
grant execute on function public.is_member(uuid) to authenticated, service_role;
grant execute on function public.has_role(uuid, public.member_role[]) to authenticated, service_role;

-- ─────────────────── Disparadores ───────────────────
-- updated_at de caballos
create function public.touch_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end $$;

create trigger horses_touch before update on public.horses
  for each row execute function public.touch_updated_at();

-- La veterinaria solo puede cambiar el estado del caballo (y updated_at, que pone el disparador).
-- Si la petición viene del servidor (sin usuario), el disparador no restringe.
create function public.horses_vet_only_status() returns trigger
language plpgsql set search_path = '' as $$
begin
  if (select auth.uid()) is not null
     and not public.has_role(old.org_id, '{dueno,encargado}')
     and (to_jsonb(new) - 'status' - 'updated_at') is distinct from (to_jsonb(old) - 'status' - 'updated_at')
  then
    raise exception 'La veterinaria solo puede cambiar el estado del caballo'
      using errcode = '42501';
  end if;
  return new;
end $$;

create trigger horses_vet_only_status before update on public.horses
  for each row execute function public.horses_vet_only_status();

-- Valores iniciales de umbrales y reglas de agenda al crear una organización (sección 5, care_rules).
create function public.seed_org_defaults() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.org_settings (org_id) values (new.id);
  insert into public.care_rules (org_id, key, label, event_type, title_pattern, every_days, default_title, skip_statuses, require_previous) values
    (new.id, 'herr', 'Herrado',            'herreria', 'herr|herradura|despalme', 42,  'Herrado',             '{cria,potrillo,descanso}', false),
    (new.id, 'vac',  'Vacuna influenza',   'sanidad',  'vacuna influenza',        180, 'Vacuna influenza',    '{}',                       false),
    (new.id, 'desp', 'Desparasitación',    'sanidad',  'desparasit',              90,  'Desparasitación',     '{}',                       false),
    (new.id, 'aie',  'Análisis AIE',       'sanidad',  'aie',                     60,  'Análisis AIE',        '{potrillo}',               false),
    (new.id, 'dent', 'Control de dientes', 'dientes',  'dient|odont',             365, 'Control de dientes',  '{}',                       true);
  return new;
end $$;

revoke execute on function public.seed_org_defaults() from public, anon, authenticated;

create trigger organizations_seed_defaults after insert on public.organizations
  for each row execute function public.seed_org_defaults();

-- ─────────────────── RLS: activada en TODAS las tablas ───────────────────
alter table public.organizations      enable row level security;
alter table public.memberships        enable row level security;
alter table public.org_settings       enable row level security;
alter table public.horses             enable row level security;
alter table public.whatsapp_messages  enable row level security;   -- sin políticas: solo el servidor
alter table public.matches            enable row level security;
alter table public.match_chukkers     enable row level security;
alter table public.events             enable row level security;
alter table public.event_costs        enable row level security;
alter table public.care_rules         enable row level security;
alter table public.notifications      enable row level security;
alter table public.push_subscriptions enable row level security;

-- Organizaciones, miembros, umbrales y reglas: lectura para miembros; escritura solo por el servidor.
create policy organizations_select on public.organizations for select to authenticated using (public.is_member(id));
create policy memberships_select   on public.memberships   for select to authenticated using (public.is_member(org_id));
create policy org_settings_select  on public.org_settings  for select to authenticated using (public.is_member(org_id));
create policy care_rules_select    on public.care_rules    for select to authenticated using (public.is_member(org_id));

-- Caballos
create policy horses_select on public.horses for select to authenticated using (public.is_member(org_id));
create policy horses_insert on public.horses for insert to authenticated
  with check (public.has_role(org_id, '{dueno,encargado}'));
create policy horses_update on public.horses for update to authenticated
  using (public.has_role(org_id, '{dueno,encargado,vet}'))
  with check (public.has_role(org_id, '{dueno,encargado,vet}'));
create policy horses_delete on public.horses for delete to authenticated
  using (public.has_role(org_id, '{dueno}'));

-- Partidos y chukkers
create policy matches_select on public.matches for select to authenticated using (public.is_member(org_id));
create policy matches_write  on public.matches for all to authenticated
  using (public.has_role(org_id, '{dueno,encargado}'))
  with check (public.has_role(org_id, '{dueno,encargado}'));
create policy match_chukkers_select on public.match_chukkers for select to authenticated using (public.is_member(org_id));
create policy match_chukkers_write  on public.match_chukkers for all to authenticated
  using (public.has_role(org_id, '{dueno,encargado}'))
  with check (public.has_role(org_id, '{dueno,encargado}'));

-- Eventos
create policy events_select on public.events for select to authenticated using (public.is_member(org_id));
create policy events_insert on public.events for insert to authenticated
  with check (
    created_by = (select auth.uid())
    and (
      public.has_role(org_id, '{dueno,encargado,petisero,vet}')
      or (public.has_role(org_id, '{herrero}') and type = 'herreria')
    )
  );
create policy events_update on public.events for update to authenticated
  using (public.has_role(org_id, '{dueno,encargado}'))
  with check (public.has_role(org_id, '{dueno,encargado}'));
create policy events_delete on public.events for delete to authenticated
  using (public.has_role(org_id, '{dueno,encargado}'));

-- Costos: solo dueño y encargado, para cualquier operación.
create policy costs_all on public.event_costs for all to authenticated
  using (public.has_role(org_id, '{dueno,encargado}'))
  with check (public.has_role(org_id, '{dueno,encargado}'));

-- Avisos y suscripciones push: cada uno ve solo los suyos.
create policy notifications_select on public.notifications for select to authenticated
  using (user_id = (select auth.uid()));
create policy notifications_mark_read on public.notifications for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy push_subscriptions_own on public.push_subscriptions for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- ─────────────────── Auditoría: tablas públicas sin RLS ───────────────────
-- Solo la puede llamar el servidor (service_role). La usan las pruebas automáticas.
create function public.tables_without_rls() returns table (table_name text)
language sql stable security definer set search_path = '' as $$
  select c.relname::text
  from pg_catalog.pg_class c
  join pg_catalog.pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity
$$;
revoke execute on function public.tables_without_rls() from public, anon, authenticated;
grant execute on function public.tables_without_rls() to service_role;
