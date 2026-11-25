# makinau.githhub.io
Dani Macaya Hub

## Accés als projectes

Els projectes demanen autenticació amb el compte Supabase autoritzat. Un cop iniciada la sessió, es pot navegar entre les carpetes sense tornar a autenticar-se. La sessió es desa a `localStorage` i es comparteix entre OurHouse, MyUni, Compartides i la portada.

El guard de les pàgines estàtiques és una barrera d’interfície, no una protecció del contingut HTML: GitHub Pages publica aquests fitxers i no pot exigir autenticació al servidor. No hi publiquis informació confidencial sense moure-la a un servei amb autorització al servidor.

## Llista de la compra

La llista de la compra i les dades d’OurHouse es desen a Supabase. Per crear les taules i les polítiques d’accés, executa [`supabase/schema.sql`](./supabase/schema.sql) a l’SQL Editor de Supabase. La clau publicable del client no és un secret; no hi posis mai una clau `service_role`. Les polítiques RLS protegeixen les dades de Supabase.
