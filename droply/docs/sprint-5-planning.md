# Sprint 5 - Comparticion y URLs Prefirmadas

## Sprint Planning
**Meta del sprint**  
Permitir compartir archivos mediante un enlace temporal seguro con token unico, caducidad por defecto de 7 dias, URLs prefirmadas para acceso controlado y una vista de visitante minimalista con auditoria de accesos.

**Backlog**
1. Generar enlaces con token unico en `shares`.
2. Crear el flujo de resolucion del token para obtener URL firmada.
3. Diseñar la vista de visitante para previsualizar o descargar.
4. Registrar accesos y descargas en `events`.
5. Mantener el flujo de compartir en `<=3` tocs.
6. Documentar el proceso y el criterio de seguridad.

**Estimacion**
- Token unico + caducidad: `3 SP`
- URLs firmadas + resolucion segura: `5 SP`
- Vista visitante: `4 SP`
- Auditoria + documentacion: `4 SP`

**Total**: `16 SP`

## Criterios de Aceptacion
- [ ] El usuario puede crear un enlace de comparticion desde el detalle del archivo.
- [ ] Cada enlace usa un `link_token` unico.
- [ ] La caducidad por defecto es de 7 dias.
- [ ] El archivo solo se accede a traves del enlace temporal y de una URL firmada.
- [ ] La vista visitante permite previsualizar imagenes y PDF cuando aplica.
- [ ] La vista visitante permite descargar el archivo.
- [ ] Cada acceso o descarga genera un evento en `events`.
- [ ] El flujo de compartir se completa en `<=3` tocs.

## Check-in Semanal
**Progreso esperado**
- Enlace temporal generado con token opaco.
- Acceso resolvido mediante URL firmada.
- Pantalla visitante lista para preview y descarga.
- Auditoria preparada para PREVIEW y DOWNLOAD.

**Bloqueos resueltos**
- El bucket sigue privado; no se abre acceso publico directo.
- El visitante no necesita autenticacion para acceder al enlace temporal.
- El control del acceso se centra en el token y en la caducidad.

**Que mostrar en la demo funcional**
- Crear enlace desde el detalle de un archivo.
- Abrir el enlace temporal en una vista minimalista.
- Ver preview si es imagen o PDF.
- Descargar el archivo.
- Comprobar que se registra el evento asociado.
