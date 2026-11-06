#!/bin/sh
# Guarda en GitHub los secretos con los que el flujo de las demos
# (.github/workflows/demos.yml) firma y notariza las demos de macOS.
#
#   sh scripts/mac-signing-secrets.sh <certificado.p12> <AuthKey_XXXX.p8> <Key ID> <Issuer ID>
#
# - certificado.p12: el «Developer ID Application» exportado desde Acceso a
#   Llaveros (clic derecho en el certificado → Exportar…), con su contraseña.
# - AuthKey_XXXX.p8: clave de la API de App Store Connect (Usuarios y acceso →
#   Integraciones → Claves del equipo), con su Key ID y el Issuer ID.
#
# Necesita la CLI de GitHub con sesión iniciada (gh auth login).
set -e
if [ $# -ne 4 ]; then
  sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
fi
P12="$1"; P8="$2"; KEY_ID="$3"; ISSUER="$4"
REPO="falconsoft3d/dmarlonstudio.com"
[ -f "$P12" ] || { echo "No existe $P12"; exit 1; }
[ -f "$P8" ] || { echo "No existe $P8"; exit 1; }
gh auth status > /dev/null 2>&1 || { echo "Inicie sesión en GitHub: gh auth login"; exit 1; }

printf "Contraseña del .p12: "
stty -echo; read -r P12_PASSWORD; stty echo; echo
# Que la contraseña abra el .p12 y que traiga el certificado correcto.
openssl pkcs12 -in "$P12" -nokeys -passin "pass:$P12_PASSWORD" -legacy 2>/dev/null \
  | grep -q "Developer ID Application" \
  || openssl pkcs12 -in "$P12" -nokeys -passin "pass:$P12_PASSWORD" 2>/dev/null \
  | grep -q "Developer ID Application" \
  || { echo "El .p12 no abre con esa contraseña o no es un «Developer ID Application»"; exit 1; }

base64 -i "$P12" | gh secret set MACOS_CERT_P12 -R "$REPO"
printf %s "$P12_PASSWORD" | gh secret set MACOS_CERT_PASSWORD -R "$REPO"
base64 -i "$P8" | gh secret set APPLE_API_KEY -R "$REPO"
printf %s "$KEY_ID" | gh secret set APPLE_API_KEY_ID -R "$REPO"
printf %s "$ISSUER" | gh secret set APPLE_API_ISSUER -R "$REPO"
echo "Listo. La próxima compilación de las demos (o Actions → demos → Run workflow) las firma y notariza."
