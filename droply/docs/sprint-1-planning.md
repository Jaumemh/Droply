# Sprint 1 - Infraestructura y Datos

## Sprint Planning
**Meta del sprint**  
Dejar Droply lista para empezar a desarrollar funcionalidades reales sobre una base segura y multiplataforma: proyecto Flutter preparado para Android, Web y Desktop, integracion base con Supabase, modelo de datos inicial en Postgres, bucket privado en Storage y auditoria preparada.

**Backlog**
1. Limpiar el scaffold Flutter y dejar un arranque tecnico de producto.
2. Integrar `supabase_flutter` y configuracion por entorno.
3. Generar el esquema SQL inicial en Supabase Postgres.
4. Activar RLS y politicas de propiedad por usuario.
5. Configurar bucket privado `droply-files` y politicas de Storage.
6. Preparar auditoria con la tabla `events`.
7. Sustituir el test demo por un smoke test del shell de infraestructura.

**Estimacion**
- Configuracion Flutter + bootstrap Supabase: `3 SP`
- Modelo SQL + constraints + indices: `5 SP`
- RLS + bucket privado + politicas de Storage: `5 SP`
- Auditoria + tests + documentacion: `3 SP`

**Total**: `16 SP`

## Criterios de Aceptacion
- [ ] La app Flutter arranca con la misma base para Android, Web y Desktop.
- [ ] `main.dart` ya no contiene el contador demo.
- [ ] Existe `.env.example` con `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
- [ ] Supabase se inicializa desde una configuracion centralizada.
- [ ] Existe la migracion SQL con tablas `users`, `folders`, `files`, `shares` y `events`.
- [ ] Todas las tablas tienen PK, FK, `created_at` y restricciones de integridad basicas.
- [ ] `folders` soporta jerarquia con `parent_id`.
- [ ] `files` guarda `owner_id`, `folder_id`, `mime_type`, `size_bytes` y `storage_path`.
- [ ] `shares` soporta `token`, `permission`, `expires_at` y `revoked`.
- [ ] `events` soporta `UPLOAD`, `DOWNLOAD` y `PREVIEW`.
- [ ] RLS esta activado en todas las tablas de dominio.
- [ ] Cada usuario autenticado solo puede operar sobre sus propios registros.
- [ ] El bucket `droply-files` es privado.
- [ ] No existe acceso publico directo a los objetos del bucket.
- [ ] La ruta de Storage queda fijada al prefijo `auth.uid()/...`.
- [ ] Existen politicas de Storage alineadas con ese prefijo.
- [ ] Hay indices sobre `owner_id`, `folder_id`, `token` y fechas.

## Check-in Semanal
**Progreso**
- Base Flutter convertida en shell de infraestructura.
- Supabase preparada para configurarse por entorno.
- Esquema SQL inicial generado con RLS, indices y bucket privado.
- Auditoria lista para el siguiente sprint funcional.

**Bloqueos resueltos**
- Se evita el acceso publico directo a Storage desde el sprint 1.
- Se separa el acceso compartido futuro del acceso autenticado mediante una estrategia posterior con signed URLs o RPC.
- Se reemplaza el scaffold roto del proyecto por una base mantenible.

**Demo funcional**
- Arranque de Droply con pantalla de estado de infraestructura.
- Inicializacion de Supabase por entorno.
- Script SQL de creacion de tablas y politicas.
- Bucket privado `droply-files` con control por prefijo de usuario.
