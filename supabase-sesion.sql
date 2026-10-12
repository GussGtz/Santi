-- Sesiones de admin.html: la sesión dura hasta que se pulsa "Salir".
-- El navegador guarda un código de sesión al azar, nunca la contraseña.

create table if not exists public.santi_sesion (
  token_hash text primary key,
  creado_en  timestamptz not null default now()
);

-- Sin políticas: nadie puede leer ni escribir esta tabla desde la página.
alter table public.santi_sesion enable row level security;

-- Entra con la contraseña y devuelve un código de sesión nuevo.
create or replace function public.admin_entrar(clave text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  token text;
begin
  if not exists (
    select 1 from public.santi_admin a
    where a.clave_hash = extensions.crypt(coalesce(clave, ''), a.clave_hash)
  ) then
    perform pg_sleep(1);
    raise exception 'Contraseña incorrecta' using errcode = '28P01';
  end if;
  token := encode(extensions.gen_random_bytes(32), 'hex');
  insert into public.santi_sesion (token_hash)
  values (encode(extensions.digest(token, 'sha256'), 'hex'));
  return token;
end;
$$;

-- Devuelve la lista de confirmados si el código de sesión sigue vigente.
create or replace function public.admin_lista(token text)
returns table (id bigint, nombre_completo text, dispositivo text, created_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.santi_sesion x
    where x.token_hash = encode(extensions.digest(coalesce(token, ''), 'sha256'), 'hex')
  ) then
    raise exception 'Sesión no válida' using errcode = '28000';
  end if;
  return query
    select s.id, s.nombre_completo, s.dispositivo, s.created_at
    from public."Santi" s
    order by s.created_at desc;
end;
$$;

-- Cierra la sesión: el código deja de servir.
create or replace function public.admin_salir(token text)
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.santi_sesion
  where token_hash = encode(extensions.digest(coalesce(token, ''), 'sha256'), 'hex');
$$;

grant execute on function public.admin_entrar(text) to anon;
grant execute on function public.admin_lista(text)  to anon;
grant execute on function public.admin_salir(text)  to anon;

notify pgrst, 'reload schema';
