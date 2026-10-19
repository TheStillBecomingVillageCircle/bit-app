-- Run once in the Supabase SQL Editor for the B. I. T. project.
-- Existing profile access policies must permit each user to update their own profile
-- and connected partners to read signature_color.
alter table public.profiles add column if not exists signature_color text;
alter table public.profiles drop constraint if exists profiles_signature_color_format;
alter table public.profiles add constraint profiles_signature_color_format check (signature_color is null or signature_color ~ '^#[0-9A-Fa-f]{6}$');
-- Inspect existing RLS policies before making changes. Do not disable RLS.
-- Ensure authenticated users may read signature_color of an active connected partner.
