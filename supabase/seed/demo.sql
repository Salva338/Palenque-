-- Palenque · Datos de demostración "Haras Demo"
-- Lo corre solo GitHub Actions (workflow "Cargar demo") cada vez que cambia este archivo.
-- También se puede pegar en Supabase → SQL Editor → New query → Run (proyecto palenque).
-- 1) Cambiá el email de abajo por el del usuario que creaste en Authentication → Users.
-- 2) Es repetible (última corrida: 26/11, alta del petisero de prueba): si "Haras Demo" ya existe, lo borra y lo vuelve a crear. No toca nada más.

do $$
declare
  _email text := 'byronzar22@gmail.com';   -- ← CAMBIALO si usaste otro email
  _nombre text := 'Byron';                 -- ← cómo te va a saludar la app
  _user uuid;
  _org uuid;
begin
  select id into _user from auth.users where lower(email) = lower(_email);
  if _user is null then
    raise exception 'No existe un usuario con el email %. Crealo primero en Authentication → Users.', _email;
  end if;

  delete from public.organizations where name = 'Haras Demo';
  insert into public.organizations (name) values ('Haras Demo') returning id into _org;

  insert into public.memberships (user_id, org_id, role, display_name)
  values (_user, _org, 'dueno', _nombre);

  -- Usuarios de prueba por rol: si existen en Authentication → Users con estos emails,
  -- se suman a Haras Demo con su rol. Si no existen, se saltean sin error.
  insert into public.memberships (user_id, org_id, role, display_name)
  select u.id, _org, r.rol::public.member_role, r.nombre
    from (values
      ('byronzar22+encargado@gmail.com', 'encargado', 'Encargado demo'),
      ('byronzar22+petisero@gmail.com',  'petisero',  'Juan'),
      ('byronzar22+vet@gmail.com',       'vet',       'Dra. Paula'),
      ('byronzar22+herrero@gmail.com',   'herrero',   'Martín')
    ) as r(email, rol, nombre)
    join auth.users u on lower(u.email) = r.email;

  insert into public.horses (org_id, number, name, sex, coat, birth_date, birth_place, sire_name, dam_name, registry_code, breeder, status, location)
  select _org, v.number, v.name, v.sex, v.coat, v.birth_date, v.birth_place, v.sire_name, v.dam_name,
         v.registry_code, v.breeder, v.status::public.horse_status, v.location
    from (values
    (1, 'Pampero', 'padrillo', 'Zaino', date '2012-10-14', 'General Rodríguez, Bs. As.', 'Gaucho Viejo', 'La Querencia', 'SB-12-0437', 'Cría propia', 'cria', 'Haras · Potrero 2'),
    (2, 'Luna Nueva', 'yegua', 'Tordillo', date '2011-09-02', 'General Rodríguez, Bs. As.', 'Ventarrón', 'Brisa', 'SB-11-0474', 'Cría propia', 'cria', 'Haras · Potrero 1'),
    (3, 'Gitana', 'yegua', 'Alazán', date '2010-11-20', 'General Rodríguez, Bs. As.', 'Ventarrón', 'Morocha', 'SB-10-0511', 'Cría propia', 'cria', 'Haras · Potrero 1'),
    (4, 'Tango', 'yegua', 'Zaino', date '2017-10-05', 'General Rodríguez, Bs. As.', null, null, 'SB-17-0548', 'Cría propia', 'en_juego', 'Caballeriza A · Box 4'),
    (5, 'Chispa', 'yegua', 'Alazán', date '2016-12-01', 'General Rodríguez, Bs. As.', null, null, 'SB-16-0585', 'Cría propia', 'en_juego', 'Caballeriza A · Box 5'),
    (6, 'Picardía', 'yegua', 'Colorado', date '2015-09-18', 'General Rodríguez, Bs. As.', null, 'Chacarera', 'SB-15-0622', 'Cría propia', 'lesionado', 'Caballeriza A · Box 6'),
    (7, 'Tormenta', 'yegua', 'Moro', date '2018-08-30', 'General Rodríguez, Bs. As.', null, null, 'SB-18-0659', 'Cría propia', 'en_juego', 'Caballeriza A · Box 7'),
    (8, 'Morena', 'yegua', 'Oscuro', date '2016-10-22', 'General Rodríguez, Bs. As.', 'Ventarrón', 'Pulpera', 'SB-16-0696', 'Cría propia', 'en_juego', 'Caballeriza A · Box 8'),
    (9, 'Indiecita', 'yegua', 'Bayo', date '2019-11-11', 'General Rodríguez, Bs. As.', null, null, 'SB-19-0733', 'Cría propia', 'en_doma', 'Caballeriza B · Box 2'),
    (10, 'Lucerito', 'macho_castrado', 'Tordillo', date '2015-10-03', 'General Rodríguez, Bs. As.', 'Ventarrón', 'Estrella', 'SB-15-0770', 'Cría propia', 'en_juego', 'Caballeriza A · Box 10'),
    (11, 'Yerba', 'yegua', 'Overo', date '2020-09-25', 'General Rodríguez, Bs. As.', null, null, 'SB-20-0807', 'Cría propia', 'en_doma', 'Caballeriza B · Box 3'),
    (12, 'Bataraza', 'yegua', 'Zaino', date '2014-09-09', 'General Rodríguez, Bs. As.', 'Gaucho Viejo', 'Tropilla', 'SB-14-0844', 'Cría propia', 'descanso', 'Potrero 4'),
    (13, 'Potranca de Luna', 'potranca', 'Tordillo', current_date - 200, 'General Rodríguez, Bs. As.', null, null, 'SB-26-0881', 'Cría propia', 'potrillo', 'Haras · Potrero 1')
  ) as v(number, name, sex, coat, birth_date, birth_place, sire_name, dam_name, registry_code, breeder, status, location);

  -- Padres que son caballos propios (Pampero, Luna Nueva, Gitana)
  update public.horses h set sire_id = p.id, sire_name = null
    from public.horses p
   where h.org_id = _org and p.org_id = _org and p.number = 1 and h.number in (4,5,6,7,9,11,13);
  update public.horses h set dam_id = m.id, dam_name = null
    from public.horses m
   where h.org_id = _org and m.org_id = _org and m.number = 2 and h.number in (4,7,11,13);
  update public.horses h set dam_id = m.id, dam_name = null
    from public.horses m
   where h.org_id = _org and m.org_id = _org and m.number = 3 and h.number in (5,9);

  -- Eventos con fechas relativas a hoy, y sus costos en la tabla aparte
  with datos(nro, fecha, tipo, titulo, nota, por, costo) as (values
    (1, current_date - 30, 'sanidad', 'Vacuna influenza y tétanos', null, 'Dra. Paula (veterinaria)', 25000),
    (1, current_date - 20, 'sanidad', 'Desparasitación', null, 'Encargado', 12000),
    (1, current_date - 10, 'sanidad', 'Análisis AIE', 'Negativo. Certificado vigente para traslados.', 'Dra. Paula (veterinaria)', 18000),
    (2, current_date - 170, 'sanidad', 'Vacuna influenza y tétanos', null, 'Dra. Paula (veterinaria)', 25000),
    (2, current_date - 95, 'sanidad', 'Desparasitación', null, 'Encargado', 12000),
    (2, current_date - 55, 'sanidad', 'Análisis AIE', 'Negativo. Certificado vigente para traslados.', 'Dra. Paula (veterinaria)', 18000),
    (3, current_date - 150, 'sanidad', 'Vacuna influenza y tétanos', null, 'Dra. Paula (veterinaria)', 25000),
    (3, current_date - 40, 'sanidad', 'Desparasitación', null, 'Encargado', 12000),
    (3, current_date - 40, 'sanidad', 'Análisis AIE', 'Negativo. Certificado vigente para traslados.', 'Dra. Paula (veterinaria)', 18000),
    (4, current_date - 20, 'herreria', 'Herrado completo', null, 'Martín (herrero)', 65000),
    (4, current_date - 60, 'sanidad', 'Vacuna influenza y tétanos', null, 'Dra. Paula (veterinaria)', 25000),
    (4, current_date - 85, 'sanidad', 'Desparasitación', null, 'Encargado', 12000),
    (4, current_date - 30, 'sanidad', 'Análisis AIE', 'Negativo. Certificado vigente para traslados.', 'Dra. Paula (veterinaria)', 18000),
    (5, current_date - 35, 'herreria', 'Herrado completo', null, 'Martín (herrero)', 65000),
    (5, current_date - 175, 'sanidad', 'Vacuna influenza y tétanos', null, 'Dra. Paula (veterinaria)', 25000),
    (5, current_date - 60, 'sanidad', 'Desparasitación', null, 'Encargado', 12000),
    (5, current_date - 58, 'sanidad', 'Análisis AIE', 'Negativo. Certificado vigente para traslados.', 'Dra. Paula (veterinaria)', 18000),
    (6, current_date - 48, 'herreria', 'Herrado completo', null, 'Martín (herrero)', 65000),
    (6, current_date - 20, 'sanidad', 'Vacuna influenza y tétanos', null, 'Dra. Paula (veterinaria)', 25000),
    (6, current_date - 92, 'sanidad', 'Desparasitación', null, 'Encargado', 12000),
    (6, current_date - 20, 'sanidad', 'Análisis AIE', 'Negativo. Certificado vigente para traslados.', 'Dra. Paula (veterinaria)', 18000),
    (7, current_date - 15, 'herreria', 'Herrado completo', null, 'Martín (herrero)', 65000),
    (7, current_date - 100, 'sanidad', 'Vacuna influenza y tétanos', null, 'Dra. Paula (veterinaria)', 25000),
    (7, current_date - 10, 'sanidad', 'Desparasitación', null, 'Encargado', 12000),
    (7, current_date - 40, 'sanidad', 'Análisis AIE', 'Negativo. Certificado vigente para traslados.', 'Dra. Paula (veterinaria)', 18000),
    (8, current_date - 44, 'herreria', 'Herrado completo', null, 'Martín (herrero)', 65000),
    (8, current_date - 186, 'sanidad', 'Vacuna influenza y tétanos', null, 'Dra. Paula (veterinaria)', 25000),
    (8, current_date - 70, 'sanidad', 'Desparasitación', null, 'Encargado', 12000),
    (8, current_date - 65, 'sanidad', 'Análisis AIE', 'Negativo. Certificado vigente para traslados.', 'Dra. Paula (veterinaria)', 18000),
    (9, current_date - 25, 'herreria', 'Herrado completo', null, 'Martín (herrero)', 65000),
    (9, current_date - 40, 'sanidad', 'Vacuna influenza y tétanos', null, 'Dra. Paula (veterinaria)', 25000),
    (9, current_date - 88, 'sanidad', 'Desparasitación', null, 'Encargado', 12000),
    (9, current_date - 50, 'sanidad', 'Análisis AIE', 'Negativo. Certificado vigente para traslados.', 'Dra. Paula (veterinaria)', 18000),
    (10, current_date - 30, 'herreria', 'Herrado completo', null, 'Martín (herrero)', 65000),
    (10, current_date - 160, 'sanidad', 'Vacuna influenza y tétanos', null, 'Dra. Paula (veterinaria)', 25000),
    (10, current_date - 45, 'sanidad', 'Desparasitación', null, 'Encargado', 12000),
    (10, current_date - 15, 'sanidad', 'Análisis AIE', 'Negativo. Certificado vigente para traslados.', 'Dra. Paula (veterinaria)', 18000),
    (11, current_date - 52, 'herreria', 'Herrado completo', null, 'Martín (herrero)', 65000),
    (11, current_date - 90, 'sanidad', 'Vacuna influenza y tétanos', null, 'Dra. Paula (veterinaria)', 25000),
    (11, current_date - 30, 'sanidad', 'Desparasitación', null, 'Encargado', 12000),
    (11, current_date - 70, 'sanidad', 'Análisis AIE', 'Negativo. Certificado vigente para traslados.', 'Dra. Paula (veterinaria)', 18000),
    (12, current_date - 40, 'herreria', 'Herrado completo', null, 'Martín (herrero)', 65000),
    (12, current_date - 195, 'sanidad', 'Vacuna influenza y tétanos', null, 'Dra. Paula (veterinaria)', 25000),
    (12, current_date - 100, 'sanidad', 'Desparasitación', null, 'Encargado', 12000),
    (12, current_date - 25, 'sanidad', 'Análisis AIE', 'Negativo. Certificado vigente para traslados.', 'Dra. Paula (veterinaria)', 18000),
    (13, current_date - 40, 'sanidad', 'Vacuna influenza y tétanos', null, 'Dra. Paula (veterinaria)', 25000),
    (13, current_date - 50, 'sanidad', 'Desparasitación', null, 'Encargado', 12000),
    (4, current_date - 3, 'trabajo', 'Vareo', null, 'Juan (petisero)', null),
    (4, current_date - 6, 'trabajo', 'Taqueo', null, 'Juan (petisero)', null),
    (4, current_date - 11, 'trabajo', 'Práctica', null, 'Juan (petisero)', null),
    (4, current_date - 13, 'trabajo', 'Galope largo', null, 'Juan (petisero)', null),
    (4, current_date - 19, 'trabajo', 'Vareo', null, 'Juan (petisero)', null),
    (5, current_date - 3, 'trabajo', 'Vareo', null, 'Juan (petisero)', null),
    (5, current_date - 6, 'trabajo', 'Taqueo', null, 'Juan (petisero)', null),
    (5, current_date - 11, 'trabajo', 'Práctica', null, 'Juan (petisero)', null),
    (5, current_date - 13, 'trabajo', 'Galope largo', null, 'Juan (petisero)', null),
    (5, current_date - 19, 'trabajo', 'Vareo', null, 'Juan (petisero)', null),
    (7, current_date - 3, 'trabajo', 'Vareo', null, 'Juan (petisero)', null),
    (7, current_date - 6, 'trabajo', 'Taqueo', null, 'Juan (petisero)', null),
    (7, current_date - 11, 'trabajo', 'Práctica', null, 'Juan (petisero)', null),
    (7, current_date - 13, 'trabajo', 'Galope largo', null, 'Juan (petisero)', null),
    (7, current_date - 19, 'trabajo', 'Vareo', null, 'Juan (petisero)', null),
    (8, current_date - 3, 'trabajo', 'Vareo', null, 'Juan (petisero)', null),
    (8, current_date - 6, 'trabajo', 'Taqueo', null, 'Juan (petisero)', null),
    (8, current_date - 11, 'trabajo', 'Práctica', null, 'Juan (petisero)', null),
    (8, current_date - 13, 'trabajo', 'Galope largo', null, 'Juan (petisero)', null),
    (8, current_date - 19, 'trabajo', 'Vareo', null, 'Juan (petisero)', null),
    (10, current_date - 3, 'trabajo', 'Vareo', null, 'Juan (petisero)', null),
    (10, current_date - 6, 'trabajo', 'Taqueo', null, 'Juan (petisero)', null),
    (10, current_date - 11, 'trabajo', 'Práctica', null, 'Juan (petisero)', null),
    (10, current_date - 13, 'trabajo', 'Galope largo', null, 'Juan (petisero)', null),
    (10, current_date - 19, 'trabajo', 'Vareo', null, 'Juan (petisero)', null),
    (4, current_date - 5, 'alimento', 'Comió poco', 'Dejó media ración a la noche.', 'Juan (petisero)', null),
    (4, current_date - 2, 'alimento', 'No quiso comer', 'No tocó la ración de la mañana.', 'Juan (petisero)', null),
    (4, current_date - 1, 'lesion', 'Mano caliente', 'Mano izquierda, algo de calor en el tendón. Se le puso hielo 20 min.', 'Juan (petisero)', null),
    (4, current_date - 120, 'vet', 'Ecografía de tendones', 'Sin novedades. Tendones en buen estado.', 'Dra. Paula (veterinaria)', 110000),
    (6, current_date - 25, 'lesion', 'Tendón inflamado', 'Mano derecha, tendón flexor superficial. Se la dejó en box.', 'Encargado', null),
    (6, current_date - 24, 'vet', 'Ecografía de tendones', 'Lesión leve. Reposo 30 días, hielo y vendaje.', 'Dra. Paula (veterinaria)', 120000),
    (6, current_date - 10, 'vet', 'Control post lesión', 'Evoluciona bien. Caminatas de mano de 20 minutos.', 'Dra. Paula (veterinaria)', 90000)
  ), nuevos as (
    insert into public.events (org_id, horse_id, type, title, note, occurred_on, created_by_name, source)
    select _org, h.id, d.tipo::public.event_type, d.titulo, d.nota, d.fecha, d.por, 'sistema'
      from datos d join public.horses h on h.org_id = _org and h.number = d.nro
    returning id, horse_id, title, occurred_on
  )
  insert into public.event_costs (event_id, org_id, amount)
  select n.id, _org, d.costo
    from nuevos n
    join public.horses h on h.id = n.horse_id
    join datos d on d.nro = h.number and d.titulo = n.title and d.fecha = n.occurred_on
   where d.costo is not null;

  raise notice 'Listo: Haras Demo con 13 caballos. % es dueño.', _email;
end $$;
