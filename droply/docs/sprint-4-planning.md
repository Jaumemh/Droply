# Sprint 4 - Subida a Storage y Barra de Progreso

## Sprint Planning
**Meta del sprint**  
Integrar Supabase Storage con el bucket privado `droply-files`, permitir subidas de hasta `50 MB`, mostrar progreso real con porcentaje, MB transferidos y tiempo restante estimado, y registrar automaticamente el evento `UPLOAD` en `events`.

**Backlog**
1. Configurar la subida real a `droply-files` mediante URL firmada.
2. Mostrar barra de progreso real con porcentaje, MB y ETA.
3. Validar el limite estricto de `50 MB`.
4. Registrar metadatos en `files` al completar la subida.
5. Registrar `UPLOAD` en `events` con trazabilidad completa.
6. Ajustar UI para que el flujo de subida sea claro y estable.
7. Documentar la latencia observada y las decisiones de estabilizacion.

**Estimacion**
- Integracion Storage + subida firmada: `5 SP`
- UI de progreso y ETA: `5 SP`
- Registro en Postgres + evento `UPLOAD`: `3 SP`
- Documentacion y chequeo de rendimiento: `3 SP`

**Total**: `16 SP`

## Criterios de Aceptacion
- [ ] El usuario puede seleccionar un archivo y subirlo al bucket privado `droply-files`.
- [ ] El sistema rechaza archivos mayores de `50 MB`.
- [ ] La barra de progreso muestra porcentaje real de subida.
- [ ] La UI muestra MB transferidos y tiempo restante estimado.
- [ ] El criterio de referencia `10 MB en <=15 s` queda documentado como objetivo de rendimiento.
- [ ] Al finalizar la subida se inserta la fila en `files`.
- [ ] Al finalizar la subida se registra el evento `UPLOAD` en `events`.
- [ ] La subida respeta `owner_id` y las politicas RLS existentes.
- [ ] La documentacion explica como se reduce la latencia y como se estabiliza el flujo.

## Check-in Semanal
**Progreso esperado**
- Storage integrado con bucket privado.
- Subida real funcionando con control de progreso.
- Metadatos persistidos en `files` tras completar la subida.
- Evento `UPLOAD` registrado automaticamente.

**Bloqueos resueltos**
- Se evita el acceso publico directo al bucket.
- La subida usa URL firmada para mantener el bucket privado.
- El progreso deja de ser simulado y pasa a ser medido por bytes reales enviados.

**Que mostrar en la demo funcional**
- Seleccionar un archivo.
- Ver la barra de progreso con porcentaje, MB y ETA.
- Confirmar que el archivo aparece en `files`.
- Confirmar que el evento `UPLOAD` queda registrado en `events`.
- Mostrar que el limite de `50 MB` bloquea archivos demasiado grandes.
