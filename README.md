<div align="center">

```
██████╗ ██████╗  ██████╗ ██████╗ ██╗  ██╗   ██╗
██╔══██╗██╔══██╗██╔═══██╗██╔══██╗██║  ╚██╗ ██╔╝
██║  ██║██████╔╝██║   ██║██████╔╝██║   ╚████╔╝ 
██║  ██║██╔══██╗██║   ██║██╔═══╝ ██║    ╚██╔╝  
██████╔╝██║  ██║╚██████╔╝██║     ███████╗██║   
╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝   
```

**Gestor de archivos en la nube · Multiplataforma · Seguro por diseño**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-RLS-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![License](https://img.shields.io/badge/Licencia-Confidencial-red?style=for-the-badge)](LICENSE)

*Trabajo de Fin de Grado · Ciclo Formativo de Grado Superior en Desarrollo de Aplicaciones Multiplataforma (DAM) · Abril 2026*

</div>

---

## 📋 Índice

- [Descripción](#-descripción)
- [Stack tecnológico](#-stack-tecnológico)
- [Arquitectura](#-arquitectura)
- [Modelo de base de datos](#-modelo-de-base-de-datos)
- [Funcionalidades](#-funcionalidades)
- [Seguridad](#-seguridad)
- [Instalación y configuración](#-instalación-y-configuración)
- [Estructura del proyecto](#-estructura-del-proyecto)
- [Sprints y metodología](#-sprints-y-metodología)
- [KPIs del MVP](#-kpis-del-mvp)
- [Riesgos residuales](#-riesgos-residuales)
- [Glosario](#-glosario)

---

## 📦 Descripción

**Droply** es una aplicación multiplataforma de gestión de archivos en la nube desarrollada con **Flutter** y **Supabase**. Cubre el ciclo completo de un gestor colaborativo: autenticación sin contraseña (OTP), organización jerárquica de carpetas, subida real de archivos con barra de progreso, compartición temporal segura mediante URLs firmadas, previsualización de imágenes y PDFs, acceso de visitante externo sin cuenta y auditoría completa de todas las acciones críticas.

El proyecto fue construido de forma iterativa a lo largo de **10 sprints**, evolucionando desde un scaffold vacío de Flutter hasta una plataforma colaborativa con carpetas compartidas, invitaciones por email y cuatro niveles de permiso.

> 📌 **Plataformas soportadas:** iOS · Android · Web · Desktop

---

## 🛠 Stack tecnológico

| Capa | Tecnología | Función |
|------|-----------|---------|
| **Frontend / Mobile** | Flutter 3.x | UI multiplataforma — iOS, Android, Web, Desktop |
| **Backend as a Service** | Supabase | Auth + PostgreSQL + Storage + Edge Functions |
| **Base de datos** | PostgreSQL | Gestionado por Supabase |
| **Seguridad** | Row Level Security (RLS) | Políticas por `owner_id = auth.uid()` |
| **Almacenamiento** | Supabase Storage | Bucket privado `droply-files` |
| **Funciones serverless** | Supabase Edge Functions (Deno) | Envío de invitaciones por email (SMTP/Gmail) |
| **Visor PDF** | syncfusion_flutter_pdfviewer | Soporte Android, Web y Desktop |

---

## 🏗 Arquitectura

Droply sigue un modelo de **tres capas claramente separadas**:

```
┌─────────────────────────────────────────────────────────┐
│                CAPA DE SEGURIDAD (transversal)          │
│   RLS · Tokens opacos · Bucket privado · Auditoría     │
├────────────────────────────────────┬────────────────────┤
│       CAPA DE BACKEND (Supabase)   │                    │
│  Auth OTP · PostgreSQL (5 tablas) │  Edge Functions    │
│  Storage (droply-files) · RPCs    │  (send-invitation) │
├────────────────────────────────────┴────────────────────┤
│                CAPA DE FRONTEND (Flutter)               │
│  OtpLoginPage · AuthGate · DashboardView               │
│  ShareViewerPage · FolderSharingDialog                 │
└─────────────────────────────────────────────────────────┘
```

### Patrón Repository + Controller

La capa de autenticación y datos sigue el patrón **Repository + Controller**:

```
AuthRepository (interfaz abstracta)
    ├── SupabaseAuthRepository  → implementación real con supabase_flutter
    └── UnsupportedAuthRepository → fallback seguro sin credenciales

AuthController (ChangeNotifier)
    └── Expone estado (AuthStatus) y acciones (sendOtp, verifyOtp, signOut)
```

Esto permite sustituir implementaciones por mocks en tests sin modificar la UI.

---

## 🗄 Modelo de base de datos

### 5 tablas de dominio

```sql
users        → Sincronizada desde auth.users via trigger
folders      → Jerarquía ilimitada via parent_id (autorreferenciado)
files        → Metadatos + ruta en Storage; soft delete con is_deleted
shares       → Token único opaco; permiso, expiración y revocación
events       → Registro de auditoría INMUTABLE (no UPDATE / no DELETE)
```

### Campos clave

| Tabla | Campo | Tipo | Descripción |
|-------|-------|------|-------------|
| `users` | `role` | text | `'free'` o `'admin'` — por defecto `'free'` |
| `users` | `quota_mb` | integer | Cuota en MB — por defecto 1024 MB |
| `folders` | `parent_id` | uuid FK NULL | Carpeta padre (`NULL` = raíz) |
| `files` | `storage_path` | text UNIQUE | Ruta en el bucket de Storage |
| `files` | `size_bytes` | bigint | Máx. 50 MB (52 428 800 bytes) |
| `files` | `is_deleted` | boolean | Soft delete — por defecto `false` |
| `shares` | `token` | text UNIQUE | Mínimo 16 caracteres, sin datos sensibles |
| `shares` | `expires_at` | timestamptz | Debe ser `> created_at` |
| `events` | `action` | enum | `UPLOAD · DOWNLOAD · PREVIEW · DELETE · SHARE_CREATE · SHARE_REVOKE · ACCESS` |

### Triggers de integridad

| Trigger | Función |
|---------|---------|
| `on_auth_user_created` | Crea perfil en `public.users` al registrarse. Idempotente con `ON CONFLICT DO UPDATE` |
| `validate_folder_parent_owner` | Valida que `parent_id` pertenezca al mismo `owner_id` |
| `validate_file_folder_owner` | Valida que `folder_id` pertenezca al mismo `owner_id` |
| `validate_share_file_owner` | Valida que `file_id` pertenezca al mismo `owner_id` |

### Índices de rendimiento

```
folders_owner_parent_idx      → owner_id, parent_id
files_owner_folder_created_idx → owner_id, folder_id, created_at DESC
shares_owner_file_idx         → owner_id, file_id
shares_token_idx              → token
events_user_created_idx       → user_id, created_at DESC
events_file_created_idx       → file_id, created_at DESC
```

---

## ✨ Funcionalidades

### 🔐 Autenticación OTP (Sprint 2)
- Flujo de 2 pasos sin contraseña: email → código de 6 dígitos
- Sesión persistente gestionada por Supabase Auth
- Estados: `unknown → unauthenticated → otpSent → authenticated`
- Reenvío con cooldown de 30 segundos visible en pantalla
- Manejo de errores inline sin abandonar el paso actual

### 📁 Gestión de carpetas y archivos (Sprints 3–4)
- CRUD completo de carpetas con jerarquía ilimitada via `parent_id`
- Navegación breadcrumb con carga dinámica por carpeta activa
- Subida de archivos hasta 50 MB con barra de progreso real
  - Transferencia en bloques de 64 KB
  - Porcentaje + MB transferidos + ETA calculado por velocidad media
  - Registro automático del evento `UPLOAD` en la tabla `events`
- Borrado sincronizado: primero Storage, luego `is_deleted = true` en BD
- Mover archivos entre carpetas

### 🔗 Compartición y URLs firmadas (Sprints 5–8)
- Generación de tokens opacos con caducidad configurable (por defecto 7 días)
- Flujo completo en ≤ 3 taps desde el dashboard
- Vista pública en `/share/<token>` accesible sin autenticación
  - Preview de imágenes (JPG, PNG, WEBP) y PDFs
  - Fallback con icono MIME para formatos no soportados
- Revocación inmediata desde el servidor
- Meta-tags `noindex` para evitar indexación por buscadores

### 🔍 Búsqueda y filtros (Sprint 6)
- Búsqueda por nombre en tiempo real (filtro en memoria, sin llamadas extra)
- Chips de filtro por tipo: **Todos · PDF · Imágenes · Otros**
- Estados vacíos diferenciados: sin archivos / sin resultados

### 👥 Carpetas compartidas (Sprint Final)
- Invitaciones por email via Edge Function (Deno Mailer + Gmail SMTP)
- **4 niveles de permiso:** `view · download · upload · full`
- Herencia de permisos a subcarpetas
- Aceptación segura via token con validación de estado y expiración
- Revocación de acceso inmediata y auditable

### 📊 Auditoría completa (Sprint 10)
- 5 eventos auditados: `UPLOAD · SHARE_CREATE · PREVIEW · ACCESS · DOWNLOAD`
- Tabla `events` inmutable por diseño (sin UPDATE ni DELETE)
- Registro de `ip_client`, `user_agent` y `metadata` JSON en cada evento

---

## 🔒 Seguridad

### Row Level Security (RLS)

RLS está habilitado en **todas las tablas de dominio**. Cada usuario solo puede ver y modificar sus propios recursos:

| Tabla | Operaciones | Condición |
|-------|-------------|-----------|
| `users` | SELECT, UPDATE | `id = auth.uid()` |
| `folders` | SELECT, INSERT, UPDATE, DELETE | `owner_id = auth.uid()` |
| `files` | SELECT, INSERT, UPDATE, DELETE | `owner_id = auth.uid()` |
| `shares` | SELECT, INSERT, UPDATE, DELETE | `owner_id = auth.uid()` |
| `events` | SELECT, INSERT | `user_id = auth.uid()` |

> ⚠️ El bucket `droply-files` es **privado** (`public: false`). No existe ninguna ruta de acceso público directo. Las políticas de Storage usan el prefijo `auth.uid()/` en el nombre del objeto.

### Funciones RPC (security definer)

Todas las RPCs operan bajo el rol `security definer`:

| RPC | Función |
|-----|---------|
| `create_share_link` | Genera token opaco, calcula expiración |
| `resolve_share_token` | Resuelve token y devuelve URL firmada de corta duración |
| `crear_invitacion_de_carpeta` | Valida carpeta/dueño, genera token seguro |
| `aceptar_invitacion_de_carpeta` | Valida token/correo/estado, crea/actualiza acceso |
| `el_usuario_tiene_acceso_a_la_carpeta` | Verifica propiedad/acceso y permiso activo |
| `obtener_carpetas_compartidas_para_el_usuario` | Lista carpetas con dueño, miembros y conteo |
| `revocar_comparticion_de_carpeta` | Elimina acceso inmediatamente y de forma auditable |

---

## 🚀 Instalación y configuración

### Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado y en el `PATH`
- Proyecto creado en [Supabase](https://supabase.com)
- Acceso al SQL Editor de Supabase

### 1. Clonar el repositorio

```bash
git clone https://github.com/Jaumemh/Droply.git
cd Droply
```

### 2. Configurar variables de entorno

```bash
cp .env.example .env
```

Edita `.env` con tus credenciales de Supabase:

```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key-publica
```

> Encontrarás estos valores en: **Project Settings → API → Project URL / anon public**

### 3. Ejecutar migraciones de base de datos

Ejecuta los archivos en orden desde el SQL Editor de Supabase:

```
supabase/migrations/0001_sprint1_infra.sql
supabase/migrations/0002_sprint5_sharing.sql
supabase/migrations/0003_...sql
supabase/migrations/0005_sprint8_access_event.sql
supabase/migrations/0009_folder_sharing_system.sql
```

> Las migraciones son idempotentes y pueden re-ejecutarse sin riesgo.

### 4. Configurar autenticación OTP

En Supabase → **Authentication → Email Templates**, sustituye:

```
{{ .ConfirmationURL }}   →   {{ .Token }}
```

### 5. Configurar Edge Function (invitaciones por email)

En Supabase → **Edge Functions → Environment Variables**, añade:

```
GMAIL_USER=tu-cuenta@gmail.com
GMAIL_APP_PASSWORD=tu-app-password-de-gmail
```

Despliega la función:

```bash
supabase functions deploy send-folder-invitation
```

### 6. Instalar dependencias y arrancar

```bash
flutter pub get
flutter run                                        # desarrollo local
flutter run --dart-define=ENV=production          # producción
```

La app arrancará en `AuthGate` y detectará automáticamente el estado de sesión.

---

## 📂 Estructura del proyecto

```
droply/
├── lib/
│   ├── main.dart                          # Bootstrap de la app
│   ├── app/
│   │   └── app.dart                       # MaterialApp raíz
│   ├── core/
│   │   ├── config/
│   │   │   ├── env.dart                   # EnvConfig con fallback a .env.example
│   │   │   └── supabase_config.dart       # Init condicional de Supabase
│   │   └── network/
│   │       └── app_http_client.dart       # Cliente HTTP condicional (io/web)
│   └── features/
│       ├── auth/
│       │   ├── auth_controller.dart       # ChangeNotifier — estado y acciones
│       │   ├── auth_repository.dart       # Interfaz abstracta
│       │   ├── auth_status.dart           # Enum AuthStatus
│       │   ├── supabase_auth_repository.dart   # Implementación real
│       │   ├── unsupported_auth_repository.dart # Fallback sin credenciales
│       │   └── presentation/
│       │       ├── auth_gate.dart         # Enrutador por estado de sesión
│       │       └── otp_login_page.dart    # UI de login en 2 pasos
│       ├── dashboard/
│       │   ├── data/
│       │   │   └── file_browser_repository.dart  # CRUD + subida firmada
│       │   └── presentation/
│       │       ├── dashboard_controller.dart      # Controlador del Tauler
│       │       └── dashboard_view.dart            # Vista principal
│       └── sharing/
│           ├── share_repository.dart     # RPCs de compartición
│           └── share_viewer_page.dart    # Vista pública del visitante
├── supabase/
│   ├── migrations/
│   │   ├── 0001_sprint1_infra.sql        # Esquema base, RLS, triggers, bucket
│   │   ├── 0002_sprint5_sharing.sql      # RPCs create/resolve share
│   │   ├── 0005_sprint8_access_event.sql # Evento ACCESS en enum
│   │   └── 0009_folder_sharing_system.sql # Sistema carpetas compartidas
│   └── functions/
│       └── send-folder-invitation/       # Edge Function SMTP
├── .env.example                          # Plantilla de variables de entorno
└── pubspec.yaml
```

---

## 🏃 Sprints y metodología

El proyecto se desarrolló con metodología ágil en sprints de **16 Story Points** cada uno:

| Sprint | Contenido | SP |
|--------|-----------|-----|
| **Sprint 1** | Infraestructura base: esquema BD, RLS, Storage, scaffold Flutter | 16 + 2 fixes |
| **Sprint 2** | Autenticación OTP: flujo 2 pasos, Repository + Controller, AuthGate | 16 |
| **Sprint 3** | CRUD de carpetas y archivos (metadatos en Postgres) | 16 |
| **Sprint 4** | Subida real a Storage: barra de progreso, ETA, evento UPLOAD | 16 |
| **Sprint 5** | Compartición y URLs prefirmadas: tokens opacos, vista pública | 16 |
| **Sprint 6** | Búsqueda, filtros por tipo y cierre del tablero | 16 |
| **Sprint 7** | Previsualización de archivos: imágenes, PDF (Syncfusion), fallback | 16 |
| **Sprint 8** | Acceso de visitante sin cuenta, auditoría de accesos, noindex | 16 |
| **Sprint 9** | Organización: mover archivos, borrado sincronizado Storage + BD | 16 |
| **Sprint 10** | Auditoría completa (5 eventos) y documentación final del MVP | 16 |
| **Sprint Final** | Sistema de carpetas compartidas: invitaciones, permisos, revocación | — |

**Total: 162 SP entregados · 100% de criterios de aceptación completados**

---

## 📈 KPIs del MVP

| KPI | Objetivo | Estado |
|-----|----------|--------|
| Login OTP completo | ≤ 30 s | ⏳ Pendiente validar en dispositivo físico |
| Subida 10 MB | ≤ 15 s | 📋 Documentado como criterio de referencia |
| Apertura / render de archivo | ≤ 2 s | ⏳ Pendiente benchmark en dispositivo físico |
| Flujo de compartición | ≤ 3 taps | ✅ Cumplido — verificado en demo |
| Ratio comparticiones | ≥ 0,6 | 📋 Métrica M1 definida para validación |

---

## ⚠️ Riesgos residuales

| Riesgo | Estado |
|--------|--------|
| Captura de IP real del visitante | ⏳ Pendiente — requiere edge function adicional |
| Preview PDF en navegadores sin soporte | ✅ Aceptado — sin bloqueo funcional |
| ETA imprecisa al inicio de subida | ✅ Aceptado — mejora con datos acumulados |
| Herencia de permisos en jerarquías profundas | ⏳ Pendiente de revisión |
| Configuración SMTP en producción | ⏳ Pendiente de verificación |
| `flutter analyze` con 0 warnings | ⚠️ Imprescindible antes de entrega definitiva |

---

## 📖 Glosario

| Término | Definición |
|---------|------------|
| **RLS** | Row Level Security — mecanismo de PostgreSQL que restringe el acceso a filas según el usuario autenticado |
| **OTP** | One-Time Password — código de 6 dígitos de un solo uso enviado por email |
| **AuthGate** | Componente Flutter que enruta al usuario según su estado de sesión |
| **Repository Pattern** | Patrón que abstrae la capa de datos detrás de una interfaz |
| **Signed URL** | URL temporal de Supabase Storage que permite acceso a objetos privados durante tiempo limitado |
| **Edge Function** | Función serverless en Deno desplegada en la infraestructura de Supabase |
| **Soft delete** | Borrado lógico con `is_deleted = true` sin eliminar físicamente de la BD |
| **BaaS** | Backend as a Service — Supabase en este proyecto |
| **Breadcrumbs** | Ruta de navegación jerárquica que muestra la posición dentro de la estructura de carpetas |

---

## 📄 Licencia

Este proyecto es un **Trabajo de Fin de Grado** desarrollado con fines académicos. Confidencial — Abril 2026.

---

<div align="center">

**Droply** · Flutter + Supabase · TFG 2.º DAM · Abril 2026

*Primera a décima entrega completada ✓*

</div>
