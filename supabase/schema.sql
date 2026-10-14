-- BIT: Becoming Intentional Together
-- Run this in Supabase SQL Editor for the first real backend.
-- Private reflections are user-owned and are never shared with a partner by default.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.partnerships (
  id uuid primary key default gen_random_uuid(),
  member_one uuid not null references auth.users(id) on delete cascade,
  member_two uuid references auth.users(id) on delete set null,
  status text not null default 'pending' check (status in ('pending','active','ended')),
  created_at timestamptz not null default now(),
  accepted_at timestamptz,
  check (member_two is null or member_two <> member_one)
);

create table if not exists public.partnership_invites (
  id uuid primary key default gen_random_uuid(),
  partnership_id uuid not null references public.partnerships(id) on delete cascade,
  inviter_id uuid not null references auth.users(id) on delete cascade,
  invitee_email text,
  token_hash text not null unique,
  expires_at timestamptz not null default (now() + interval '7 days'),
  accepted_by uuid references auth.users(id) on delete set null,
  accepted_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  partnership_id uuid not null references public.partnerships(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (length(trim(body)) between 1 and 10000),
  created_at timestamptz not null default now(),
  edited_at timestamptz
);

create table if not exists public.private_reflections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default '',
  body text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.relationship_checkins (
  id uuid primary key default gen_random_uuid(),
  partnership_id uuid not null references public.partnerships(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  topic text not null,
  scheduled_for timestamptz,
  status text not null default 'proposed' check (status in ('proposed','agreed','completed','cancelled')),
  created_at timestamptz not null default now()
);

create table if not exists public.agreements (
  id uuid primary key default gen_random_uuid(),
  partnership_id uuid not null references public.partnerships(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  title text not null,
  details text not null default '',
  status text not null default 'proposed' check (status in ('proposed','active','revisited','retired')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.is_partnership_member(target_partnership uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.partnerships p
    where p.id = target_partnership
      and auth.uid() in (p.member_one, p.member_two)
      and p.status = 'active'
  );
$$;

alter table public.profiles enable row level security;
alter table public.partnerships enable row level security;
alter table public.partnership_invites enable row level security;
alter table public.messages enable row level security;
alter table public.private_reflections enable row level security;
alter table public.relationship_checkins enable row level security;
alter table public.agreements enable row level security;

drop policy if exists "Users read own profile" on public.profiles;
create policy "Users read own profile" on public.profiles for select to authenticated using (id = auth.uid());
drop policy if exists "Users create own profile" on public.profiles;
create policy "Users create own profile" on public.profiles for insert to authenticated with check (id = auth.uid());
drop policy if exists "Users update own profile" on public.profiles;
create policy "Users update own profile" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "Members read their partnerships" on public.partnerships;
create policy "Members read their partnerships" on public.partnerships for select to authenticated using (auth.uid() in (member_one, member_two));
drop policy if exists "Users create partnership invitations" on public.partnerships;
create policy "Users create partnership invitations" on public.partnerships for insert to authenticated with check (member_one = auth.uid() and member_two is null and status = 'pending');
drop policy if exists "Members update partnerships" on public.partnerships;
create policy "Members update partnerships" on public.partnerships for update to authenticated using (auth.uid() in (member_one, member_two)) with check (auth.uid() in (member_one, member_two));

drop policy if exists "Inviter sees own invites" on public.partnership_invites;
create policy "Inviter sees own invites" on public.partnership_invites for select to authenticated using (inviter_id = auth.uid());
drop policy if exists "Inviter creates invite" on public.partnership_invites;
create policy "Inviter creates invite" on public.partnership_invites for insert to authenticated with check (inviter_id = auth.uid() and exists (select 1 from public.partnerships p where p.id = partnership_id and p.member_one = auth.uid() and p.status = 'pending'));
drop policy if exists "Inviter cancels unaccepted invite" on public.partnership_invites;
create policy "Inviter cancels unaccepted invite" on public.partnership_invites for delete to authenticated using (inviter_id = auth.uid() and accepted_at is null);

drop policy if exists "Active partners read messages" on public.messages;
create policy "Active partners read messages" on public.messages for select to authenticated using (public.is_partnership_member(partnership_id));
drop policy if exists "Active partners send messages as self" on public.messages;
create policy "Active partners send messages as self" on public.messages for insert to authenticated with check (sender_id = auth.uid() and public.is_partnership_member(partnership_id));
drop policy if exists "Senders edit own messages" on public.messages;
create policy "Senders edit own messages" on public.messages for update to authenticated using (sender_id = auth.uid() and public.is_partnership_member(partnership_id)) with check (sender_id = auth.uid() and public.is_partnership_member(partnership_id));
drop policy if exists "Senders delete own messages" on public.messages;
create policy "Senders delete own messages" on public.messages for delete to authenticated using (sender_id = auth.uid() and public.is_partnership_member(partnership_id));

drop policy if exists "Reflections are private to owner" on public.private_reflections;
create policy "Reflections are private to owner" on public.private_reflections for select to authenticated using (user_id = auth.uid());
drop policy if exists "Users create private reflections" on public.private_reflections;
create policy "Users create private reflections" on public.private_reflections for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "Users update private reflections" on public.private_reflections;
create policy "Users update private reflections" on public.private_reflections for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "Users delete private reflections" on public.private_reflections;
create policy "Users delete private reflections" on public.private_reflections for delete to authenticated using (user_id = auth.uid());

drop policy if exists "Partners read checkins" on public.relationship_checkins;
create policy "Partners read checkins" on public.relationship_checkins for select to authenticated using (public.is_partnership_member(partnership_id));
drop policy if exists "Partners propose checkins" on public.relationship_checkins;
create policy "Partners propose checkins" on public.relationship_checkins for insert to authenticated with check (created_by = auth.uid() and public.is_partnership_member(partnership_id));
drop policy if exists "Partners update checkins" on public.relationship_checkins;
create policy "Partners update checkins" on public.relationship_checkins for update to authenticated using (public.is_partnership_member(partnership_id)) with check (public.is_partnership_member(partnership_id));

drop policy if exists "Partners read agreements" on public.agreements;
create policy "Partners read agreements" on public.agreements for select to authenticated using (public.is_partnership_member(partnership_id));
drop policy if exists "Partners propose agreements" on public.agreements;
create policy "Partners propose agreements" on public.agreements for insert to authenticated with check (created_by = auth.uid() and public.is_partnership_member(partnership_id));
drop policy if exists "Partners update agreements" on public.agreements;
create policy "Partners update agreements" on public.agreements for update to authenticated using (public.is_partnership_member(partnership_id)) with check (public.is_partnership_member(partnership_id));

-- IMPORTANT: Invite acceptance must be implemented through a trusted server-side
-- function/Edge Function that validates the token and ensures both partners consent.
-- Do not expose the service-role key in browser code.
