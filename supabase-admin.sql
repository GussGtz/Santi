-- Acceso a la lista de confirmados (admin.html) con una sola contraseña.
-- La contraseña se crea desde admin.html la primera vez y aquí solo se guarda cifrada.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.santi_admin (
  id         int  primary key default 1 check (id = 1),
  clave_hash text not null
);

-- Sin políticas: nadie puede leer ni escribir esta tabla desde la página.
alter table public.santi_admin enable row level security;

-- ¿Ya se creó la contraseña?
create or replace function public.admin_tiene_clave()
returns boolean
language sql
security definer
set search_path = ''
as $$
  select exists (select 1 from public.santi_admin);
$$;

-- Crea la contraseña. Solo funciona si todavía no existe una.
create or replace function public.admin_crear_clave(clave text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  if clave is null or char_length(clave) < 8 then
    raise exception 'La contraseña debe tener al menos 8 caracteres';
  end if;
  insert into public.santi_admin (id, clave_hash)
  values (1, extensions.crypt(clave, extensions.gen_salt('bf', 10)))
  on conflict (id) do nothing;
  return found;
end;
$$;

-- Devuelve la lista de confirmados solo con la contraseña correcta.
create or replace function public.admin_confirmados(clave text)
returns table (id bigint, nombre_completo text, dispositivo text, created_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.santi_admin a
    where a.clave_hash = extensions.crypt(coalesce(clave, ''), a.clave_hash)
  ) then
    perform pg_sleep(1);
    raise exception 'Contraseña incorrecta' using errcode = '28P01';
  end if;
  return query
    select s.id, s.nombre_completo, s.dispositivo, s.created_at
    from public."Santi" s
    order by s.created_at desc;
end;
$$;

grant execute on function public.admin_tiene_clave()        to anon;
grant execute on function public.admin_crear_clave(text)    to anon;
grant execute on function public.admin_confirmados(text)    to anon;

notify pgrst, 'reload schema';
