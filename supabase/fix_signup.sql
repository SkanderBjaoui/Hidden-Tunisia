-- =====================================================================
-- Hidden Tunisia - signup fix (safe to run several times)
-- Run in: Supabase Dashboard > SQL Editor > New query > Run
--
-- 1. Rebuilds the "create profile on signup" trigger so a problem there can
--    never block registration.
-- 2. Lets a signed-in user create their OWN profile row (used by the app as
--    a safety net).
-- 3. Creates profiles for any account that already exists without one.
-- =====================================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, username)
  values (
    new.id,
    left(coalesce(nullif(trim(new.raw_user_meta_data ->> 'username'), ''),
                  nullif(split_part(new.email, '@', 1), ''),
                  'explorer'), 40)
  )
  on conflict (id) do nothing;
  return new;
exception when others then
  -- Never block the signup because of the profile; the app creates it later.
  raise warning 'handle_new_user failed: %', sqlerrm;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

drop policy if exists "users insert their own profile" on public.profiles;
create policy "users insert their own profile"
  on public.profiles for insert to authenticated
  with check (id = auth.uid());

insert into public.profiles (id, username)
select id,
       left(coalesce(nullif(trim(raw_user_meta_data ->> 'username'), ''),
                     nullif(split_part(email, '@', 1), ''),
                     'explorer'), 40)
from auth.users
on conflict (id) do nothing;
