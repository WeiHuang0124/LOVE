-- 已經跑過舊版 schema.sql 的話，跑這一段補上缺的東西。
-- 全新專案直接跑 schema.sql 即可，不需要這支。

-- 想去清單的欄位
alter table public.wishes add column if not exists county text default '';
alter table public.wishes add column if not exists note   text default '';
alter table public.wishes add column if not exists ig     text;

-- 讓「誰加入了空間 / 改了暱稱」也能即時同步
alter publication supabase_realtime add table public.profiles;
