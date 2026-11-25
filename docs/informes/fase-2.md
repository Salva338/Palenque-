# Informe · Fase 2 · 25 de noviembre de 2026

## Qué se construyó
- Proyecto base en Next.js 16 con TypeScript estricto y Tailwind 4, con la identidad visual del prototipo: colores verde y latón, tipografías Fraunces e Inter y logo del caballo.
- Las tipografías van incluidas en el proyecto como paquetes de npm, así que la app no depende de Google Fonts.
- La configuración de shadcn/ui (`components.json` y `lib/utils.ts`) quedó escrita a mano, porque el instalador no pudo conectarse a su registro. Los componentes se suman a medida que hagan falta.
- `.env.example` (versionado y sin valores) con todas las variables de la sección 4. `.env*` excluido en `.gitignore` desde el primer commit.
- Documentación del instructivo en `docs/`: guía, especificación, prototipo y diagramas.
- Repositorio: `Salva338/Palenque-`, rama `main`. Publicado en Vercel (equipo Salva, plan Hobby).

## Resultado de `npm run verify:quick` (salida real, sobre una copia limpia del repo)
```
> tsc --noEmit          (sin errores)
> eslint                (sin errores)
> vitest run
 Test Files  1 passed (1)
      Tests  4 passed (4)
```
Todavía no existe `npm run verify` completo. Las capas de base de datos, webhook, pantallas y auditorías llegan en las fases siguientes.

## Semáforo
- 🟢 Tipos y estilo
- 🟢 Pruebas unitarias: `.env.example` existe y viene sin valores, `.gitignore` excluye los `.env`, `norm()` funciona
- 🟢 Publicación en Vercel: el despliegue de producción salió en 26 segundos
- 🟢 Prueba humana en el celular: la página se abrió bien en un iPhone
- ⚪ No probado: permisos, webhook, pantallas y auditorías (no corresponden a esta fase)

## Pruebas de las pruebas hechas (14.6)
- Se sacó `.env.example` a propósito: 2 pruebas fallaron. Al volver a poner el archivo, las 4 pasaron de nuevo.

## Arreglos durante el cierre
- En una copia limpia del repo, `tsc` fallaba porque el tipo `LayoutProps` solo existe después de que Next.js genera sus tipos. Vercel compilaba bien igual, pero la verificación local no. Se reemplazó por un tipo explícito.

## No probado y riesgos conocidos
- Plan Hobby de Vercel: es solo para uso no comercial. Antes del piloto hay que pasar a Pro (Fase 8).
- El repo es de Salva y los cambios los sube la cuenta de Byron. Si Vercel Hobby bloquea despliegues de autores que no son dueños de la cuenta, va a haber que revisarlo.
- La región de las funciones (São Paulo, `gru1`) todavía no se configuró. Hace falta recién cuando haya funciones de servidor (Fase 3 en adelante).

## Cómo lo probó la persona en el celular
- Byron abrió la dirección pública de Vercel en su iPhone y vio la pantalla de Palenque con el encabezado verde, el logo y los colores del prototipo.
