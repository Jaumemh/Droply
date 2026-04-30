# Sprint 7 - Criterios de aceptacion

- La previsualizacion usa URLs firmadas de Supabase.
- Las imagenes JPG, PNG y WEBP se muestran en la app.
- Los PDF se renderizan dentro de la app sin descarga externa.
- Los DOCX disponen de vista previa en web mediante visor compatible o apertura guiada.
- La UI muestra placeholder durante la carga y no bloquea la pantalla.
- El render inicial del archivo se resuelve en `<=2 s` en el caso normal.
- Los tipos no compatibles muestran icono representativo y boton de descarga directa.
- La solucion funciona en Android, Web y Desktop.
- El acceso sigue limitado al bucket privado `droply-files`.
- La demo permite mostrar el flujo de apertura temporal del archivo compartido.
