# Palenque

App de gestión de caballerizas y haras (PWA). El petisero carga novedades por WhatsApp (audio o texto); la app calcula agenda y alertas. Este repositorio es el MVP, construido a partir de un prototipo HTML.

## Leé esto primero

1. `docs/GUIA-MVP-PALENQUE.md`: el orden de trabajo (fases 0 a 8) y lo que le toca hacer a la persona.
2. `docs/ESPECIFICACION-PALENQUE.md`: qué se construye (modelo de datos, permisos, reglas, pantallas, WhatsApp).
3. `docs/prototipo/Palenque-prototipo.html`: referencia visual y de comportamiento (datos inventados).

Si el repositorio ya tiene código, mirá `git log` y los archivos para saber en qué fase estamos antes de proponer nada.

## Con quién trabajás

La persona **no sabe programar**. Hablale en castellano rioplatense (voseo), simple y directo. Explicá cada cosa en una frase antes de hacerla. Una fase por vez y una tarea chica por vez. Cuando le toque a ella hacer algo (crear una cuenta, pegar una llave, tocar un botón en un panel web), decíselo con el nombre exacto del botón.

## Reglas permanentes

- **Secretos:** nunca le pidas que pegue llaves en el chat. Los valores van en `.env.local` (que debe estar en `.gitignore` antes del primer commit). No imprimas `.env*`.
- **Confirmación obligatoria** antes de: borrar archivos o datos, `git push --force`, resetear la base remota, cambiar de plan o pagos, enviar WhatsApp reales a números que no sean de prueba.
- **Documentación vigente:** verificá la documentación oficial de Meta, Supabase, Vercel, Next.js, Anthropic y del proveedor de transcripción antes de usar sus APIs. Si contradice la guía, ganá la documentación y avisá.
- **Sin Docker.** No uses `supabase start`. Migraciones en `supabase/migrations` y `supabase db push` contra el proyecto en la nube.
- **Permisos:** RLS en todas las tablas. El código de servidor que use `SUPABASE_SECRET_KEY` aplica la matriz de permisos a mano.
- **Commits** chicos y frecuentes, en castellano. Hasta el piloto se trabaja sobre `main`; desde el piloto, en ramas con pull request.
- **No agregues dependencias** sin explicar para qué sirven.
- **No avances de fase** hasta que pase la prueba de la fase actual.
- Al cerrar cada fase, resumí en 3 líneas: qué quedó andando, qué probar y qué sigue.

## Pruebas y auditorías (obligatorio, ver sección 14 de la especificación)

- Cada funcionalidad nueva lleva sus pruebas en el mismo commit. Sin prueba no está terminada.
- Nunca debilites, borres ni saltees una prueba para ponerla en verde. Si falla, arreglá el código; si la prueba está mal, explicalo a la persona antes de tocarla.
- No digas "anda" sin haber corrido `npm run verify` en esta sesión y mostrar el resultado real. Lo que no pudiste probar se informa como "no probado".
- Las pruebas usan solo el proyecto `palenque-test` (`.env.test.local`) y `assertTestEnvironment()`. Nunca producción, nunca WhatsApp reales. Avisá el costo antes de correr `npm run eval`.
- Al cerrar cada fase: mostrá el semáforo (🟢🟡🔴⚪) en castellano simple y escribí `docs/informes/fase-N.md`.
- Hacé "la prueba de la prueba" de las protecciones críticas (14.6): rompelas a propósito, confirmá que la prueba falla y deshacé el cambio.
- Al final de las fases 3, 5, 6 y 8 la persona va a abrir una sesión nueva para una revisión independiente. En esa sesión **solo revisás y reportás**, no modificás código.
