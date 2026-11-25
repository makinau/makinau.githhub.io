# OurHouse

OurHouse stores household data in Supabase so authorized family members can use
the same data from different browsers and devices. The Supabase Auth session is
kept in `localStorage` and shared with the other projects on this site;
household records and PDFs are stored in Supabase.

## Supabase setup

1. Create a Supabase project.
2. In the Supabase SQL Editor, run [`supabase/schema.sql`](../supabase/schema.sql).
3. In **Authentication → Users**, create one account for each family member.
   Keep public sign-ups disabled so only accounts you create can sign in.
4. Add those accounts as household members by running this query with their
   email addresses:

   ```sql
   insert into public.household_members (user_id)
   select id from auth.users
   where email in ('person@example.com', 'family@example.com')
   on conflict do nothing;
   ```

5. In [`index.html`](./index.html), set `url` and `anonKey` in
   `window.OURHOUSE_SUPABASE_CONFIG` to the project's **Project URL** and
   **publishable/anon key**. These browser values are public; never put a
   service-role key in the website.
6. Configure the Supabase Auth **Site URL** and allowed redirect URLs for the
   website's deployed address, then publish the static site.

The garage has a separate clothing list stored in `public.clothing_items`.
Each item has a description and an owner (Ernest, Queralt, Dani, or Estel). If
the project was already configured, run `../supabase/schema.sql` again to update
the table and move existing garage clothing entries into it. This migration is
safe to rerun. Garage tools are stored separately in `public.garage_tools`,
with a description for each tool; rerun the schema to create the table and
move existing garage tools into it. Garage products (such as paint, solvents,
and sprays) are stored separately in `public.garage_products`, with only a
description and an optional expiry date; rerun the schema to create the table
and move existing garage product entries into it. The clothing, tools, and
products lists can each be hidden independently.

The first authorized sign-in creates the household record. Existing
`ourhouse-items-v1` Local Storage data is migrated to Supabase; if a server
record already exists, items are merged by ID and the browser's older item
replaces a matching server item. The old Local Storage entry is removed only
after the server save succeeds. Previously attached PDFs that lived in a
local folder need to be attached again; new PDF attachments are uploaded to the
private `ourhouse-pdfs` bucket.
