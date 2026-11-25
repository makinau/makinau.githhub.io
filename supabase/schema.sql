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

-- OurHouse household data, garage inventory, and private PDF storage.

create table if not exists public.household_members (
  user_id uuid primary key references auth.users (id) on delete cascade
);

alter table public.household_members enable row level security;
grant select on public.household_members to authenticated;

drop policy if exists "Members can view their own membership" on public.household_members;
create policy "Members can view their own membership"
  on public.household_members
  for select
  to authenticated
  using (user_id = auth.uid());

create table if not exists public.household_data (
  id text primary key check (id = 'home'),
  items jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.household_data enable row level security;
grant select, insert, update on public.household_data to authenticated;

drop policy if exists "Household members can read data" on public.household_data;
create policy "Household members can read data"
  on public.household_data
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.household_members
      where user_id = auth.uid()
    )
  );

drop policy if exists "Household members can create data" on public.household_data;
create policy "Household members can create data"
  on public.household_data
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.household_members
      where user_id = auth.uid()
    )
  );

drop policy if exists "Household members can update data" on public.household_data;
create policy "Household members can update data"
  on public.household_data
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.household_members
      where user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.household_members
      where user_id = auth.uid()
    )
  );

create table if not exists public.clothing_items (
  id text primary key,
  description text not null check (length(trim(description)) > 0),
  owner text check (owner in ('Ernest', 'Queralt', 'Dani', 'Estel'))
);

alter table public.clothing_items add column if not exists description text;

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'clothing_items' and column_name = 'name'
  ) and exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'clothing_items' and column_name = 'detail'
  ) then
    execute $migration$
      update public.clothing_items
      set description = concat_ws(E'\n\n', nullif(trim(name), ''), nullif(trim(detail), ''))
      where description is null or length(trim(description)) = 0
    $migration$;
  elsif exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'clothing_items' and column_name = 'name'
  ) then
    execute $migration$
      update public.clothing_items
      set description = nullif(trim(name), '')
      where description is null or length(trim(description)) = 0
    $migration$;
  end if;
end $$;

update public.clothing_items
set description = 'Sense descripció'
where description is null or length(trim(description)) = 0;

alter table public.clothing_items alter column description set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'clothing_items_description_check'
      and conrelid = 'public.clothing_items'::regclass
  ) then
    alter table public.clothing_items
      add constraint clothing_items_description_check check (length(trim(description)) > 0);
  end if;
end $$;

alter table public.clothing_items
  drop column if exists name,
  drop column if exists detail,
  drop column if exists created_at;

alter table public.clothing_items enable row level security;
grant select, insert, update, delete on public.clothing_items to authenticated;

drop policy if exists "Household members can read clothing" on public.clothing_items;
create policy "Household members can read clothing"
  on public.clothing_items
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.household_members
      where user_id = auth.uid()
    )
  );

drop policy if exists "Household members can add clothing" on public.clothing_items;
create policy "Household members can add clothing"
  on public.clothing_items
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.household_members
      where user_id = auth.uid()
    )
  );

drop policy if exists "Household members can update clothing" on public.clothing_items;
create policy "Household members can update clothing"
  on public.clothing_items
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.household_members
      where user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.household_members
      where user_id = auth.uid()
    )
  );

drop policy if exists "Household members can delete clothing" on public.clothing_items;
create policy "Household members can delete clothing"
  on public.clothing_items
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.household_members
      where user_id = auth.uid()
    )
  );

create table if not exists public.garage_tools (
  id text primary key,
  description text not null check (length(trim(description)) > 0)
);

alter table public.garage_tools enable row level security;
grant select, insert, update, delete on public.garage_tools to authenticated;

drop policy if exists "Household members can read tools" on public.garage_tools;
create policy "Household members can read tools"
  on public.garage_tools
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.household_members
      where user_id = auth.uid()
    )
  );

drop policy if exists "Household members can add tools" on public.garage_tools;
create policy "Household members can add tools"
  on public.garage_tools
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.household_members
      where user_id = auth.uid()
    )
  );

drop policy if exists "Household members can update tools" on public.garage_tools;
create policy "Household members can update tools"
  on public.garage_tools
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.household_members
      where user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.household_members
      where user_id = auth.uid()
    )
  );

drop policy if exists "Household members can delete tools" on public.garage_tools;
create policy "Household members can delete tools"
  on public.garage_tools
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.household_members
      where user_id = auth.uid()
    )
  );

create table if not exists public.garage_products (
  id text primary key,
  description text not null check (length(trim(description)) > 0),
  expiry date
);

alter table public.garage_products enable row level security;
grant select, insert, update, delete on public.garage_products to authenticated;

drop policy if exists "Household members can read products" on public.garage_products;
create policy "Household members can read products"
  on public.garage_products
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.household_members
      where user_id = auth.uid()
    )
  );

drop policy if exists "Household members can add products" on public.garage_products;
create policy "Household members can add products"
  on public.garage_products
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.household_members
      where user_id = auth.uid()
    )
  );

drop policy if exists "Household members can update products" on public.garage_products;
create policy "Household members can update products"
  on public.garage_products
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.household_members
      where user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.household_members
      where user_id = auth.uid()
    )
  );

drop policy if exists "Household members can delete products" on public.garage_products;
create policy "Household members can delete products"
  on public.garage_products
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.household_members
      where user_id = auth.uid()
    )
  );

insert into public.clothing_items (id, description, owner)
select
  garage_item->>'id',
  coalesce(
    nullif(concat_ws(E'\n\n', nullif(trim(garage_item->>'name'), ''), nullif(trim(garage_item->>'detail'), '')), ''),
    'Sense descripció'
  ),
  case
    when garage_item->>'owner' in ('Ernest', 'Queralt', 'Dani', 'Estel') then garage_item->>'owner'
    else null
  end
from public.household_data as household
cross join lateral jsonb_array_elements(coalesce(household.items->'garatge', '[]'::jsonb)) as garage(garage_item)
where garage_item->>'garageType' = 'roba'
  and garage_item->>'id' is not null
  and garage_item->>'name' is not null
on conflict (id) do nothing;

insert into public.garage_tools (id, description)
select
  garage_item->>'id',
  coalesce(
    nullif(concat_ws(E'\n\n', nullif(trim(garage_item->>'name'), ''), nullif(trim(garage_item->>'detail'), '')), ''),
    'Sense descripció'
  )
from public.household_data as household
cross join lateral jsonb_array_elements(coalesce(household.items->'garatge', '[]'::jsonb)) as garage(garage_item)
where garage_item->>'garageType' = 'eines'
  and garage_item->>'id' is not null
  and garage_item->>'name' is not null
on conflict (id) do nothing;

insert into public.garage_products (id, description, expiry)
select
  garage_item->>'id',
  coalesce(
    nullif(concat_ws(E'\n\n', nullif(trim(garage_item->>'name'), ''), nullif(trim(garage_item->>'detail'), '')), ''),
    'Sense descripció'
  ),
  case
    when nullif(garage_item->>'expiry', '') ~ '^\d{4}-\d{2}-\d{2}$' then (garage_item->>'expiry')::date
    else null
  end
from public.household_data as household
cross join lateral jsonb_array_elements(coalesce(household.items->'garatge', '[]'::jsonb)) as garage(garage_item)
where garage_item->>'garageType' = 'drogueria'
  and garage_item->>'id' is not null
  and garage_item->>'name' is not null
on conflict (id) do nothing;

update public.household_data as household
set items = jsonb_set(
  household.items,
  '{garatge}',
  coalesce((
    select jsonb_agg(garage_item order by ordinal)
    from jsonb_array_elements(coalesce(household.items->'garatge', '[]'::jsonb)) with ordinality as garage(garage_item, ordinal)
    where (
      garage_item->>'garageType' is distinct from 'roba'
      and garage_item->>'garageType' is distinct from 'eines'
      and garage_item->>'garageType' is distinct from 'drogueria'
    )
      or garage_item->>'id' is null
      or garage_item->>'name' is null
  ), '[]'::jsonb),
  true
),
updated_at = now()
where exists (
  select 1
  from jsonb_array_elements(coalesce(household.items->'garatge', '[]'::jsonb)) as garage(garage_item)
  where (
      garage_item->>'garageType' = 'roba'
      or garage_item->>'garageType' = 'eines'
      or garage_item->>'garageType' = 'drogueria'
    )
    and garage_item->>'id' is not null
    and garage_item->>'name' is not null
);

insert into storage.buckets (id, name, public)
values ('ourhouse-pdfs', 'ourhouse-pdfs', false)
on conflict (id) do update set public = false;

drop policy if exists "Household members can read PDFs" on storage.objects;
create policy "Household members can read PDFs"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'ourhouse-pdfs'
    and exists (
      select 1
      from public.household_members
      where user_id = auth.uid()
    )
  );

drop policy if exists "Household members can upload PDFs" on storage.objects;
create policy "Household members can upload PDFs"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'ourhouse-pdfs'
    and exists (
      select 1
      from public.household_members
      where user_id = auth.uid()
    )
  );

drop policy if exists "Household members can update PDFs" on storage.objects;
create policy "Household members can update PDFs"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'ourhouse-pdfs'
    and exists (
      select 1
      from public.household_members
      where user_id = auth.uid()
    )
  )
  with check (
    bucket_id = 'ourhouse-pdfs'
    and exists (
      select 1
      from public.household_members
      where user_id = auth.uid()
    )
  );

drop policy if exists "Household members can delete PDFs" on storage.objects;
create policy "Household members can delete PDFs"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'ourhouse-pdfs'
    and exists (
      select 1
      from public.household_members
      where user_id = auth.uid()
    )
  );
