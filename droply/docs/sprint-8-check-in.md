# Sprint 8 - Check-in semanal

## Progreso
- El enlace temporal valida token, revocacion y caducidad.
- La pagina publica muestra solo el nombre y el tamano del archivo.
- La descarga usa URL firmada sobre el bucket privado.
- Se registra auditoria al abrir y al descargar.

## Seguridad resuelta
- El visitante no accede a tablas privadas del propietario.
- El token actua como unica referencia publica y caduca automaticamente.
- La URL final es firmada y de corta duracion.
- La pagina no es indexable por buscadores.

## Demo funcional
- Abrir un enlace valido.
- Ver nombre y tamano del archivo.
- Pulsar `Descargar archivo`.
- Probar un token caducado para ver la pantalla de error.

