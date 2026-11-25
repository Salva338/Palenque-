-- Palenque · Migración 2: permisos de acceso a las tablas para la API de Supabase
-- En este proyecto las tablas nuevas no quedan expuestas solas a la API: sin estos GRANT
-- ni siquiera el servidor (service_role) puede leerlas ("permission denied for table ...").
--
-- Qué se habilita:
--   * authenticated (usuarios con sesión): leer y escribir, SIEMPRE filtrado por las políticas RLS.
--   * service_role (solo el servidor, con la llave secreta): acceso completo.
--   * anon (sin sesión): NADA. Palenque no tiene datos públicos.

grant usage on schema public to authenticated, service_role;

grant select, insert, update, delete on all tables in schema public to authenticated, service_role;

-- Las tablas que se creen en próximas migraciones heredan lo mismo.
alter default privileges for role postgres in schema public
  grant select, insert, update, delete on tables to authenticated, service_role;

-- Por las dudas, sacarle todo a anon (si algún valor por defecto se lo hubiera dado).
revoke all on all tables in schema public from anon;
alter default privileges for role postgres in schema public revoke all on tables from anon;
