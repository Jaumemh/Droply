# Memoria tecnica final - Estructura propuesta

## 1. Portada
- Titulo del proyecto
- Autor
- Centro
- Curso/grupo
- Fecha

## 2. Resumen ejecutivo
- Problema detectado
- Solucion propuesta
- Resultado del MVP

## 3. Descripcion del problema
- Necesidad de compartir archivos de forma rapida y segura
- Limitaciones de soluciones genericas
- Objetivo de reducir pasos y aumentar control

## 4. Objetivos del proyecto
- Objetivo general
- Objetivos especificos
- KPIs del MVP

## 5. Solucion tecnica
- Flutter como cliente multiplataforma
- Supabase como backend
- Auth OTP por email
- Storage privado
- RLS y auditoria

## 6. Arquitectura del sistema
- Capas de la app
- Flujo de autenticacion
- Flujo de subida
- Flujo de comparticion
- Flujo de visitante

## 7. Modelo de datos
- `users`
- `folders`
- `files`
- `shares`
- `events`
- Relaciones y cardinalidades

## 8. Esquema ER final
- Usuario propietario
- Carpetas jerarquicas con `parent_id`
- Archivos con `folder_id`
- Enlaces temporales con `token`
- Eventos de auditoria

## 9. Seguridad
- RLS por tabla
- Bucket privado
- URL firmadas
- Tokens opacos y caducidad

## 10. Implementacion
- Autenticacion
- CRUD carpetas
- CRUD archivos
- Subida con progreso
- Comparticion temporal
- Visor de visitante

## 11. Pruebas y validacion
- Login <= 30 s
- Subida 10 MB <= 15 s
- Render <= 2 s
- Compartir en <= 3 toques

## 12. Resultados y conclusiones
- Cumplimiento de KPIs
- Riesgos residuales
- Posibles mejoras futuras

## 13. Anexos
- Capturas
- Tabla de acciones
- Checklist de entrega

