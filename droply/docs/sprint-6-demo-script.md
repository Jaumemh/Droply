# Sprint 6 - Guion tecnico para la demo

## Objetivo
Mostrar el flujo critico completo de Droply sin salir del caso de uso principal:
**Alta OTP -> Subida 10 MB -> Compartir -> Acceso visitante**

## Guion
1. **Inicio de la app**
   - Mostrar la pantalla de acceso.
   - Indicar que el login es por email OTP y no requiere contrasena.
2. **Alta OTP**
   - Introducir email.
   - Solicitar codigo.
   - Introducir OTP de 6 digitos.
   - Confirmar entrada al tablero autenticado.
3. **Subida de archivo de 10 MB**
   - Abrir selector de archivos.
   - Elegir un archivo de ejemplo de 10 MB.
   - Mostrar barra de progreso, porcentaje, MB transferidos y tiempo restante.
   - Resaltar el objetivo de `<= 15 s`.
4. **Compartir**
   - Abrir el archivo subido.
   - Pulsar `Compartir`.
   - Copiar enlace temporal.
   - Explicar caducidad por defecto de 7 dias.
5. **Acceso visitante**
   - Abrir el enlace en otra ventana o perfil.
   - Mostrar la pantalla minimalista del archivo.
   - Descargar el archivo usando URL firmada.
6. **Cierre**
   - Resumir que se han validado autenticacion, almacenamiento, comparticion y acceso temporal.

## Mensajes clave para verbalizar
- `Droply reduce el flujo a pasos cortos y medibles.`
- `La subida se controla con progreso real y ETA.`
- `La comparticion usa enlaces temporales y bucket privado.`
- `El acceso del visitante sigue protegido por autenticacion.`

