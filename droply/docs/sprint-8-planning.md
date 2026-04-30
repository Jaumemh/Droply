# Sprint 8 - Planificacion

## Meta
Implementar el acceso de visitante con validacion de token, pagina web de descarga, auditoria de accesos y bloqueo de enlaces caducados o revocados.

## Backlog
1. Validar el token del enlace contra la tabla `shares`.
2. Mostrar pagina publica con nombre del archivo, tamano y boton de descarga.
3. Registrar evento `ACCESS` al abrir el enlace y `DOWNLOAD` al pulsar descargar.
4. Bloquear enlaces revocados o caducados con pantalla de error clara.
5. Evitar indexacion con meta-tags `noindex`.
6. Documentar criterios de aceptacion y demo.

## Estimacion
- Validacion de token y auditoria: 5 SP
- Vista web de visitante: 4 SP
- Seguridad, noindex y errores: 3 SP
- Documentacion: 2 SP

## Total
14 SP

