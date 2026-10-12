-- Confirmaciones del cumple 8 de Santi.
-- Pega esto en Supabase: SQL Editor > New query > Run.

create table if not exists public.confirmaciones (
  id              bigint generated always as identity primary key,
  nombre_completo text        not null check (char_length(nombre_completo) between 5 and 80),
  dispositivo_id  uuid        not null unique,   -- una sola confirmación por dispositivo
  dispositivo     text,                          -- navegador y sistema del invitado
  creado_en       timestamptz not null default now()
);

alter table public.confirmaciones enable row level security;

-- Los invitados solo pueden agregar su confirmación.
-- No pueden leer, editar ni borrar la lista: eso solo se ve desde el panel de Supabase.
drop policy if exists "invitados pueden confirmar" on public.confirmaciones;
create policy "invitados pueden confirmar"
  on public.confirmaciones
  for insert
  to anon
  with check (true);

grant insert on public.confirmaciones to anon;
