-- 0001_initial_schema.sql
-- Initial V1 schema: profiles, products, images and seller status.

create extension if not exists pgcrypto;

-- 1. Product publication lifecycle
create type public.product_status as enum (
  'draft',
  'published',
  'archived'
);

-- 2. Private account-level profile
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 3. Public seller profile.
-- Only put information here that the artisan agrees to display publicly.
create table public.artisan_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  public_name text not null default 'Artisan',
  bio text not null default '',
  craft text,
  district text,
  state text,
  whatsapp_number text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 4. Verification status is separate so artisans cannot
-- change their own status through the normal client API.
create table public.artisan_verification_status (
  user_id uuid primary key
    references public.profiles(id) on delete cascade,
  status text not null default 'unverified'
    check (status in ('unverified', 'pending_review', 'verified')),
  updated_at timestamptz not null default now()
);

-- 5. Product catalogue
create table public.products (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null
    references public.profiles(id) on delete cascade,
  title text not null,
  description text not null default '',
  category text not null
    check (category in (
      'pottery',
      'textiles',
      'weaving',
      'woodwork',
      'metalwork',
      'jewelry',
      'paintings',
      'other'
    )),
  price numeric(12, 2) not null check (price >= 0),
  currency text not null default 'INR'
    check (currency = 'INR'),
  status public.product_status not null default 'draft',
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index products_owner_id_idx
  on public.products(owner_id);

create index products_discovery_idx
  on public.products(category, published_at desc)
  where status = 'published';

-- 6. Image metadata.
-- The actual image files live in Supabase Storage.
create table public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null
    references public.products(id) on delete cascade,
  storage_path text not null unique,
  alt_text text not null default '',
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create index product_images_product_id_idx
  on public.product_images(product_id, sort_order);

-- 7. Automatically maintain updated_at timestamps
create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger artisan_profiles_set_updated_at
before update on public.artisan_profiles
for each row execute function public.set_updated_at();

create trigger verification_set_updated_at
before update on public.artisan_verification_status
for each row execute function public.set_updated_at();

create trigger products_set_updated_at
before update on public.products
for each row execute function public.set_updated_at();

-- 8. Set published_at automatically when a product is published
create function public.set_product_publication_time()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.status = 'published' then
    if tg_op = 'INSERT'
       or old.status is distinct from 'published' then
      new.published_at = now();
    end if;
  else
    new.published_at = null;
  end if;

  return new;
end;
$$;

create trigger products_set_publication_time
before insert or update of status on public.products
for each row execute function public.set_product_publication_time();

-- 9. Automatically create associated records for a new auth user
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  user_name text;
begin
  user_name := coalesce(
    nullif(new.raw_user_meta_data ->> 'display_name', ''),
    'Artisan'
  );

  insert into public.profiles (id, display_name)
  values (new.id, user_name);

  insert into public.artisan_profiles (user_id, public_name)
  values (new.id, user_name);

  insert into public.artisan_verification_status (user_id)
  values (new.id);

  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- 10. Enable row-level security on every application table
alter table public.profiles enable row level security;
alter table public.artisan_profiles enable row level security;
alter table public.artisan_verification_status enable row level security;
alter table public.products enable row level security;
alter table public.product_images enable row level security;

-- Private profiles: each signed-in user can read/update only their own.
create policy "profiles_select_own"
on public.profiles for select to authenticated
using ((select auth.uid()) = id);

create policy "profiles_update_own"
on public.profiles for update to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

-- Public seller information is readable by customers.
create policy "artisan_profiles_public_read"
on public.artisan_profiles for select to anon, authenticated
using (true);

create policy "artisan_profiles_update_own"
on public.artisan_profiles for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

-- Verification is publicly visible but has no client write policy.
-- Status changes must be made through a trusted administrative process.
create policy "verification_status_public_read"
on public.artisan_verification_status for select to anon, authenticated
using (true);

-- Customers can read published products; owners can also read their own drafts.
create policy "products_read_published_or_owned"
on public.products for select to anon, authenticated
using (
  status = 'published'
  or owner_id = (select auth.uid())
);

create policy "products_insert_own"
on public.products for insert to authenticated
with check (owner_id = (select auth.uid()));

create policy "products_update_own"
on public.products for update to authenticated
using (owner_id = (select auth.uid()))
with check (owner_id = (select auth.uid()));

create policy "products_delete_own"
on public.products for delete to authenticated
using (owner_id = (select auth.uid()));

-- Image metadata follows the visibility/ownership of its product.
create policy "product_images_read_visible_product"
on public.product_images for select to anon, authenticated
using (
  exists (
    select 1
    from public.products p
    where p.id = product_id
      and (
        p.status = 'published'
        or p.owner_id = (select auth.uid())
      )
  )
);

create policy "product_images_insert_own_product"
on public.product_images for insert to authenticated
with check (
  exists (
    select 1
    from public.products p
    where p.id = product_id
      and p.owner_id = (select auth.uid())
  )
);

create policy "product_images_update_own_product"
on public.product_images for update to authenticated
using (
  exists (
    select 1
    from public.products p
    where p.id = product_id
      and p.owner_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1
    from public.products p
    where p.id = product_id
      and p.owner_id = (select auth.uid())
  )
);

create policy "product_images_delete_own_product"
on public.product_images for delete to authenticated
using (
  exists (
    select 1
    from public.products p
    where p.id = product_id
      and p.owner_id = (select auth.uid())
  )
);
