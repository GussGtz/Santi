# Santi

Invitación web al cumple 8 de Santi: viernes 16 de octubre, 4:00 PM, Salón de Fiestas Mar (Cancún).

- `index.html`: la página lista para publicar en un hosting.
- `invitacion-santi.html`: la misma página sin el encabezado del documento.
- `supabase.sql`: prepara la tabla `Santi` en Supabase.

Para activar las confirmaciones, ejecuta `supabase.sql` en el SQL Editor de Supabase.

## Lista de confirmados

`admin.html` muestra quién ha confirmado. Pide una contraseña, que se crea la primera vez que se abre la página. `supabase-admin.sql` contiene las funciones que la protegen.

## App instalable (PWA)

`manifest.webmanifest`, `sw.js` y la carpeta `icons/` permiten instalar la invitación en el teléfono y abrirla sin conexión. Si cambias `index.html`, sube el número de `VERSION` en `sw.js`.
