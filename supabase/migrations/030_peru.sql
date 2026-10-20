-- Experiencias Perú y el Mundo — adaptación de la base copiada de Ecuador.
-- 1) Zona horaria de Perú (America/Lima) en todas las funciones.
-- 2) Destinos nacionales de Perú en la validación del canje.
-- 3) Textos de bienvenida y mensajes.
-- 4) Paquetes: solo Escape Plus (12 meses) y Escape Premium (24 meses).

-- ---------- 1, 2 y 3: reescritura de funciones ----------
do $$
declare r record; d text; n text;
begin
  for r in
    select p.oid, pg_get_functiondef(p.oid) as def
    from pg_proc p join pg_namespace ns on ns.oid = p.pronamespace
    where ns.nspname = 'public' and p.prokind = 'f'
  loop
    d := r.def;
    n := d;
    n := replace(n, 'America/Guayaquil', 'America/Lima');
    n := replace(n, '''Quito'',''Guayaquil'',''Manta'',''Cuenca'',''Loja'',''Galápagos (Puerto Ayora)'')',
                    '''Paracas'',''Cusco'',''Máncora'',''Arequipa'',''Ica'',''Tarapoto'',''Cajamarca'',''Huaraz'',''Puno'',''Iquitos'')');
    n := replace(n, '''Quito'',''Guayaquil'',''Manta'',''Cuenca'',''Loja'')',
                    '''Paracas'',''Cusco'',''Máncora'',''Arequipa'',''Ica'',''Tarapoto'',''Cajamarca'',''Huaraz'',''Puno'',''Iquitos'')');
    n := replace(n, 'Experiencias Ecuador y el Mundo', 'Experiencias Perú y el Mundo');
    n := replace(n, ' y recibir puntos de regalo', '');
    if n <> d then execute n; end if;
  end loop;
end $$;

-- Comprobación: ninguna función debe seguir con datos de Ecuador.
do $$
begin
  if exists (
    select 1 from pg_proc p join pg_namespace ns on ns.oid = p.pronamespace
    where ns.nspname = 'public' and p.prokind = 'f'
      and (pg_get_functiondef(p.oid) ~* 'guayaquil|ecuador|galápagos|''quito''')
  ) then
    raise exception 'Quedan referencias de Ecuador en las funciones';
  end if;
end $$;

-- ---------- 4: paquetes ----------
update public.products set active = false, purchasable = false where slug = 'escape-esencial';

update public.products set
  tagline = 'Perú y el mundo en un solo paquete',
  description = 'Una escapada nacional de 3 días y 2 noches para 2 personas con desayuno y una invitación hotelera internacional con fee de emisión US$0.',
  price = 199.00, purchasable = true, active = true,
  validity_months = 12,
  national_count = 1, national_days = 3, national_nights = 2, national_people = 2, breakfast_included = true,
  international_count = 1, points = 0, bonus_points = 0,
  highlight = 'Más elegido', sort = 1,
  conditions = 'Vigencia de 12 meses desde el pago aprobado para solicitar la escapada nacional y la invitación hotelera internacional.
Destinos nacionales: Paracas, Cusco, Máncora, Arequipa, Ica, Tarapoto, Cajamarca, Huaraz, Puno e Iquitos, en los hoteles del catálogo vigente, con desayuno.
Invitación hotelera internacional: más de 130 destinos, desde 4 días y 3 noches hasta 8 días y 7 noches según destino. Fee de emisión US$0 en este paquete. El viajero paga los impuestos gubernamentales y las tasas del hotel o resort, que varían por destino y temporada.
Una vez emitida, la invitación debe registrarse en 30 días; los impuestos y tasas se pagan dentro de 7 días tras el registro; desde la activación hay 18 meses para viajar.
Solo se puede usar una invitación internacional por año y no se puede repetir destino.'
where slug = 'escape-plus';

update public.products set
  tagline = 'El doble de experiencias para disfrutar y regalar',
  description = 'Dos escapadas nacionales de 3 días y 2 noches para 2 personas con desayuno y dos invitaciones hoteleras internacionales con fee de emisión US$0.',
  price = 398.00, purchasable = true, active = true,
  validity_months = 24,
  national_count = 2, national_days = 3, national_nights = 2, national_people = 2, breakfast_included = true,
  international_count = 2, points = 0, bonus_points = 0,
  highlight = 'Más experiencias', sort = 2,
  conditions = 'Vigencia de 24 meses desde el pago aprobado para solicitar las escapadas nacionales y las invitaciones hoteleras internacionales.
Destinos nacionales: Paracas, Cusco, Máncora, Arequipa, Ica, Tarapoto, Cajamarca, Huaraz, Puno e Iquitos, en los hoteles del catálogo vigente, con desayuno.
Invitaciones hoteleras internacionales: más de 130 destinos, desde 4 días y 3 noches hasta 8 días y 7 noches según destino. Fee de emisión US$0 en este paquete. El viajero paga los impuestos gubernamentales y las tasas del hotel o resort.
Una invitación por año, sin repetir destino. Las dos invitaciones no pueden usarse en el mismo destino (no pueden viajar 4 personas al mismo destino). El incumplimiento de esta regla puede anular todos los certificados.
Desde la activación de cada invitación hay 18 meses para viajar.'
where slug = 'escape-premium';

-- Tarjetas de puntos: fuera del catálogo (igual que Ecuador).
update public.products set active = false where category = 'points';
