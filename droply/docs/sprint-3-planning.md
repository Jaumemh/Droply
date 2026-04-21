# Sprint 3 - CRUD de Carpetas y Archivos

## Sprint Planning
**Meta del sprint**  
Construir el `Tauler` operativo de Droply para listar, crear, renombrar y eliminar carpetas y archivos con Supabase Postgres, respetando `owner_id` y las politicas RLS del Sprint 1.

**Backlog**
1. Crear la capa de datos para `folders` y `files`.
2. Implementar navegación por `parent_id` para recorrer la jerarquia.
3. Diseñar el `Tauler` con tarjetas de carpetas y filas de archivos.
4. Añadir acciones CRUD con validacion basica de nombres.
5. Mantener la seguridad por usuario autenticado y RLS.
6. Documentar el flujo de navegacion entre carpetas.

**Estimacion**
- Capa de datos y queries: `4 SP`
- Navegacion por carpetas: `3 SP`
- UI del Tauler: `5 SP`
- CRUD y validaciones: `4 SP`

**Total**: `16 SP`

## Criterios de Aceptacion
- [ ] El `Tauler` lista carpetas y archivos del usuario autenticado.
- [ ] Las carpetas se muestran como tarjetas.
- [ ] Los archivos se muestran como filas en una tabla/lista.
- [ ] Se puede crear una carpeta en menos de `2 s` en el caso feliz.
- [ ] Se puede renombrar una carpeta.
- [ ] Se puede eliminar una carpeta propia.
- [ ] Se puede crear un archivo de metadatos.
- [ ] Se puede renombrar un archivo.
- [ ] Se puede eliminar un archivo propio.
- [ ] La navegacion entra y sale de carpetas usando `parent_id`.
- [ ] Todas las operaciones respetan `owner_id` y RLS.

## Check-in Semanal
**Progreso**
- Se ha creado la base del CRUD de carpetas y archivos.
- El `Tauler` ya esta pensado como vista jerarquica y no como lista plana.
- La navegacion se resuelve cargando el nivel actual segun `parent_id`.

**Bloqueos resueltos**
- No se rompe la seguridad al navegar porque cada query sigue filtrando por `owner_id`.
- La jerarquia no necesita un arbol complejo en memoria: se calcula por el folder actual.
- El dashboard se mantiene coherente con la guia visual azul de Droply.

**Demo funcional**
- Crear carpeta desde el Tauler.
- Entrar en una carpeta haciendo clic en su tarjeta.
- Renombrar y eliminar carpetas y archivos.
- Volver a la raiz desde la ruta de navegacion.
