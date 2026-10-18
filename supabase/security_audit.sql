-- B. I. T. security audit: READ-ONLY. Run in Supabase SQL Editor.
-- Review results before inviting users. This does not prove security on its own.
select c.relname as table_name, c.relrowsecurity as rls_enabled,
       c.relforcerowsecurity as rls_forced
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relkind='r'
and c.relname in ('profiles','partnerships','partnership_invites','messages','private_reflections','relationship_checkins','agreements')
order by c.relname;

select tablename, policyname, roles, cmd, qual, with_check
from pg_policies where schemaname='public'
and tablename in ('profiles','partnerships','partnership_invites','messages','private_reflections','relationship_checkins','agreements')
order by tablename,policyname;

-- Watch for overly broad access: all/anon/public policies, or missing owner checks.
-- Inspect function privileges, especially SECURITY DEFINER functions.
select n.nspname as schema_name,p.proname as function_name,
p.prosecdef as security_definer,
pg_get_function_identity_arguments(p.oid) as args,
p.proacl as access_list
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' order by p.proname;
