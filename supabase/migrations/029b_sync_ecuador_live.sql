-- Funciones que en Ecuador se ajustaron directamente en la base (no estaban en las migraciones).
-- Se copian tal cual para que Perú parta de la versión vigente.

CREATE OR REPLACE FUNCTION public.access_reactivate(p_purchase_id uuid)
 RETURNS timestamp with time zone
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_p public.access_purchases%rowtype; v_ends timestamptz := now() + interval '14 days';
begin
  select * into v_p from public.access_purchases where id = p_purchase_id for update;
  if not found or v_p.kind <> 'reactivation' or v_p.user_id is null then raise exception 'Compra no encontrada'; end if;
  if v_p.status <> 'approved' then raise exception 'El pago no está aprobado'; end if;
  if v_p.credited_at is not null then
    return (select purchase_window_ends_at from public.profiles where user_id = v_p.user_id);
  end if;
  update public.profiles set purchase_window_started_at = now(), purchase_window_ends_at = v_ends, purchase_window_reminder = 0
    where user_id = v_p.user_id and role = 'user';
  update public.access_purchases set credited_at = now() where id = v_p.id;
  insert into public.audit_events (actor_user_id, event_type, details)
    values (v_p.user_id, 'access_reactivated', jsonb_build_object('purchase_id', v_p.id, 'payphone_id', v_p.payphone_id));
  perform public.post_message(v_p.user_id, 'auto', '✅ Acceso reactivado: tienes 14 días para elegir tu experiencia',
    'Elige tu paquete con precios especiales antes de que termine el plazo.',
    '/cuenta/catalogo', null, false);
  return v_ends;
end; $function$;

CREATE OR REPLACE FUNCTION public.admin_extend_purchase_window(p_user_id uuid, p_days integer DEFAULT 14)
 RETURNS timestamp with time zone
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_ends timestamptz := now() + make_interval(days => greatest(1, least(coalesce(p_days, 14), 60)));
begin
  if not public.is_admin() then raise exception 'Acceso no autorizado'; end if;
  update public.profiles set purchase_window_started_at = now(), purchase_window_ends_at = v_ends, purchase_window_reminder = 0
    where user_id = p_user_id and role = 'user';
  if not found then raise exception 'Cliente no encontrado'; end if;
  perform public.post_message(p_user_id, 'auto', '⏳ Tienes ' || greatest(1, least(coalesce(p_days, 14), 60)) || ' días más para elegir tu experiencia',
    'Reabrimos tu periodo de precios especiales. Elige tu paquete con precios especiales antes de que termine.', '/cuenta/catalogo', null, true);
  insert into public.audit_events (actor_user_id, event_type, details)
    values (auth.uid(), 'purchase_window_extended', jsonb_build_object('user_id', p_user_id, 'ends', v_ends));
  return v_ends;
end; $function$;

CREATE OR REPLACE FUNCTION public.company_team_finalize(p_actor uuid, p_user_id uuid, p_name text, p_email text, p_role text, p_department text, p_daily_limit integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_actor public.profiles%rowtype;
begin
  select * into v_actor from public.profiles where user_id = p_actor;
  if v_actor.role <> 'company' or v_actor.company_role not in ('owner','admin') then raise exception 'Acceso no autorizado'; end if;
  if p_role not in ('admin','member') then raise exception 'Tipo de usuario inválido'; end if;
  insert into public.profiles (user_id, role, full_name, email, company_id, created_via, company_role, department, daily_limit, member_status, invited_by)
    values (p_user_id, 'company', trim(p_name), public.normalize_email(p_email), v_actor.company_id, 'company', p_role,
      nullif(trim(p_department), ''), case when p_role = 'member' then p_daily_limit end, 'active', p_actor);
  if nullif(trim(p_department), '') is not null then
    update public.companies set departments = array_append(departments, trim(p_department))
      where id = v_actor.company_id and not (trim(p_department) = any(departments));
  end if;
  insert into public.audit_events (actor_user_id, company_id, event_type, details)
    values (p_actor, v_actor.company_id, 'company_team_member_added',
      jsonb_build_object('email', public.normalize_email(p_email), 'role', p_role, 'department', p_department, 'daily_limit', p_daily_limit));
end; $function$;

CREATE OR REPLACE FUNCTION public.company_team_report(p_from date, p_to date)
 RETURNS TABLE(member_id uuid, member_name text, department text, created integer, activated integer)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
begin
  if not public.company_is_manager() then raise exception 'Acceso no autorizado'; end if;
  return query
    select m.user_id, m.full_name, coalesce(m.department, case m.company_role when 'owner' then 'Administrador principal' else 'Administración' end),
      count(l.id)::int,
      (count(l.id) filter (where u.encrypted_password is not null and u.encrypted_password <> ''))::int
    from public.quota_ledger l
    join public.profiles m on m.user_id = l.created_by
    left join auth.users u on u.id = l.user_id
    where l.company_id = public.current_company_id() and l.reason = 'user_created'
      and (l.created_at at time zone 'America/Guayaquil')::date between p_from and p_to
    group by m.user_id, m.full_name, m.department, m.company_role
    order by 3, 4 desc;
end; $function$;

CREATE OR REPLACE FUNCTION public.ensure_purchase_window()
 RETURNS timestamp with time zone
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_p public.profiles%rowtype;
begin
  select * into v_p from public.profiles where user_id = auth.uid() for update;
  if not found or v_p.role <> 'user' then return null; end if;
  if v_p.purchase_window_started_at is not null then return v_p.purchase_window_ends_at; end if;
  update public.profiles set purchase_window_started_at = now(), purchase_window_ends_at = now() + interval '14 days', purchase_window_reminder = 0
    where user_id = v_p.user_id;
  perform public.post_message(v_p.user_id, 'auto', '⏳ Tienes 14 días para elegir tu experiencia',
    'Son precios especiales de hospedaje que conseguimos por tiempo limitado. Elige tu paquete en los próximos 14 días. Una vez comprado, tienes de 12 a 24 meses para usarlo.',
    '/cuenta/catalogo', null, false);
  return now() + interval '14 days';
end; $function$;

CREATE OR REPLACE FUNCTION public.gift_entitlements(p_entitlement_ids uuid[], p_recipient_name text, p_email text, p_email_confirm text, p_dedication text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare v_check jsonb; v_email text; v_recipient uuid; v_gift uuid; v_code text; r public.entitlements%rowtype;
begin
  v_check := public.gift_precheck(p_entitlement_ids, p_recipient_name, p_email, p_email_confirm);
  v_email := v_check->>'email';
  select id into v_recipient from auth.users where lower(email) = v_email;
  if v_recipient is null then raise exception 'Primero debe crearse la cuenta del destinatario'; end if;
  perform public.ensure_user_profile(v_recipient, p_recipient_name, v_email);
  for r in select * from public.entitlements where id = any(p_entitlement_ids) for update loop
    if r.owner_id <> auth.uid() or not public.entitlement_giftable(r) then
      raise exception 'Alguna experiencia ya no se puede regalar';
    end if;
  end loop;
  insert into public.gifts (sender_id, recipient_id, recipient_name, recipient_email, dedication)
    values (auth.uid(), v_recipient, trim(p_recipient_name), v_email, nullif(trim(p_dedication), ''))
    returning id, code into v_gift, v_code;
  insert into public.entitlement_transfers (entitlement_id, from_user, to_user, gift_id)
    select id, auth.uid(), v_recipient, v_gift from public.entitlements where id = any(p_entitlement_ids);
  update public.entitlements set owner_id = v_recipient, gift_id = v_gift where id = any(p_entitlement_ids);
  insert into public.audit_events (actor_user_id, event_type, details)
    values (auth.uid(), 'entitlements_gifted', jsonb_build_object('gift', v_code, 'count', array_length(p_entitlement_ids, 1)));
  return jsonb_build_object('gift_id', v_gift, 'gift_code', v_code, 'recipient_id', v_recipient);
end; $function$;

CREATE OR REPLACE FUNCTION public.post_message(p_user_id uuid, p_kind text, p_title text, p_body text, p_link text DEFAULT NULL::text, p_booking_id uuid DEFAULT NULL::uuid, p_email boolean DEFAULT true)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_id uuid;
begin
  if p_user_id is not null and not exists (select 1 from public.profiles where user_id = p_user_id and role = 'user') then
    return null;
  end if;
  insert into public.messages (user_id, kind, title, body, link, booking_id, created_by, email_status)
    values (p_user_id, p_kind, p_title, p_body, p_link, p_booking_id, auth.uid(),
            case when p_email and p_user_id is not null then 'pending' else 'none' end)
    returning id into v_id;
  return v_id;
end; $function$;

CREATE OR REPLACE FUNCTION public.trg_booking_messages()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_label text := public.booking_label(new.kind, new.destination); v_title text; v_body text;
begin
  if tg_op = 'INSERT' then
    perform public.post_message(new.user_id, 'auto', 'Recibimos tu solicitud: ' || v_label,
      case when new.kind = 'points' then 'Acreditaremos tus puntos en tu cuenta BookVipPoints (' || new.destination || ') y te avisaremos.'
           else 'Respondemos en 24 a 48 horas hábiles. Te escribiremos aquí y a tu correo.' end,
      '/cuenta/reservas', new.id, true);
    return new;
  end if;
  if new.status is distinct from old.status or new.admin_message is distinct from old.admin_message then
    if new.status = 'requested' then return new; end if;
    if new.kind = 'points' and new.status = 'confirmed' then return new; end if;
    v_title := case new.status
      when 'in_progress' then 'Estamos gestionando: ' || v_label
      when 'confirmed' then '¡Confirmada! ' || v_label
      when 'cancelled' then 'Solicitud cancelada: ' || v_label
      else 'Actualización: ' || v_label end;
    v_body := coalesce(nullif(trim(new.admin_message), ''),
      case new.status
        when 'in_progress' then 'Estamos coordinando tu solicitud. Te avisaremos apenas esté lista.'
        when 'confirmed' then 'Tu solicitud fue confirmada.'
        when 'cancelled' then 'Tu solicitud fue cancelada y la experiencia volvió a estar disponible.'
        else 'Hay novedades en tu solicitud.' end);
    perform public.post_message(new.user_id, 'auto', v_title, v_body, '/cuenta/reservas', new.id, true);
  end if;
  return new;
end; $function$;

CREATE OR REPLACE FUNCTION public.user_update_booking_dates(p_booking_id uuid, p_check_in date, p_alt_check_in date DEFAULT NULL::date)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_b public.booking_requests%rowtype; v_until timestamptz;
  v_min date := (now() at time zone 'America/Guayaquil')::date + 30;
begin
  if public.current_app_role() <> 'user' then raise exception 'Acceso no autorizado'; end if;
  select * into v_b from public.booking_requests where id = p_booking_id for update;
  if not found or v_b.user_id <> auth.uid() then raise exception 'Solicitud no encontrada'; end if;
  if v_b.kind <> 'national' then raise exception 'Solo las escapadas nacionales tienen fechas'; end if;
  if v_b.status not in ('requested', 'in_progress') then
    raise exception 'Esta reserva ya fue confirmada y no admite cambios.';
  end if;
  select valid_until into v_until from public.entitlements where id = v_b.entitlement_id;
  if p_check_in is null then raise exception 'Elige tu fecha de entrada'; end if;
  if p_check_in < v_min or (p_alt_check_in is not null and p_alt_check_in < v_min) then
    raise exception 'Las fechas deben ser con al menos 30 días de anticipación (desde el %).', to_char(v_min, 'DD/MM/YYYY');
  end if;
  if p_check_in > v_until::date or (p_alt_check_in is not null and p_alt_check_in > v_until::date) then
    raise exception 'Las fechas deben estar dentro de la vigencia de tu experiencia (hasta el %).', to_char(v_until, 'DD/MM/YYYY');
  end if;
  update public.booking_requests set check_in = p_check_in, alt_check_in = p_alt_check_in, status = 'requested',
    updated_at = now() where id = p_booking_id;
end; $function$;
