# Sprint 7 - Check-in semanal

## Progreso
- El visor comparte la misma URL firmada que usa la descarga temporal.
- Las imagenes se cargan con placeholder y render progresivo.
- Los PDF ya quedan integrados en la app.
- Los DOCX se abren con visor compatible guiado desde la previsualizacion.
- Al hacer clic en la card del archivo se abre la previsualizacion.
- El fallback para otros tipos ya esta definido.

## Riesgos resueltos
- Se evita mostrar una pantalla vacia cuando el archivo no es imagen o PDF.
- La UI no bloquea el flujo mientras se resuelve la carga del preview.
- La vista reutiliza el acceso temporal del bucket privado sin exponer URLs publicas.

## Demo funcional
- Abrir un enlace compartido autenticado.
- Hacer clic en la card del archivo para abrir la vista previa.
- Mostrar imagen o PDF renderizado dentro de la app.
- Mostrar DOCX con acceso guiado al visor web compatible.
- Mostrar el fallback de un archivo no soportado.
- Descargar desde la misma URL firmada sin salir del flujo.
