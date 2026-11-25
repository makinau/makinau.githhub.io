# makinau.githhub.io
Dani Macaya Hub

## Llista de la compra

La llista es desa a Supabase i és compartida entre els usuaris autenticats del projecte d’OurHouse. Per crear les taules i les polítiques d’accés, executa [`supabase/schema.sql`](./supabase/schema.sql) a l’SQL Editor de Supabase.

La pàgina reutilitza la sessió de Supabase Auth desada al navegador. Per tant, OurHouse i aquesta pàgina han de fer servir el mateix projecte Supabase i obrir-se des del mateix domini. La clau publicable del client no és un secret; no hi posis mai una clau `service_role`. Les polítiques RLS de l’esquema limiten l’accés als usuaris autenticats.
