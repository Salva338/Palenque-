# Palenque · Especificación del MVP (para Claude Code)

Versión del 3 de noviembre de 2026. Este documento define **qué se construye y cómo**. La guía `GUIA-MVP-PALENQUE.md` define **en qué orden y con qué ayuda de la persona**. Si algo de acá contradice la documentación oficial vigente de un servicio, ganá la documentación y avisale a la persona.

La referencia visual y de comportamiento es el prototipo `docs/prototipo/Palenque-prototipo.html` (un solo archivo HTML con datos inventados). **Leelo entero antes de la Fase 4.** Es una demo: la lógica de IA son expresiones regulares y plantillas, los permisos son cosméticos y el modo sin señal es un botón. El MVP hace de verdad todo eso.

---

## 1. Producto y usuarios

**Palenque** es una app de gestión de caballerizas y haras (el prototipo está orientado a polo: chukkers, partidos). Un caballo tiene una ficha con su historial de eventos (sanidad, herrería, trabajo, partidos, lesiones, cría, costos). La app calcula sola vencimientos y alertas. El petisero carga novedades **por WhatsApp**, con audio o texto, sin abrir ninguna app.

| Rol | Quién es | Qué hace |
|---|---|---|
| `dueno` | Dueño del haras | Ve todo, incluidos costos. Administra usuarios y reglas |
| `encargado` | Encargado de la caballeriza | Ve y carga todo, incluidos costos |
| `petisero` | Quien cuida y trabaja los caballos | Carga lo cotidiano. **No ve costos** |
| `vet` | Veterinaria | Carga controles y tratamientos, cambia estados. Recibe avisos de lesión. **No ve costos** |
| `herrero` | Herrero externo | Solo carga herrados. No ve costos |

**Multi-organización desde el día uno:** toda fila de negocio lleva `org_id`. Una persona pertenece a una organización en el MVP (el teléfono de WhatsApp es único entre membresías).

**Fuera del MVP** `[v1.1]`: receptoras de transferencia embrionaria como entidad, ficha de venta, resumen por IA, documentos con vencimiento, imágenes y video por WhatsApp, copropietarios, integración con sensores, múltiples idiomas, múltiples organizaciones por persona.

---

## 2. Decisiones técnicas cerradas

| Tema | Decisión |
|---|---|
| Tipo de app | **PWA** (web responsive instalable). Sin tiendas de apps |
| Framework | **Next.js** (App Router, TypeScript estricto) |
| Estilos y componentes | **Tailwind CSS + shadcn/ui**. Identidad visual del prototipo |
| Base de datos | **Postgres en Supabase**, región São Paulo |
| Auth | Supabase Auth (email y contraseña) |
| Permisos | **Row Level Security** en todas las tablas |
| Archivos | Supabase Storage, buckets **privados**, URLs firmadas |
| Hosting | **Vercel**, funciones en São Paulo (`gru1`) si está disponible |
| WhatsApp | **WhatsApp Cloud API** de Meta, directo (sin intermediario) |
| IA de texto | API de Anthropic. Modelo por variable de entorno (`ANTHROPIC_MODEL`). Punto de partida: `claude-sonnet-5-5`; evaluar `claude-haiku-5-5` para bajar costo. Verificá nombres vigentes en docs.claude.com |
| Transcripción | Proveedor intercambiable detrás de una interfaz (`lib/transcription`). Por defecto, OpenAI. Verificá modelos y formatos aceptados en su documentación |
| Validación | Zod en todos los límites (formularios, API, webhook, salida del modelo) |
| Offline | Dexie (IndexedDB) con cola de escritura; service worker |
| Push | Web Push (VAPID) con la librería `web-push` |
| Email | Resend (opcional) |
| Errores | Sentry (Fase 8) |

**No usar:** Docker, `supabase start`, ORMs pesados (se usa el cliente de Supabase y SQL en migraciones), servicios que agreguen cuentas nuevas sin avisar a la persona.

---

## 3. Convenciones y estructura

- **Idioma:** textos de la interfaz en castellano rioplatense (voseo, `es-AR`). Código, tablas y columnas en inglés. Los valores de enumeraciones del dominio son los del prototipo (`en_juego`, `herreria`, `lesion`).
- **Fechas:** `date` para fechas de eventos. `timestamptz` para momentos. La zona horaria de negocio es `America/Argentina/Buenos_Aires`; "hoy" se calcula en esa zona, no en UTC.
- **Dinero:** `numeric(14,2)` con `currency` (por defecto `ARS`). Nunca `float`.
- **IDs:** `uuid`. Los eventos creados desde el cliente generan su UUID en el cliente (idempotencia para la cola offline).
- **Textos normalizados:** para buscar y comparar, función `norm()` (minúsculas, sin tildes) como en el prototipo.
- **Commits:** chicos y frecuentes, en castellano.
- **Nada de lógica de permisos solo en el cliente.** La interfaz oculta lo que no corresponde, pero la base de datos y el servidor son los que mandan.

```
app/
  (auth)/login/
  (app)/                    ← layout con tabs; requiere sesión
    page.tsx                ← Inicio
    caballos/ , caballos/[id]/
    cargar/ , agenda/ , mas/
    partidos/ , costos/ , equipo/
  api/
    whatsapp/webhook/route.ts
    cron/daily/route.ts , cron/retry/route.ts
  h/[token]/page.tsx        ← destino del QR
components/ , lib/
  supabase/ (client.ts, server.ts, admin.ts  ← admin.ts con "server-only")
  rules/ (agenda.ts, alerts.ts, norm.ts)
  whatsapp/ (verify.ts, send.ts, media.ts, extract.ts, confirm.ts)
  transcription/ , offline/ , push/
supabase/migrations/ , supabase/seed/
scripts/ (seed-demo.ts, eval-mensajes.ts)
docs/
```

---

## 4. Variables de entorno

| Variable | Pública | Dónde se usa |
|---|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | Sí | Cliente y servidor |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | Sí | Cliente y servidor (llave `sb_publishable_...`) |
| `SUPABASE_SECRET_KEY` | **No** | Solo servidor (`sb_secret_...`). Salta RLS. Nunca en el cliente |
| `NEXT_PUBLIC_APP_URL` | Sí | Links absolutos, QR |
| `WHATSAPP_VERIFY_TOKEN` | No | Verificación GET del webhook |
| `WHATSAPP_APP_SECRET` | No | Firma `X-Hub-Signature-256` |
| `WHATSAPP_ACCESS_TOKEN` | No | Token permanente del usuario del sistema |
| `WHATSAPP_PHONE_NUMBER_ID` | No | Número emisor |
| `WHATSAPP_BUSINESS_ACCOUNT_ID` | No | WABA |
| `WHATSAPP_GRAPH_VERSION` | No | Versión de la Graph API (verificá la vigente) |
| `ANTHROPIC_API_KEY`, `ANTHROPIC_MODEL` | No | Extracción de eventos |
| `TRANSCRIPTION_API_KEY`, `TRANSCRIPTION_MODEL` | No | Audio a texto |
| `CRON_SECRET` | No | Autoriza `/api/cron/*` (Vercel lo manda como `Authorization: Bearer`) |
| `NEXT_PUBLIC_VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `VAPID_SUBJECT` | Mixto | Web Push |
| `RESEND_API_KEY` | No | Email (opcional) |
| `APP_ENV` | No | `development`, `test` o `production`. Elige el cliente simulado de WhatsApp y habilita las pruebas (sección 14) |
| `TEST_SUPABASE_PROJECT_REF` | No | Solo en `.env.test.local`: identificador del proyecto `palenque-test`; las pruebas abortan si la URL no lo contiene |

Mantené un `.env.example` con los **nombres** y sin valores, versionado en git. `.env*` reales nunca se versionan. Las pruebas usan `.env.test.local`, apuntando a un proyecto de Supabase aparte (sección 14.4).

---

## 5. Modelo de datos

Escribí esto como migraciones numeradas en `supabase/migrations/` y aplicalas con `supabase db push`. El SQL de abajo es la base; ajustalo si hace falta, pero **no cambies la lógica de permisos sin avisar**.

```sql
-- Tipos
create type member_role  as enum ('dueno','encargado','petisero','vet','herrero');
create type horse_status as enum ('en_juego','en_doma','lesionado','descanso','cria','potrillo','vendido','retirado');
create type event_type   as enum ('vet','sanidad','herreria','dientes','alimento','conducta','trabajo','partido','lesion','cria','traslado','nota');
create type event_source as enum ('app','whatsapp','sistema');

-- Organizaciones y miembros
create table organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table memberships (
  user_id uuid not null references auth.users(id) on delete cascade,
  org_id  uuid not null references organizations(id) on delete cascade,
  role member_role not null,
  display_name text not null,
  phone_e164 text,                       -- ej: +5491112345678, para identificar por WhatsApp
  created_at timestamptz not null default now(),
  primary key (user_id, org_id)
);
create unique index memberships_phone_uidx on memberships(phone_e164) where phone_e164 is not null;

create table org_settings (
  org_id uuid primary key references organizations(id) on delete cascade,
  load_chukkers_14d int not null default 4,      -- umbral de carga alta (VALIDAR con gente del rubro)
  no_eat_count_7d   int not null default 2,
  injury_window_days int not null default 3
);

-- Caballos
create table horses (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references organizations(id) on delete cascade,
  number int not null,
  name text not null,
  aliases text[] not null default '{}',          -- apodos para que el bot los reconozca
  sex text not null check (sex in ('padrillo','yegua','macho_castrado','potranca','potrillo','caballo')),
  coat text,
  birth_date date,
  birth_place text,
  sire_id uuid references horses(id) on delete set null,
  dam_id  uuid references horses(id) on delete set null,
  sire_name text, dam_name text,                 -- para padres que no son caballos propios
  registry_code text,
  breeder text,
  status horse_status not null default 'en_juego',
  location text,
  photo_path text,
  qr_token text not null unique default replace(gen_random_uuid()::text,'-',''),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (org_id, number)
);

-- Mensajes de WhatsApp (solo servidor)
create table whatsapp_messages (
  id uuid primary key default gen_random_uuid(),
  wa_message_id text not null unique,            -- idempotencia: Meta puede reenviar
  org_id  uuid references organizations(id) on delete set null,
  user_id uuid references auth.users(id) on delete set null,
  from_phone text not null,
  direction text not null check (direction in ('in','out')),
  msg_type text not null,                        -- text, audio, interactive, image...
  body text, media_id text, media_path text, transcript text,
  raw jsonb not null,
  status text not null default 'received'
    check (status in ('received','processing','awaiting_confirmation','done','rejected','failed','ignored')),
  proposal jsonb,                                -- eventos propuestos, pendientes de confirmar
  error text,
  attempts int not null default 0,
  created_at timestamptz not null default now(),
  processed_at timestamptz
);
create index whatsapp_messages_status_idx on whatsapp_messages(status, created_at);

-- Partidos
create table matches (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references organizations(id) on delete cascade,
  played_on date not null,                       -- editable: se puede cargar un partido de ayer
  tournament text, rival text, result text,
  created_at timestamptz not null default now()
);
create table match_chukkers (
  match_id uuid not null references matches(id) on delete cascade,
  chukker_no smallint not null check (chukker_no between 1 and 8),
  horse_id uuid not null references horses(id) on delete cascade,
  primary key (match_id, chukker_no)
);

-- Eventos: registro append-only de todo lo que le pasa a un caballo
create table events (
  id uuid primary key default gen_random_uuid(), -- el cliente puede generarlo (cola offline)
  org_id   uuid not null references organizations(id) on delete cascade,
  horse_id uuid not null references horses(id) on delete cascade,
  type event_type not null,
  title text not null,
  note text,
  occurred_on date not null,
  chukkers smallint,
  match_id uuid references matches(id) on delete set null,
  source event_source not null default 'app',
  inbound_message_id uuid references whatsapp_messages(id) on delete set null,
  created_by uuid references auth.users(id) on delete set null,
  created_by_name text,
  photo_path text,
  created_at timestamptz not null default now()
);
create index events_horse_idx    on events(horse_id, occurred_on desc);
create index events_org_type_idx on events(org_id, type, occurred_on desc);

-- Costos en tabla aparte: RLS filtra filas, no columnas. Así petisero y vet no los ven nunca.
create table event_costs (
  event_id uuid primary key references events(id) on delete cascade,
  org_id uuid not null references organizations(id) on delete cascade,
  amount numeric(14,2) not null check (amount >= 0),
  currency char(3) not null default 'ARS'
);

-- Reglas de agenda por organización (valores iniciales del prototipo)
create table care_rules (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references organizations(id) on delete cascade,
  key text not null,
  label text not null,
  event_type event_type not null,
  title_pattern text not null,                   -- regex sobre el título normalizado
  every_days int not null check (every_days > 0),
  default_title text not null,
  skip_statuses horse_status[] not null default '{}',
  require_previous boolean not null default false, -- si no hay registro previo, no se genera vencimiento
  enabled boolean not null default true,
  unique (org_id, key)
);
-- Valores iniciales: herr (herreria, 'herr|herradura|despalme', 42, salta cria/potrillo/descanso),
-- vac (sanidad, 'vacuna influenza', 180), desp (sanidad, 'desparasit', 90),
-- aie (sanidad, 'aie', 60, salta potrillo), dent (dientes, 'dient|odont', 365, require_previous).

-- Avisos
create table notifications (
  id uuid primary key default gen_random_uuid(),
  org_id  uuid not null references organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null,                            -- 'lesion','no_comio','carga_alta','vencimiento'
  horse_id uuid references horses(id) on delete cascade,
  title text not null, body text,
  dedupe_key text not null,                      -- evita avisar dos veces lo mismo
  read_at timestamptz,
  created_at timestamptz not null default now(),
  unique (user_id, dedupe_key)
);
create table push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  endpoint text not null unique, p256dh text not null, auth text not null,
  created_at timestamptz not null default now()
);
```

### 5.1 RLS: funciones auxiliares y ejemplos

Activá RLS en **todas** las tablas. Las funciones son `security definer` para evitar recursión de políticas sobre `memberships`.

```sql
create function public.is_member(_org uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.memberships m
                 where m.org_id = _org and m.user_id = (select auth.uid()))
$$;

create function public.has_role(_org uuid, _roles member_role[]) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.memberships m
                 where m.org_id = _org and m.user_id = (select auth.uid()) and m.role = any(_roles))
$$;

alter table horses enable row level security;
create policy horses_select on horses for select using (is_member(org_id));
create policy horses_insert on horses for insert with check (has_role(org_id, '{dueno,encargado}'));
create policy horses_update on horses for update using (has_role(org_id, '{dueno,encargado,vet}'))
                                                with check (has_role(org_id, '{dueno,encargado,vet}'));
create policy horses_delete on horses for delete using (has_role(org_id, '{dueno}'));

alter table events enable row level security;
create policy events_select on events for select using (is_member(org_id));
create policy events_insert on events for insert with check (
  has_role(org_id, '{dueno,encargado,petisero,vet}')
  or (has_role(org_id, '{herrero}') and type = 'herreria'));
create policy events_update on events for update using (has_role(org_id, '{dueno,encargado}'));
create policy events_delete on events for delete using (has_role(org_id, '{dueno,encargado}'));

alter table event_costs enable row level security;
create policy costs_all on event_costs for all
  using (has_role(org_id, '{dueno,encargado}')) with check (has_role(org_id, '{dueno,encargado}'));
```

### 5.2 Matriz de permisos (aplicala a todas las tablas)

| Acción | dueno | encargado | petisero | vet | herrero |
|---|:-:|:-:|:-:|:-:|:-:|
| Ver caballos, fichas, eventos, partidos | ✓ | ✓ | ✓ | ✓ | ✓ |
| Ver y cargar costos | ✓ | ✓ | ✗ | ✗ | ✗ |
| Crear eventos | ✓ | ✓ | ✓ | ✓ | solo `herreria` |
| Editar o borrar eventos | ✓ | ✓ | ✗ | ✗ | ✗ |
| Crear y editar caballos | ✓ | ✓ | ✗ | ✗ | ✗ |
| Cambiar estado de un caballo | ✓ | ✓ | ✗ | ✓ | ✗ |
| Borrar caballos | ✓ | ✗ | ✗ | ✗ | ✗ |
| Cargar y editar partidos | ✓ | ✓ | ✗ | ✗ | ✗ |
| Administrar usuarios, reglas y umbrales | ✓ | ✗ | ✗ | ✗ | ✗ |
| Ver notificaciones propias | ✓ | ✓ | ✓ | ✓ | ✓ |

`whatsapp_messages`: RLS activada **sin ninguna política** (solo accede el servidor con la secret key). `memberships`, `org_settings` y `care_rules`: lectura para miembros; escritura solo del dueño (a través del servidor).

**Importante:** la `SUPABASE_SECRET_KEY` **salta RLS**. Todo código de servidor que la use (webhook de WhatsApp, cron, invitar usuarios) tiene que aplicar la matriz de permisos **a mano** (por ejemplo una función `canCreateEvent(role, type)`), porque la base no lo hará.

### 5.3 Pruebas de permisos (obligatorias)

Escribí pruebas automáticas que, con usuarios de distintos roles y de dos organizaciones, comprueben al menos: (1) petisero no lee `event_costs`; (2) usuario de la org A no lee nada de la org B; (3) herrero solo inserta eventos `herreria`; (4) petisero no actualiza ni borra eventos; (5) nadie del cliente lee `whatsapp_messages`.

### 5.4 Datos de demostración

`scripts/seed-demo.ts` carga la organización **"Haras Demo"** con los 13 caballos, sus eventos y los 4 partidos de la función `seed()` del prototipo, usando **fechas relativas a hoy** (hace N días), para que la demo siempre se vea viva. El script es idempotente y solo toca la organización demo.

---

## 6. Reglas de negocio (portadas del prototipo)

Implementalas como funciones puras y testeadas en `lib/rules/`. Los valores salen de `care_rules` y `org_settings`, no del código.

**Agenda.** Para cada caballo activo (no `vendido` ni `retirado`) y cada regla habilitada: buscar el último evento del tipo de la regla cuyo título normalizado cumpla `title_pattern`. Vencimiento = fecha del último + `every_days`. Sin registro previo: si `require_previous`, no se genera; si no, queda "sin registro". Se saltan los estados de `skip_statuses`. Se ordena por días restantes. Grupos en pantalla: vencidos, próximos 14 días, próximos 30 días. "Hecho ✓" crea un evento con `default_title`.

**Alertas por caballo.**
1. **No comió:** al menos `no_eat_count_7d` eventos de alimentación "no comió/comió poco" en los últimos 7 días → alerta roja "patrón detectado, conviene que la vea la veterinaria".
2. **Lesión reciente:** evento `lesion` en los últimos `injury_window_days` días y estado distinto de `lesionado` → alerta roja "no debería jugar hasta revisarla".
3. **En recuperación:** estado `lesionado` → alerta ámbar con el último control veterinario.
4. **Carga alta:** `chukkers` sumados en 14 días ≥ `load_chukkers_14d` → alerta ámbar. **El umbral de ejemplo (4) hay que validarlo con un polista o veterinario antes de presentarlo como regla.**
5. **Vencimientos atrasados:** una alerta agregada con los primeros 3.

**Disponibilidad para el próximo partido:** `lesionado` o alerta roja → "No disponible"; `descanso` → "En descanso"; carga alta → "Mejor que descanse"; si no → "Disponible".

**Partidos.** Cargar un partido (con **fecha editable**) y el caballo de cada chukker crea el partido, sus chukkers y un evento `partido` por caballo con la cantidad de chukkers, todo en una transacción (función SQL o RPC).

### 6.1 Errores del prototipo que NO hay que repetir

1. **Doble conteo de "no comió":** el prototipo guardaba el mensaje completo en la nota y después buscaba "no comió" en título + nota, así que un mensaje con varios hechos disparaba alertas falsas. Buscar solo en `type` y `title` estructurados, nunca en texto libre.
2. **Fuga de costos entre roles:** la pestaña Costos seguía renderizándose al cambiar de rol. Los costos se piden solo si el servidor autoriza (RLS) y la interfaz no los renderiza si no llegaron.
3. **Año duplicado** en fechas ("14 oct 2012 2012"). Una sola función de formato de fechas.
4. **Negaciones:** "no está rengo" marcaba lesión. El modelo debe detectar negación (campo `negated`) y no crear el evento.
5. **Avisos falsos:** el bot decía "le avisé a la veterinaria" sin avisar a nadie. Solo afirmar lo que realmente se hizo.
6. **La alerta más importante se apagaba sola:** al pasar el estado a `lesionado`, desaparecía la alerta roja. Conservarla hasta que haya un control veterinario posterior a la lesión.
7. **Fechas:** sin validación, una fecha futura rompía las ventanas de 7 y 14 días. Rechazar fechas futuras.
8. **`save()` tragaba errores de cuota.** Mostrar "Guardado" solo cuando se confirmó el guardado. Los errores se muestran y se registran.

---

## 7. Pantallas y criterios de aceptación

Mobile first (480 px de ancho máximo es la referencia del prototipo; en escritorio la app se centra o usa un layout más ancho). Tabs inferiores: **Inicio, Caballos, + Cargar, Agenda, Más**. Colores del prototipo: fondo `#f4efe4`, tarjeta `#fffdf8`, tinta `#1c2620`, verde `#1f4030` / `#2e5a43`, latón `#b08a3e`, línea `#e4dccb`, alerta `#b4412f`, ámbar `#c08419`, ok `#3d7a52`, WhatsApp `#0b8f6a`. Tipografías Fraunces (títulos) e Inter (texto).

| # | Pantalla | Alcance | Criterios de aceptación |
|---|---|---|---|
| 1 | **Login y estructura** | MVP | Email y contraseña. Sin sesión redirige a login. Tabs persistentes. Muestra el rol |
| 2 | **Inicio** | MVP | Saludo según hora, 4 KPIs (caballos, en juego, lesionados, alertas) que filtran al tocar, tarjeta "Atención hoy" con alertas, últimos 5 movimientos |
| 3 | **Caballos** | MVP | Lista ordenada por número. Búsqueda por nombre, número o pelaje sin tildes. Chips de estado con contadores. Punto rojo si hay alerta roja |
| 4 | **Ficha: encabezado** | MVP | Foto o iniciales con color de pelaje, estado editable (según rol), banners de alerta, datos básicos, acciones Cargar / QR / Foto |
| 5 | **Ficha: Historial** | MVP | Línea de tiempo, filtro por tipo, fecha relativa, quién cargó y por qué canal (app o WhatsApp). Costo solo si el rol lo permite |
| 6 | **Ficha: Familia** | MVP | Árbol de 3 generaciones, padres propios clicables, hijos con chukkers de 6 meses |
| 7 | **Ficha: Partidos** | MVP | Cantidad de partidos, chukkers 6 meses y 14 días |
| 8 | **Ficha: Costos** | MVP (solo dueño y encargado) | Gráfico por mes (pensión y alimento + variables) y desglose por rubro. Los fijos mensuales son configurables, no constantes |
| 9 | **Cargar** | MVP | Paso 1 elegir uno o varios caballos (atajo "todos los en juego"); paso 2 tipo; paso 3 detalle sugerido por tipo, nota, fecha (no futura), costo (solo si el rol lo permite), foto. Para lesión: casilla "marcar como lesionado y avisar". Funciona sin conexión (cola) |
| 10 | **Agenda** | MVP | Tres grupos (vencidos, 14 días, 30 días). "Hecho ✓" registra el evento. Reglas desde `care_rules` |
| 11 | **Partidos y rotación** | MVP | Disponibilidad para el próximo partido con barra de carga; lista de partidos; cargar partido con fecha |
| 12 | **Equipo y permisos** | MVP | Lista de miembros con rol y teléfono. El dueño puede editar rol y teléfono (el teléfono habilita WhatsApp) |
| 13 | **QR por caballo** | MVP | Genera QR de `NEXT_PUBLIC_APP_URL/h/<qr_token>`. Escanearlo **pide login** y abre la ficha. Imprimible |
| 14 | **Centro de avisos** | MVP | Lista de notificaciones propias, marcar como leídas |
| 15 | **Cría** | `[v1.1]` | Padrillos, yeguas madres, crías jóvenes; receptoras como entidad |
| 16 | **Ficha de venta** | `[v1.1]` | Tarjeta resumida y texto copiable. Sin la palabra "verificada": son datos cargados por el propio haras |
| 17 | **Resumen por IA** | `[v1.1]` | Resumen de 6 meses generado por el modelo a partir del historial |
| 18 | **Asistente por WhatsApp (simulador)** | No | El simulador del prototipo se reemplaza por WhatsApp real (sección 8). Se puede conservar como herramienta interna de pruebas |

---

## 8. WhatsApp

### 8.1 Flujo

`Meta → POST /api/whatsapp/webhook → guardar crudo + responder 200 → procesar (async) → [descargar y transcribir audio] → extraer con Claude → pedir confirmación → Sí → escribir eventos → responder`.

### 8.2 Webhook

- **GET** (verificación): si `hub.mode=subscribe` y `hub.verify_token` coincide con `WHATSAPP_VERIFY_TOKEN`, responder `hub.challenge` en texto plano con 200. Si no, 403.
- **POST:** leer el cuerpo **crudo** (sin parsear antes), calcular HMAC-SHA256 con `WHATSAPP_APP_SECRET` y comparar con el header `X-Hub-Signature-256` usando comparación de tiempo constante. Firma inválida → 401 sin procesar nada.
- Insertar cada mensaje entrante en `whatsapp_messages` con `wa_message_id` único (`on conflict do nothing`): Meta puede reenviar el mismo evento, y no se debe procesar dos veces.
- **Responder 200 enseguida** (Meta reintenta si tarda). El procesamiento sigue en segundo plano con `after()` de Next.js (verificá su disponibilidad y límites de duración en la documentación vigente de Next.js y Vercel). Respaldo: `/api/cron/retry` reprocesa mensajes en `received` o `processing` con más de 2 minutos y `attempts < 5`.
- Ignorar los eventos de estado (`statuses`: entregado, leído). Procesar solo `messages`.

### 8.3 Identificar al remitente

Buscar `from` (formato E.164) en `memberships.phone_e164`. Número desconocido → `status = 'ignored'`, **sin responder** (cada respuesta cuesta). Aplicar la matriz de permisos con el rol del remitente: `herrero` solo puede cargar `herreria`; todos los demás pueden crear eventos.

### 8.4 Audios

1. El mensaje trae un `media_id`. Pedir `GET /{media_id}` con el token como Bearer: devuelve una URL temporal.
2. Descargar esa URL **también con el Bearer**. Los audios de WhatsApp son OGG con Opus; verificá en la documentación del proveedor si lo acepta o convertir con `ffmpeg`.
3. Transcribir en español rioplatense pasando como contexto la **lista de nombres y apodos de los caballos de esa organización** (nombres como "Bataraza" o "Picardía" y el acento se confunden fácil).
4. Guardar `transcript`. Guardar el audio en un bucket privado y borrarlo a los 30 días.

### 8.5 Extracción con Claude

Usar **llamada a herramienta (tool use) con esquema**, no texto libre. El modelo devuelve datos; el **servidor** resuelve el caballo de forma determinista (por número o por nombre/apodo normalizado), no el modelo.

```json
{
  "name": "registrar_novedades",
  "description": "Registra novedades de caballos mencionadas en el mensaje de un petisero.",
  "input_schema": {
    "type": "object",
    "properties": {
      "items": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "horse_ref": { "type": "string", "description": "Cómo nombró al caballo la persona: número ('el 4') o nombre" },
            "type": { "type": "string", "enum": ["vet","sanidad","herreria","dientes","alimento","conducta","trabajo","partido","lesion","cria","traslado","nota"] },
            "title": { "type": "string" },
            "note": { "type": "string" },
            "occurred_on": { "type": ["string","null"], "description": "YYYY-MM-DD; null si es hoy" },
            "negated": { "type": "boolean", "description": "true si la frase niega el hecho ('no está rengo')" }
          },
          "required": ["horse_ref", "type", "title", "negated"]
        }
      },
      "questions": { "type": "array", "items": { "type": "string" }, "description": "Preguntas cortas si algo es ambiguo" },
      "off_topic": { "type": "boolean" }
    },
    "required": ["items", "questions", "off_topic"]
  }
}
```

**Instrucciones del sistema (resumen):** sos el asistente de carga de una caballeriza; interpretás español rioplatense y jerga ("rengo", "mano caliente", "no comió", "vareo", "taqueo", "herré"); "el 4" es el caballo número 4; un evento por cada par (caballo, tipo); los eventos con `negated = true` no se crean; **no inventes** caballos, fechas ni datos: ante la duda, devolvé una pregunta en `questions`; si el mensaje no trata de novedades de caballos, `off_topic = true`. Pasale la fecha de hoy en `America/Argentina/Buenos_Aires`. Validá la salida con Zod; si falla, un reintento y después `status = 'failed'`.

### 8.6 Confirmación y escritura

- Armar la propuesta, guardarla en `whatsapp_messages.proposal` y enviar **un solo mensaje** con botones de respuesta (`interactive` de tipo `button`): "Sí, cargar" y "No, corregir". Los ids de los botones llevan el id del mensaje (`confirm:<uuid>`, `reject:<uuid>`). Verificá en la documentación vigente los límites (cantidad de botones, largo del título).
- **Nunca se escribe en la ficha sin el Sí.** Para lesiones la confirmación es obligatoria siempre.
- Con **Sí:** crear los eventos en una transacción, con `source = 'whatsapp'` e `inbound_message_id`. Si hay una lesión, pasar el caballo a `lesionado`. Responder una vez: "Listo. Cargué en Tango #4: …". **Solo prometer avisos que de verdad se enviaron.**
- Con **No:** responder "Contame de nuevo" y tomar el próximo mensaje como reemplazo.
- Si hay `questions`, enviarlas y esperar la respuesta (que se interpreta junto con el mensaje original).
- Caballo no encontrado o ambiguo: preguntar con una lista corta de candidatos. Nunca adivinar.

### 8.7 Templates (mensajes fuera de las 24 horas)

Fuera de la ventana de 24 horas desde el último mensaje de la persona, WhatsApp solo permite **templates aprobados**. Crearlos en WhatsApp Manager (categoría `utility`; son transaccionales):

1. `alerta_lesion`: "Hola {{1}}, se registró una lesión en {{2}}: {{3}}. Revisá la ficha en Palenque."
2. `resumen_vencimientos`: "Hola {{1}}, hay {{2}} vencimientos para esta semana. Entrá a Palenque para verlos."

El texto final lo aprueba Meta. Usá templates **solo para lesiones y resumen diario**; el resto de los avisos van por push o email.

### 8.8 Costos y política de Meta

- Meta cobra por mensaje y, desde el 1 de octubre de 2026, también las respuestas dentro de la ventana de 24 horas. **Enviá una sola respuesta por mensaje entrante** (la confirmación o el resultado, no varias).
- **Desde el 15 de enero de 2026** Meta no permite asistentes de IA generalistas en la API. El bot hace una sola tarea: cargar novedades. Si `off_topic = true`, responder una frase fija: "Solo puedo cargar novedades de caballos. Probá: 'el 4 no comió'", y no conversar.
- Confirmar tarifas y reglas en la documentación de Meta antes de lanzar.

### 8.9 Pruebas

- **Fixtures** con payloads reales del webhook (texto, audio, botón, estado).
- **Evaluación del modelo:** `scripts/eval-mensajes.ts` corre `docs/mensajes-de-prueba.md` (50 a 100 mensajes reales con resultado esperado) y reporta aciertos por tipo de error (caballo, tipo, negación, ambigüedad).
- Casos obligatorios: negación ("no está rengo"), caballo inexistente ("el 40"), varios caballos en un mensaje ("herré a Chispa y a Morena"), varios hechos de un caballo, mensaje fuera de tema, mensaje duplicado (mismo `wa_message_id`).
- Las pruebas **no envían mensajes reales**; el cliente de envío se simula.

---

## 9. Avisos, agenda y trabajos programados

- **Cálculo:** alertas y agenda se calculan en el servidor con las funciones de la sección 6, no en el navegador.
- **Notificaciones internas:** una fila en `notifications` por usuario y alerta, con `dedupe_key` (por ejemplo `lesion:<horse_id>:<fecha>`). El mismo aviso no se repite.
- **Quién recibe qué:** lesión → veterinaria, encargado y dueño. No comió repetido → veterinaria y encargado. Carga alta → encargado. Vencimientos → encargado y dueño.
- **Canales:** centro de avisos en la app (siempre) → Web Push (si el usuario lo activó) → email con Resend (opcional) → WhatsApp con template **solo** lesiones y resumen diario.
- **Trabajos programados** (Vercel Cron en `vercel.json`): `/api/cron/daily` (vencimientos, resumen) y `/api/cron/retry` (reproceso de WhatsApp). Ambos exigen `Authorization: Bearer ${CRON_SECRET}`. **Limitación:** en el plan Hobby los cron jobs corren como máximo una vez por día; en Pro pueden correr hasta una vez por minuto. Diseñá `retry` para que, si solo puede correr una vez por día, el webhook igual haga un reintento inmediato por su cuenta.
- **Web Push:** generar claves VAPID, guardar suscripciones en `push_subscriptions`, pedir el permiso solo cuando el usuario toca "Activar avisos". En iPhone solo funciona con la PWA instalada en la pantalla de inicio.

---

## 10. PWA y offline

- **Manifest** (nombre, íconos, `display: standalone`, colores) y **service worker** (verificá qué librería es compatible con la versión de Next.js en uso; Serwist es una opción).
- **Qué funciona sin conexión (alcance del MVP):** crear eventos desde Cargar y ver lo último que se cargó. **No** se promete uso completo sin conexión.
- **Cola de escritura:** Dexie guarda cada evento nuevo con su UUID generado en el cliente y fotos como blobs. Al volver la conexión o al enfocar la app, se envían en orden con inserción idempotente (`on conflict (id) do nothing`). Como los eventos son append-only, casi no hay conflictos. Ediciones de ficha: la última escritura gana.
- **Indicador de estado** visible (en línea / sin señal / N pendientes). Un evento pendiente muestra la etiqueta "Pendiente de sincronizar" hasta confirmarse en el servidor.
- **Límite de almacenamiento:** si la escritura local falla (cuota llena), **avisar al usuario** y no decir "Guardado".
- En iPhone, el navegador puede borrar datos locales de sitios poco usados: por eso la cola se vacía apenas hay conexión y la PWA debe estar instalada.

---

## 11. Seguridad

1. RLS en **todas** las tablas. Revisar los avisos de "Advisors" de Supabase.
2. `SUPABASE_SECRET_KEY` solo en código de servidor (`import "server-only"` en `lib/supabase/admin.ts`). Nunca en variables `NEXT_PUBLIC_*`.
3. Verificar la firma de **cada** POST del webhook.
4. Zod en todas las entradas; sanitizar lo que se muestra.
5. Buckets de Storage privados con URLs firmadas de corta duración.
6. El QR contiene un `qr_token` aleatorio, no un id predecible, y **exige login**: escanearlo no expone datos.
7. Rutas `/api/cron/*` protegidas con `CRON_SECRET`.
8. Límite de frecuencia básico por número de WhatsApp y por IP en endpoints públicos.
9. No registrar contenido sensible en logs: ni llaves, ni cuerpos completos de mensajes salvo en `whatsapp_messages`.
10. Nunca versionar `.env*`. Si se detecta una llave en git, avisar de inmediato a la persona para rotarla.
11. Dependencias: no agregar paquetes sin explicar para qué sirven.

---

## 12. Fases y definición de terminado

| Fase | Entregable | Definición de terminado |
|---|---|---|
| 2 | Proyecto base publicado | URL de Vercel abierta desde el celular, con la identidad visual |
| 3 | Migraciones, RLS, login, demo | Las 5 pruebas de permisos (5.3) pasan; la demo carga; se puede iniciar sesión con cada rol |
| 4 | Pantallas 1 a 14 y PWA | Cada pantalla cumple su criterio de la sección 7; instalable; la cola offline sincroniza |
| 5 | Webhook | Un mensaje a la línea de prueba queda en `whatsapp_messages`; un reenvío no duplica; firma inválida da 401 |
| 6 | Bot con confirmación | Casos obligatorios de 8.9 pasan; `eval-mensajes` reporta aciertos y la persona los aprueba |
| 7 | Avisos | Una lesión por WhatsApp avisa una sola vez; la agenda marca vencimientos reales |
| 8 | Piloto | Checklist de la guía completo; una semana sin pérdida de datos |

**Definición de terminado común a todas las fases (sección 14):** `npm run verify` en verde (o con avisos 🟡 aceptados por la persona), pruebas nuevas incluidas, semáforo mostrado, informe `docs/informes/fase-N.md` escrito y la prueba humana en el celular hecha.

Al cerrar cada fase: resumen de 3 líneas a la persona, informe y commit con push.

---

## 13. Qué no hacer

- No avanzar de fase sin que pase la prueba de la actual.
- No guardar llaves en el código, en commits ni en mensajes de la conversación. No imprimir `.env*`.
- No ejecutar comandos destructivos (`git push --force`, `supabase db reset` remoto, borrar tablas o archivos) sin confirmación explícita.
- No mandar mensajes reales de WhatsApp a números que no sean los de prueba sin confirmación.
- No prometer funciones que el prototipo solo simulaba (avisos, modo sin señal, "verificada") si todavía no existen.
- No agregar alcance (pantallas `[v1.1]`) sin que la persona lo pida.
- No dar por buena la interpretación del bot sin la evaluación de la sección 8.9.
- No debilitar, borrar ni saltear pruebas para ponerlas en verde; no declarar "anda" sin haber corrido `npm run verify` (sección 14).
- No correr pruebas contra la base de producción ni con llaves de producción.

---

## 14. Pruebas y auditorías

Objetivo: que la persona sepa si el código funciona **sin tener que leerlo**. Regla madre: *una fase no está terminada porque Claude lo diga, sino porque un comando lo demuestra y queda escrito en el informe de la fase.*

### 14.1 Reglas para Claude

1. Cada funcionalidad nueva llega con sus pruebas en el mismo commit. Sin prueba, no está terminada.
2. **Nunca** debilitar, borrar, saltear (`skip`, `only`, `xit`) ni comentar una prueba para ponerla en verde. Si una prueba falla, se arregla el código. Si la prueba está mal, se explica por qué y se corrige la prueba a la vista de la persona.
3. Nunca declarar "anda" sin haber corrido `npm run verify` en esa sesión y mostrar el resultado real. No inventar ni resumir resultados que no se ejecutaron.
4. Si algo no se pudo probar (falta una cuenta, no hay red, requiere el celular), decirlo como **"no probado"** en el informe. Eso no es un fallo, es información.
5. Las pruebas jamás tocan la base de producción ni envían WhatsApp reales (14.4).
6. Explicar cada resultado en castellano y en una frase: qué se probó, qué pasó, si la persona tiene que hacer algo.

### 14.2 Capas de control

| # | Capa | Qué atrapa | Cuándo corre |
|---|---|---|---|
| 1 | Tipos y estilo (`tsc --noEmit`, `eslint`) | Errores de código antes de ejecutar | Cada cambio |
| 2 | Pruebas unitarias (Vitest) | Reglas de negocio de la sección 6: fechas, vencimientos, carga, alertas | Cada cambio |
| 3 | Pruebas de base y permisos (RLS) contra el proyecto `palenque-test` | Que un rol vea o escriba lo que no debe; costos filtrados | Cada fase y antes de cada despliegue |
| 4 | Pruebas del webhook con payloads de ejemplo | Firma, duplicados, tipos de mensaje, remitente desconocido | Desde la fase 5 |
| 5 | Evaluación del bot (`scripts/eval-mensajes.ts`) | Que entienda bien los mensajes reales | Desde la fase 6, cada vez que cambie el prompt, el esquema o el modelo |
| 6 | Pruebas de punta a punta (Playwright) | Que las pantallas clave funcionen como las usa una persona, en tamaño celular | Desde la fase 4 |
| 7 | Auditorías: dependencias, secretos, RLS, Lighthouse, Advisors de Supabase | Fallas que ninguna prueba de funciones ve | Fin de cada fase y antes del piloto |
| 8 | Revisión independiente (sesión nueva, sin el contexto del que escribió el código) | Errores de criterio y huecos de seguridad | Fin de las fases 3, 5, 6 y 8 |
| 9 | Prueba humana en el celular, guiada por la guía | Lo que ningún robot siente: si se entiende y se usa | Fin de cada fase |

Ninguna capa reemplaza a otra. Las capas 1 a 7 las ejecuta Claude; la 8 la dispara la persona con un prompt de la guía; la 9 la hace la persona.

### 14.3 Comandos (scripts de `package.json`)

| Comando | Qué hace | Tiempo esperado |
|---|---|---|
| `npm run verify:quick` | Tipos + estilo + pruebas unitarias | Menos de 1 minuto |
| `npm run test:rls` | Pruebas de permisos y base contra `palenque-test` | Pocos minutos |
| `npm run test:webhook` | Webhook con payloads de ejemplo y cliente de envío simulado | Menos de 1 minuto |
| `npm run eval` | Evaluación del bot (llama a la API de Claude: **cuesta unos centavos**, avisar antes de correrla) | Pocos minutos |
| `npm run e2e` | Playwright en viewport de celular contra la app local | Pocos minutos |
| `npm run audit` | Auditorías de 14.7 | Pocos minutos |
| `npm run verify` | `verify:quick` + `test:rls` + `test:webhook` + `e2e` + `audit` (y `eval` desde la fase 6) y escribe el semáforo | Entre 5 y 15 minutos |

`verify` termina con código de salida distinto de cero si cualquier cosa falla, e imprime el **semáforo** (14.9).

### 14.4 Entorno de pruebas (sin tocar producción)

- Segundo proyecto de Supabase llamado `palenque-test`, solo con datos inventados. Se crea en la fase 1 (guía, 1.2). Con un solo proyecto no hay forma segura de probar permisos.
- Sus llaves van en `.env.test.local` (ignorado por git), con los mismos nombres de variable que en la sección 4, más `APP_ENV=test` y `TEST_SUPABASE_PROJECT_REF=<ref del proyecto de pruebas>`.
- **Protección obligatoria:** todo script de pruebas que toque la base empieza con una función `assertTestEnvironment()` que aborta si `APP_ENV` no es `test` o si la URL de Supabase no contiene `TEST_SUPABASE_PROJECT_REF`. Es lo primero que se escribe y tiene su propia prueba (con una URL falsa de "producción" tiene que abortar).
- Las migraciones se aplican a `palenque-test` igual que a producción (`supabase db push` con el proyecto enlazado, confirmando a cuál apunta). No se usa `supabase db reset` remoto: cada corrida crea su propia organización de prueba con datos nuevos y la borra al terminar.
- Usuarios de prueba: uno por rol (dueño, encargado, petisero, veterinaria, herrero), creados por el script de preparación con la llave secreta del proyecto de pruebas.
- El cliente de WhatsApp y el de transcripción tienen una versión simulada (`lib/whatsapp/client.mock.ts`) que se elige según `APP_ENV`. En `test` nunca sale un mensaje real.
- Para `eval` y para una prueba manual de extremo a extremo con el modelo real se usa la API de Claude con la llave real: es la única excepción y siempre con aviso de costo.

### 14.5 Pruebas mínimas por fase

| Fase | Obligatorias (además de lo de la sección 12) |
|---|---|
| 2 | `verify:quick` corre y pasa sobre el proyecto vacío; existe una prueba que falla a propósito si falta `.env.example`. |
| 3 | Las 5 pruebas de permisos de 5.3. Una prueba por cada tabla que confirma que RLS está activo. Petisero y veterinaria **no** pueden leer `event_costs` (probado por consulta directa, no solo en pantalla). Un usuario de otra organización no ve nada. `assertTestEnvironment()` probada. |
| 4 | Unitarias de las reglas de la sección 6 con fechas fijas (no "hoy"): herraje vencido, carga de chukkers, estados. E2E: iniciar sesión por rol, cargar un evento, verlo en la ficha, cola offline (simular sin red, cargar, volver la red, sincroniza una sola vez). Lighthouse móvil sin errores graves de accesibilidad. |
| 5 | Webhook: firma válida pasa, firma inválida da 401, verificación GET con token correcto e incorrecto, mismo `wa_message_id` dos veces no duplica, remitente desconocido no escribe datos, payload de estado no rompe, audio, texto y botón se rutean bien. |
| 6 | Los casos obligatorios de 8.9. Nada se escribe en `events` sin confirmación; lesión siempre pide confirmación; "No" no escribe. La evaluación reporta aciertos por tipo de error y compara contra la corrida anterior (no puede empeorar sin que se avise). |
| 7 | Cron: sin `CRON_SECRET` da 401; el mismo aviso no se repite (`dedupe_key`); cada rol recibe solo lo que le corresponde (sección 9). Reloj simulado para vencimientos. |
| 8 | `npm run verify` completo en verde, informe final, revisión independiente hecha, checklist de la guía. |

### 14.6 Pruebas de las pruebas

Una prueba en verde no demuestra nada si nunca pudo fallar. Para cada protección crítica, Claude hace **una vez** esta rutina y la anota en el informe:

1. Romper la protección a propósito (por ejemplo: quitar la política que oculta `event_costs`; comentar la verificación de firma; quitar el chequeo de `wa_message_id`; escribir sin pedir confirmación).
2. Correr la prueba correspondiente y comprobar que **falla**.
3. Deshacer el cambio (`git checkout -- <archivo>` o `git restore`) y comprobar que vuelve a pasar.
4. Nunca hacer commit del estado roto.

Protecciones críticas que se verifican así: costos ocultos, aislamiento entre organizaciones, firma del webhook, idempotencia, confirmación obligatoria, `CRON_SECRET`, `assertTestEnvironment()`.

### 14.7 Auditorías (`npm run audit`)

| Auditoría | Cómo | Criterio |
|---|---|---|
| Dependencias | `npm audit` | Sin vulnerabilidades altas ni críticas sin explicar. Si hay una, Claude explica a qué afecta y propone cómo resolver, sin forzar actualizaciones que rompan. |
| Secretos en el código | Script `scripts/audit-secretos.mjs` (o una herramienta de escaneo de secretos; que Claude explique cuál usa y por qué) que busca patrones como `sb_secret_`, tokens de Meta, `sk-ant-` y llaves privadas en archivos versionados **y en el historial de git** | Cero hallazgos. Si hay uno, avisar y rotar la llave. |
| Secretos en el paquete que baja el navegador | Después de `next build`, buscar en la carpeta de salida pública el valor de cada variable que no sea `NEXT_PUBLIC_*` y el prefijo `sb_secret_` | Cero coincidencias. |
| RLS | Consulta contra `palenque-test`: tablas del esquema `public` sin RLS activo, y tablas con RLS pero sin ninguna política | Lista vacía. |
| Costos | Verificar que ninguna vista ni función expone columnas de `event_costs` a roles sin permiso | Cero fugas. |
| Advisors de Supabase | Panel del proyecto → Advisors (seguridad y rendimiento); la persona o Claude revisan y anotan cada aviso | Cero avisos de seguridad sin resolver o justificar por escrito. |
| Rendimiento, accesibilidad y buenas prácticas | Lighthouse en modo móvil sobre las pantallas principales | Accesibilidad y buenas prácticas sin errores graves; rendimiento sin regresión respecto del informe anterior. No se fija un número mágico: se registra y se compara. |
| Cabeceras y rutas | Rutas `/api/cron/*`, `/api/whatsapp/webhook` y datos privados responden como corresponde sin sesión | 401 o 403 donde corresponde. |

### 14.8 Revisión independiente

Quien escribe el código tiende a no ver sus propios errores. Al final de las fases 3, 5, 6 y 8:

1. Abrir una **sesión nueva** de Claude Code (o pedir un subagente revisor si tu versión lo soporta) que no vio cómo se escribió el código.
2. Darle el prompt de revisión de la guía: revisar solo lo nuevo de esa fase contra esta especificación (secciones 5, 8, 11 y esta), buscando permisos mal aplicados, filtración de secretos, falta de validación, condiciones de carrera, mensajes duplicados, textos engañosos para la persona y pruebas que no prueban nada.
3. El revisor **no modifica código**: entrega una lista priorizada (crítico, importante, menor) con archivo y línea.
4. La sesión de desarrollo resuelve los críticos e importantes, o justifica por escrito por qué no, y se vuelve a correr `verify`.
5. Si tu versión de Claude Code trae un comando propio de revisión de seguridad (por ejemplo `/security-review`), correlo también, pero **verificá en la documentación vigente** qué hace exactamente en tu versión antes de apoyarte en él. No reemplaza los pasos anteriores.

### 14.9 El semáforo

Al terminar `verify` y al cerrar cada fase, Claude muestra este resumen en castellano, sin jerga:

```
SEMÁFORO · Fase N · <fecha>
🟢 Pasa:        lo que está probado y anda
🟡 Con aviso:   lo que anda pero tiene algo para mirar (explicar en una frase)
🔴 Falla:       lo que no anda (explicar el efecto, no el error técnico)
⚪ No probado:  lo que no se pudo probar y por qué
Siguiente paso: una sola cosa que le toca a la persona (o "ninguna")
```

Si hay algún 🔴, la fase no se cierra. Si hay 🟡, la persona decide si seguir, y la decisión queda en el informe.

### 14.10 Informe por fase (`docs/informes/fase-N.md`)

Plantilla, en castellano y corta:

```
# Informe · Fase N · <fecha>
## Qué se construyó
## Resultado de `npm run verify` (pegar la salida real)
## Semáforo
## Pruebas de las pruebas hechas (14.6)
## Auditorías (14.7): resultados y avisos justificados
## Revisión independiente (si corresponde): hallazgos y cómo se resolvieron
## No probado y riesgos conocidos
## Cómo lo probó la persona en el celular
```

El informe se versiona en git. Es la evidencia de que la fase está terminada.

### 14.11 Integración continua (desde la fase 3)

- Un flujo de GitHub Actions (`.github/workflows/ci.yml`) que en cada push corra `verify:quick`, `test:webhook`, `audit` y, con las llaves del proyecto de pruebas guardadas como *secrets* del repositorio, `test:rls`.
- **Nunca** cargar en GitHub las llaves de producción para correr pruebas.
- Un push en rojo se atiende antes de seguir con otra tarea.
- Sobre las acciones de revisión automática que ofrece Claude Code para GitHub: es opcional; si se usa, verificar la documentación vigente (https://code.claude.com/docs/en/github-actions), tener en cuenta que consume créditos de la API y que no reemplaza este plan.
- Vercel despliega automáticamente al hacer push a `main`: por eso, hasta que exista el piloto, se acepta que producción puede romperse; desde el piloto se trabaja en ramas y se despliega solo con CI en verde.

### 14.12 Límites (decirlos con honestidad)

- Las pruebas demuestran lo que se probó, no que no haya errores.
- La evaluación del bot vale tanto como los mensajes reales que la persona aporte; con 10 mensajes no dice casi nada. Meta: 50 a 100 (8.9).
- Estas auditorías no son una prueba de penetración profesional. Antes de cargar datos de un haras real conviene una revisión humana de seguridad si el presupuesto lo permite.
- Meta, Supabase y Vercel pueden cambiar sus paneles y reglas: la guía es la fotografía de una fecha.
