# Sprint 7 - Planificacion

## Meta
Implementar un modulo de previsualizacion rapido para archivos compartidos usando URLs firmadas de Supabase, con soporte para imagenes y PDF, y fallback claro para otros formatos.

## Backlog
1. Reutilizar la URL firmada generada para el enlace temporal.
2. Implementar previsualizacion de JPG, PNG y WEBP con carga progresiva.
3. Integrar visor PDF multiplataforma dentro de Flutter.
4. Abrir la previsualizacion al hacer clic en la card del archivo.
5. Crear fallback para tipos no compatibles con icono y descarga directa.
6. Optimizar carga con Future precalculado y UI no bloqueante.
7. Documentar criterios de aceptacion, demo y metricas.

## Estimacion
- Acceso a Storage firmado y carga inicial: 3 SP
- Visor de imagenes: 3 SP
- Visor PDF multiplataforma: 5 SP
- Apertura por click, fallback y documentacion: 3 SP

## Total
14 SP
