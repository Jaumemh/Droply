# Sprint 9 - Criterios de aceptacion

- La navegacion por carpetas respeta `parent_id` y `owner_id`.
- Crear carpeta genera un registro valido en `folders`.
- Renombrar carpeta actualiza su nombre sin romper jerarquia.
- Mover archivo actualiza `folder_id` y el archivo aparece en la nueva carpeta.
- Eliminar archivo borra el objeto de Storage y marca `is_deleted = true`.
- El contenido de carpetas se organiza sin mostrar archivos ajenos al usuario.
- El borrado de carpetas mantiene la integridad referencial y no rompe la vista.

