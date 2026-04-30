# Sprint 8 - Criterios de aceptacion

- El token se valida contra `shares` y solo se acepta si existe, no esta revocado y no ha caducado.
- La vista de visitante muestra nombre del archivo y tamano.
- El boton `Descargar archivo` usa la URL firmada del bucket privado.
- Al abrir el enlace se registra un evento `ACCESS`.
- Al descargar se registra un evento `DOWNLOAD`.
- Los enlaces invalidos o caducados muestran `Enlace caducado o no disponible`.
- La pagina incluye meta-tags `noindex`.
- El visitante no necesita ver datos privados del propietario.

