create table if not exists public.shopping_items (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) between 1 and 120),
  done boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.shopping_stores (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) between 1 and 40),
  created_at timestamptz not null default now()
);

create unique index if not exists shopping_stores_name_lower_idx
  on public.shopping_stores (lower(name));

create table if not exists public.shopping_item_stores (
  item_id uuid not null references public.shopping_items (id) on delete cascade,
  store_id uuid not null references public.shopping_stores (id) on delete cascade,
  primary key (item_id, store_id)
);

alter table public.shopping_items enable row level security;
alter table public.shopping_stores enable row level security;
alter table public.shopping_item_stores enable row level security;

drop policy if exists "Authenticated users can manage shopping items" on public.shopping_items;
create policy "Authenticated users can manage shopping items"
  on public.shopping_items for all to authenticated
  using (true) with check (true);

drop policy if exists "Authenticated users can manage shopping stores" on public.shopping_stores;
create policy "Authenticated users can manage shopping stores"
  on public.shopping_stores for all to authenticated
  using (true) with check (true);

drop policy if exists "Authenticated users can manage shopping item stores" on public.shopping_item_stores;
create policy "Authenticated users can manage shopping item stores"
  on public.shopping_item_stores for all to authenticated
  using (true) with check (true);

grant select, insert, update, delete
  on public.shopping_items, public.shopping_stores, public.shopping_item_stores
  to authenticated;

grant usage on schema public to authenticated;
