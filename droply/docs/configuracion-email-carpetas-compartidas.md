# Configuración de Email para Carpetas Compartidas

## 📧 Reutilizar SMTP de Supabase Auth

Ya tienes Gmail SMTP configurado para OTP en **Authentication > Email > SMTP Settings**. 
Vamos a usar esas **mismas credenciales** para las invitaciones de carpetas compartidas.

---

## 🔧 Pasos de Configuración

### 1️⃣ Obtener las credenciales actuales

1. Ve a **Supabase Dashboard**
2. Navega a **Authentication > Email**
3. Haz clic en la pestaña **SMTP Settings**
4. Verás tu configuración actual:
   ```
   Host: smtp.gmail.com
   Port: 465 (o 587)
   Username: tu-email@gmail.com ← COPIA ESTE
   Password: •••••••••••••• ← ESTE LO TIENES GUARDADO
   Sender email: tu-email@gmail.com
   Sender name: Droply (o como lo tengas)
   ```

### 2️⃣ Configurar las variables de entorno de la Edge Function

1. Ve a **Project Settings** (icono engranaje abajo izquierda)
2. Navega a **Edge Functions** en el menú lateral
3. Haz clic en la pestaña **Secrets**
4. Agrega estas 2 variables con los valores que copiaste:

   **Secret 1:**
   ```
   Name: GMAIL_USER
   Value: [tu email de Gmail, el mismo que está en SMTP Settings]
   ```

   **Secret 2:**
   ```
   Name: GMAIL_APP_PASSWORD
   Value: [la contraseña de app de Gmail, la misma que está en SMTP Settings]
   ```

5. Haz clic en **Add secret** para cada una

---

## 📤 Desplegar la Edge Function

Una vez configuradas las variables, despliega la función:

```powershell
# Desde la carpeta raíz del proyecto
cd "c:\Users\jaume\Documents\PI FINAL\droply"

# Desplegar la función
supabase functions deploy send-folder-invitation
```

---

## 🧪 Probar que funciona

### Desde Supabase Dashboard:

1. Ve a **Edge Functions > send-folder-invitation**
2. Haz clic en **Invoke**
3. Usa este JSON de prueba:

```json
{
  "to": "tu-email-de-prueba@gmail.com",
  "invitationLink": "https://droply.app/#/accept-folder-invitation?token=test123",
  "folderName": "Carpeta de Prueba",
  "senderEmail": "remitente@ejemplo.com",
  "message": "Te invito a colaborar en esta carpeta",
  "permission": "Ver y descargar",
  "expiresAt": "2026-05-12T17:39:27.320099Z"
}
```

4. Si recibes el email, ¡funciona! ✅

---

## 📧 Ejemplo del Email que se envía

El email que recibirán los invitados tendrá:

- ✅ Diseño profesional con gradiente verde
- ✅ Icono de carpeta compartida
- ✅ Nombre de la carpeta y quién la comparte
- ✅ Nivel de permisos (Ver, Descargar, Subir, Control total)
- ✅ Fecha de expiración (7 días)
- ✅ Mensaje personalizado (opcional)
- ✅ Botón grande "Aceptar Invitación"
- ✅ Link alternativo por si no funciona el botón
- ✅ Footer con branding de Droply

---

## 🔐 Seguridad

- Las credenciales SMTP se almacenan encriptadas en Supabase
- Nunca se exponen en el código fuente
- Solo las Edge Functions con permisos pueden acceder a ellas
- Los tokens de invitación expiran en 7 días
- Cada token es único (32 bytes aleatorios)

---

## ⚠️ Solución de Problemas

### "Failed to send invitation"

1. Verifica que las variables estén bien escritas (GMAIL_USER, GMAIL_APP_PASSWORD)
2. Confirma que la contraseña de app de Gmail sea válida
3. Revisa los logs en **Edge Functions > send-folder-invitation > Logs**

### "Authentication failed"

- La contraseña de app de Gmail expiró o es incorrecta
- Regenera una nueva en: https://myaccount.google.com/apppasswords
- Actualiza el secret GMAIL_APP_PASSWORD

### El email no llega

- Revisa la carpeta de Spam
- Verifica que el email de destino sea válido
- Confirma en Gmail > Configuración > Cuentas que SMTP está activo

---

## 📋 Checklist Final

- [ ] GMAIL_USER configurado en Edge Functions > Secrets
- [ ] GMAIL_APP_PASSWORD configurado en Edge Functions > Secrets
- [ ] Edge Function desplegada con `supabase functions deploy send-folder-invitation`
- [ ] Migración de base de datos aplicada (`0009_folder_sharing_system.sql`)
- [ ] Prueba de invitación enviada y recibida correctamente

---

## 🚀 Listo para usar

Una vez completados todos los pasos:

1. Abre Droply en el navegador
2. Haz clic en el botón verde **Compartir** de cualquier carpeta
3. Ingresa un email
4. Selecciona permisos
5. Haz clic en **Enviar invitación**
6. El destinatario recibirá un email profesional con el enlace para aceptar

¡El sistema está completo y funcionando! 🎉
