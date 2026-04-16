# Droply

Base multiplataforma de Flutter + Supabase para el Sprint 1 de infraestructura y datos.

## Stack
- Flutter para Android, Web y Desktop
- Supabase Auth, Postgres y Storage
- RLS desde el arranque del proyecto

## Configuracion rapida
1. Sustituye los placeholders de `.env.example` o pasa los valores reales con `--dart-define`.
2. Ejecuta `flutter pub get`.
3. Lanza la app con `flutter run -d chrome` o el target que necesites.

## Supabase
- Migracion inicial: `supabase/migrations/0001_sprint1_infra.sql`
- Bucket privado: `droply-files`
- Convencion de Storage: `auth.uid()/folder_or_root/uuid-filename.ext`

## Documentacion del sprint
- Planning y checks Trello: `docs/sprint-1-planning.md`
