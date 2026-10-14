-- BIT invitation acceptance: run this once in Supabase SQL Editor after the base schema.
create or replace function public.accept_partnership_invite(raw_token text)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_invite public.partnership_invites%rowtype;
  v_email text;
begin
  if auth.uid() is null then
    raise exception 'Sign in to accept this BIT invitation.';
  end if;
  v_email := lower(coalesce(auth.jwt() ->> 'email', ''));
  if raw_token is null or length(raw_token) < 32 then
    raise exception 'This invitation link is invalid.';
  end if;

  select * into v_invite
  from public.partnership_invites
  where token_hash = encode(digest(raw_token, 'sha256'), 'hex')
  for update;

  if not found then
    raise exception 'This invitation link is invalid or has already been used.';
  end if;
  if v_invite.expires_at <= now() then
    raise exception 'This invitation has expired. Ask the person who invited you to send a new one.';
  end if;
  if v_invite.accepted_at is not null then
    raise exception 'This invitation has already been accepted.';
  end if;
  if v_invite.inviter_id = auth.uid() then
    raise exception 'You cannot accept your own invitation.';
  end if;
  if v_invite.invitee_email is not null and lower(v_invite.invitee_email) <> v_email then
    raise exception 'Sign in with the email address this invitation was sent to.';
  end if;

  update public.partnerships
  set member_two = auth.uid(), status = 'active', accepted_at = now()
  where id = v_invite.partnership_id
    and member_one = v_invite.inviter_id
    and member_two is null
    and status = 'pending';

  if not found then
    raise exception 'This shared space is no longer available.';
  end if;

  update public.partnership_invites
  set accepted_by = auth.uid(), accepted_at = now()
  where id = v_invite.id;

  return v_invite.partnership_id;
end;
$$;

revoke all on function public.accept_partnership_invite(text) from public, anon;
grant execute on function public.accept_partnership_invite(text) to authenticated;
