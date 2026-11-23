-- =====================================================================
-- Hidden Tunisia - database schema
-- Run this whole file once in: Supabase Dashboard > SQL Editor > New query
-- Users live in Supabase's built-in auth.users table; we add a public
-- "profiles" table linked to it.
-- =====================================================================

-- ---------- Tables ----------

create table public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  username    text not null check (char_length(username) between 1 and 40),
  avatar_url  text,
  created_at  timestamptz not null default now()
);

create table public.places (
  id           uuid primary key default gen_random_uuid(),
  name         text not null check (char_length(name) between 3 and 120),
  city         text not null,
  description  text not null,
  category     text not null check (category in
                 ('cafes','nature','beaches','historical','restaurants','viewpoints')),
  image_url    text,
  base_rating  numeric(2,1) not null default 4.0 check (base_rating between 1 and 5),
  latitude     double precision not null check (latitude between -90 and 90),
  longitude    double precision not null check (longitude between -180 and 180),
  address      text not null default '',
  -- Filled when an OpenStreetMap result is saved (avoids duplicates).
  source_id    text unique,
  -- NULL for the seed data, otherwise the user who created the place.
  created_by   uuid references public.profiles (id) on delete set null,
  created_at   timestamptz not null default now()
);

-- A review always carries a 1-5 star rating, so reviews + ratings are one
-- table. One review per user per place (the user can edit it).
create table public.reviews (
  id          uuid primary key default gen_random_uuid(),
  place_id    uuid not null references public.places (id) on delete cascade,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  rating      smallint not null check (rating between 1 and 5),
  comment     text not null check (char_length(comment) >= 5),
  created_at  timestamptz not null default now(),
  unique (place_id, user_id)
);

create table public.favorites (
  user_id     uuid not null references public.profiles (id) on delete cascade,
  place_id    uuid not null references public.places (id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (user_id, place_id)
);

create index reviews_place_idx   on public.reviews (place_id);
create index favorites_user_idx  on public.favorites (user_id);

-- ---------- Automatic profile creation ----------
-- When someone registers, create their profile row. The username typed in
-- the app arrives in raw_user_meta_data.

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
                  split_part(new.email, '@', 1)), 40)
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Profiles for accounts that already existed before this script ran.
insert into public.profiles (id, username)
select id, left(split_part(email, '@', 1), 40) from auth.users
on conflict (id) do nothing;

-- ---------- Row Level Security ----------
-- RLS is enforced by the database itself, so even someone who copies the
-- anon key from the app can only do what these policies allow.

alter table public.profiles  enable row level security;
alter table public.places    enable row level security;
alter table public.reviews   enable row level security;
alter table public.favorites enable row level security;

-- profiles: any signed-in user can read (review authors), edit only their own
create policy "profiles are readable by signed-in users"
  on public.profiles for select to authenticated using (true);
create policy "users update their own profile"
  on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- places: public read, signed-in users create, owners edit/delete
create policy "places are readable by everyone"
  on public.places for select using (true);
create policy "signed-in users create places"
  on public.places for insert to authenticated
  with check (created_by = auth.uid());
create policy "owners update their places"
  on public.places for update to authenticated
  using (created_by = auth.uid()) with check (created_by = auth.uid());
create policy "owners delete their places"
  on public.places for delete to authenticated
  using (created_by = auth.uid());

-- reviews: public read, users write only their own
create policy "reviews are readable by everyone"
  on public.reviews for select using (true);
create policy "users create their own reviews"
  on public.reviews for insert to authenticated
  with check (user_id = auth.uid());
create policy "users update their own reviews"
  on public.reviews for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "users delete their own reviews"
  on public.reviews for delete to authenticated
  using (user_id = auth.uid());

-- favorites: completely private to the owner
create policy "users read their own favorites"
  on public.favorites for select to authenticated using (user_id = auth.uid());
create policy "users add their own favorites"
  on public.favorites for insert to authenticated with check (user_id = auth.uid());
create policy "users remove their own favorites"
  on public.favorites for delete to authenticated using (user_id = auth.uid());

-- ---------- Storage (destination images) ----------
-- Public bucket: anyone can view images, but only signed-in users can upload,
-- and only inside a folder named after their own user id.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('place-images', 'place-images', true, 5242880,
        array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy "place images are public"
  on storage.objects for select using (bucket_id = 'place-images');
create policy "users upload to their own folder"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'place-images'
              and (storage.foldername(name))[1] = auth.uid()::text);
create policy "users update their own images"
  on storage.objects for update to authenticated
  using (bucket_id = 'place-images'
         and (storage.foldername(name))[1] = auth.uid()::text);
create policy "users delete their own images"
  on storage.objects for delete to authenticated
  using (bucket_id = 'place-images'
         and (storage.foldername(name))[1] = auth.uid()::text);

-- ---------- Realtime ----------
-- Lets the app refresh automatically when places or reviews change.
alter publication supabase_realtime add table public.places, public.reviews;
