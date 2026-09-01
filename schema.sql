-- ══════════════════════════════════════════════════
--  戀途 — Supabase schema
--  貼到 Supabase Dashboard → SQL Editor → Run
-- ══════════════════════════════════════════════════

-- ---------- 資料表 ----------
create table if not exists public.couples (
  id          uuid primary key default gen_random_uuid(),
  invite_code text unique not null,
  created_at  timestamptz default now()
);

create table if not exists public.profiles (
  id           uuid primary key references auth.users on delete cascade,
  couple_id    uuid references public.couples on delete set null,
  display_name text,
  created_at   timestamptz default now()
);

create table if not exists public.checkins (
  id         text primary key,               -- 前端產生，離線也能建
  couple_id  uuid not null references public.couples on delete cascade,
  name       text not null default '',
  county     text not null default '',
  date       date,
  note       text default '',
  lat        double precision,
  lng        double precision,
  igs        text[] default '{}',
  photo_path text,
  photos     int default 0,
  created_by uuid,
  updated_at timestamptz default now()
);

create table if not exists public.wishes (
  id         text primary key,
  couple_id  uuid not null references public.couples on delete cascade,
  title      text not null,
  done       boolean default false,
  county     text default '',
  note       text default '',
  ig         text,
  created_by uuid,
  updated_at timestamptz default now()
);

create index if not exists checkins_couple_idx on public.checkins(couple_id);
create index if not exists wishes_couple_idx   on public.wishes(couple_id);

-- ---------- 我屬於哪一對 ----------
create or replace function public.my_couple()
returns uuid
language sql stable security definer set search_path = public
as $$ select couple_id from public.profiles where id = auth.uid() $$;

-- ---------- RLS ----------
alter table public.couples  enable row level security;
alter table public.profiles enable row level security;
alter table public.checkins enable row level security;
alter table public.wishes   enable row level security;

drop policy if exists couples_read on public.couples;
create policy couples_read on public.couples
  for select using (id = public.my_couple());

drop policy if exists profiles_rw on public.profiles;
create policy profiles_rw on public.profiles
  for all using (id = auth.uid() or couple_id = public.my_couple())
  with check (id = auth.uid());

drop policy if exists checkins_rw on public.checkins;
create policy checkins_rw on public.checkins
  for all using (couple_id = public.my_couple())
  with check (couple_id = public.my_couple());

drop policy if exists wishes_rw on public.wishes;
create policy wishes_rw on public.wishes
  for all using (couple_id = public.my_couple())
  with check (couple_id = public.my_couple());

-- ---------- 建立 / 加入 ----------
create or replace function public.create_couple(nick text default null)
returns table (couple_id uuid, invite_code text)
language plpgsql security definer set search_path = public
as $$
declare
  new_code text;
  new_id   uuid;
  alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';  -- 拿掉容易看錯的 I O 0 1
  i int;
begin
  if auth.uid() is null then raise exception '尚未登入'; end if;

  loop
    new_code := '';
    for i in 1..6 loop
      new_code := new_code || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
    end loop;
    exit when not exists (select 1 from public.couples c where c.invite_code = new_code);
  end loop;

  insert into public.couples (invite_code) values (new_code) returning id into new_id;

  insert into public.profiles (id, couple_id, display_name)
  values (auth.uid(), new_id, nick)
  on conflict (id) do update set couple_id = new_id,
                                 display_name = coalesce(nick, public.profiles.display_name);

  return query select new_id, new_code;
end $$;

create or replace function public.join_couple(code text, nick text default null)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare target uuid; n int;
begin
  if auth.uid() is null then raise exception '尚未登入'; end if;

  select c.id into target from public.couples c
   where upper(c.invite_code) = upper(trim(code));
  if target is null then raise exception '邀請碼不存在'; end if;

  select count(*) into n from public.profiles p where p.couple_id = target;
  if n >= 2 then raise exception '這組邀請碼已經有兩個人了'; end if;

  insert into public.profiles (id, couple_id, display_name)
  values (auth.uid(), target, nick)
  on conflict (id) do update set couple_id = target,
                                 display_name = coalesce(nick, public.profiles.display_name);
  return target;
end $$;

grant execute on function public.create_couple(text) to authenticated, anon;
grant execute on function public.join_couple(text, text) to authenticated, anon;

-- ---------- 即時同步 ----------
alter publication supabase_realtime add table public.profiles;
alter publication supabase_realtime add table public.checkins;
alter publication supabase_realtime add table public.wishes;

-- ---------- 照片儲存空間 ----------
insert into storage.buckets (id, name, public)
values ('memories', 'memories', false)
on conflict (id) do nothing;

drop policy if exists memories_rw on storage.objects;
create policy memories_rw on storage.objects
  for all
  using  (bucket_id = 'memories' and (storage.foldername(name))[1] = public.my_couple()::text)
  with check (bucket_id = 'memories' and (storage.foldername(name))[1] = public.my_couple()::text);
