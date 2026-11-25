# Palenque

App de gestión de caballerizas y haras. El petisero carga las novedades por WhatsApp (con audio o texto) y la app calcula sola la agenda y las alertas de cada caballo.

- **En línea:** https://palenque-rust.vercel.app
- **Estado:** MVP en construcción. Fase 2 cerrada (proyecto base publicado).

## Documentación

- `CLAUDE.md`: reglas de trabajo.
- `docs/GUIA-MVP-PALENQUE.md`: el orden de las fases.
- `docs/ESPECIFICACION-PALENQUE.md`: qué se construye.
- `docs/informes/`: el informe de cada fase cerrada.

## Comandos

```
npm install            # instala las dependencias
npm run dev            # abre la app en http://localhost:3000
npm run verify:quick   # tipos, estilo y pruebas
```

Las llaves van en `.env.local`, que nunca se sube al repo. La lista de variables está en `.env.example`.
