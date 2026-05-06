# Script para desplegar la función de invitaciones

Write-Host "📧 Desplegando Edge Function: send-folder-invitation" -ForegroundColor Cyan
Write-Host ""

# Verificar que estamos en el directorio correcto
$expectedPath = "c:\Users\jaume\Documents\PI FINAL\droply"
$currentPath = Get-Location

if ($currentPath.Path -ne $expectedPath) {
    Write-Host "❌ Error: Debes estar en la carpeta raíz del proyecto" -ForegroundColor Red
    Write-Host "   Ubicación actual: $currentPath" -ForegroundColor Yellow
    Write-Host "   Ubicación esperada: $expectedPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Ejecuta:" -ForegroundColor Cyan
    Write-Host "  cd '$expectedPath'" -ForegroundColor White
    exit 1
}

# Verificar que existe la función
$functionPath = "supabase\functions\send-folder-invitation\index.ts"
if (-not (Test-Path $functionPath)) {
    Write-Host "❌ Error: No se encuentra la función en $functionPath" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Función encontrada" -ForegroundColor Green
Write-Host ""

# Recordatorio de configuración
Write-Host "⚠️  IMPORTANTE: Antes de desplegar, asegúrate de tener configuradas las variables:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   En Supabase Dashboard > Project Settings > Edge Functions > Secrets:" -ForegroundColor White
Write-Host "   • GMAIL_USER (el mismo email que usas para OTP)" -ForegroundColor White
Write-Host "   • GMAIL_APP_PASSWORD (la misma contraseña que usas para OTP)" -ForegroundColor White
Write-Host ""

$response = Read-Host "¿Ya configuraste las variables? (s/n)"
if ($response -ne "s" -and $response -ne "S") {
    Write-Host ""
    Write-Host "❌ Configuración cancelada" -ForegroundColor Red
    Write-Host ""
    Write-Host "Pasos:" -ForegroundColor Cyan
    Write-Host "  1. Ve a tu proyecto en Supabase Dashboard" -ForegroundColor White
    Write-Host "  2. Project Settings > Edge Functions > Secrets" -ForegroundColor White
    Write-Host "  3. Agrega GMAIL_USER y GMAIL_APP_PASSWORD" -ForegroundColor White
    Write-Host "  4. Ejecuta este script de nuevo" -ForegroundColor White
    exit 0
}

Write-Host ""
Write-Host "🚀 Desplegando función..." -ForegroundColor Cyan

# Desplegar la función
try {
    supabase functions deploy send-folder-invitation --no-verify-jwt
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ ¡Función desplegada exitosamente!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Próximos pasos:" -ForegroundColor Cyan
        Write-Host "  1. Aplica la migración de BD si no lo has hecho:" -ForegroundColor White
        Write-Host "     supabase db reset" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  2. Prueba enviando una invitación desde la app" -ForegroundColor White
        Write-Host ""
        Write-Host "  3. O prueba manualmente en Dashboard > Edge Functions > send-folder-invitation > Invoke" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "❌ Error al desplegar la función" -ForegroundColor Red
        Write-Host "   Revisa los mensajes de error arriba" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host ""
    Write-Host "❌ Error: $_" -ForegroundColor Red
    exit 1
}
