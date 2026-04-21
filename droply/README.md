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

## Configuracion OTP por email
- Activa `Email Auth` en Supabase Auth.
- Configura la plantilla para enviar OTP por email.
- Usa `{{ .Token }}` en la plantilla.
- No uses `{{ .ConfirmationURL }}` si quieres un codigo de 6 digitos en lugar de magic link.

## Documentacion del sprint
- Planning y checks Trello: `docs/sprint-1-planning.md`
- Informe de cierre Sprint 2: `docs/sprint-2-closing-report.md`
- Planning Sprint 3: `docs/sprint-3-planning.md`
- Check-in Sprint 3: `docs/sprint-3-closing-report.md`
