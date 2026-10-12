-- Confirmaciones del cumple 8 de Santi, en la tabla "Santi".
-- Pega esto en Supabase: SQL Editor > New query > Run.
-- Sirve tanto si la tabla ya existe como si no: solo agrega lo que falte.

create table if not exists public."Santi" (
  id         bigint generated always as identity primary key,
  created_at timestamptz not null default now()
);

alter table public."Santi" add column if not exists nombre_completo text;
alter table public."Santi" add column if not exists dispositivo_id  uuid;
alter table public."Santi" add column if not exists dispositivo     text;

-- Una sola confirmación por dispositivo.
create unique index if not exists santi_dispositivo_unico on public."Santi" (dispositivo_id);

alter table public."Santi" enable row level security;

-- Los invitados solo pueden agregar su confirmación.
-- No pueden leer, editar ni borrar la lista: eso solo se ve desde el panel de Supabase.
drop policy if exists "invitados pueden confirmar" on public."Santi";
create policy "invitados pueden confirmar"
  on public."Santi"
  for insert
  to anon
  with check (
    char_length(nombre_completo) between 5 and 80
    and dispositivo_id is not null
  );

grant insert on public."Santi" to anon;

-- Avisa a la API que la tabla cambió.
notify pgrst, 'reload schema';
