# Informe · Fase 3 · 25 de noviembre de 2026

## Qué se construyó
- **Modelo de datos** (`supabase/migrations/20261125190000_modelo_base.sql`): organizaciones, miembros, umbrales, caballos, eventos, costos (en una tabla aparte), partidos, reglas de agenda, avisos, suscripciones push y mensajes de WhatsApp.
  - Las llaves foráneas usan `(id, org_id)`, así que un evento, costo o chukker no puede apuntar a datos de otra organización.
  - Hay un disparador que deja a la veterinaria cambiar solo el estado del caballo.
  - Cada organización nueva arranca con sus umbrales y las 5 reglas de agenda.
- **RLS en todas las tablas**, con la matriz de permisos de la sección 5.2. `whatsapp_messages` tiene RLS sin políticas, así que solo la lee el servidor.
- **Permisos de tabla para la API** (`20261125200000_permisos_de_tablas.sql`): `authenticated` siempre filtrado por RLS, `service_role` completo y `anon` sin acceso.
- **Freno de pruebas** `assertTestEnvironment()`, con 5 pruebas propias.
- **29 pruebas de permisos** (`tests/rls/permisos.test.ts`) contra `palenque-test`. Crean dos organizaciones con un usuario por rol y al terminar borran todo.
- **Robots de GitHub Actions:**
  - `CI`: tipos, estilo y pruebas unitarias; después migraciones y pruebas de permisos en `palenque-test`; y solo si todo pasó, migraciones en `palenque`. Se conecta por el Session pooler, porque GitHub no tiene IPv6.
  - `Cargar demo`: corre `supabase/seed/demo.sql` en la base real.
- **Inicio de sesión** con email y contraseña:
  - `proxy.ts` manda al login a quien no tiene sesión.
  - Los errores salen en castellano y hay botón de cerrar sesión.
  - La página principal muestra el haras, el rol y la cantidad de caballos. Los datos se leen con RLS.
- **Datos de demostración "Haras Demo":** 13 caballos (con padre y madre cuando son propios), 79 eventos con fechas relativas a hoy y 50 costos. El script es repetible y solo toca la organización demo. Además suma usuarios de prueba por rol si existen (`byronzar22+petisero@gmail.com`, etc.).

## Resultado de las verificaciones (salidas reales)
- `npm run verify:quick` en esta sesión: tipos y estilo sin errores, **13 pruebas pasadas de 13**.
- GitHub Actions, corrida "Pruebas de permisos: las inserciones sin datos de vuelta…":
  - Tipos, estilo y pruebas unitarias: 9 de 9 (2 archivos).
  - Migraciones y permisos en palenque-test: **29 de 29**.
  - Migraciones en palenque (real): aplicadas. Supabase muestra "Last migration: permisos_de_tablas".
- `npm run verify` completo no existe todavía. Faltan las capas de webhook, pantallas (e2e) y auditorías, que corresponden a fases siguientes.

## Semáforo
- 🟢 Tipos, estilo y pruebas unitarias.
- 🟢 Pruebas de permisos en `palenque-test`: 29 de 29. Cubren las 5 obligatorias de 5.3, RLS en todas las tablas, la matriz de caballos, el visitante anónimo y los valores iniciales de cada organización.
- 🟢 Prueba humana en el celular, como dueño: Byron entró, vio "Haras Demo", el rol Dueño y 13 caballos.
- 🟡 Prueba humana como **petisero**: todavía no se hizo. Falta crear `byronzar22+petisero@gmail.com` en Authentication → Users y volver a correr "Cargar demo". La regla está cubierta por las pruebas automáticas, pero la guía pide verlo en el celular.
- ⚪ Revisión independiente (fin de la Fase 3): no hecha.

## Pruebas de las pruebas hechas (14.6)
- **Freno de pruebas:** se desactivó a propósito la comparación de la URL. Fallaron 2 pruebas, se deshizo el cambio y volvieron a pasar las 5.
- **Costos ocultos y aislamiento entre organizaciones:** se probó en una copia local de la base (Postgres en memoria con PGlite, mismas migraciones y mismos datos demo). No se hizo contra Supabase para no dejar una regla rota aplicada en `palenque-test`.
  - Normal: el dueño ve 50 costos, el petisero 0, y el usuario de otro haras 0 caballos de Haras Demo.
  - Se reemplazó la política de `event_costs` por una que deja ver todo: el petisero pasó a ver **50 costos**. La protección hace falta y funciona.
  - Se reemplazó la política de lectura de `horses` por una abierta: el usuario de otro haras pasó a ver **13 caballos**.
  - Pendiente: hacer esta misma rutina con la suite de Vitest contra `palenque-test` (romper, ver la prueba en rojo, deshacer con otra migración).

## Arreglos durante la fase
- GitHub Actions no tiene IPv6, así que se pasó a la conexión por el Session pooler.
- Los proyectos nuevos de Supabase no exponen las tablas a la API sin GRANT, así que se agregó la migración 2.
- Las pruebas ahora limpian espacios en las llaves y avisan si un secreto tiene mal formato. Esto apareció porque al principio se cargó una llave del proyecto equivocado.
- Con `cacheComponents` de Next 16, lo que depende de la sesión va dentro de `<Suspense>`.

## No probado y riesgos conocidos
- **Llaves que se vieron en pantalla compartida y en una reunión grabada:** el token de acceso de Supabase y la Secret key del proyecto real. Byron y Salva decidieron no rotarlas por ahora. **Hay que rotarlas antes de cargar datos de un cliente real** (checklist de la Fase 8).
- `palenque-test` está en Oregon y en otra organización de Supabase. No afecta, porque solo lo usan las pruebas.
- El repositorio es **público** (decisión tomada para que Vercel Hobby publique los cambios). Las llaves nunca van al repo; se revisó el historial y no hay ninguna.
- GitHub avisa que `actions/checkout@v4`, `setup-node@v4` y `setup-cli@v1` corren con Node 20, que está en desuso. Conviene actualizarlas más adelante.
- La región de las funciones de Vercel (São Paulo) no está confirmada.

## Cómo lo probó la persona en el celular
- Abrió palenque-rust.vercel.app, entró con su email y contraseña y vio "¡Hola, Byron!", Haras Demo, el rol Dueño y "Caballos cargados: 13".
