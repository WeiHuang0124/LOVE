-- 已經跑過舊版 schema.sql 的話，跑這一段補上缺的東西。
-- 全新專案直接跑 schema.sql 即可。

-- ① 想去清單的欄位
alter table public.wishes add column if not exists county text default '';
alter table public.wishes add column if not exists note   text default '';
alter table public.wishes add column if not exists ig     text;

-- ② 讓「誰加入了空間 / 改了暱稱」也能即時同步
alter publication supabase_realtime add table public.profiles;

-- ③ 上限從 2 人放寬到 4 個裝置
--    原本的限制讓「你的手機 + 你的電腦」就把名額用光，女友加不進來。
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

  select count(*) into n from public.profiles p
   where p.couple_id = target and p.id <> auth.uid();
  if n >= 4 then raise exception '這個空間已經有 4 台裝置了，先到設定裡移除一個'; end if;

  insert into public.profiles (id, couple_id, display_name)
  values (auth.uid(), target, nick)
  on conflict (id) do update set couple_id = target,
                                 display_name = coalesce(nick, public.profiles.display_name);
  return target;
end $$;

-- ④ 移除成員／裝置
create or replace function public.remove_member(target uuid)
returns void
language plpgsql security definer set search_path = public
as $$
declare mine uuid;
begin
  if auth.uid() is null then raise exception '尚未登入'; end if;
  mine := public.my_couple();
  if mine is null then raise exception '你還沒有空間'; end if;
  if (select p.couple_id from public.profiles p where p.id = target) is distinct from mine
    then raise exception '這個人不在你的空間裡'; end if;
  update public.profiles set couple_id = null where id = target;
end $$;

grant execute on function public.join_couple(text, text) to authenticated, anon;
grant execute on function public.remove_member(uuid)     to authenticated, anon;
