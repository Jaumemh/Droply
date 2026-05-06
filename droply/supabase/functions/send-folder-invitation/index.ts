import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { SMTPClient } from 'https://deno.land/x/denomailer/mod.ts';

const GMAIL_USER = Deno.env.get('GMAIL_USER');
const GMAIL_APP_PASSWORD = Deno.env.get('GMAIL_APP_PASSWORD');

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-supabase-api-version',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function buildPlainTextEmail(params: {
  senderEmail: string;
  folderName: string;
  permission: string;
  formattedExpiry: string;
  invitationLink: string;
  message?: string | null;
}) {
  const lines = [
    'Invitación a carpeta compartida - Droply',
    '',
    `${params.senderEmail} te ha invitado a acceder a una carpeta compartida en Droply:`,
    '',
    `Carpeta: ${params.folderName}`,
    `Permisos: ${params.permission}`,
    `Válido hasta: ${params.formattedExpiry}`,
    params.message ? `Mensaje: ${params.message}` : null,
    '',
    `Acepta la invitación aquí: ${params.invitationLink}`,
    '',
    'Droply',
  ];

  return lines.filter(Boolean).join('\n');
}

function buildHtmlEmail(params: {
  senderEmail: string;
  folderName: string;
  permission: string;
  formattedExpiry: string;
  invitationLink: string;
  message?: string | null;
}) {
  return `
    <!DOCTYPE html>
    <html lang="es">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Invitación a carpeta compartida - Droply</title>
    </head>
    <body style="margin:0;padding:0;background-color:#f3f4f6;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif;">
      <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f3f4f6;padding:40px 20px;">
        <tr>
          <td align="center">
            <table width="600" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 6px rgba(0,0,0,0.1);">
              <tr>
                <td style="background:linear-gradient(135deg,#10B981 0%,#059669 100%);padding:40px 30px;text-align:center;">
                  <div style="background-color:#ffffff;width:80px;height:80px;margin:0 auto 20px;border-radius:50%;display:flex;align-items:center;justify-content:center;">
                    <span style="font-size:42px;line-height:1;">📁</span>
                  </div>
                  <h1 style="margin:0;color:#ffffff;font-size:28px;font-weight:700;">Invitación a Carpeta Compartida</h1>
                  <p style="margin:10px 0 0;color:rgba(255,255,255,0.9);font-size:16px;">Droply - compartir archivos fácilmente</p>
                </td>
              </tr>
              <tr>
                <td style="padding:40px 30px;">
                  <p style="font-size:16px;color:#374151;line-height:1.6;margin:0 0 20px;">Hola,</p>
                  <p style="font-size:16px;color:#374151;line-height:1.6;margin:0 0 20px;">
                    <strong style="color:#10B981;">${params.senderEmail}</strong> te ha invitado a acceder a una carpeta compartida en <strong>Droply</strong>.
                  </p>
                  <div style="background-color:#f9fafb;border:2px solid #e5e7eb;border-radius:12px;padding:24px;margin:24px 0;">
                    <div style="display:flex;align-items:center;margin-bottom:16px;">
                      <span style="font-size:32px;margin-right:12px;">📁</span>
                      <h2 style="margin:0;font-size:20px;color:#111827;font-weight:600;">${params.folderName}</h2>
                    </div>
                    <div style="border-top:1px solid #e5e7eb;padding-top:16px;">
                      <p style="margin:0 0 8px;font-size:14px;color:#6b7280;">
                        <strong>Permisos:</strong> <span style="color:#10B981;font-weight:600;">${params.permission}</span>
                      </p>
                      <p style="margin:0;font-size:14px;color:#6b7280;">
                        <strong>Válido hasta:</strong> ${params.formattedExpiry}
                      </p>
                    </div>
                  </div>
                  ${params.message ? `
                  <div style="background-color:#eff6ff;border-left:4px solid #3b82f6;padding:16px;margin:24px 0;border-radius:0 8px 8px 0;">
                    <p style="margin:0;font-size:14px;color:#1e40af;font-style:italic;">"${params.message}"</p>
                  </div>
                  ` : ''}
                  <p style="font-size:16px;color:#374151;line-height:1.6;margin:24px 0 32px;">
                    Para aceptar la invitación y acceder a la carpeta, haz clic en el botón de abajo:
                  </p>
                  <div style="text-align:center;margin:32px 0;">
                    <a href="${params.invitationLink}" style="display:inline-block;background:linear-gradient(135deg,#10B981 0%,#059669 100%);color:#ffffff;text-decoration:none;padding:16px 40px;border-radius:12px;font-weight:600;font-size:16px;box-shadow:0 4px 6px rgba(16,185,129,0.3);">
                      Aceptar invitación
                    </a>
                  </div>
                  <p style="font-size:14px;color:#6b7280;line-height:1.6;margin:24px 0 0;">O copia y pega este enlace en tu navegador:</p>
                  <div style="background-color:#f9fafb;padding:12px;border-radius:8px;margin-top:8px;word-break:break-all;">
                    <code style="font-size:13px;color:#059669;">${params.invitationLink}</code>
                  </div>
                  <div style="border-top:2px solid #e5e7eb;margin-top:40px;padding-top:24px;">
                    <p style="font-size:13px;color:#9ca3af;line-height:1.5;margin:0;">
                      <strong>Importante:</strong> Esta invitación expira el <strong>${params.formattedExpiry}</strong>.
                      Si no reconoces al remitente, puedes ignorar este correo de forma segura.
                    </p>
                  </div>
                </td>
              </tr>
              <tr>
                <td style="background-color:#f9fafb;padding:30px;text-align:center;border-top:1px solid #e5e7eb;">
                  <p style="margin:0 0 8px;font-size:14px;color:#6b7280;font-weight:600;">Droply</p>
                  <p style="margin:0;font-size:12px;color:#9ca3af;">Compartir archivos de forma sencilla</p>
                  <div style="margin-top:16px;">
                    <a href="https://droply.app" style="color:#10B981;text-decoration:none;font-size:12px;margin:0 8px;">Sitio web</a>
                    <span style="color:#d1d5db;">•</span>
                    <a href="https://droply.app/help" style="color:#10B981;text-decoration:none;font-size:12px;margin:0 8px;">Ayuda</a>
                  </div>
                  <p style="margin:16px 0 0;font-size:11px;color:#9ca3af;">© ${new Date().getFullYear()} Droply. Todos los derechos reservados.</p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
  `;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { status: 200, headers: corsHeaders });
  }

  try {
    const { to, invitationLink, folderName, senderEmail, message, permission, expiresAt } = await req.json();

    if (!to || !invitationLink || !folderName || !senderEmail) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    if (!GMAIL_USER || !GMAIL_APP_PASSWORD) {
      console.error('Missing environment variables: GMAIL_USER or GMAIL_APP_PASSWORD');
      return new Response(
        JSON.stringify({ error: 'Email service not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const expiryDate = new Date(expiresAt);
    const formattedExpiry = expiryDate.toLocaleDateString('es-ES', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });

    const emailParams = {
      senderEmail,
      folderName,
      permission,
      formattedExpiry,
      invitationLink,
      message,
    };

    const plainTextContent = buildPlainTextEmail(emailParams);
    const htmlContent = buildHtmlEmail(emailParams);

    const client = new SMTPClient({
      connection: {
        hostname: 'smtp.gmail.com',
        port: 465,
        tls: true,
        auth: {
          username: GMAIL_USER!,
          password: GMAIL_APP_PASSWORD!,
        },
      },
    });

    await client.send({
      from: GMAIL_USER!,
      to,
      subject: `Droply: invitación de ${senderEmail} para ${folderName}`,
      content: plainTextContent,
      html: htmlContent,
    });

    await client.close();

    return new Response(
      JSON.stringify({ success: true, message: 'Invitation sent successfully' }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (error) {
    console.error('Error sending invitation:', error);
    return new Response(
      JSON.stringify({
        error: error?.message || 'Failed to send invitation',
        details: error?.toString?.() || String(error),
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
