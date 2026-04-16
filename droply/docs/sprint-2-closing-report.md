# Sprint 2 - Informe de Cierre

## Objetivo del sprint
Implementar un flujo de autenticacion OTP por email con 2 pasos visibles, sesion persistente y una shell autenticada minima para Droply.

## Resultado funcional
- Paso 1: el usuario introduce su email y solicita un codigo OTP.
- Paso 2: el usuario introduce un codigo de 6 digitos y valida la sesion.
- Si existe una sesion persistida, la app entra directamente al dashboard autenticado.
- La app permite cerrar sesion y volver al flujo de acceso.

## Logica tecnica
- La autenticacion se centraliza en `AuthController` y `AuthRepository`.
- `SupabaseAuthRepository` encapsula `signInWithOtp`, `verifyOTP`, `currentSession`, `currentUser` y `onAuthStateChange`.
- `AuthGate` decide entre login OTP y dashboard autenticado segun el estado de sesion.
- La persistencia se delega a `supabase_flutter`, evitando almacenamiento manual adicional.

## Seguridad
- No se usa contrasena local ni se almacena OTP en el dispositivo.
- El codigo se verifica contra Supabase Auth usando `verifyOTP`.
- La sesion persistida depende del mecanismo nativo del SDK de Supabase.
- El bucket sigue siendo privado y las politicas RLS del Sprint 1 siguen vigentes.
- Para enviar codigos por email y no magic links, la plantilla de Supabase debe usar `{{ .Token }}`.

## Cumplimiento del flujo de entrada de 2 pasos
- El paso 1 solicita email y muestra una unica accion principal: enviar codigo.
- El paso 2 bloquea el email actual, solicita OTP de 6 digitos y ofrece verificar, reenviar y cambiar email.
- El flujo visible se mantiene en 2 pasos y se optimiza para completarse en `<=30 s`.

## UX y validaciones
- Validacion minima de formato email.
- OTP limitado a 6 digitos.
- Mensajes de error para email invalido, OTP invalido, OTP expirado y fallos de red.
- Cooldown de 30 segundos para reenviar codigo.
- Mensaje de ayuda para revisar spam o promociones.

## Riesgos residuales
- La entrega real del email depende de la configuracion SMTP/Auth de Supabase.
- El tiempo `<=30 s` depende de latencia de red y del proveedor de correo.
- Si la plantilla de email mantiene `{{ .ConfirmationURL }}`, Supabase enviara magic link en lugar de OTP.

## Demo funcional esperada
- Usuario abre la app sin sesion y ve el login de 2 pasos.
- Solicita OTP, introduce codigo y entra al dashboard autenticado.
- Cierra la app y vuelve a abrirla: la sesion se restaura.
- Cierra sesion y la app vuelve al login.
