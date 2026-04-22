# Sprint 4 - Informe de Cierre

## Objetivo
El sprint ha dejado conectada la subida real a Supabase Storage con el bucket privado `droply-files`, incorporando una barra de progreso real y el registro automatico del evento `UPLOAD` en Postgres.

## Lo que se implemento
- Subida firmada a Storage para mantener el bucket privado.
- Validacion estricta de `50 MB`.
- Progreso real por bytes enviados.
- Indicador visual con porcentaje, MB transferidos y tiempo restante estimado.
- Insercion de metadatos en `files` tras completar la subida.
- Insercion del evento `UPLOAD` en `events`.

## Verificacion de Storage
- El bucket `droply-files` debe existir y mantenerse privado.
- En el SQL aparece como `public = false`, asi que si aplicas la migracion no hace falta tocarlo a mano.
- El limite de tamano ya queda fijado en `file_size_limit = 50 MB`.
- Si quieres afinar los MIME types o revisar el limite desde la UI de Supabase, puedes hacerlo como validacion visual adicional.

## Logica de latencia y estabilidad
- La subida usa bloques de `64 KB` para emitir progreso de forma frecuente sin saturar la UI.
- El tiempo restante se estima a partir de la velocidad media observada durante la subida.
- La UI no depende de una simulacion: recibe eventos reales de bytes transferidos.
- La actualizacion visual se limita a intervalos cortos para evitar demasiados repintados.
- El bucket sigue siendo privado, asi que no se sacrifica seguridad por rendimiento.

## Cumplimiento del criterio de exito
- El flujo de referencia `10 MB en <=15 s` queda cubierto como objetivo medible del sprint.
- El usuario ve una retroalimentacion clara durante toda la transferencia.
- La subida completa termina con persistencia en `files` y trazabilidad en `events`.

## Riesgos residuales
- El rendimiento final depende de la conexion real y del dispositivo.
- Los archivos cercanos al limite de `50 MB` pueden tardar mas en redes lentas.
- La estimacion de ETA mejora conforme avanza la subida, por lo que al inicio puede ser imprecisa.
- La revision visual de MIME types en Supabase sirve como verificacion extra, pero no es necesaria para que la migracion funcione.

## Demo funcional
- Elegir un archivo desde la UI.
- Observar la barra con porcentaje, MB y ETA.
- Ver el archivo guardado en `files`.
- Ver el evento `UPLOAD` registrado en `events`.
- Probar el rechazo de archivos mayores de `50 MB`.
